import { CHAMPION } from '../config';
import type { ChampionDef } from '../types';
import { Save } from './Save';
import { REALMS, getRealm } from '../data/realms';

/**
 * Meta — the progression math that sits between runs.
 *
 * Champion leveling & evolution (Clash-Royale-style card growth), realm unlocks
 * and first-clear rewards, and the Warden's permanent upgrades. Pure functions
 * where possible; anything that mutates goes through Save.
 */

export interface EffectiveStats {
  hp: number;
  damage: number;
  attackSpeed: number;
  range: number;
  moveSpeed: number;
  power: number; // a single rating for UI sorting
}

/** Compute a champion's stats at its current saved level & evolution. */
export function effectiveStats(def: ChampionDef): EffectiveStats {
  const st = Save.champion(def.id);
  const level = st?.level ?? 1;
  const evolved = st?.evolved ?? false;
  const growth = 1 + CHAMPION.growthPerLevel * (level - 1);
  const evoMul = evolved ? 1 + CHAMPION.evolvePowerBonus : 1;
  const m = growth * evoMul;
  const hp = Math.round(def.hp * m);
  const damage = Math.round(def.damage * m);
  return {
    hp,
    damage,
    attackSpeed: def.attackSpeed,
    range: def.range,
    moveSpeed: def.moveSpeed,
    power: Math.round((hp * 0.4 + damage * def.attackSpeed * 8) * (def.count || 1)),
  };
}

/** Shards required to reach the next level. */
export function levelUpShardCost(level: number): number {
  return 3 + level * 2;
}

/** Gold required to reach the next level. */
export function levelUpGoldCost(level: number): number {
  return 30 + level * 25;
}

export function canLevelUp(id: string): boolean {
  const st = Save.champion(id);
  if (!st || !st.unlocked || st.level >= CHAMPION.maxLevel) return false;
  return (
    st.shards >= levelUpShardCost(st.level) && Save.data.gold >= levelUpGoldCost(st.level)
  );
}

export function levelUp(id: string): boolean {
  if (!canLevelUp(id)) return false;
  const st = Save.champion(id);
  st.shards -= levelUpShardCost(st.level);
  Save.data.gold -= levelUpGoldCost(st.level);
  st.level += 1;
  Save.flush();
  return true;
}

export const EVOLVE_CORE_COST = 3;
export const EVOLVE_GOLD_COST = 300;

export function canEvolve(id: string): boolean {
  const st = Save.champion(id);
  if (!st || st.evolved || st.level < CHAMPION.evolveLevel) return false;
  return Save.data.cores >= EVOLVE_CORE_COST && Save.data.gold >= EVOLVE_GOLD_COST;
}

export function evolve(id: string): boolean {
  if (!canEvolve(id)) return false;
  const st = Save.champion(id);
  Save.data.cores -= EVOLVE_CORE_COST;
  Save.data.gold -= EVOLVE_GOLD_COST;
  st.evolved = true;
  Save.flush();
  return true;
}

/** Cost in shards to unlock a locked champion (by rarity). */
export function unlockShardCost(rarity: string): number {
  switch (rarity) {
    case 'legendary':
      return 40;
    case 'epic':
      return 24;
    case 'rare':
      return 12;
    default:
      return 6;
  }
}

export function canUnlock(def: ChampionDef): boolean {
  const st = Save.champion(def.id);
  return !st.unlocked && st.shards >= unlockShardCost(def.rarity);
}

export function unlockChampion(def: ChampionDef): boolean {
  if (!canUnlock(def)) return false;
  const st = Save.champion(def.id);
  st.shards -= unlockShardCost(def.rarity);
  st.unlocked = true;
  Save.flush();
  return true;
}

/** Award duplicate shards toward a champion (from run rewards). */
export function grantChampionShards(id: string, n: number) {
  const st = Save.champion(id);
  if (st) st.shards += n;
}

// ── Realm progression ────────────────────────────────────────

export function realmUnlocked(realmId: string): boolean {
  const realm = getRealm(realmId);
  return Save.data.clearedRealms.length >= realm.unlockAfter;
}

export function realmCleared(realmId: string): boolean {
  return Save.data.clearedRealms.includes(realmId);
}

/** Record the deepest wave reached in a realm. */
export function recordWave(realmId: string, wave: number) {
  const best = Save.data.bestWave[realmId] ?? 0;
  if (wave > best) Save.data.bestWave[realmId] = wave;
}

export interface RunRewards {
  gold: number;
  shards: number;
  cores: number;
  firstClear: boolean;
  unlockedRealm?: string;
}

/**
 * Settle a finished run: pay currencies, mark clears, unlock the next realm.
 * `victory` means all waves cleared.
 */
export function settleRun(
  realmId: string,
  victory: boolean,
  wavesCleared: number,
  goldEarned: number,
  kills: number,
): RunRewards {
  const realm = getRealm(realmId);
  recordWave(realmId, wavesCleared);
  Save.data.stats.runs += 1;
  Save.data.stats.kills += kills;

  const firstClear = victory && !realmCleared(realmId);
  let gold = Math.round(goldEarned);
  let shards = Math.floor(wavesCleared * 0.6);
  let cores = 0;

  if (victory) {
    Save.data.stats.victories += 1;
    gold += Math.round(realm.goldReward * (firstClear ? 1 : 0.4));
    shards += realm.shardReward;
    cores += firstClear ? 2 : 1;
  }

  let unlockedRealm: string | undefined;
  if (firstClear) {
    Save.data.clearedRealms.push(realmId);
    // Did clearing this realm unlock a new one?
    const next = REALMS.find(
      (r) => !realmUnlockedBefore(r.id) && Save.data.clearedRealms.length >= r.unlockAfter,
    );
    if (next) unlockedRealm = next.id;
  }

  Save.data.gold += gold;
  Save.data.shards += shards;
  Save.data.cores += cores;

  // Distribute a few champion shards to owned deck members.
  const perChamp = Math.max(1, Math.floor(shards / Math.max(1, Save.data.deck.length)));
  for (const cid of Save.data.deck) grantChampionShards(cid, perChamp);

  Save.flush();
  return { gold, shards, cores, firstClear, unlockedRealm };
}

// Helper: was a realm already unlocked before the just-recorded clear?
const _snapshotBefore = new Set<string>();
function realmUnlockedBefore(id: string): boolean {
  return _snapshotBefore.has(id);
}
export function snapshotUnlocks() {
  _snapshotBefore.clear();
  for (const r of REALMS) if (realmUnlocked(r.id)) _snapshotBefore.add(r.id);
}

// ── Warden upgrades ──────────────────────────────────────────

export function wardenUpgradeCost(level: number): number {
  return 150 + level * 120;
}
export function canUpgradeWarden(): boolean {
  return Save.data.gold >= wardenUpgradeCost(Save.data.wardenLevel);
}
export function upgradeWarden(): boolean {
  if (!canUpgradeWarden()) return false;
  Save.data.gold -= wardenUpgradeCost(Save.data.wardenLevel);
  Save.data.wardenLevel += 1;
  Save.flush();
  return true;
}
