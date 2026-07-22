import Phaser from 'phaser';
import type { IArena } from './Arena';
import { Palette } from '../core/Palette';
import { DEPTH, WARDEN } from '../config';
import { Save } from '../core/Save';
import { Audio } from '../core/Audio';

/**
 * Warden — the hero you pilot (the Archero half of the game).
 *
 * Drag to move; the Warden auto-fires at the nearest foe only while standing
 * still, so positioning is the whole game. Charges an ultimate as it fights,
 * and instead of dying it is knocked down and revives at the Bastion.
 */
export class Warden {
  arena: IArena;
  x: number;
  y: number;
  radius = WARDEN.radius;
  hp: number;
  maxHp: number;
  alive = true;
  ultCharge = 0;

  private sprite: Phaser.GameObjects.Image;
  private shadow: Phaser.GameObjects.Image;
  private aura: Phaser.GameObjects.Image;
  private moveVec = { x: 0, y: 0 };
  private moving = false;
  private fireCd = 0;
  private damage: number;
  private range: number;
  private speed: number;
  private fireInterval: number;
  private iframes = 0;
  private downed = false;
  private downTimer = 0;

  constructor(arena: IArena, x: number, y: number) {
    this.arena = arena;
    this.x = x;
    this.y = y;
    const lvl = Save.data.wardenLevel;
    const dmgScale = 1 + (lvl - 1) * 0.09;
    const hpScale = 1 + (lvl - 1) * 0.07;
    const mods = arena.mods;
    this.maxHp = Math.round((WARDEN.maxHp * hpScale + mods.wardenMaxHpAdd));
    this.hp = this.maxHp;
    this.damage = WARDEN.projectileDamage * dmgScale * mods.wardenDamageMul;
    this.range = WARDEN.range * mods.wardenRangeMul;
    this.speed = WARDEN.speed * mods.wardenSpeedMul;
    this.fireInterval = WARDEN.fireCooldown / 1000 / mods.wardenAttackSpeedMul;

    const scene = arena.stage;
    this.aura = scene.add.image(x, y, 'fx:glow-ember').setDepth(DEPTH.warden - 1).setDisplaySize(120, 120).setAlpha(0.35).setBlendMode(Phaser.BlendModes.ADD);
    this.shadow = scene.add.image(x, y + 20, 'fx:shadow').setDepth(DEPTH.shadow).setDisplaySize(64, 26).setAlpha(0.5);
    this.sprite = scene.add.image(x, y, 'warden').setDepth(DEPTH.warden).setOrigin(0.5, 0.82);
    this.sprite.setScale(104 / this.sprite.height);
  }

  /** Scene feeds a movement vector each frame (already in -1..1 per axis). */
  setMove(x: number, y: number) {
    this.moveVec.x = x;
    this.moveVec.y = y;
    this.moving = Math.hypot(x, y) > 0.15;
  }

  heal(amount: number) {
    if (!this.alive) return;
    this.hp = Math.min(this.maxHp, this.hp + amount);
  }

  takeDamage(dmg: number) {
    if (!this.alive || this.downed || this.iframes > 0) return;
    this.hp -= dmg;
    this.iframes = 0.6;
    this.arena.shake(0.008, 120);
    if (Save.data.settings.haptics && navigator.vibrate) navigator.vibrate(30);
    Audio.hurt();
    this.sprite.setTintFill(0xffffff);
    this.arena.stage.time.delayedCall(80, () => !this.downed && this.sprite.clearTint());
    if (this.hp <= 0) this.down();
  }

  private down() {
    this.downed = true;
    this.downTimer = 2.6;
    this.hp = 0;
    this.arena.burst(this.x, this.y - 20, Palette.ember2, 20);
    this.arena.ring(this.x, this.y - 20, Palette.danger, 90);
    this.arena.floatText(this.x, this.y - 60, 'WARDEN DOWN', Palette.danger, true);
    this.arena.shake(0.02, 300);
    this.sprite.setAlpha(0.3).setTint(Palette.textFaint);
    this.aura.setAlpha(0.05);
  }

  private revive() {
    this.downed = false;
    this.hp = Math.round(this.maxHp * 0.6);
    this.iframes = 1.4;
    this.x = this.arena.bastion.x;
    this.y = this.arena.bastion.y - 120;
    this.sprite.setAlpha(1).clearTint();
    this.aura.setAlpha(0.35);
    this.arena.ring(this.x, this.y - 20, Palette.ember1, 100);
    this.arena.floatText(this.x, this.y - 60, 'RISE AGAIN', Palette.ember0, true);
  }

  get ultReady(): boolean {
    return this.ultCharge >= WARDEN.ultChargeMax;
  }

  releaseUlt() {
    if (!this.ultReady || this.downed) return;
    this.ultCharge = 0;
    Audio.ultimate();
    this.arena.shake(0.025, 350);
    this.arena.ring(this.x, this.y - 20, Palette.ember0, 40);

    // Radial arrow storm.
    const shots = 18;
    for (let i = 0; i < shots; i++) {
      const a = (i / shots) * Math.PI * 2;
      this.arena.spawnProjectile({
        x: this.x,
        y: this.y - 30,
        angle: a,
        speed: 560,
        damage: this.damage * 1.6,
        texture: 'proj:arrow',
        tint: Palette.ember0,
        source: 'warden',
        pierce: 3,
        crit: true,
        burn: this.arena.mods.burnOnHit,
      });
    }
    // Shockwave damage.
    const wave = this.arena.enemiesInRadius(this.x, this.y, 220);
    for (const e of wave) {
      this.arena.damageEnemy(e, this.damage * 2.4, { source: 'warden', crit: true, x: e.x, y: e.y - e.radius, slow: 0.5 });
    }
    // Expanding visual ring.
    const g = this.arena.stage.add.image(this.x, this.y - 20, 'fx:ring').setTint(Palette.ember1).setDepth(DEPTH.fx).setScale(0.2);
    this.arena.stage.tweens.add({ targets: g, scale: 3.4, alpha: 0, duration: 500, onComplete: () => g.destroy() });
  }

  addUlt(n: number) {
    this.ultCharge = Math.min(WARDEN.ultChargeMax, this.ultCharge + n);
  }

  update(dt: number, bounds: Phaser.Geom.Rectangle) {
    if (this.iframes > 0) this.iframes -= dt;

    if (this.downed) {
      this.downTimer -= dt;
      this.shadow.setPosition(this.x, this.y + 20);
      if (this.downTimer <= 0) this.revive();
      return;
    }

    // Move.
    const mag = Math.hypot(this.moveVec.x, this.moveVec.y);
    if (mag > 0.15) {
      const nx = this.moveVec.x / mag;
      const ny = this.moveVec.y / mag;
      const sp = this.speed * Math.min(1, mag);
      this.x = Phaser.Math.Clamp(this.x + nx * sp * dt, bounds.left, bounds.right);
      this.y = Phaser.Math.Clamp(this.y + ny * sp * dt, bounds.top, bounds.bottom);
      this.sprite.setFlipX(nx < 0);
      // Running lean.
      this.sprite.setRotation(Phaser.Math.Clamp(nx, -1, 1) * 0.08);
    } else {
      this.sprite.setRotation(0);
    }

    // Auto-fire only while standing still.
    this.fireCd -= dt;
    if (!this.moving) {
      if (this.fireCd <= 0) {
        const fired = this.fire();
        if (fired) this.fireCd = this.fireInterval;
      }
    } else {
      // Small warmup so you can't machine-gun by micro-stopping.
      this.fireCd = Math.max(this.fireCd, this.fireInterval * 0.5);
    }

    // Visuals.
    this.sprite.setPosition(this.x, this.y);
    this.shadow.setPosition(this.x, this.y + 20);
    this.aura.setPosition(this.x, this.y - 10);
    const pulse = this.moving ? 0.18 : 0.3 + Math.sin(this.arena.stage.time.now / 300) * 0.08;
    this.aura.setAlpha(this.ultReady ? 0.5 : pulse);
    this.aura.setTint(this.ultReady ? Palette.ember0 : Palette.ember2);
    if (this.iframes > 0) this.sprite.setAlpha(0.5 + Math.sin(this.arena.stage.time.now / 40) * 0.4);
    else this.sprite.setAlpha(1);
  }

  private fire(): boolean {
    const target = this.arena.nearestEnemy(this.x, this.y, this.range);
    if (!target) return false;
    const baseAngle = Math.atan2(target.y - target.radius * 0.5 - (this.y - 20), target.x - this.x);
    this.sprite.setFlipX(Math.cos(baseAngle) < 0);
    const mods = this.arena.mods;
    const shots = 1 + mods.multishot;
    const spread = 0.16;
    for (let i = 0; i < shots; i++) {
      const off = shots === 1 ? 0 : (i - (shots - 1) / 2) * spread;
      const crit = Math.random() < mods.critChance;
      const dmg = this.damage * (crit ? mods.critMul : 1);
      this.arena.spawnProjectile({
        x: this.x,
        y: this.y - 20,
        angle: baseAngle + off,
        speed: WARDEN.projectileSpeed,
        damage: dmg,
        texture: 'proj:arrow',
        tint: crit ? Palette.ember0 : Palette.ember1,
        source: 'warden',
        pierce: mods.projectilePierce,
        crit,
        burn: mods.burnOnHit,
        slow: mods.slowOnHit || undefined,
        chain: mods.chainLightning || undefined,
        homing: target,
        scale: 1.1,
      });
    }
    this.addUlt(WARDEN.ultChargePerHit * 0.5);
    Audio.shoot();
    // Recoil.
    this.arena.stage.tweens.add({ targets: this.sprite, scaleX: this.sprite.scaleX * 0.92, duration: 60, yoyo: true });
    return true;
  }

  destroy() {
    this.sprite.destroy();
    this.shadow.destroy();
    this.aura.destroy();
  }
}
