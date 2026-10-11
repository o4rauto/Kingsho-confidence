# Bastion Rush

> **A last-stand roguelite tower-brawler.** *Kingdom Rush* lanes × *Clash Royale*
> collection & deploy-energy × *Archero* hero action — fused into one coherent
> loop, built to ship on Android.

Portrait, mobile-first, 60 FPS, **zero external assets** — every sprite, sound,
and level is generated from code. Built with **Godot 4.3** and an AI asset pipeline
(ChatGPT → Tripo → Blender → Mixamo), shipped to Android.

---

## 1. The Concept

The Sunspire fell, and the world of **Aethelgard** shattered along the rifts it
had held shut. From those wounds pours **The Rush** — corrupted echoes of the
fallen, an endless tide marching on the last lit places.

You are the **Warden of the Last Bastion**. Each descent into a broken **Realm**,
you plant a beachhead and hold it: summon champions along the path, and fight in
person as the Warden — moving, aiming, unleashing. Survive the waves, choose your
boons, push deeper, and take back Aethelgard one Realm at a time.

**Fantasy:** *"I am the last light, and I decide where the dark breaks."*

## 2. The Fusion (why it's the child of all three)

| Pillar | From | In Bastion Rush |
| --- | --- | --- |
| **Lane defense** | Kingdom Rush | Enemies march winding lanes toward your Bastion. Distinct types (runners, brutes, flyers, casters, bosses) demand different answers. |
| **Collect & deploy** | Clash Royale | A regenerating **Aether** bar. Spend it to deploy **champion cards** from your deck. Collect, **level**, and **evolve** champions between runs. |
| **Hero action** | Archero | You pilot the **Warden**: drag to move, and auto-fire *only while standing still*. After every wave, draft **1 of 3 Boons** that stack for the run. |

The synthesis is the point: your towers hold the line while *you* dance through
it, and the run-scoped Boons make every descent feel different from the permanent
meta-progression of your collection.

## 3. Core Loop

```
Pick a Realm ─▶ Assemble deck (4 champions) ─▶ Descend
     ▲                                             │
     │                                             ▼
   Rewards ◀── Victory / Defeat ◀── Waves: move · aim · deploy · ULT
     │                                             │
     └──────── Level & evolve champions  ◀── Draft a Boon (between waves)
```

- **Win:** clear every wave (each Realm ends on a boss).
- **Lose:** the Bastion's Integrity hits zero. The Warden itself never dies — when
  downed it revives at the Bastion, so a run ends on the *fortress*, not a death.
- **Earn:** Gold, Shards, and Cores → level up champions, unlock new ones, evolve
  your best, and upgrade the Warden.

## 4. Content

- **10 unlockable Realms**, each a different game (see §8): lane count and
  shape, biome, sky, weather, hazard, enemy roster, boss and music. Clearing
  one unlocks the next.
- **10 champions** across 4 roles (melee / ranged / tower / support) and 4
  rarities, each with a distinct silhouette, ability, and **evolution** form.
- **34 enemies** across 10 biome rosters with traits (armor, shields, regen,
  splitting, healing) and **10 unique bosses** with signature abilities.
- **17 Boons** — damage, multishot, pierce, crit, lifesteal, chain lightning,
  burn, frost, Aether regen, Bastion repair, and more.

## 5. Progression & Economy (the money model)

Designed for a fair, retention-friendly free-to-play economy (monetization hooks
are *designed-in but not yet wired* — see the launch checklist):

- **Gold** — soft currency from every run. Spent on champion level-ups & Warden
  upgrades.
- **Shards** — collect duplicates to unlock and level champions (Clash-Royale-style).
- **Cores** — premium-feel currency from boss/first-clears, spent on **evolutions**.

Natural IAP / rewarded-ad slots (not implemented, intentionally): Gold/Shard
bundles, a "double first-clear rewards" rewarded ad, cosmetic Warden skins,
and a battle-pass over the Realm campaign. Nothing is pay-to-win by design —
skill (positioning + boon drafting) carries every run.

## 6. Running it (Godot 4.3)

The game is the Godot project in [`godot/`](./godot). Open `godot/project.godot`
in **Godot 4.3** and press Play. Portrait, GL Compatibility renderer (runs on
weak GPUs and nearly every Android phone).

The original Phaser prototype lives in `web-prototype/` for reference.

## 7. Building the art — the AI asset pipeline

Built with the same method as the reference video: **ChatGPT images → Tripo 3D
parts → assembled in Blender → AccuRIG rig → Mixamo animations → custom
animations by Claude via the Blender MCP → engine.** Step-by-step (Portuguese):
[`pipeline/README.md`](./pipeline/README.md).

Every character, boss, prop, image and sound has an **asset slot**: drop the
file in place and the game swaps the procedural placeholder for it — no code
changes. The game is fully playable before any art exists.

## 8. Ten realms, ten different games

| # | Realm | Lanes | Hazard | Boss |
|---|---|---|---|---|
| 1 | The Broken Gate | 2 straight | tutorial | The Maw (charge) |
| 2 | Emberfall Wood | 2 zigzag | falling embers | Cinder Treant (summons) |
| 3 | The Sunken March | 3 serpent | mud + fog | The Drowned King (shield) |
| 4 | Hollow Keep | 2 crossing | ballista targets you | Siege Titan (slam) |
| 5 | The Rift Throne | 3 forking | rift portals | Rift Sovereign (summons) |
| 6 | Frostpeak Pass | 1 serpent | ice + blizzards | Frost Wyrm (charge) |
| 7 | Sunscar Dunes | 4 converging | sandstorms + oasis | Sand Colossus (splits) |
| 8 | Ashen Caldera | 3 zigzag | eruptions hit everyone | Magma Tyrant (slam) |
| 9 | Gloomroot Mire | 3 braided | root snares | Bog Mother (summons) |
| 10 | The Shattered Sunspire | 3 spiral | rotating sunbeam | The Eclipse (shield) |

Each also has its own palette, sky, fog, light, weather, set pieces, enemy
roster with traits (armor, shields, regen, splitting, healing) and music.

## 9. Shipping to Android

Godot: *Manage Export Templates* (4.3) → *Project ▸ Export ▸ Android*, configure
the Android SDK and a release keystore (**never commit it**), export an `.aab`,
upload to Google Play Console. Monetization slots (IAP, rewarded ads) remain
designed-in but not wired.

---

*Bastion Rush — hold the last light against the Rush.*
