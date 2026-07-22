import Phaser from 'phaser';
import { Palette, mix, cssHex } from '../core/Palette';
import {
  AETHER,
  BASTION,
  DEPTH,
  GAME_WIDTH,
  GAME_HEIGHT,
  RARITY_COLOR,
} from '../config';
import { freshModifiers } from '../types';
import type { RunModifiers } from '../types';
import { getRealm } from '../data/realms';
import { getChampion } from '../data/champions';
import { getEnemy } from '../data/enemies';
import { BOONS } from '../data/boons';
import type { BoonDef } from '../types';
import { effectiveStats, settleRun, snapshotUnlocks } from '../core/Meta';
import { Save } from '../core/Save';
import { Audio } from '../core/Audio';
import { label, drawPanel, fadeTo, button } from '../core/UI';
import type { IArena, ProjectileConfig, DamageOpts, Vec } from '../game/Arena';
import { Enemy } from '../game/Enemy';
import { Champion } from '../game/Champion';
import { Warden } from '../game/Warden';
import { Projectile } from '../game/Projectile';

type RunState = 'intro' | 'playing' | 'boon' | 'paused' | 'over';

/**
 * GameScene — the battlefield. This is where the three influences fuse:
 *  · Kingdom Rush: enemies march lanes toward your Bastion.
 *  · Clash Royale: spend regenerating Aether to deploy champion cards.
 *  · Archero: pilot the Warden — move to reposition, stand still to fire, and
 *    pick a Boon after every wave.
 */
export class GameScene extends Phaser.Scene implements IArena {
  // ── IArena state ──
  enemies: Enemy[] = [];
  champions: Champion[] = [];
  warden!: Warden;
  mods: RunModifiers = freshModifiers();
  bastion: Vec = { x: GAME_WIDTH / 2, y: GAME_HEIGHT - 150 };

  private projectiles: Projectile[] = [];
  private realmId = 'broken-gate';
  private deck: string[] = [];
  private paths: Vec[][] = [];
  private integrity = BASTION.maxIntegrity;
  private aether = AETHER.start;
  private state: RunState = 'intro';

  private waveIndex = -1;
  private remainingToSpawn = 0;
  private goldEarned = 0;
  private kills = 0;

  // Field geometry.
  private fieldTop = 96;
  private fieldBottom = GAME_HEIGHT - 250;
  private wardenBounds!: Phaser.Geom.Rectangle;

  // Input / deploy.
  private selectedCard = -1;
  private cardCooldown: number[] = [];
  private ghost?: Phaser.GameObjects.Image;
  private ghostRing?: Phaser.GameObjects.Graphics;
  private joyActive = false;
  private joyId = -1;
  private joyOrigin = { x: 0, y: 0 };
  private joyPointer?: Phaser.Input.Pointer;
  private joyBase?: Phaser.GameObjects.Graphics;

  // HUD refs.
  private integrityBar!: Phaser.GameObjects.Graphics;
  private integrityText!: Phaser.GameObjects.Text;
  private waveText!: Phaser.GameObjects.Text;
  private goldText!: Phaser.GameObjects.Text;
  private aetherBar!: Phaser.GameObjects.Graphics;
  private aetherText!: Phaser.GameObjects.Text;
  private wardenHpBar!: Phaser.GameObjects.Graphics;
  private ultButton!: Phaser.GameObjects.Container;
  private ultFill!: Phaser.GameObjects.Graphics;
  private bossBar!: Phaser.GameObjects.Container;
  private cards: Phaser.GameObjects.Container[] = [];
  private bastionSprite!: Phaser.GameObjects.Image;

  private bastionFlash = 0;

  constructor() {
    super('Game');
  }

  create(data: { realmId?: string; deck?: string[] }) {
    this.realmId = data?.realmId ?? 'broken-gate';
    this.deck = (data?.deck ?? Save.data.deck).slice(0, 4);
    const realm = getRealm(this.realmId);

    // Reset per-run state (scenes are reused).
    this.enemies = [];
    this.champions = [];
    this.projectiles = [];
    this.mods = freshModifiers();
    this.integrity = BASTION.maxIntegrity;
    this.aether = AETHER.start;
    this.waveIndex = -1;
    this.remainingToSpawn = 0;
    this.goldEarned = 0;
    this.kills = 0;
    this.selectedCard = -1;
    this.cardCooldown = this.deck.map(() => 0);
    this.state = 'intro';
    this.cards = [];

    this.cameras.main.fadeIn(300, 5, 7, 15);
    this.cameras.main.setBackgroundColor(realm.ground2);

    this.drawField(realm);
    this.buildPaths(realm.lanes);
    this.buildBastion();

    this.wardenBounds = new Phaser.Geom.Rectangle(40, this.fieldTop + 30, GAME_WIDTH - 80, this.fieldBottom - this.fieldTop - 10);
    this.warden = new Warden(this, GAME_WIDTH / 2, this.fieldBottom - 40);

    this.buildHud(realm);
    this.buildInput();

    // Intro banner then first wave.
    this.showBanner(realm.name.toUpperCase(), realm.subtitle, () => {
      this.state = 'playing';
      this.startNextWave();
    });
  }

  // ────────────────────────────────────────────────────────
  // Field & paths
  // ────────────────────────────────────────────────────────
  private drawField(realm: ReturnType<typeof getRealm>) {
    const g = this.add.graphics().setDepth(DEPTH.ground);
    const bands = 20;
    for (let i = 0; i < bands; i++) {
      const t = i / (bands - 1);
      g.fillStyle(mix(realm.ground, realm.ground2, t), 1);
      g.fillRect(0, (GAME_HEIGHT / bands) * i, GAME_WIDTH, GAME_HEIGHT / bands + 1);
    }
    // Subtle ground texture blotches.
    for (let i = 0; i < 40; i++) {
      const x = Math.random() * GAME_WIDTH;
      const y = this.fieldTop + Math.random() * (GAME_HEIGHT - this.fieldTop);
      g.fillStyle(mix(realm.ground, Palette.black, 0.25), 0.15);
      g.fillCircle(x, y, 20 + Math.random() * 50);
    }
    // Vignette.
    const vig = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'fx:glow-rush').setDisplaySize(GAME_WIDTH * 2, GAME_HEIGHT * 2).setTint(Palette.night0).setAlpha(0.5).setDepth(DEPTH.decal);
    vig.setBlendMode(Phaser.BlendModes.MULTIPLY);
  }

  private buildPaths(lanes: number) {
    const realm = getRealm(this.realmId);
    const bx = this.bastion.x;
    const by = this.bastion.y;
    const g = this.add.graphics().setDepth(DEPTH.path);
    for (let i = 0; i < lanes; i++) {
      const startX = GAME_WIDTH * ((i + 1) / (lanes + 1));
      const wander = (i % 2 === 0 ? 1 : -1) * 40;
      const pts: Vec[] = [
        { x: startX, y: -30 },
        { x: startX, y: this.fieldTop + 40 },
        { x: Phaser.Math.Linear(startX, bx, 0.35) + wander, y: GAME_HEIGHT * 0.34 },
        { x: Phaser.Math.Linear(startX, bx, 0.7) - wander, y: GAME_HEIGHT * 0.55 },
        { x: bx + (i - (lanes - 1) / 2) * 34, y: by - 90 },
        { x: bx, y: by - 24 },
      ];
      this.paths.push(pts);
      this.drawPath(g, pts, realm.accent);
    }
  }

  private drawPath(g: Phaser.GameObjects.Graphics, pts: Vec[], accent: number) {
    // Smooth the polyline via a Phaser spline for a nicer trail.
    const curve = new Phaser.Curves.Spline(pts.map((p) => new Phaser.Math.Vector2(p.x, p.y)));
    const pointsResolved = curve.getPoints(64);
    // Wide dark bed.
    g.lineStyle(58, mix(Palette.night0, accent, 0.06), 0.5);
    this.strokePolyline(g, pointsResolved);
    // Inner lighter track.
    g.lineStyle(44, mix(Palette.night1, accent, 0.12), 0.6);
    this.strokePolyline(g, pointsResolved);
    // Dashed centre guide.
    g.lineStyle(3, mix(accent, Palette.white, 0.2), 0.25);
    for (let i = 0; i < pointsResolved.length - 2; i += 4) {
      g.lineBetween(pointsResolved[i].x, pointsResolved[i].y, pointsResolved[i + 1].x, pointsResolved[i + 1].y);
    }
  }

  private strokePolyline(g: Phaser.GameObjects.Graphics, pts: Phaser.Math.Vector2[]) {
    g.beginPath();
    g.moveTo(pts[0].x, pts[0].y);
    for (let i = 1; i < pts.length; i++) g.lineTo(pts[i].x, pts[i].y);
    g.strokePath();
  }

  private buildBastion() {
    const glow = this.add.image(this.bastion.x, this.bastion.y - 30, 'bastion:glow').setDisplaySize(280, 280).setAlpha(0.3).setBlendMode(Phaser.BlendModes.ADD).setDepth(DEPTH.bastion - 1).setTint(Palette.ember1);
    this.tweens.add({ targets: glow, alpha: 0.45, scale: 1.08, duration: 1800, yoyo: true, repeat: -1 });
    this.bastionSprite = this.add.image(this.bastion.x, this.bastion.y, 'bastion').setDepth(DEPTH.bastion).setOrigin(0.5, 0.82).setScale(0.9);
  }

  // ────────────────────────────────────────────────────────
  // IArena implementation
  // ────────────────────────────────────────────────────────
  /** IArena exposes the scene under `stage` (Phaser reserves `scene`). */
  get stage(): Phaser.Scene {
    return this;
  }

  spawnProjectile(cfg: ProjectileConfig) {
    this.projectiles.push(new Projectile(this, cfg));
  }

  damageEnemy(e: Enemy, dmg: number, opts: DamageOpts) {
    if (!e.alive) return;
    e.applyDamage(dmg);
    // Impact FX.
    if (opts.x !== undefined && opts.y !== undefined) {
      this.burst(opts.x, opts.y, opts.crit ? Palette.ember0 : Palette.white, opts.crit ? 6 : 3, 'fx:spark');
    }
    if (opts.crit) this.floatText(e.x, e.y - e.radius * 2, `${Math.round(dmg)}`, Palette.ember0, true);

    if (opts.burn) e.applyBurn(opts.burn);
    if (opts.slow) e.applySlow(opts.slow);

    // Warden lifesteal.
    if (opts.source === 'warden' && this.mods.lifestealPct > 0) {
      this.healWarden(dmg * this.mods.lifestealPct);
    }

    // Chain lightning.
    if (opts.chain && opts.chain > 0 && !opts.noChain) {
      const hit = this.enemiesInRadius(e.x, e.y, 150).filter((o) => o !== e).slice(0, opts.chain);
      for (const o of hit) {
        this.lightning(e.x, e.y - e.radius, o.x, o.y - o.radius);
        this.damageEnemy(o, dmg * 0.5, { source: opts.source, noChain: true, x: o.x, y: o.y - o.radius });
      }
    }
  }

  damageWarden(dmg: number) {
    this.warden.takeDamage(dmg);
  }

  damageBastion(dmg: number) {
    if (this.state === 'over') return;
    this.integrity = Math.max(0, this.integrity - dmg);
    this.bastionFlash = 1;
    Audio.hurt();
    this.shake(0.01, 150);
    if (this.integrity <= 0) this.endRun(false);
  }

  healWarden(amount: number) {
    this.warden.heal(amount);
  }

  floatText(x: number, y: number, text: string, color: number, big = false) {
    const t = this.add.text(x, y, text, {
      fontFamily: 'system-ui, sans-serif',
      fontSize: `${big ? 26 : 18}px`,
      color: cssHex(color),
      fontStyle: 'bold',
      stroke: cssHex(Palette.night0),
      strokeThickness: 4,
    }).setOrigin(0.5).setDepth(DEPTH.toast);
    this.tweens.add({
      targets: t,
      y: y - 46,
      alpha: 0,
      scale: big ? 1.3 : 1,
      duration: big ? 900 : 650,
      ease: 'Cubic.out',
      onComplete: () => t.destroy(),
    });
  }

  burst(x: number, y: number, color: number, count = 6, key = 'fx:soft') {
    const n = Math.min(count, 14);
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2;
      const spd = 30 + Math.random() * 120;
      const img = this.add.image(x, y, key).setTint(color).setDepth(DEPTH.fx).setBlendMode(Phaser.BlendModes.ADD).setScale(0.2 + Math.random() * 0.3);
      this.tweens.add({
        targets: img,
        x: x + Math.cos(a) * spd,
        y: y + Math.sin(a) * spd,
        alpha: 0,
        scale: 0,
        duration: 300 + Math.random() * 250,
        ease: 'Cubic.out',
        onComplete: () => img.destroy(),
      });
    }
  }

  ring(x: number, y: number, color: number, radius = 80) {
    const img = this.add.image(x, y, 'fx:ring').setTint(color).setDepth(DEPTH.fx).setBlendMode(Phaser.BlendModes.ADD).setScale(0.1);
    this.tweens.add({
      targets: img,
      scale: radius / 60,
      alpha: 0,
      duration: 420,
      ease: 'Cubic.out',
      onComplete: () => img.destroy(),
    });
  }

  private lightning(x1: number, y1: number, x2: number, y2: number) {
    const g = this.add.graphics().setDepth(DEPTH.fx);
    g.lineStyle(3, Palette.aether0, 0.9);
    g.beginPath();
    g.moveTo(x1, y1);
    const segs = 4;
    for (let i = 1; i < segs; i++) {
      const t = i / segs;
      const jx = Phaser.Math.Linear(x1, x2, t) + (Math.random() - 0.5) * 30;
      const jy = Phaser.Math.Linear(y1, y2, t) + (Math.random() - 0.5) * 30;
      g.lineTo(jx, jy);
    }
    g.lineTo(x2, y2);
    g.strokePath();
    this.tweens.add({ targets: g, alpha: 0, duration: 200, onComplete: () => g.destroy() });
  }

  shake(intensity: number, dur = 150) {
    if (Save.data.settings.screenShake) this.cameras.main.shake(dur, intensity);
  }

  nearestEnemy(x: number, y: number, maxDist: number, exclude?: Enemy): Enemy | null {
    let best: Enemy | null = null;
    let bestD = maxDist * maxDist;
    for (const e of this.enemies) {
      if (!e.alive || e === exclude) continue;
      const dx = e.x - x;
      const dy = e.y - e.radius * 0.5 - y;
      const d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    return best;
  }

  enemiesInRadius(x: number, y: number, radius: number): Enemy[] {
    const r2 = radius * radius;
    const out: Enemy[] = [];
    for (const e of this.enemies) {
      if (!e.alive) continue;
      const dx = e.x - x;
      const dy = e.y - y;
      if (dx * dx + dy * dy <= r2) out.push(e);
    }
    return out;
  }

  // ────────────────────────────────────────────────────────
  // Waves
  // ────────────────────────────────────────────────────────
  private startNextWave() {
    const realm = getRealm(this.realmId);
    this.waveIndex++;
    if (this.waveIndex >= realm.waves.length) {
      this.endRun(true);
      return;
    }
    // Between-wave payouts.
    if (this.waveIndex > 0) {
      this.aether = Math.min(AETHER.max, this.aether + AETHER.waveBonus);
      if (this.mods.bastionRepairPerWave > 0) {
        this.integrity = Math.min(BASTION.maxIntegrity, this.integrity + this.mods.bastionRepairPerWave);
        this.floatText(this.bastion.x, this.bastion.y - 140, `+${this.mods.bastionRepairPerWave} REPAIR`, Palette.good);
      }
    }

    const wave = realm.waves[this.waveIndex];
    const hpScale = 1 + this.waveIndex * 0.12;
    this.remainingToSpawn = 0;

    for (const group of wave.groups) {
      const laneIdx = Math.min(group.lane ?? 0, this.paths.length - 1);
      const path = this.paths[laneIdx];
      for (let k = 0; k < group.count; k++) {
        this.remainingToSpawn++;
        this.time.delayedCall(group.at + k * group.gap, () => {
          if (this.state === 'over') return;
          this.spawnEnemy(group.enemy, path, hpScale);
          this.remainingToSpawn--;
        });
      }
    }

    this.updateWaveText();
    const isBoss = wave.groups.some((g) => getEnemy(g.enemy).kind === 'boss');
    if (isBoss) {
      Audio.boss();
      this.showBanner('BOSS WAVE', 'Hold the line', undefined, Palette.danger);
    }
  }

  private spawnEnemy(id: string, path: Vec[], hpScale: number) {
    const def = getEnemy(id);
    const e = new Enemy(this, def, path, hpScale);
    this.enemies.push(e);
    // Spawn poof.
    this.burst(e.x, e.y - e.radius, def.color, 6);
  }

  private waveComplete(): boolean {
    return this.remainingToSpawn <= 0 && this.enemies.every((e) => !e.alive);
  }

  // ────────────────────────────────────────────────────────
  // Main loop
  // ────────────────────────────────────────────────────────
  override update(_time: number, delta: number) {
    if (this.state !== 'playing') return;
    const dt = Math.min(delta / 1000, 0.05);

    // Feed warden movement from the active joystick pointer.
    if (this.joyActive && this.joyPointer) {
      const dx = (this.joyPointer.x - this.joyOrigin.x) / 60;
      const dy = (this.joyPointer.y - this.joyOrigin.y) / 60;
      this.warden.setMove(Phaser.Math.Clamp(dx, -1, 1), Phaser.Math.Clamp(dy, -1, 1));
    } else {
      this.warden.setMove(0, 0);
    }

    this.warden.update(dt, this.wardenBounds);
    for (const c of this.champions) c.update(dt);
    for (const e of this.enemies) e.update(dt);
    for (const p of this.projectiles) p.update(dt);

    // Sweep dead enemies & pay bounties.
    for (const e of this.enemies) {
      if (!e.alive && !e.rewarded) {
        e.rewarded = true;
        if (!e.reachedBastion) {
          this.kills++;
          const bounty = Math.round(e.def.bounty * this.mods.goldMul);
          this.goldEarned += bounty;
          this.warden.addUlt(e.isBoss ? 40 : 4);
          this.burst(e.x, e.y - e.radius, e.def.color, e.isBoss ? 24 : 8);
          this.coinPop(e.x, e.y - e.radius, bounty);
          if (e.isBoss) {
            this.ring(e.x, e.y - e.radius, Palette.ember0, 160);
            this.shake(0.02, 400);
          }
          Audio.enemyDie();
        }
        e.destroy();
      }
    }
    this.enemies = this.enemies.filter((e) => e.alive);
    this.champions = this.champions.filter((c) => c.alive);
    this.projectiles = this.projectiles.filter((p) => p.alive);

    // Aether regen.
    this.aether = Math.min(AETHER.max, this.aether + AETHER.regenPerSec * this.mods.aetherRegenMul * dt);

    // Cooldowns.
    for (let i = 0; i < this.cardCooldown.length; i++) {
      if (this.cardCooldown[i] > 0) this.cardCooldown[i] = Math.max(0, this.cardCooldown[i] - dt);
    }

    this.updateHud(dt);

    // Wave complete → boon or victory.
    if (this.waveComplete()) {
      const realm = getRealm(this.realmId);
      if (this.waveIndex >= realm.waves.length - 1) {
        this.endRun(true);
      } else {
        this.offerBoon();
      }
    }
  }

  private coinPop(x: number, y: number, amount: number) {
    if (amount <= 0) return;
    const coin = this.add.image(x, y, 'icon:coin').setDisplaySize(20, 20).setDepth(DEPTH.fx);
    this.tweens.add({
      targets: coin,
      x: 60,
      y: 30,
      scale: 0.5,
      duration: 500,
      ease: 'Cubic.in',
      onComplete: () => coin.destroy(),
    });
  }

  // ────────────────────────────────────────────────────────
  // Boons (between-wave roguelite pick)
  // ────────────────────────────────────────────────────────
  private offerBoon() {
    this.state = 'boon';
    this.selectedCard = -1;
    this.clearGhost();
    Audio.boon();

    const picks = this.rollBoons(3);
    const overlay = this.add.container(0, 0).setDepth(DEPTH.overlay);
    const dim = this.add.graphics();
    dim.fillStyle(Palette.night0, 0.82);
    dim.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    dim.setInteractive(new Phaser.Geom.Rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT), Phaser.Geom.Rectangle.Contains);
    overlay.add(dim);

    overlay.add(label(this, GAME_WIDTH / 2, GAME_HEIGHT * 0.2, 'CHOOSE A BOON', { size: 30, weight: '900', align: 'center', letter: 2 }).setOrigin(0.5));
    overlay.add(label(this, GAME_WIDTH / 2, GAME_HEIGHT * 0.2 + 40, `Wave ${this.waveIndex + 1} cleared`, { size: 16, weight: '700', color: Palette.textDim, align: 'center' }).setOrigin(0.5));

    const cardW = GAME_WIDTH - 100;
    const cardH = 150;
    const startY = GAME_HEIGHT * 0.3;
    picks.forEach((boon, i) => {
      const y = startY + i * (cardH + 20);
      const card = this.buildBoonCard(boon, 50, y, cardW, cardH, () => {
        boon.apply(this.mods);
        Audio.victory();
        this.recomputeWarden();
        overlay.destroy();
        this.state = 'playing';
        this.time.delayedCall(280, () => this.startNextWave());
      });
      overlay.add(card);
    });

    overlay.setAlpha(0);
    this.tweens.add({ targets: overlay, alpha: 1, duration: 220 });
  }

  private rollBoons(n: number): BoonDef[] {
    const weight: Record<string, number> = { common: 10, rare: 6, epic: 3, legendary: 1 };
    const pool = BOONS.slice();
    const out: BoonDef[] = [];
    for (let i = 0; i < n && pool.length; i++) {
      const total = pool.reduce((s, b) => s + (weight[b.rarity] ?? 1), 0);
      let r = Math.random() * total;
      let idx = 0;
      for (let j = 0; j < pool.length; j++) {
        r -= weight[pool[j].rarity] ?? 1;
        if (r <= 0) {
          idx = j;
          break;
        }
      }
      out.push(pool[idx]);
      pool.splice(idx, 1);
    }
    return out;
  }

  private buildBoonCard(boon: BoonDef, x: number, y: number, w: number, h: number, onPick: () => void): Phaser.GameObjects.Container {
    const c = this.add.container(x, y);
    const rc = RARITY_COLOR[boon.rarity];
    const g = this.add.graphics();
    drawPanel(g, w, h, { fill: mix(Palette.panel, rc, 0.14), stroke: rc, strokeWidth: 3, radius: 20, highlight: true });
    c.add(g);
    // Icon disc.
    const disc = this.add.graphics();
    disc.fillStyle(mix(Palette.night1, rc, 0.3), 1);
    disc.fillCircle(80, h / 2, 48);
    disc.lineStyle(3, rc, 1);
    disc.strokeCircle(80, h / 2, 48);
    c.add(disc);
    c.add(this.add.image(80, h / 2, `icon:${boon.icon}`).setDisplaySize(52, 52));
    c.add(label(this, 150, 34, boon.name, { size: 24, weight: '900', color: Palette.text }));
    c.add(label(this, 150, 70, boon.desc, { size: 17, weight: '600', color: Palette.textDim }));
    c.add(label(this, 150, h - 34, boon.rarity.toUpperCase(), { size: 13, weight: '800', color: rc }));

    g.setInteractive(new Phaser.Geom.Rectangle(0, 0, w, h), Phaser.Geom.Rectangle.Contains);
    g.on('pointerdown', () => c.setScale(0.97));
    g.on('pointerout', () => c.setScale(1));
    g.on('pointerup', () => {
      c.setScale(1);
      onPick();
    });
    // Entrance.
    c.setAlpha(0).setX(x + 30);
    this.tweens.add({ targets: c, alpha: 1, x, duration: 260, delay: 60, ease: 'Back.out' });
    return c;
  }

  /** Warden caches stats at construction, so re-create its derived numbers. */
  private recomputeWarden() {
    // Simplest correct approach: rebuild the Warden preserving position & hp ratio.
    const oldHpFrac = this.warden.hp / this.warden.maxHp;
    const x = this.warden.x;
    const y = this.warden.y;
    const ult = this.warden.ultCharge;
    this.warden.destroy();
    this.warden = new Warden(this, x, y);
    this.warden.hp = Math.round(this.warden.maxHp * oldHpFrac);
    this.warden.ultCharge = ult;
  }

  // ────────────────────────────────────────────────────────
  // HUD
  // ────────────────────────────────────────────────────────
  private buildHud(realm: ReturnType<typeof getRealm>) {
    // Top bar: integrity + wave + gold.
    const topBg = this.add.graphics().setDepth(DEPTH.hud);
    drawPanel(topBg, GAME_WIDTH - 20, 68, { fill: Palette.night1, stroke: Palette.stroke, radius: 16, alpha: 0.9 });
    topBg.x = 10;
    topBg.y = 8;

    this.add.image(46, 34, 'bastion').setDisplaySize(30, 30).setDepth(DEPTH.hud);
    this.integrityBar = this.add.graphics().setDepth(DEPTH.hud);
    this.integrityText = label(this, 210, 26, '100', { size: 16, weight: '800', color: Palette.text }).setDepth(DEPTH.hud);

    this.waveText = label(this, GAME_WIDTH - 20, 22, 'WAVE 1', { size: 18, weight: '900', color: Palette.text, align: 'right' }).setDepth(DEPTH.hud);
    this.goldText = label(this, GAME_WIDTH - 20, 46, '0', { size: 15, weight: '700', color: Palette.warn, align: 'right' }).setDepth(DEPTH.hud);

    // Pause button.
    const pause = this.add.container(GAME_WIDTH / 2, 34).setDepth(DEPTH.hud);
    const pg = this.add.graphics();
    pg.fillStyle(Palette.panelHi, 1);
    pg.fillRoundedRect(-22, -18, 44, 36, 10);
    pg.fillStyle(Palette.text, 1);
    pg.fillRect(-8, -9, 5, 18);
    pg.fillRect(3, -9, 5, 18);
    pause.add(pg);
    pause.setSize(44, 36).setInteractive(new Phaser.Geom.Rectangle(-22, -18, 44, 36), Phaser.Geom.Rectangle.Contains);
    pause.on('pointerup', () => this.togglePause());

    // Bottom: aether bar + cards.
    const trayY = GAME_HEIGHT - 150;
    const trayBg = this.add.graphics().setDepth(DEPTH.hud);
    drawPanel(trayBg, GAME_WIDTH, 160, { fill: Palette.night1, stroke: Palette.stroke, radius: 24, alpha: 0.95 });
    trayBg.y = trayY - 6;

    // Aether bar.
    this.aetherBar = this.add.graphics().setDepth(DEPTH.hud);
    this.aetherText = label(this, GAME_WIDTH / 2, trayY + 12, '', { size: 14, weight: '800', color: Palette.night0, align: 'center' }).setOrigin(0.5).setDepth(DEPTH.hud + 1);

    // Cards.
    const n = this.deck.length;
    const cw = 150;
    const gap = 8;
    const totalW = n * cw + (n - 1) * gap;
    const startX = GAME_WIDTH / 2 - totalW / 2 + cw / 2;
    for (let i = 0; i < n; i++) {
      const cx = startX + i * (cw + gap);
      this.cards.push(this.buildCard(i, cx, trayY + 78, cw, 128));
    }

    // Warden HP bar + ult button (bottom-left / right corners above tray).
    this.wardenHpBar = this.add.graphics().setDepth(DEPTH.hud);
    this.buildUltButton();

    // Boss bar (hidden until a boss appears).
    this.bossBar = this.add.container(GAME_WIDTH / 2, 88).setDepth(DEPTH.hud).setVisible(false);
    const bg = this.add.graphics();
    drawPanel(bg, GAME_WIDTH - 60, 34, { fill: Palette.night0, stroke: Palette.danger, strokeWidth: 2, radius: 10 });
    bg.x = -(GAME_WIDTH - 60) / 2;
    const fill = this.add.graphics();
    const name = label(this, 0, -22, '', { size: 15, weight: '900', color: Palette.danger, align: 'center' }).setOrigin(0.5);
    this.bossBar.add([bg, fill, name]);
    this.bossBar.setData('fill', fill);
    this.bossBar.setData('name', name);

    void realm;
  }

  private buildCard(index: number, cx: number, cy: number, w: number, h: number): Phaser.GameObjects.Container {
    const id = this.deck[index];
    const def = getChampion(id);
    const st = Save.champion(id);
    const c = this.add.container(cx, cy).setDepth(DEPTH.hud);
    const rc = RARITY_COLOR[def.rarity];

    const g = this.add.graphics();
    drawPanel(g, w, h, { fill: mix(Palette.panel, rc, 0.12), stroke: rc, strokeWidth: 2, radius: 14, highlight: true });
    g.x = -w / 2;
    g.y = -h / 2;
    c.add(g);

    const key = st.evolved ? `champ:${id}:evo` : `champ:${id}`;
    const img = this.add.image(0, -6, key).setDisplaySize(78, 90);
    c.add(img);
    c.setData('img', img);

    // Cost pip.
    const pip = this.add.graphics();
    pip.fillStyle(Palette.aether1, 1);
    pip.fillCircle(-w / 2 + 20, -h / 2 + 20, 16);
    c.add(pip);
    c.add(label(this, -w / 2 + 20, -h / 2 + 20, `${def.cost}`, { size: 18, weight: '900', color: Palette.night0, align: 'center' }).setOrigin(0.5));
    c.add(label(this, 0, h / 2 - 16, def.name, { size: 13, weight: '800', align: 'center' }).setOrigin(0.5));

    // Selection highlight + cooldown overlay.
    const sel = this.add.graphics();
    c.add(sel);
    c.setData('sel', sel);
    const cd = this.add.graphics();
    c.add(cd);
    c.setData('cd', cd);

    c.setSize(w, h);
    c.setInteractive(new Phaser.Geom.Rectangle(-w / 2, -h / 2, w, h), Phaser.Geom.Rectangle.Contains);
    c.on('pointerup', () => this.onCardTap(index));
    return c;
  }

  private buildUltButton() {
    const x = GAME_WIDTH - 60;
    const y = GAME_HEIGHT - 200;
    const c = this.add.container(x, y).setDepth(DEPTH.hud);
    const ring = this.add.graphics();
    ring.fillStyle(Palette.night0, 0.85);
    ring.fillCircle(0, 0, 42);
    ring.lineStyle(3, Palette.ember2, 1);
    ring.strokeCircle(0, 0, 42);
    c.add(ring);
    this.ultFill = this.add.graphics();
    c.add(this.ultFill);
    c.add(this.add.image(0, 0, 'fx:orb').setDisplaySize(44, 44).setTint(Palette.ember0));
    c.add(label(this, 0, 30, 'ULT', { size: 12, weight: '900', color: Palette.ember0, align: 'center' }).setOrigin(0.5));
    c.setSize(84, 84).setInteractive(new Phaser.Geom.Circle(0, 0, 42), Phaser.Geom.Circle.Contains);
    c.on('pointerup', () => {
      if (this.warden.ultReady) {
        this.warden.releaseUlt();
      }
    });
    this.ultButton = c;
  }

  private onCardTap(index: number) {
    if (this.state !== 'playing') return;
    const def = getChampion(this.deck[index]);
    if (this.cardCooldown[index] > 0) {
      Audio.uiBack();
      return;
    }
    if (this.aether < def.cost) {
      Audio.uiBack();
      this.floatText(GAME_WIDTH / 2, GAME_HEIGHT - 180, 'NOT ENOUGH AETHER', Palette.danger);
      return;
    }
    if (this.selectedCard === index) {
      this.selectedCard = -1;
      this.clearGhost();
    } else {
      this.selectedCard = index;
      this.makeGhost(def.id);
      Audio.uiClick();
    }
  }

  private makeGhost(id: string) {
    this.clearGhost();
    const st = Save.champion(id);
    const key = st.evolved ? `champ:${id}:evo` : `champ:${id}`;
    const def = getChampion(id);
    this.ghost = this.add.image(this.warden.x, this.fieldBottom - 100, key).setDepth(DEPTH.overlay).setAlpha(0.7).setOrigin(0.5, 0.86);
    this.ghost.setScale((def.role === 'tower' ? 96 : 84) / this.ghost.height);
    this.ghostRing = this.add.graphics().setDepth(DEPTH.overlay - 1);
  }

  private clearGhost() {
    this.ghost?.destroy();
    this.ghostRing?.destroy();
    this.ghost = undefined;
    this.ghostRing = undefined;
    for (const c of this.cards) (c.getData('sel') as Phaser.GameObjects.Graphics).clear();
  }

  private validDeploy(x: number, y: number): boolean {
    if (y < this.fieldTop + 20 || y > this.fieldBottom + 40) return false;
    if (x < 30 || x > GAME_WIDTH - 30) return false;
    if (Phaser.Math.Distance.Between(x, y, this.bastion.x, this.bastion.y - 30) < 70) return false;
    for (const c of this.champions) {
      if (Phaser.Math.Distance.Between(x, y, c.x, c.y) < 44) return false;
    }
    return true;
  }

  private updateGhost(x: number, y: number) {
    if (!this.ghost || !this.ghostRing) return;
    const def = getChampion(this.deck[this.selectedCard]);
    const ok = this.validDeploy(x, y);
    this.ghost.setPosition(x, y).setTint(ok ? Palette.white : Palette.danger);
    this.ghostRing.clear();
    this.ghostRing.lineStyle(2, ok ? Palette.aether0 : Palette.danger, 0.6);
    this.ghostRing.strokeCircle(x, y, def.range);
    this.ghostRing.fillStyle(ok ? Palette.aether1 : Palette.danger, 0.08);
    this.ghostRing.fillCircle(x, y, def.range);
  }

  private tryDeploy(x: number, y: number) {
    const index = this.selectedCard;
    const def = getChampion(this.deck[index]);
    if (!this.validDeploy(x, y) || this.aether < def.cost) {
      Audio.uiBack();
      this.floatText(x, y - 20, 'INVALID', Palette.danger);
      return;
    }
    this.aether -= def.cost;
    this.cardCooldown[index] = 4 + def.cost * 0.6;
    Audio.deploy();
    this.deployChampion(def.id, x, y);
    this.selectedCard = -1;
    this.clearGhost();
  }

  private deployChampion(id: string, x: number, y: number) {
    const def = getChampion(id);
    const base = effectiveStats(def);
    const st = Save.champion(id);
    const hp = Math.round(base.hp * this.mods.championHpMul);
    const count = def.count;
    for (let i = 0; i < count; i++) {
      const ox = count > 1 ? (i - (count - 1) / 2) * 34 : 0;
      const c = new Champion(this, def, x + ox, y, { hp, damage: base.damage }, st.evolved);
      this.champions.push(c);
      if (i === 0) c.flashRange();
    }
  }

  // ────────────────────────────────────────────────────────
  // Input
  // ────────────────────────────────────────────────────────
  private buildInput() {
    // A field zone catches touches that aren't on HUD widgets (topOnly input).
    const zone = this.add.zone(0, 0, GAME_WIDTH, GAME_HEIGHT).setOrigin(0).setDepth(DEPTH.decal);
    zone.setInteractive(new Phaser.Geom.Rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT), Phaser.Geom.Rectangle.Contains);
    this.joyBase = this.add.graphics().setDepth(DEPTH.hud).setVisible(false);

    zone.on('pointerdown', (p: Phaser.Input.Pointer) => {
      if (this.state !== 'playing') return;
      if (this.selectedCard >= 0) {
        this.updateGhost(p.x, p.y);
        return;
      }
      // Start joystick.
      this.joyActive = true;
      this.joyId = p.id;
      this.joyPointer = p;
      this.joyOrigin = { x: p.x, y: p.y };
      this.drawJoy(p.x, p.y, p.x, p.y);
    });
    zone.on('pointermove', (p: Phaser.Input.Pointer) => {
      if (this.state !== 'playing') return;
      if (this.selectedCard >= 0) {
        this.updateGhost(p.x, p.y);
      } else if (this.joyActive && p.id === this.joyId) {
        this.drawJoy(this.joyOrigin.x, this.joyOrigin.y, p.x, p.y);
      }
    });
    zone.on('pointerup', (p: Phaser.Input.Pointer) => {
      if (this.selectedCard >= 0) {
        this.tryDeploy(p.x, p.y);
        return;
      }
      if (this.joyActive && p.id === this.joyId) this.endJoy();
    });
    // Safety: release joystick if the pointer leaves everything.
    this.input.on('pointerup', (p: Phaser.Input.Pointer) => {
      if (this.joyActive && p.id === this.joyId) this.endJoy();
    });
  }

  private drawJoy(ox: number, oy: number, px: number, py: number) {
    if (!this.joyBase) return;
    const g = this.joyBase.setVisible(true);
    g.clear();
    g.fillStyle(Palette.night0, 0.4);
    g.fillCircle(ox, oy, 60);
    g.lineStyle(3, Palette.ember1, 0.5);
    g.strokeCircle(ox, oy, 60);
    const dx = px - ox;
    const dy = py - oy;
    const d = Math.min(60, Math.hypot(dx, dy)) || 0.001;
    const a = Math.atan2(dy, dx);
    g.fillStyle(Palette.ember1, 0.85);
    g.fillCircle(ox + Math.cos(a) * d, oy + Math.sin(a) * d, 26);
  }

  private endJoy() {
    this.joyActive = false;
    this.joyId = -1;
    this.joyPointer = undefined;
    this.warden.setMove(0, 0);
    this.joyBase?.setVisible(false).clear();
  }

  // ────────────────────────────────────────────────────────
  // HUD update
  // ────────────────────────────────────────────────────────
  private updateHud(_dt: number) {
    // Integrity.
    this.integrityBar.clear();
    const ix = 70;
    const iw = 128;
    this.integrityBar.fillStyle(Palette.night0, 1);
    this.integrityBar.fillRoundedRect(ix, 26, iw, 16, 8);
    const frac = this.integrity / BASTION.maxIntegrity;
    this.integrityBar.fillStyle(frac > 0.5 ? Palette.good : frac > 0.25 ? Palette.warn : Palette.danger, 1);
    this.integrityBar.fillRoundedRect(ix, 26, iw * frac, 16, 8);
    this.integrityText.setText(`${Math.ceil(this.integrity)}`);
    this.integrityText.setPosition(ix + iw + 8, 26);
    this.goldText.setText(`⛃ ${this.goldEarned}`);

    // Aether.
    this.aetherBar.clear();
    const aw = GAME_WIDTH - 80;
    const ax = 40;
    const ay = GAME_HEIGHT - 150 + 4;
    this.aetherBar.fillStyle(Palette.night0, 1);
    this.aetherBar.fillRoundedRect(ax, ay, aw, 22, 11);
    const afrac = this.aether / AETHER.max;
    this.aetherBar.fillStyle(Palette.aether1, 1);
    this.aetherBar.fillRoundedRect(ax, ay, aw * afrac, 22, 11);
    this.aetherBar.fillStyle(Palette.aether0, 0.5);
    this.aetherBar.fillRoundedRect(ax, ay, aw * afrac, 8, 8);
    // Pip ticks.
    for (let i = 1; i < AETHER.max; i++) {
      this.aetherBar.fillStyle(Palette.night0, 0.6);
      this.aetherBar.fillRect(ax + (aw / AETHER.max) * i, ay, 1.5, 22);
    }
    this.aetherText.setText(`◆ ${Math.floor(this.aether)} / ${AETHER.max}`);

    // Cards state (affordability, selection, cooldown).
    for (let i = 0; i < this.cards.length; i++) {
      const def = getChampion(this.deck[i]);
      const affordable = this.aether >= def.cost && this.cardCooldown[i] <= 0;
      const card = this.cards[i];
      card.setAlpha(affordable ? 1 : 0.7);
      (card.getData('img') as Phaser.GameObjects.Image).setTint(affordable ? Palette.white : 0x6a7a9a);
      const sel = card.getData('sel') as Phaser.GameObjects.Graphics;
      sel.clear();
      if (this.selectedCard === i) {
        sel.lineStyle(4, Palette.ember0, 1);
        sel.strokeRoundedRect(-77, -66, 154, 132, 16);
      }
      const cd = card.getData('cd') as Phaser.GameObjects.Graphics;
      cd.clear();
      if (this.cardCooldown[i] > 0) {
        const cdFrac = this.cardCooldown[i] / (4 + def.cost * 0.6);
        cd.fillStyle(Palette.night0, 0.7);
        cd.fillRoundedRect(-75, -64 + 128 * (1 - cdFrac), 150, 128 * cdFrac, 12);
      }
    }

    // Warden HP bar (above the tray, left).
    this.wardenHpBar.clear();
    const whx = 40;
    const why = GAME_HEIGHT - 200;
    this.wardenHpBar.fillStyle(Palette.night0, 0.85);
    this.wardenHpBar.fillRoundedRect(whx, why, 150, 18, 9);
    const wf = Phaser.Math.Clamp(this.warden.hp / this.warden.maxHp, 0, 1);
    this.wardenHpBar.fillStyle(wf > 0.4 ? Palette.ember2 : Palette.danger, 1);
    this.wardenHpBar.fillRoundedRect(whx, why, 150 * wf, 18, 9);
    this.wardenHpBar.lineStyle(2, Palette.night0, 1);

    // Ult fill.
    this.ultFill.clear();
    const uf = this.warden.ultCharge / 100;
    this.ultFill.fillStyle(Palette.ember2, 0.3);
    this.ultFill.slice(0, 0, 38, Phaser.Math.DegToRad(-90), Phaser.Math.DegToRad(-90 + 360 * uf), false);
    this.ultFill.fillPath();
    this.ultButton.setScale(this.warden.ultReady ? 1.06 + Math.sin(this.time.now / 150) * 0.05 : 1);

    // Boss bar.
    const boss = this.enemies.find((e) => e.isBoss && e.alive);
    if (boss) {
      this.bossBar.setVisible(true);
      const fill = this.bossBar.getData('fill') as Phaser.GameObjects.Graphics;
      const name = this.bossBar.getData('name') as Phaser.GameObjects.Text;
      name.setText(boss.def.name.toUpperCase());
      fill.clear();
      const bw = GAME_WIDTH - 68;
      fill.fillStyle(Palette.danger, 1);
      fill.fillRoundedRect(-bw / 2, -6, bw * boss.hpFrac(), 22, 8);
    } else {
      this.bossBar.setVisible(false);
    }

    // Bastion hit flash.
    if (this.bastionFlash > 0) {
      this.bastionFlash -= _dt * 4;
      this.bastionSprite.setTint(mix(Palette.white, Palette.danger, 0.5));
      if (this.bastionFlash <= 0) this.bastionSprite.clearTint();
    }
  }

  private updateWaveText() {
    const realm = getRealm(this.realmId);
    this.waveText.setText(`WAVE ${this.waveIndex + 1}/${realm.waves.length}`);
  }

  // ────────────────────────────────────────────────────────
  // Banners, pause, end
  // ────────────────────────────────────────────────────────
  private showBanner(title: string, sub: string, onDone?: () => void, color: number = Palette.ember0) {
    const c = this.add.container(GAME_WIDTH / 2, GAME_HEIGHT * 0.4).setDepth(DEPTH.toast);
    const t = label(this, 0, 0, title, { size: 44, weight: '900', color, align: 'center', letter: 2 }).setOrigin(0.5);
    const s = label(this, 0, 46, sub, { size: 18, weight: '700', color: Palette.textDim, align: 'center' }).setOrigin(0.5);
    c.add([t, s]);
    c.setScale(0.7).setAlpha(0);
    this.tweens.add({ targets: c, scale: 1, alpha: 1, duration: 400, ease: 'Back.out' });
    this.tweens.add({
      targets: c,
      alpha: 0,
      delay: 1100,
      duration: 400,
      onComplete: () => {
        c.destroy();
        onDone?.();
      },
    });
  }

  private togglePause() {
    if (this.state === 'playing') {
      this.state = 'paused';
      Audio.uiClick();
      const c = this.add.container(0, 0).setDepth(DEPTH.overlay).setName('pause');
      const dim = this.add.graphics();
      dim.fillStyle(Palette.night0, 0.8);
      dim.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
      dim.setInteractive(new Phaser.Geom.Rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT), Phaser.Geom.Rectangle.Contains);
      c.add(dim);
      c.add(label(this, GAME_WIDTH / 2, GAME_HEIGHT * 0.34, 'PAUSED', { size: 40, weight: '900', align: 'center', letter: 3 }).setOrigin(0.5));
      button(this, GAME_WIDTH / 2, GAME_HEIGHT * 0.5, 'RESUME', () => this.resumeGame(), { width: 280, height: 64, variant: 'ember', size: 24 }).setDepth(DEPTH.overlay).setName('pauseBtn');
      button(this, GAME_WIDTH / 2, GAME_HEIGHT * 0.5 + 84, 'ABANDON RUN', () => this.abandon(), { width: 280, height: 60, variant: 'ghost', size: 20 }).setDepth(DEPTH.overlay).setName('pauseBtn');
    }
  }

  private resumeGame() {
    this.children.getByName('pause')?.destroy();
    this.children.list.filter((o) => o.name === 'pauseBtn').forEach((o) => o.destroy());
    this.state = 'playing';
    Audio.uiClick();
  }

  private abandon() {
    Audio.uiBack();
    this.state = 'over';
    this.settleAndExit(false);
  }

  private endRun(victory: boolean) {
    if (this.state === 'over') return;
    this.state = 'over';
    this.endJoy();
    this.clearGhost();
    if (victory) {
      this.showBanner('REALM CLEARED', 'The light holds', () => this.settleAndExit(true), Palette.ember0);
    } else {
      this.showBanner('THE BASTION FELL', 'Regroup and return', () => this.settleAndExit(false), Palette.danger);
    }
  }

  private settleAndExit(victory: boolean) {
    const realm = getRealm(this.realmId);
    const rewards = settleRun(this.realmId, victory, this.waveIndex + (victory ? 1 : 0), this.goldEarned, this.kills);
    snapshotUnlocks();
    fadeTo(this, 400, () => {
      this.scene.start('Result', {
        realmId: this.realmId,
        victory,
        wavesCleared: Math.min(this.waveIndex + (victory ? 1 : 0), realm.waves.length),
        totalWaves: realm.waves.length,
        kills: this.kills,
        rewards,
      });
    });
  }
}
