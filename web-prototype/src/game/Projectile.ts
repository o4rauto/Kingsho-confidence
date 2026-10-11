import Phaser from 'phaser';
import type { IArena, ProjectileConfig } from './Arena';
import type { Enemy } from './Enemy';
import { DEPTH } from '../config';

/**
 * Projectile — arrows, bolts, orbs, and enemy hexes.
 *
 * Straight-flying with optional light homing toward a locked target. Player and
 * champion shots hurt enemies (with pierce); enemy shots hurt the Warden.
 */
export class Projectile {
  arena: IArena;
  sprite: Phaser.GameObjects.Image;
  glow?: Phaser.GameObjects.Image;
  x: number;
  y: number;
  angle: number;
  speed: number;
  cfg: ProjectileConfig;
  alive = true;
  private life = 2.4;
  private pierce: number;
  private hitSet = new Set<Enemy>();

  constructor(arena: IArena, cfg: ProjectileConfig) {
    this.arena = arena;
    this.cfg = cfg;
    this.x = cfg.x;
    this.y = cfg.y;
    this.angle = cfg.angle;
    this.speed = cfg.speed;
    this.pierce = cfg.pierce ?? 0;

    const scene = arena.stage;
    this.sprite = scene.add
      .image(this.x, this.y, cfg.texture)
      .setDepth(DEPTH.projectile)
      .setRotation(this.angle)
      .setScale(cfg.scale ?? 1);
    if (cfg.tint !== undefined) this.sprite.setTint(cfg.tint);
    if (cfg.crit) this.sprite.setScale((cfg.scale ?? 1) * 1.5);
  }

  update(dt: number): boolean {
    if (!this.alive) return false;
    this.life -= dt;
    if (this.life <= 0) return this.kill();

    // Homing steer.
    if (this.cfg.homing && this.cfg.homing.alive) {
      const desired = Math.atan2(this.cfg.homing.y - this.radiusY() - this.y, this.cfg.homing.x - this.x);
      this.angle = steer(this.angle, desired, 5 * dt);
      this.sprite.setRotation(this.angle);
    }

    const vx = Math.cos(this.angle) * this.speed;
    const vy = Math.sin(this.angle) * this.speed;
    this.x += vx * dt;
    this.y += vy * dt;
    this.sprite.setPosition(this.x, this.y);

    const { width, height } = this.arena.stage.scale;
    if (this.x < -40 || this.x > width + 40 || this.y < -40 || this.y > height + 40) {
      return this.kill();
    }

    if (this.cfg.source === 'enemy') {
      // Hurt the Warden.
      const w = this.arena.warden;
      if (w.alive && Phaser.Math.Distance.Between(this.x, this.y, w.x, w.y) < w.radius + 10) {
        this.arena.damageWarden(this.cfg.damage);
        this.arena.burst(this.x, this.y, this.cfg.tint ?? 0xff4d7d, 6);
        return this.kill();
      }
      return true;
    }

    // Player / champion shot vs enemies.
    for (const e of this.arena.enemies) {
      if (!e.alive || this.hitSet.has(e)) continue;
      if (Phaser.Math.Distance.Between(this.x, this.y, e.x, e.y - e.radius * 0.5) < e.radius + 8) {
        this.hitSet.add(e);
        this.arena.damageEnemy(e, this.cfg.damage, {
          source: this.cfg.source,
          crit: this.cfg.crit,
          burn: this.cfg.burn,
          slow: this.cfg.slow,
          chain: this.cfg.chain,
          x: this.x,
          y: this.y,
        });
        if (this.pierce > 0) {
          this.pierce--;
        } else {
          return this.kill();
        }
      }
    }
    return true;
  }

  private radiusY(): number {
    return 8;
  }

  private kill(): boolean {
    if (!this.alive) return false;
    this.alive = false;
    this.sprite.destroy();
    this.glow?.destroy();
    return false;
  }

  destroy() {
    this.kill();
  }
}

/** Rotate `from` toward `to` by at most `max` radians. */
function steer(from: number, to: number, max: number): number {
  let diff = Phaser.Math.Angle.Wrap(to - from);
  diff = Phaser.Math.Clamp(diff, -max, max);
  return from + diff;
}
