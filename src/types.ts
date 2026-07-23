import type { Rarity } from './config';

/** How a deployed champion behaves once it is on the field. */
export type ChampionRole = 'melee' | 'ranged' | 'tower' | 'support';

/** A champion/unit definition (data-driven, immutable). */
export interface ChampionDef {
  id: string;
  name: string;
  title: string;
  role: ChampionRole;
  rarity: Rarity;
  /** Aether cost to deploy during a run. */
  cost: number;
  /** Base combat stats at champion level 1. */
  hp: number;
  damage: number;
  /** Attacks per second. */
  attackSpeed: number;
  range: number;
  moveSpeed: number;
  /** How many instances a single deploy places (e.g. swarm units). */
  count: number;
  /** One-line flavor for the collection screen. */
  lore: string;
  /** Short mechanical description. */
  ability: string;
  /** Base color used to generate this champion's art. */
  color: number;
}

/** How an enemy moves & threatens the Bastion. */
export type EnemyKind = 'runner' | 'brute' | 'flyer' | 'caster' | 'boss';

export interface EnemyDef {
  id: string;
  name: string;
  kind: EnemyKind;
  hp: number;
  damage: number;
  speed: number;
  radius: number;
  /** Gold dropped on death. */
  bounty: number;
  /** Integrity damage dealt to the Bastion if it reaches the core. */
  breach: number;
  color: number;
}

/** A single spawn instruction within a wave. */
export interface SpawnGroup {
  enemy: string;
  count: number;
  /** Delay before this group starts, ms from wave start. */
  at: number;
  /** Gap between each unit in the group, ms. */
  gap: number;
  /** Which lane/path index to use. */
  lane?: number;
}

export interface WaveDef {
  groups: SpawnGroup[];
}

export interface RealmDef {
  id: string;
  name: string;
  subtitle: string;
  /** Unlock requirement: number of prior realms that must be cleared. */
  unlockAfter: number;
  /** Environment palette hints. */
  ground: number;
  ground2: number;
  accent: number;
  /** Number of enemy lanes. */
  lanes: number;
  waves: WaveDef[];
  /** Base reward for a first clear. */
  goldReward: number;
  shardReward: number;
}

/** Roguelite boon applied during a run. */
export interface BoonDef {
  id: string;
  name: string;
  desc: string;
  rarity: Rarity;
  icon: string; // glyph id used by Art
  /** Whether it can be picked multiple times in a run. */
  stack: boolean;
  apply: (s: RunModifiers) => void;
}

/** Mutable per-run modifiers accumulated from boons. */
export interface RunModifiers {
  wardenDamageMul: number;
  wardenAttackSpeedMul: number;
  wardenSpeedMul: number;
  wardenMaxHpAdd: number;
  wardenRangeMul: number;
  projectilePierce: number;
  multishot: number;
  critChance: number;
  critMul: number;
  lifestealPct: number;
  aetherRegenMul: number;
  championDamageMul: number;
  championHpMul: number;
  bastionRepairPerWave: number;
  goldMul: number;
  chainLightning: number;
  burnOnHit: number;
  slowOnHit: number;
}

export function freshModifiers(): RunModifiers {
  return {
    wardenDamageMul: 1,
    wardenAttackSpeedMul: 1,
    wardenSpeedMul: 1,
    wardenMaxHpAdd: 0,
    wardenRangeMul: 1,
    projectilePierce: 0,
    multishot: 0,
    critChance: 0.05,
    critMul: 1.8,
    lifestealPct: 0,
    aetherRegenMul: 1,
    championDamageMul: 1,
    championHpMul: 1,
    bastionRepairPerWave: 0,
    goldMul: 1,
    chainLightning: 0,
    burnOnHit: 0,
    slowOnHit: 0,
  };
}

/** Per-champion meta state (persisted). */
export interface ChampionState {
  level: number;
  /** Duplicate shards collected toward the next level-up. */
  shards: number;
  unlocked: boolean;
  evolved: boolean;
}

/** The full persisted player profile. */
export interface SaveData {
  version: number;
  gold: number;
  shards: number;
  cores: number;
  wardenLevel: number;
  clearedRealms: string[];
  bestWave: Record<string, number>;
  champions: Record<string, ChampionState>;
  deck: string[];
  settings: {
    sfx: boolean;
    music: boolean;
    haptics: boolean;
    screenShake: boolean;
  };
  stats: {
    runs: number;
    kills: number;
    victories: number;
  };
  createdAt: number;
}
