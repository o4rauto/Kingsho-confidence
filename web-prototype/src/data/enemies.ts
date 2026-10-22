import type { EnemyDef } from '../types';
import { Palette } from '../core/Palette';

/**
 * The Rush — corrupted echoes pouring from the rifts.
 *
 * Enemy variety drives the tower-defense puzzle: fast swarms want AoE, brutes
 * want focus fire, flyers ignore ground blockers, casters punish a slow line.
 */
export const ENEMIES: EnemyDef[] = [
  {
    id: 'wisp',
    name: 'Rift Wisp',
    kind: 'runner',
    hp: 36,
    damage: 6,
    speed: 74,
    radius: 13,
    bounty: 4,
    breach: 4,
    color: Palette.rush2,
  },
  {
    id: 'husk',
    name: 'Ashen Husk',
    kind: 'runner',
    hp: 70,
    damage: 10,
    speed: 56,
    radius: 16,
    bounty: 6,
    breach: 7,
    color: Palette.rush1,
  },
  {
    id: 'gloombat',
    name: 'Gloombat',
    kind: 'flyer',
    hp: 44,
    damage: 8,
    speed: 104,
    radius: 14,
    bounty: 8,
    breach: 6,
    color: 0xa267d6,
  },
  {
    id: 'ravager',
    name: 'Ravager',
    kind: 'brute',
    hp: 220,
    damage: 20,
    speed: 42,
    radius: 22,
    bounty: 14,
    breach: 12,
    color: Palette.rush0,
  },
  {
    id: 'hexmage',
    name: 'Hexmage',
    kind: 'caster',
    hp: 120,
    damage: 16,
    speed: 48,
    radius: 17,
    bounty: 16,
    breach: 14,
    color: 0xd14bff,
  },
  {
    id: 'ogre',
    name: 'Rift Ogre',
    kind: 'brute',
    hp: 520,
    damage: 34,
    speed: 34,
    radius: 28,
    bounty: 30,
    breach: 22,
    color: 0x7a2140,
  },
  // ── Bosses ──────────────────────────────────────────────
  {
    id: 'the-maw',
    name: 'The Maw',
    kind: 'boss',
    hp: 2600,
    damage: 40,
    speed: 30,
    radius: 42,
    bounty: 160,
    breach: 100,
    color: Palette.rush0,
  },
  {
    id: 'siege-titan',
    name: 'Siege Titan',
    kind: 'boss',
    hp: 5200,
    damage: 55,
    speed: 26,
    radius: 48,
    bounty: 260,
    breach: 100,
    color: 0x5a1730,
  },
  {
    id: 'rift-sovereign',
    name: 'Rift Sovereign',
    kind: 'boss',
    hp: 9000,
    damage: 70,
    speed: 30,
    radius: 52,
    bounty: 420,
    breach: 100,
    color: 0x2a0f3a,
  },
];

export const ENEMY_BY_ID: Record<string, EnemyDef> = Object.fromEntries(
  ENEMIES.map((e) => [e.id, e]),
);

export function getEnemy(id: string): EnemyDef {
  const e = ENEMY_BY_ID[id];
  if (!e) throw new Error(`Unknown enemy: ${id}`);
  return e;
}
