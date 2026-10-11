# Bastion Rush — notes for Claude

Mobile (portrait, Android) last-stand roguelite: Kingdom Rush lanes × Clash Royale
cards/Aether × Archero hero. **The game is the Godot 4.3 project in `godot/`**
(GL Compatibility renderer, GDScript). `web-prototype/` is the old Phaser version, kept for reference only.

## How the project is built (the asset pipeline)
Same method as the reference video: AI images → 3D parts → assemble in Blender →
rig (AccuRIG) → Mixamo animations → custom animations by Claude via the Blender MCP
→ engine. Full guide: `pipeline/README.md` (Portuguese — the developer is Brazilian;
answer them in Portuguese).

- Images: `pipeline/tools/generate_art.py` (OpenAI `gpt-image-1`, needs `OPENAI_API_KEY`
  in the shell — never write keys to files). One shared STYLE string keeps everything
  cohesive: chunky toy-like cartoon, Clash-Royale-like. Keep new prompts on that style.
- Blender scripts: `pipeline/blender/` (assemble parts, transparent materials, export
  with NLA animations). With the Blender MCP connected (`.mcp.json`), run them with
  `exec(open(path).read())` and call the function.
- **Asset slots** (no code changes needed):
  - `godot/assets/models/<id>.glb` → characters/bosses/bastion/props, auto-scaled,
    animations matched loosely to idle/run/attack/hit/die/cast/fly (`scripts/game/model_rig.gd`).
  - `godot/assets/art/{portraits,realms,boons,ui}/` → 2D art (`UIKit.art()`).
  - `godot/assets/audio/<name>.ogg` → sounds; `music_<realm_id>.ogg` per realm.
  - ids come from `scripts/autoload/game_data.gd`; dump them with `--export-data`.

## Code map (godot/)
- Flow: title (`menu`) → 3 local save slots → castle-gate transition (`ui/gate.gd`, via
  `Nav.go(scene, params, true)`) → world map (`map`) → battle → result. Map bottom bar:
  Herói, Campeões, Melhorias (star tree), Bestiário, Conquistas.
- `scripts/autoload/`: `game_data.gd` (towers, champions = tower specializations, 34 enemies,
  boons, upgrade tree, achievements, 10 realms — each realm differs in lanes/layout, palette,
  hazard, roster, boss, music), `save.gd` (slots + global settings + progression math),
  `asset_lib.gd` (GLB slots; otherwise hand-built chibi characters/towers baked into ONE
  vertex-coloured mesh each, toon + ink outline), `sfx.gd`, `nav.gd` (scenes, gates, dev flags).
- `scripts/game/`: `battle.gd` (gold economy, build spots, waves, hazards, combat API, input,
  auto-play), `world_builder.gd` (terrain, 8 lane layouts, build pads, props, weather),
  `champion.gd` (a tower: archer/barracks/mage/artillery, tiers, specialization),
  `soldier.gd` (barracks units that block enemies), `enemy.gd`, `warden.gd` (the hero,
  tap-to-move), `projectile.gd`, `model_rig.gd`. `scripts/dev_gallery.gd` = model lineup.
- `scripts/ui/`: `ui_kit.gd` (wood/parchment widgets), `icon.gd` (drawn icons), `hud.gd`
  (incl. the radial build ring), screens.

## Rules
- Performance first: the dev machine may render in software. No full-screen blended
  effects, no per-frame text/Graphics rebuilds, keep particles small. HUD updates only on change.
- Every realm must stay distinct in everything (layout, look, hazard, enemies, boss, music).
- Verify before claiming done:
  `godot --headless --path godot --quit-after 120` (no SCRIPT ERROR), then auto-play the
  affected realms: `-- --scene=battle --realm=<id> --auto --level=<n>` and read AUTO_RESULT,
  and take screenshots with `-- --shot=/tmp/x.png --frames=90 --scene=<scene> --slot=1` (needs a display).
  Character/tower lineup: `-- --scene=dev_gallery --gallery=heroes|enemies|towers`.
- Headless "Parameter \"m\" is null" / ObjectDB leak lines are harmless noise.
