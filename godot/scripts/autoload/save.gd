extends Node
## Save — three local save slots (like the classic "Local Save" screen) +
## global settings, and all the meta-progression math.
##
## Progression is deliberately simple:
##   · STARS  (1–3 per realm)   → spent on the Upgrades tree (refundable).
##   · GOLD   (realm rewards)   → levels up champions and the hero.
##   · Champions JOIN your collection as you conquer realms.
##   · Champions EVOLVE automatically at level 5 (★) and 10 (★★).

const SLOT_PATH := "user://bastion_rush_slot%d.json"
const SETTINGS_PATH := "user://bastion_rush_settings.json"
const SLOTS := 3
const STARTER_DECK := ["pyre_knight", "thistle_archer", "runestone", "sister_vale"]

var slot := 0                 # 0 = no slot chosen yet (title screen / dev runs)
var data: Dictionary = {}
var settings := {"sfx": true, "music": true, "haptics": true, "shake": true}

func _ready() -> void:
	_load_settings()
	data = _fresh()

func _fresh() -> Dictionary:
	var d := {
		"version": 2, "gold": 150, "stars": {}, "best_wave": {}, "cleared": [],
		"champions": {}, "deck": STARTER_DECK.duplicate(),
		"hero": {"name": GameData.HERO.name, "cape": 0, "level": 1},
		"upgrades": {}, "seen": [], "claimed": [], "intro_seen": false,
		"stats": {"runs": 0, "kills": 0, "victories": 0, "builds": 0, "bosses": 0},
	}
	for c in GameData.champions:
		d.champions[c.id] = {"level": 1}
	for u in GameData.UPGRADES:
		d.upgrades[u.id] = 0
	return d

# ── Slots ───────────────────────────────────────────────────
func slot_exists(i: int) -> bool:
	return FileAccess.file_exists(SLOT_PATH % i)

## Small summary for the slot picker (reads the file without switching slot).
func slot_summary(i: int) -> Dictionary:
	if not slot_exists(i):
		return {}
	var d := _read(SLOT_PATH % i)
	var stars := 0
	for k in d.get("stars", {}):
		stars += int(d.stars[k])
	return {"stars": stars, "cleared": d.get("cleared", []).size(), "hero": d.get("hero", {}).get("name", GameData.HERO.name)}

func use_slot(i: int) -> void:
	slot = i
	data = _fresh()
	if slot_exists(i):
		var parsed := _read(SLOT_PATH % i)
		for k in parsed:
			if data.has(k) and data[k] is Dictionary and parsed[k] is Dictionary:
				for kk in parsed[k]:
					data[k][kk] = parsed[k][kk]
			else:
				data[k] = parsed[k]
	_sanitize()
	flush()

func delete_slot(i: int) -> void:
	if slot_exists(i):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SLOT_PATH % i))
	if slot == i:
		slot = 0
		data = _fresh()

func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func _sanitize() -> void:
	for c in GameData.champions:
		if not data.champions.has(c.id) or not data.champions[c.id] is Dictionary:
			data.champions[c.id] = {"level": 1}
		data.champions[c.id].level = clampi(int(data.champions[c.id].get("level", 1)), 1, GameData.MAX_LEVEL)
	var deck: Array = []
	for id in data.deck:
		if champ_unlocked(String(id)) and not deck.has(id) and deck.size() < GameData.DECK_SIZE:
			deck.append(String(id))
	for id in STARTER_DECK:
		if deck.size() < GameData.DECK_SIZE and not deck.has(id):
			deck.append(id)
	data.deck = deck

func flush() -> void:
	if slot == 0:
		return
	var f := FileAccess.open(SLOT_PATH % slot, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load_settings() -> void:
	var d := _read(SETTINGS_PATH)
	for k in d:
		settings[k] = d[k]

func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))

# ── Champions ───────────────────────────────────────────────
func champ(id: String) -> Dictionary:
	return data.champions[id]

func champ_unlocked(id: String) -> bool:
	return data.cleared.size() >= int(GameData.champion(id).get("unlock_after", 0))

## 0, 1 (★) or 2 (★★) — evolutions are automatic with level.
func evo(id: String) -> int:
	var lv := int(champ(id).level)
	var n := 0
	for e in GameData.EVOLVE_LEVELS:
		if lv >= int(e): n += 1
	return n

func stats(def: Dictionary) -> Dictionary:
	var lv := int(champ(def.id).level)
	var m: float = (1.0 + GameData.GROWTH_PER_LEVEL * (lv - 1)) * (1.0 + GameData.EVOLVE_BONUS * evo(def.id))
	var hp: float = round(def.hp * m)
	var dmg: float = round(def.damage * m)
	return {"hp": hp, "damage": dmg, "power": int(round((hp * 0.4 + dmg * def.atk_speed * 8.0) * def.count))}

func level_cost(level: int) -> int:
	return 60 + level * 45

func can_level(id: String) -> bool:
	var lv := int(champ(id).level)
	return champ_unlocked(id) and lv < GameData.MAX_LEVEL and int(data.gold) >= level_cost(lv)

func level_up(id: String) -> bool:
	if not can_level(id): return false
	var st := champ(id)
	data.gold -= level_cost(int(st.level))
	st.level = int(st.level) + 1
	flush()
	return true

# ── Hero ────────────────────────────────────────────────────
func hero_level() -> int:
	return int(data.hero.level)

func hero_cost() -> int:
	return 100 + hero_level() * 60

func hero_level_up() -> bool:
	if hero_level() >= GameData.HERO_MAX_LEVEL or int(data.gold) < hero_cost():
		return false
	data.gold -= hero_cost()
	data.hero.level = hero_level() + 1
	flush()
	return true

func hero_cape() -> Color:
	return GameData.CAPES[clampi(int(data.hero.cape), 0, GameData.CAPES.size() - 1)][1]

func hero_name() -> String:
	var n := String(data.hero.name).strip_edges()
	return n if n != "" else GameData.HERO.name

# ── Stars & upgrades ────────────────────────────────────────
func total_stars() -> int:
	var n := 0
	for k in data.stars:
		n += int(data.stars[k])
	return n

func spent_stars() -> int:
	var n := 0
	for u in GameData.UPGRADES:
		for t in int(data.upgrades.get(u.id, 0)):
			n += int(GameData.UPGRADE_COSTS[t])
	return n

func free_stars() -> int:
	return total_stars() - spent_stars()

func upgrade_level(id: String) -> int:
	return int(data.upgrades.get(id, 0))

func buy_upgrade(id: String) -> bool:
	var lv := upgrade_level(id)
	if lv >= GameData.UPGRADE_COSTS.size() or free_stars() < int(GameData.UPGRADE_COSTS[lv]):
		return false
	data.upgrades[id] = lv + 1
	flush()
	return true

## Sum of every bought tier's mods, e.g. {"archer_dmg": 0.25, "start_gold": 50}.
func upgrade_mods() -> Dictionary:
	var m := {}
	for u in GameData.UPGRADES:
		for t in upgrade_level(u.id):
			var tm: Dictionary = u.tiers[t].mods
			for k in tm:
				m[k] = float(m.get(k, 0.0)) + float(tm[k])
	return m

func reset_upgrades() -> void:
	for u in GameData.UPGRADES:
		data.upgrades[u.id] = 0
	flush()

# ── Realms ──────────────────────────────────────────────────
func realm_unlocked(id: String) -> bool:
	return data.cleared.size() >= int(GameData.realm(id).unlock_after)

func realm_cleared(id: String) -> bool:
	return data.cleared.has(id)

func realm_stars(id: String) -> int:
	return int(data.stars.get(id, 0))

func mark_seen(enemy_id: String) -> void:
	if not data.seen.has(enemy_id):
		data.seen.append(enemy_id)

## Pays out a finished battle. Returns the reward summary.
func settle_run(realm_id: String, victory: bool, waves: int, integrity_frac: float, kills: int, builds: int, bosses: int) -> Dictionary:
	var r := GameData.realm(realm_id)
	var unlocked_champs: Array = []
	for c in GameData.champions:
		if champ_unlocked(c.id): unlocked_champs.append(c.id)
	data.best_wave[realm_id] = max(int(data.best_wave.get(realm_id, 0)), waves)
	data.stats.runs += 1
	data.stats.kills += kills
	data.stats.builds += builds
	data.stats.bosses += bosses
	var first: bool = victory and not realm_cleared(realm_id)
	var stars := 0
	var gold := 0
	if victory:
		data.stats.victories += 1
		stars = 3 if integrity_frac >= 0.9 else (2 if integrity_frac >= 0.5 else 1)
		gold = int(r.gold * (1.0 if first else 0.35))
	else:
		gold = int(r.gold * 0.25 * float(waves) / maxf(1.0, r.wave_list.size()))
	var new_stars: int = maxi(0, stars - realm_stars(realm_id))
	if stars > realm_stars(realm_id):
		data.stars[realm_id] = stars
	if first:
		data.cleared.append(realm_id)
	var new_realm := ""
	for x in GameData.realms:
		if x.unlock_after == data.cleared.size() and first:
			new_realm = x.id
	var new_champ := ""
	for c in GameData.champions:
		if champ_unlocked(c.id) and not unlocked_champs.has(c.id):
			new_champ = c.id
	data.gold += gold
	flush()
	return {"gold": gold, "stars": stars, "new_stars": new_stars, "first": first, "new_realm": new_realm, "new_champ": new_champ}

# ── Achievements ────────────────────────────────────────────
func stat_value(key: String) -> int:
	match key:
		"cleared": return data.cleared.size()
		"stars": return total_stars()
		"hero_level": return hero_level()
		"max_champ_level":
			var m := 1
			for id in data.champions: m = maxi(m, int(data.champions[id].level))
			return m
	return int(data.stats.get(key, 0))

func achievement_done(a: Dictionary) -> bool:
	return stat_value(a.stat) >= int(a.target)

func claim(a: Dictionary) -> bool:
	if data.claimed.has(a.id) or not achievement_done(a):
		return false
	data.claimed.append(a.id)
	data.gold += int(a.gold)
	flush()
	return true

func claimable_count() -> int:
	var n := 0
	for a in GameData.ACHIEVEMENTS:
		if achievement_done(a) and not data.claimed.has(a.id): n += 1
	return n

func hero_stats(lv := -1) -> Dictionary:
	var l := hero_level() if lv < 0 else lv
	var u := 1.0 + float(upgrade_mods().get("hero_power", 0.0))
	return {
		"hp": round(GameData.HERO.max_hp * (1.0 + 0.07 * (l - 1)) * u),
		"damage": round(GameData.HERO.damage * (1.0 + 0.08 * (l - 1)) * u * 10.0) / 10.0,
		"range": GameData.HERO.range, "speed": GameData.HERO.speed * (1.0 + float(upgrade_mods().get("hero_speed", 0.0))),
	}
