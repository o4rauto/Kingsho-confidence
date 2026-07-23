import type { RealmDef, WaveDef, SpawnGroup } from '../types';
import { Palette } from '../core/Palette';

/**
 * Realms — the unlockable campaign maps.
 *
 * Each realm ramps enemy mix, lane count, and ends on a boss wave. Clearing a
 * realm unlocks the next and pays out gold + shards. `bestWave` in the save
 * tracks how deep you have pushed for replay motivation.
 */

/** Terse spawn-group builder to keep wave tables readable. */
function g(enemy: string, count: number, at: number, gap = 700, lane = 0): SpawnGroup {
  return { enemy, count, at, gap, lane };
}

function wave(...groups: SpawnGroup[]): WaveDef {
  return { groups };
}

export const REALMS: RealmDef[] = [
  {
    id: 'broken-gate',
    name: 'The Broken Gate',
    subtitle: 'Where the first rift tore open',
    unlockAfter: 0,
    ground: Palette.night2,
    ground2: Palette.night1,
    accent: Palette.ember2,
    lanes: 2,
    goldReward: 120,
    shardReward: 6,
    waves: [
      wave(g('wisp', 5, 0, 620, 0)),
      wave(g('wisp', 5, 0, 520, 0), g('husk', 3, 900, 800, 1)),
      wave(g('husk', 6, 0, 620, 0), g('wisp', 6, 400, 380, 1)),
      wave(g('husk', 5, 0, 560, 0), g('ravager', 1, 1200, 0, 1), g('wisp', 6, 1600, 320, 0)),
      wave(g('wisp', 10, 0, 300, 0), g('husk', 6, 800, 500, 1), g('ravager', 2, 2600, 1400, 0)),
      wave(g('the-maw', 1, 400, 0, 0), g('wisp', 8, 1200, 500, 1)),
    ],
  },
  {
    id: 'emberfall-wood',
    name: 'Emberfall Wood',
    subtitle: 'The canopy remembers the fire',
    unlockAfter: 1,
    ground: 0x14251c,
    ground2: 0x0d1a13,
    accent: Palette.good,
    lanes: 2,
    goldReward: 180,
    shardReward: 8,
    waves: [
      wave(g('husk', 6, 0, 520, 0), g('gloombat', 3, 700, 500, 1)),
      wave(g('gloombat', 6, 0, 420, 0), g('wisp', 6, 500, 360, 1)),
      wave(g('husk', 6, 0, 480, 0), g('ravager', 2, 900, 1100, 1), g('gloombat', 4, 1500, 420, 0)),
      wave(g('gloombat', 8, 0, 320, 1), g('husk', 8, 400, 420, 0)),
      wave(g('ravager', 3, 0, 1100, 0), g('gloombat', 6, 600, 400, 1), g('husk', 8, 1400, 380, 0)),
      wave(g('hexmage', 2, 0, 900, 0), g('gloombat', 8, 500, 320, 1), g('husk', 8, 1000, 360, 0)),
      wave(g('the-maw', 1, 300, 0, 1), g('gloombat', 10, 800, 380, 0), g('ravager', 2, 3000, 1200, 1)),
    ],
  },
  {
    id: 'sunken-march',
    name: 'The Sunken March',
    subtitle: 'Drowned banners, drowned kings',
    unlockAfter: 2,
    ground: 0x122436,
    ground2: 0x0a1622,
    accent: Palette.aether1,
    lanes: 3,
    goldReward: 260,
    shardReward: 10,
    waves: [
      wave(g('husk', 8, 0, 420, 0), g('hexmage', 2, 800, 900, 1), g('wisp', 8, 500, 320, 2)),
      wave(g('gloombat', 8, 0, 340, 2), g('ravager', 2, 700, 1200, 0), g('husk', 8, 500, 380, 1)),
      wave(g('hexmage', 4, 0, 700, 1), g('husk', 10, 300, 340, 0), g('gloombat', 8, 600, 340, 2)),
      wave(g('ravager', 4, 0, 900, 0), g('hexmage', 3, 600, 800, 2), g('wisp', 12, 400, 260, 1)),
      wave(g('ogre', 1, 0, 0, 1), g('husk', 12, 400, 300, 0), g('gloombat', 10, 700, 300, 2)),
      wave(g('hexmage', 5, 0, 620, 1), g('ravager', 4, 500, 800, 0), g('gloombat', 10, 900, 280, 2)),
      wave(g('ogre', 2, 0, 1600, 0), g('hexmage', 4, 700, 700, 2), g('husk', 12, 500, 300, 1)),
      wave(g('siege-titan', 1, 400, 0, 1), g('hexmage', 4, 1200, 800, 0), g('gloombat', 12, 900, 280, 2)),
    ],
  },
  {
    id: 'hollow-keep',
    name: 'Hollow Keep',
    subtitle: 'A fortress the Rush made its own',
    unlockAfter: 3,
    ground: 0x241826,
    ground2: 0x160e17,
    accent: Palette.rush2,
    lanes: 3,
    goldReward: 340,
    shardReward: 12,
    waves: [
      wave(g('ravager', 4, 0, 700, 0), g('hexmage', 3, 500, 700, 2), g('husk', 10, 400, 320, 1)),
      wave(g('ogre', 2, 0, 1400, 1), g('gloombat', 12, 400, 260, 0), g('hexmage', 3, 900, 700, 2)),
      wave(g('hexmage', 6, 0, 560, 1), g('ravager', 5, 400, 640, 0), g('gloombat', 12, 700, 260, 2)),
      wave(g('ogre', 3, 0, 1300, 0), g('husk', 14, 300, 280, 1), g('hexmage', 4, 800, 640, 2)),
      wave(g('ravager', 6, 0, 560, 2), g('ogre', 2, 800, 1600, 0), g('gloombat', 14, 500, 240, 1)),
      wave(g('hexmage', 8, 0, 480, 1), g('ravager', 6, 400, 560, 0), g('ogre', 2, 1200, 1600, 2)),
      wave(g('ogre', 4, 0, 1100, 0), g('hexmage', 6, 600, 560, 2), g('gloombat', 16, 500, 220, 1)),
      wave(g('siege-titan', 1, 300, 0, 0), g('ogre', 3, 900, 1400, 2), g('hexmage', 6, 1200, 600, 1)),
    ],
  },
  {
    id: 'rift-throne',
    name: 'The Rift Throne',
    subtitle: 'The heart of the Rush, and its end',
    unlockAfter: 4,
    ground: 0x1a0f2b,
    ground2: 0x0d0718,
    accent: Palette.aether2,
    lanes: 3,
    goldReward: 500,
    shardReward: 18,
    waves: [
      wave(g('ravager', 6, 0, 560, 0), g('hexmage', 5, 400, 560, 2), g('gloombat', 14, 400, 240, 1)),
      wave(g('ogre', 3, 0, 1200, 1), g('hexmage', 6, 500, 500, 0), g('gloombat', 16, 400, 220, 2)),
      wave(g('the-maw', 1, 0, 0, 1), g('ravager', 6, 600, 500, 0), g('hexmage', 6, 800, 500, 2)),
      wave(g('ogre', 4, 0, 1000, 0), g('hexmage', 8, 400, 480, 2), g('gloombat', 18, 400, 200, 1)),
      wave(g('siege-titan', 1, 0, 0, 2), g('ogre', 3, 800, 1200, 0), g('hexmage', 8, 600, 480, 1)),
      wave(g('ravager', 10, 0, 380, 0), g('ogre', 4, 700, 900, 1), g('gloombat', 20, 400, 180, 2)),
      wave(g('the-maw', 1, 0, 0, 0), g('siege-titan', 1, 200, 0, 2), g('hexmage', 8, 900, 460, 1)),
      wave(g('rift-sovereign', 1, 500, 0, 1), g('ogre', 5, 1400, 1000, 0), g('hexmage', 10, 1200, 460, 2)),
    ],
  },
];

export const REALM_BY_ID: Record<string, RealmDef> = Object.fromEntries(
  REALMS.map((r) => [r.id, r]),
);

export function getRealm(id: string): RealmDef {
  const r = REALM_BY_ID[id];
  if (!r) throw new Error(`Unknown realm: ${id}`);
  return r;
}
