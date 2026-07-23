# Bastion Rush

> **A last-stand roguelite tower-brawler.** *Kingdom Rush* lanes × *Clash Royale*
> collection & deploy-energy × *Archero* hero action — fused into one coherent
> loop, built to ship on Android.

Portrait, mobile-first, 60 FPS, **zero external assets** — every sprite, sound,
and level is generated from code. Built with **Phaser 3 + TypeScript + Vite** and
packaged for the Play Store with **Capacitor**.

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

- **5 unlockable Realms** — The Broken Gate, Emberfall Wood, The Sunken March,
  Hollow Keep, The Rift Throne — each with its own palette, lane count, wave
  tables, and boss. Clearing one unlocks the next.
- **10 champions** across 4 roles (melee / ranged / tower / support) and 4
  rarities, each with a distinct silhouette, ability, and **evolution** form.
- **9 enemy archetypes** including 3 escalating bosses.
- **18 Boons** — damage, multishot, pierce, crit, lifesteal, chain lightning,
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

## 6. Running it

```bash
npm install
npm run dev        # play in the browser at http://localhost:5173
npm run build      # typecheck + production bundle into dist/
npm run preview    # serve the production build
```

Everything is generated at runtime, so there are no asset downloads.

## 7. Shipping to Android (Google Play)

The web build is wrapped natively with Capacitor. On a machine with **Android
Studio + JDK 17** installed:

```bash
npm run build                 # 1. build the web game
npx cap add android           # 2. scaffold the native project (first time only)
npm run cap:sync              # 3. copy dist/ into the native shell
npm run android:open          # 4. open Android Studio
# In Android Studio: Build ▸ Generate Signed Bundle / APK ▸ Android App Bundle (.aab)
```

`npm run android:build` chains build → sync → `gradlew bundleRelease` once a
signing config is in place.

### Launch checklist

- [ ] Set a permanent `appId` in `capacitor.config.ts` (currently
      `com.aethelgard.bastionrush`).
- [ ] Create an upload **keystore** and wire a `release` signing config in
      `android/app/build.gradle`. **Never commit the keystore or its passwords.**
- [ ] Provide app icons & the splash screen (`npx @capacitor/assets generate`).
- [ ] Set `versionCode` / `versionName` per release.
- [ ] Confirm `targetSdk` meets the current Play requirement.
- [ ] Create the app in **Google Play Console** (requires a paid developer
      account) and complete the store listing, content rating, data-safety form,
      and privacy policy.
- [ ] Upload the signed `.aab` to a testing track, then promote to production.
- [ ] *(Optional, for monetization)* integrate a billing/ads SDK and wire the
      IAP/rewarded-ad slots described in §5.

> These steps require **your** developer account, signing keys, and store assets,
> so they must be done on your side — the game itself is build-ready.

## 8. Architecture

```
src/
  main.ts             Phaser bootstrap & scene list
  config.ts           Global tuning (Aether, Warden, Bastion, depths)
  types.ts            Shared data contracts + run modifiers
  core/
    Palette.ts        The art direction, in one file
    Art.ts            Procedural texture forge (every sprite, generated)
    Audio.ts          Procedural WebAudio SFX + ambient music
    Save.ts           localStorage persistence
    Meta.ts           Leveling, evolution, unlocks, run settlement
    UI.ts / Backdrop.ts / RNG.ts
  data/
    champions.ts enemies.ts boons.ts realms.ts   (data-driven content)
  game/
    Arena.ts          Interface entities use to talk to the battlefield
    Enemy.ts Champion.ts Warden.ts Projectile.ts
  scenes/
    Boot / Menu / RealmSelect / Loadout / Collection / Game / Result / Settings
```

Content is **data-driven** — new champions, enemies, boons, and realms are added
by editing the tables in `src/data/`, no engine changes required.

## 9. Design notes & roadmap

Shipped: full core loop, meta-progression, 5 realms, 10 champions, procedural
art & audio, save system, Android packaging config, verified boot + combat +
deploy pipelines via automated headless smoke tests.

Next candidates: more realms & champions, daily challenges, champion skins,
haptics tuning, a tutorial overlay for first-time players, and cloud save.

---

*Bastion Rush — hold the last light against the Rush.*
