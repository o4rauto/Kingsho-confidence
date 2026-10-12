import Phaser from 'phaser';
import type { EnemyDef } from '../types';
import type { IArena, Vec } from './Arena';
import { Palette } from '../core/Palette';
import { DEPTH } from '../config';

/**
 * Enemy — a member of the Rush marching on the Bastion.
 *
 * Follows its lane's waypoints (flyers cut straight), carries burn/slow status,
 * and deals a breach of integrity if it reaches the core. Death pays bounty and
 * drops a spark of gold.
 */
export class Enemy {
  arena: IArena;
  def: EnemyDef;
  sprite: Phaser.GameObjects.Image;
  shadow: Phaser.GameObjects.Image;
  hpBar: Phaser.GameObjects.Graphics;

  x: number;
  y: number;
  hp: number;
  maxHp: number;
  radius: number;
  alive = true;
  /** Set when the enemy dies by reaching the Bastion (no bounty). */
  reachedBastion = false;
  /** Guards against paying bounty twice. */
  rewarded = false;
  isBoss: boolean;
  scaleMul: number;

  private path: Vec[];
  private seg = 0;
  private slowT = 0;
  private slowF = 1;
  private burnT = 0;
  private burnDps = 0;
  private bob = Math.random() * Math.PI * 2;
  private hitFlash = 0;
  private castCd = 1.6 + Math.random() * 2;

  constructor(arena: IArena, def: EnemyDef, path: Vec[], hpScale: number, sizeScale = 1) {
    this.arena = arena;
    this.def = def;
    this.path = path;
    this.isBoss = def.kind === 'boss';
    this.scaleMul = sizeScale;
    this.maxHp = Math.round(def.hp * hpScale);
    this.hp = this.maxHp;
    this.radius = def.radius * sizeScale;
    this.x = path[0].x;
    this.y = path[0].y;

    const scene = arena.stage;
    this.shadow = scene.add.image(this.x, this.y, 'fx:shadow').setDepth(DEPTH.shadow).setDisplaySize(this.radius * 2.4, this.radius * 1.1).setAlpha(0.5);
    this.sprite = scene.add.image(this.x, this.y, `enemy:${def.id}`).setDepth(DEPTH.enemy);
    const texH = this.sprite.height;
    const targetH = this.radius * (this.isBoss ? 2.6 : 3.1) * (def.kind === 'brute' ? 1.15 : 1);
    this.sprite.setScale(targetH / texH);
    this.sprite.setOrigin(0.5, 0.86);

    this.hpBar = scene.add.graphics().setDepth(DEPTH.enemy + 1);
    if (this.isBoss) {
      scene.tweens.add({ targets: this.sprite, scaleX: this.sprite.scaleX * 1.04, duration: 700, yoyo: true, repeat: -1 });
    }
  }

  applyDamage(dmg: number) {
    if (!this.alive) return;
    this.hp -= dmg;
    this.hitFlash = 1;
    if (this.hp <= 0) this.alive = false; // scene settles the kill next frame
  }

  applyBurn(dps: number) {
    this.burnDps = Math.max(this.burnDps, dps);
    this.burnT = 3;
  }

  applySlow(factor: number) {
    this.slowF = Math.min(this.slowF, 1 - factor);
    this.slowT = 1.4;
  }

  update(dt: number) {
    if (!this.alive) return;

    // Status timers.
    if (this.slowT > 0) {
      this.slowT -= dt;
      if (this.slowT <= 0) this.slowF = 1;
    }
    if (this.burnT > 0) {
      this.burnT -= dt;
      this.hp -= this.burnDps * dt;
      if (Math.random() < 0.3) this.arena.burst(this.x + (Math.random() - 0.5) * this.radius, this.y - this.radius, Palette.ember2, 1);
      if (this.hp <= 0) {
        this.alive = false;
        return;
      }
    }

    // Movement.
    const speed = this.def.speed * this.slowF;
    let tx: number;
    let ty: number;
    if (this.def.kind === 'flyer') {
      tx = this.arena.bastion.x;
      ty = this.arena.bastion.y;
    } else {
      const wp = this.path[this.seg];
      tx = wp.x;
      ty = wp.y;
    }
    const dx = tx - this.x;
    const dy = ty - this.y;
    const dist = Math.hypot(dx, dy) || 1;
    const step = speed * dt;
    if (dist <= step + 2) {
      if (this.def.kind !== 'flyer' && this.seg < this.path.length - 1) {
        this.seg++;
      } else {
        // Reached the Bastion.
        this.alive = false;
        this.reachedBastion = true;
        this.arena.damageBastion(this.def.breach);
        this.arena.ring(this.arena.bastion.x, this.arena.bastion.y - 40, Palette.danger, 80);
        return;
      }
    } else {
      this.x += (dx / dist) * step;
      this.y += (dy / dist) * step;
      if (Math.abs(dx) > 4) this.sprite.setFlipX(dx < 0);
    }

    // Casters hurl hexes at the Warden from range.
    if (this.def.kind === 'caster') {
      this.castCd -= dt;
      const w = this.arena.warden;
      if (this.castCd <= 0 && w.alive && Phaser.Math.Distance.Between(this.x, this.y, w.x, w.y) < 420) {
        const a = Math.atan2(w.y - (this.y - this.radius), w.x - this.x);
        this.arena.spawnProjectile({
          x: this.x,
          y: this.y - this.radius,
          angle: a,
          speed: 300,
          damage: this.def.damage,
          texture: 'proj:enemy',
          tint: 0xff4d7d,
          source: 'enemy',
          targetWarden: true,
          scale: 1.1,
        });
        this.castCd = 2.8;
      }
    }

    // Visuals.
    this.bob += dt * 8;
    const bobY = this.def.kind === 'flyer' ? Math.sin(this.bob) * 5 : 0;
    this.sprite.setPosition(this.x, this.y + bobY);
    this.shadow.setPosition(this.x, this.y + 2);
    this.shadow.setAlpha(this.def.kind === 'flyer' ? 0.3 : 0.5);

    // Hit flash (tint toward white briefly).
    if (this.hitFlash > 0) {
      this.hitFlash -= dt * 6;
      const t = Phaser.Math.Clamp(this.hitFlash, 0, 1);
      this.sprite.setTintFill(Phaser.Display.Color.GetColor(255, 255 * (1 - t) + 255 * t, 255 * (1 - t) + 255 * t));
      if (this.hitFlash <= 0) this.sprite.clearTint();
    } else if (this.slowF < 1) {
      this.sprite.setTint(Palette.aether0);
    } else {
      this.sprite.clearTint();
    }

    // HP bar (small, only when damaged; bosses handled by scene HUD).
    this.hpBar.clear();
    if (!this.isBoss && this.hp < this.maxHp) {
      const w = this.radius * 2.2;
      const top = this.y - this.radius * 2.6 + bobY;
      this.hpBar.fillStyle(Palette.night0, 0.8);
      this.hpBar.fillRoundedRect(this.x - w / 2, top, w, 5, 2);
      const frac = Phaser.Math.Clamp(this.hp / this.maxHp, 0, 1);
      this.hpBar.fillStyle(frac > 0.5 ? Palette.good : frac > 0.25 ? Palette.warn : Palette.danger, 1);
      this.hpBar.fillRoundedRect(this.x - w / 2, top, w * frac, 5, 2);
    }
  }

  hpFrac(): number {
    return Phaser.Math.Clamp(this.hp / this.maxHp, 0, 1);
  }

  destroy() {
    this.sprite.destroy();
    this.shadow.destroy();
    this.hpBar.destroy();
  }
}
