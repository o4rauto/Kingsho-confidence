/**
 * Bastion Rush — global configuration & tuning constants.
 *
 * A single source of truth for the design "feel". Balance lives here so the
 * whole game can be re-tuned without hunting through scene code.
 */

/** Logical design resolution. The camera scales to fit any device. */
export const GAME_WIDTH = 720;
export const GAME_HEIGHT = 1280;

/** Portrait mobile aspect. Everything is authored against this canvas. */
export const SAFE = { top: 46, bottom: 30, left: 18, right: 18 };

/** Persistence key prefix for save data. */
export const SAVE_KEY = 'bastion-rush.save.v1';

/** Aether (deploy energy) tuning — the Clash-Royale-style resource. */
export const AETHER = {
  max: 10,
  start: 5,
  /** Aether regenerated per second during a run. */
  regenPerSec: 0.62,
  /** Bonus regen granted between waves. */
  waveBonus: 2,
};

/** Warden (hero) base stats — the Archero-style avatar you pilot. */
export const WARDEN = {
  radius: 22,
  speed: 235,
  maxHp: 120,
  fireCooldown: 520, // ms
  projectileSpeed: 640,
  projectileDamage: 14,
  range: 360,
  ultChargePerHit: 6,
  ultChargeMax: 100,
};

/** The Bastion you defend. If its integrity hits zero, the run ends. */
export const BASTION = {
  maxIntegrity: 100,
};

/** Meta-progression currencies. */
export const CURRENCY = {
  gold: 'gold',
  shards: 'shards',
  cores: 'cores',
} as const;

export type CurrencyId = (typeof CURRENCY)[keyof typeof CURRENCY];

/** Rarities used across champions & drops. */
export const RARITY = ['common', 'rare', 'epic', 'legendary'] as const;
export type Rarity = (typeof RARITY)[number];

export const RARITY_COLOR: Record<Rarity, number> = {
  common: 0x9fb0d0,
  rare: 0x4ea3ff,
  epic: 0xc06bff,
  legendary: 0xffb033,
};

export const RARITY_LABEL: Record<Rarity, string> = {
  common: 'Common',
  rare: 'Rare',
  epic: 'Epic',
  legendary: 'Legendary',
};

/** Champion level cap and the per-level stat growth multiplier. */
export const CHAMPION = {
  maxLevel: 12,
  /** Multiplicative growth applied per level above 1. */
  growthPerLevel: 0.14,
  /** Evolution unlocks at this level and grants a power spike + new look. */
  evolveLevel: 8,
  evolvePowerBonus: 0.35,
};

/** How many champion slots a run loadout has. */
export const DECK_SIZE = 4;

/** Global depth ordering so draw order stays predictable. */
export const DEPTH = {
  ground: 0,
  path: 1,
  decal: 2,
  bastion: 5,
  shadow: 8,
  unit: 10,
  enemy: 11,
  warden: 14,
  projectile: 18,
  fx: 24,
  hud: 40,
  overlay: 60,
  toast: 80,
};
