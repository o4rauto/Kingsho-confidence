extends Node
## Save — persistent profile + all meta-progression math.

const PATH := "user://bastion_rush_save.json"
const STARTER_DECK := ["pyre_knight", "thistle_archer", "runestone", "sister_vale"]

var data: Dictionary = {}

func _ready() -> void:
	load_game()

func _fresh() -> Dictionary:
	return {
		"version": 1, "gold": 250, "shards": 0, "cores": 0, "warden_level": 1,
		"cleared": [], "best_wave": {}, "champions": {}, "deck": STARTER_DECK.duplicate(),
		"settings": {"sfx": true, "music": true, "haptics": true, "shake": true},
		"stats": {"runs": 0, "kills": 0, "victories": 0},
	}

func load_game() -> void:
	data = _fresh()
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			for k in parsed:
				data[k] = parsed[k]
	for c in GameData.champions:
		if not data.champions.has(c.id):
			var starter: bool = STARTER_DECK.has(c.id)
			data.champions[c.id] = {"level": 1, "shards": 0, "unlocked": starter or c.rarity == "common", "evolved": false}
	var deck: Array = []
	for id in data.deck:
		if data.champions.has(id) and data.champions[id].unlocked and deck.size() < GameData.DECK_SIZE:
			deck.append(id)
	if deck.is_empty():
		deck = STARTER_DECK.duplicate()
	data.deck = deck

func flush() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func wipe() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	load_game()
	flush()

func champ(id: String) -> Dictionary:
	return data.champions[id]

# ── Champion growth ─────────────────────────────────────────
func stats(def: Dictionary) -> Dictionary:
	var st := champ(def.id)
	var m: float = (1.0 + GameData.GROWTH_PER_LEVEL * (st.level - 1)) * (1.0 + GameData.EVOLVE_BONUS if st.evolved else 1.0)
	var hp: float = round(def.hp * m)
	var dmg: float = round(def.damage * m)
	return {"hp": hp, "damage": dmg, "power": int(round((hp * 0.4 + dmg * def.atk_speed * 8.0) * def.count))}

func level_shard_cost(level: int) -> int: return 3 + level * 2
func level_gold_cost(level: int) -> int: return 30 + level * 25
const EVOLVE_CORES := 3
const EVOLVE_GOLD := 300

func can_level(id: String) -> bool:
	var st := champ(id)
	return st.unlocked and st.level < GameData.MAX_LEVEL and st.shards >= level_shard_cost(int(st.level)) and data.gold >= level_gold_cost(int(st.level))

func level_up(id: String) -> bool:
	if not can_level(id): return false
	var st := champ(id)
	st.shards -= level_shard_cost(int(st.level))
	data.gold -= level_gold_cost(int(st.level))
	st.level += 1
	flush()
	return true

func can_evolve(id: String) -> bool:
	var st := champ(id)
	return st.unlocked and not st.evolved and st.level >= GameData.EVOLVE_LEVEL and data.cores >= EVOLVE_CORES and data.gold >= EVOLVE_GOLD

func evolve(id: String) -> bool:
	if not can_evolve(id): return false
	data.cores -= EVOLVE_CORES
	data.gold -= EVOLVE_GOLD
	champ(id).evolved = true
	flush()
	return true

func unlock_cost(rarity: String) -> int:
	return {"legendary": 40, "epic": 24, "rare": 12}.get(rarity, 6)

func can_unlock(def: Dictionary) -> bool:
	var st := champ(def.id)
	return not st.unlocked and st.shards >= unlock_cost(def.rarity)

func unlock(def: Dictionary) -> bool:
	if not can_unlock(def): return false
	var st := champ(def.id)
	st.shards -= unlock_cost(def.rarity)
	st.unlocked = true
	flush()
	return true

# ── Realms ──────────────────────────────────────────────────
func realm_unlocked(id: String) -> bool:
	return data.cleared.size() >= GameData.realm(id).unlock_after

func realm_cleared(id: String) -> bool:
	return data.cleared.has(id)

## Pays out a finished run. Returns the reward summary.
func settle_run(realm_id: String, victory: bool, waves: int, gold_earned: int, kills: int) -> Dictionary:
	var r := GameData.realm(realm_id)
	var unlocked_before: Array = []
	for x in GameData.realms:
		if realm_unlocked(x.id): unlocked_before.append(x.id)
	data.best_wave[realm_id] = max(int(data.best_wave.get(realm_id, 0)), waves)
	data.stats.runs += 1
	data.stats.kills += kills
	var first: bool = victory and not realm_cleared(realm_id)
	var gold: int = int(gold_earned * 0.5)
	var shards: int = int(waves * 0.6)
	var cores: int = 0
	if victory:
		data.stats.victories += 1
		gold += int(r.gold * (1.0 if first else 0.4))
		shards += r.shards
		cores += 2 if first else 1
	if first:
		data.cleared.append(realm_id)
	var new_realm := ""
	for x in GameData.realms:
		if realm_unlocked(x.id) and not unlocked_before.has(x.id):
			new_realm = x.id
	data.gold += gold
	data.shards += shards
	data.cores += cores
	var per: int = max(1, shards / max(1, data.deck.size()))
	for id in data.deck:
		champ(id).shards += per
	flush()
	return {"gold": gold, "shards": shards, "cores": cores, "first": first, "new_realm": new_realm}

# ── Warden ──────────────────────────────────────────────────
func warden_cost() -> int: return 150 + int(data.warden_level) * 120

func upgrade_warden() -> bool:
	if data.gold < warden_cost(): return false
	data.gold -= warden_cost()
	data.warden_level += 1
	flush()
	return true
