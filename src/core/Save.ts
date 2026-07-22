import { SAVE_KEY, DECK_SIZE } from '../config';
import type { SaveData, ChampionState } from '../types';
import { CHAMPIONS } from '../data/champions';

/**
 * SaveSystem — durable player profile.
 *
 * Uses localStorage (available in browser and in the Capacitor Android
 * WebView). All mutations flow through here so persistence stays consistent
 * and a single `flush()` writes the whole profile.
 */
class SaveSystem {
  data!: SaveData;

  load(): SaveData {
    let parsed: Partial<SaveData> | null = null;
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (raw) parsed = JSON.parse(raw) as SaveData;
    } catch {
      parsed = null;
    }
    this.data = this.migrate(parsed);
    this.ensureChampions();
    return this.data;
  }

  private migrate(p: Partial<SaveData> | null): SaveData {
    const base = this.fresh();
    if (!p) return base;
    return {
      ...base,
      ...p,
      settings: { ...base.settings, ...(p.settings ?? {}) },
      stats: { ...base.stats, ...(p.stats ?? {}) },
      bestWave: { ...(p.bestWave ?? {}) },
      champions: { ...(p.champions ?? {}) },
      clearedRealms: p.clearedRealms ?? [],
      deck: p.deck && p.deck.length ? p.deck : base.deck,
    };
  }

  private fresh(): SaveData {
    return {
      version: 1,
      gold: 250,
      shards: 0,
      cores: 0,
      wardenLevel: 1,
      clearedRealms: [],
      bestWave: {},
      champions: {},
      // Starter deck: the four champions unlocked from the first run.
      deck: ['pyre-knight', 'thistle-archer', 'runestone', 'sister-vale'],
      settings: { sfx: true, music: true, haptics: true, screenShake: true },
      stats: { runs: 0, kills: 0, victories: 0 },
      createdAt: Date.now(),
    };
  }

  /** Make sure every champion in the catalogue has a state entry. */
  private ensureChampions() {
    for (const def of CHAMPIONS) {
      if (!this.data.champions[def.id]) {
        const starter = this.data.deck.includes(def.id);
        this.data.champions[def.id] = {
          level: 1,
          shards: 0,
          unlocked: starter || def.rarity === 'common',
          evolved: false,
        };
      }
    }
    // Keep deck valid & sized.
    this.data.deck = this.data.deck
      .filter((id) => this.data.champions[id]?.unlocked)
      .slice(0, DECK_SIZE);
    if (this.data.deck.length === 0) {
      this.data.deck = ['pyre-knight', 'thistle-archer', 'runestone', 'sister-vale'];
    }
  }

  champion(id: string): ChampionState {
    return this.data.champions[id];
  }

  flush() {
    try {
      localStorage.setItem(SAVE_KEY, JSON.stringify(this.data));
    } catch {
      /* storage full or unavailable — fail silently, game still runs */
    }
  }

  /** Reset everything (used by the settings screen). */
  wipe() {
    localStorage.removeItem(SAVE_KEY);
    this.data = this.fresh();
    this.ensureChampions();
    this.flush();
  }
}

export const Save = new SaveSystem();
