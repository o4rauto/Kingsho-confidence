import Phaser from 'phaser';
import type { ChampionDef } from '../types';
import type { IArena } from './Arena';
import { Palette, mix } from '../core/Palette';
import { DEPTH } from '../config';

/**
 * Champion — a deployed defender (the Clash-Royale card, placed on the field).
 *
 * Emplacements that hold ground and fight the Rush by role: melee units block
 * and trade blows, towers/ranged snipe, support heals. Special champions layer
 * on slow, chain lightning, or a fire nova.
 */
export class Champion {
  arena: IArena;
  def: ChampionDef;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  damage: number;
  range: number;
  alive = true;

  private sprite: Phaser.GameObjects.Image;
  private shadow: Phaser.GameObjects.Image;
  private hpBar: Phaser.GameObjects.Graphics;
  private rangeRing?: Phaser.GameObjects.Graphics;
  private cd = 0;
  private attackInterval: number;
  private bodyRadius: number;
  private evolved: boolean;
  private baseScaleX = 1;
  private lifetimeFx = 0;

  constructor(
    arena: IArena,
    def: ChampionDef,
    x: number,
    y: number,
    stats: { hp: number; damage: number },
    evolved: boolean,
  ) {
    this.arena = arena;
    this.def = def;
    this.x = x;
    this.y = y;
    this.maxHp = stats.hp;
    this.hp = stats.hp;
    this.damage = stats.damage;
    this.range = def.range;
    this.evolved = evolved;
    this.attackInterval = 1 / def.attackSpeed;
    this.bodyRadius = def.role === 'melee' ? 40 : 26;

    const scene = arena.stage;
    this.shadow = scene.add.image(x, y + 4, 'fx:shadow').setDepth(DEPTH.shadow).setDisplaySize(56, 24).setAlpha(0.45);
    const key = evolved ? `champ:${def.id}:evo` : `champ:${def.id}`;
    this.sprite = scene.add.image(x, y, key).setDepth(DEPTH.unit).setOrigin(0.5, 0.86);
    const targetH = def.role === 'tower' ? 96 : 84;
    this.sprite.setScale(targetH / this.sprite.height);
    this.baseScaleX = this.sprite.scaleX;
    this.hpBar = scene.add.graphics().setDepth(DEPTH.unit + 1);

    // Deploy pop-in.
    this.sprite.setScale(this.baseScaleX * 0.3, this.sprite.scaleY * 0.3);
    scene.tweens.add({
      targets: this.sprite,
      scaleX: this.baseScaleX,
      scaleY: targetH / this.sprite.height,
      duration: 260,
      ease: 'Back.out',
    });
    arena.ring(x, y, evolved ? Palette.ember1 : Palette.aether0, 60);
  }

  /** Briefly show the attack radius (on deploy / selection). */
  flashRange() {
    const g = this.arena.stage.add.graphics().setDepth(DEPTH.decal);
    g.lineStyle(2, mix(Palette.aether0, Palette.white, 0.2), 0.5);
    g.strokeCircle(this.x, this.y, this.range);
    g.fillStyle(Palette.aether1, 0.06);
    g.fillCircle(this.x, this.y, this.range);
    this.arena.stage.tweens.add({ targets: g, alpha: 0, duration: 700, onComplete: () => g.destroy() });
  }

  takeDamage(dmg: number) {
    if (!this.alive) return;
    this.hp -= dmg;
    if (this.hp <= 0) this.die();
  }

  private die() {
    this.alive = false;
    this.arena.burst(this.x, this.y - 20, this.def.color, 12);
    this.arena.floatText(this.x, this.y - 40, 'DOWN', Palette.danger);
    this.destroy();
  }

  update(dt: number) {
    if (!this.alive) return;

    // Blocking: nearby enemies get chipped/slowed and chip us back.
    if (this.def.role === 'melee') {
      const near = this.arena.enemiesInRadius(this.x, this.y, this.bodyRadius);
      for (const e of near) {
        e.applySlow(0.35);
        this.takeDamage(e.def.damage * 0.5 * dt);
        if (!this.alive) return;
      }
    } else {
      // Ranged/tower still get hurt if something walks right onto them.
      const onTop = this.arena.enemiesInRadius(this.x, this.y, this.bodyRadius);
      for (const e of onTop) this.takeDamage(e.def.damage * 0.35 * dt);
      if (!this.alive) return;
    }

    // Attack.
    this.cd -= dt;
    if (this.cd <= 0) {
      const acted = this.act();
      if (acted) this.cd = this.attackInterval;
    }

    // Idle bob for living units.
    if (this.def.role !== 'tower') {
      this.lifetimeFx += dt;
      this.sprite.y = this.y + Math.sin(this.lifetimeFx * 3) * 1.5;
    }
    this.shadow.setPosition(this.x, this.y + 4);

    // HP bar.
    this.hpBar.clear();
    if (this.hp < this.maxHp) {
      const w = 46;
      const top = this.y - (this.def.role === 'tower' ? 96 : 84) - 6;
      this.hpBar.fillStyle(Palette.night0, 0.85);
      this.hpBar.fillRoundedRect(this.x - w / 2, top, w, 6, 3);
      const frac = Phaser.Math.Clamp(this.hp / this.maxHp, 0, 1);
      this.hpBar.fillStyle(this.evolved ? Palette.ember1 : Palette.good, 1);
      this.hpBar.fillRoundedRect(this.x - w / 2, top, w * frac, 6, 3);
    }
  }

  /** Perform the role action. Returns true if it triggered (starts cooldown). */
  private act(): boolean {
    const mods = this.arena.mods;
    const dmg = this.damage * mods.championDamageMul;

    if (this.def.role === 'support') {
      if (this.def.id === 'ashen-queen') {
        // Fire nova.
        const hit = this.arena.enemiesInRadius(this.x, this.y, this.range);
        if (hit.length === 0) return false;
        this.arena.ring(this.x, this.y, Palette.ember2, this.range);
        this.arena.burst(this.x, this.y - 20, Palette.ember1, 16);
        for (const e of hit) {
          this.arena.damageEnemy(e, dmg, { source: 'champion', burn: 6, x: e.x, y: e.y - e.radius });
        }
        this.squash();
        return true;
      }
      // Healer: mend the most-wounded ally in range (incl. Warden).
      const target = this.lowestAlly();
      if (!target) return false;
      const heal = 18 + this.damage;
      if ('takeDamage' in target) {
        target.hp = Math.min(target.maxHp, target.hp + heal);
      }
      this.arena.floatText(target.x, target.y - 50, `+${Math.round(heal)}`, Palette.good);
      this.beam(target.x, target.y, Palette.good);
      return true;
    }

    // Combat roles need a target in range.
    const target = this.arena.nearestEnemy(this.x, this.y, this.range);
    if (!target) return false;

    const isSlow = this.def.id === 'frost-warden';
    const isChain = this.def.id === 'stormcaller';

    if (this.def.role === 'melee') {
      // Only strike if the target is close enough to actually reach.
      if (Phaser.Math.Distance.Between(this.x, this.y, target.x, target.y) > this.range + target.radius) {
        return false;
      }
      this.arena.damageEnemy(target, dmg, { source: 'champion', x: target.x, y: target.y - target.radius });
      this.arena.burst(target.x, target.y - target.radius, Palette.ember0, 4);
      this.lunge(target.x, target.y);
      return true;
    }

    // Ranged / tower: fire a bolt.
    const angle = Math.atan2(target.y - target.radius * 0.5 - (this.y - 40), target.x - this.x);
    const tex = this.def.role === 'tower' ? 'proj:bolt' : 'proj:arrow';
    this.arena.spawnProjectile({
      x: this.x,
      y: this.y - 40,
      angle,
      speed: 620,
      damage: dmg,
      texture: tex,
      tint: this.evolved ? Palette.ember1 : this.def.color,
      source: 'champion',
      homing: target,
      slow: isSlow ? 0.4 : undefined,
      chain: isChain ? 2 : undefined,
      scale: this.def.role === 'tower' ? 1.1 : 1,
    });
    this.squash();
    return true;
  }

  private lowestAlly(): Champion | { x: number; y: number; hp: number; maxHp: number; takeDamage?: unknown } | null {
    let best: Champion | null = null;
    let bestFrac = 0.98;
    for (const c of this.arena.champions) {
      if (!c.alive || c === this) continue;
      const frac = c.hp / c.maxHp;
      if (Phaser.Math.Distance.Between(this.x, this.y, c.x, c.y) <= this.range && frac < bestFrac) {
        best = c;
        bestFrac = frac;
      }
    }
    const w = this.arena.warden;
    if (w.alive && w.hp / w.maxHp < bestFrac && Phaser.Math.Distance.Between(this.x, this.y, w.x, w.y) <= this.range) {
      return w as unknown as { x: number; y: number; hp: number; maxHp: number };
    }
    return best;
  }

  private beam(tx: number, ty: number, color: number) {
    const g = this.arena.stage.add.graphics().setDepth(DEPTH.fx);
    g.lineStyle(3, color, 0.8);
    g.lineBetween(this.x, this.y - 40, tx, ty - 30);
    this.arena.stage.tweens.add({ targets: g, alpha: 0, duration: 260, onComplete: () => g.destroy() });
    this.squash();
  }

  private squash() {
    const scene = this.arena.stage;
    scene.tweens.add({
      targets: this.sprite,
      scaleX: this.baseScaleX * 1.12,
      duration: 70,
      yoyo: true,
    });
  }

  private lunge(tx: number, ty: number) {
    const a = Math.atan2(ty - this.y, tx - this.x);
    const scene = this.arena.stage;
    scene.tweens.add({
      targets: this.sprite,
      x: this.x + Math.cos(a) * 10,
      y: this.y + Math.sin(a) * 6,
      duration: 80,
      yoyo: true,
    });
  }

  destroy() {
    this.sprite.destroy();
    this.shadow.destroy();
    this.hpBar.destroy();
    this.rangeRing?.destroy();
  }
}
