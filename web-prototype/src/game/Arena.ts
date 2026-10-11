import type Phaser from 'phaser';
import type { RunModifiers } from '../types';
import type { Enemy } from './Enemy';
import type { Champion } from './Champion';
import type { Warden } from './Warden';

/**
 * Arena — the contract entities use to talk to the battlefield.
 *
 * GameScene implements this. Keeping entities dependent on an interface (rather
 * than the concrete scene) keeps the module graph clean and the combat systems
 * easy to reason about.
 */

export type DamageSource = 'warden' | 'champion' | 'enemy';

export interface ProjectileConfig {
  x: number;
  y: number;
  angle: number;
  speed: number;
  damage: number;
  texture: string;
  tint?: number;
  scale?: number;
  source: DamageSource;
  pierce?: number;
  /** Light homing toward this enemy if still alive. */
  homing?: Enemy | null;
  /** Status effects carried by the projectile. */
  burn?: number;
  slow?: number;
  chain?: number;
  crit?: boolean;
  /** For enemy projectiles targeting the Warden. */
  targetWarden?: boolean;
}

export interface DamageOpts {
  source: DamageSource;
  crit?: boolean;
  burn?: number;
  slow?: number;
  chain?: number;
  /** Point of impact for FX. */
  x?: number;
  y?: number;
  /** Suppress chain re-trigger to avoid infinite loops. */
  noChain?: boolean;
}

export interface Vec {
  x: number;
  y: number;
}

export interface IArena {
  readonly stage: Phaser.Scene;
  readonly enemies: Enemy[];
  readonly champions: Champion[];
  readonly warden: Warden;
  readonly mods: RunModifiers;
  readonly bastion: Vec;

  spawnProjectile(cfg: ProjectileConfig): void;
  damageEnemy(e: Enemy, dmg: number, opts: DamageOpts): void;
  damageWarden(dmg: number): void;
  damageBastion(dmg: number): void;
  healWarden(amount: number): void;

  floatText(x: number, y: number, text: string, color: number, big?: boolean): void;
  burst(x: number, y: number, color: number, count?: number, key?: string): void;
  ring(x: number, y: number, color: number, radius?: number): void;
  shake(intensity: number, dur?: number): void;

  nearestEnemy(x: number, y: number, maxDist: number, exclude?: Enemy): Enemy | null;
  enemiesInRadius(x: number, y: number, radius: number): Enemy[];
}
