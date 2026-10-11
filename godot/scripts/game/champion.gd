extends Node3D
const ModelRig := preload("res://scripts/game/model_rig.gd")
const SoldierScript := preload("res://scripts/game/soldier.gd")
## A tower on a stone build spot (Kingdom-Rush structure). Works on its own.
##   archer    — fast arrows, hits flyers
##   barracks  — 3 soldiers hold the road at a rally point, respawn when killed
##   mage      — arcane bolts that ignore armour
##   artillery — lobbed bombs with splash (ground only)
## Tiers 1→3 by upgrading; at tier 3 it can SPECIALIZE into one of the
## family's champions (they keep their meta level / evolutions).

var battle
var family := "archer"
var spec: Dictionary = {}
var pad: int = -1
var tier := 0
var spent := 0
var alive := true
var damage := 1.0
var soldier_hp := 1.0
var atk_range := 6.0
var rate := 1.0
var splash := 0.0
var cd := 0.5
var evo := 0
var rally := Vector3.ZERO
var soldiers: Array = []
var respawn: Array = []
var model: Node3D
var shooter: ModelRig
var um: Dictionary

func setup(b, fam: String, pad_index: int, pos: Vector3, paid: int) -> void:
	battle = b
	family = fam
	pad = pad_index
	spent = paid
	position = pos
	um = battle.upgrade_mods
	_rebuild()
	_apply_stats()
	if family == "barracks":
		rally = battle.rally_point_for(pos)
		_sync_soldiers(true)
	scale = Vector3.ONE * 0.3
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func title() -> String:
	return spec.name if not spec.is_empty() else "%s %s" % [GameData.TOWERS[family].name, ["I", "II", "III"][tier]]

func unit_id() -> String:
	return spec.id if not spec.is_empty() else ("footman" if family == "barracks" else "bowman")

# ── visuals ─────────────────────────────────────────────────
func _rebuild() -> void:
	if model: model.queue_free()
	if shooter: shooter.queue_free()
	shooter = null
	model = AssetLib.make_tower(family, tier, spec.get("id", ""))
	model.position.y = 0.26
	add_child(model)
	var top: float = AssetLib.tower_top(family, tier) + 0.26
	var sid: String = spec.get("id", "")
	if family == "archer":
		if sid != "":
			shooter = AssetLib.make(sid, AssetLib.kind_for(spec), spec.color, 1.15, evo > 0)
		else:
			shooter = AssetLib.make("bowman", "", Color("3fae4f") if tier < 2 else Color("3a6ab0"), 1.0)
	elif family == "mage" and sid != "":
		shooter = AssetLib.make(sid, AssetLib.kind_for(spec), spec.color, 1.15, evo > 0)
	elif family == "artillery" and sid == "ashen_queen":
		shooter = AssetLib.make(sid, "queen", spec.color, 1.3, evo > 0)
		top = 0.95
	if shooter:
		shooter.position.y = top
		add_child(shooter)
		shooter.play("idle")

func _apply_stats() -> void:
	var t: Dictionary = GameData.TOWERS[family]
	var dmg_up := 1.0 + float(um.get(family + "_dmg", 0.0))
	var range_up := 1.0 + float(um.get(family + "_range", 0.0))
	if spec.is_empty():
		damage = float(t.damage[tier])
		rate = float(t.rate[tier])
		atk_range = float(t.range[tier])
		soldier_hp = float(t.get("hp", [0, 0, 0])[tier])
		splash = float(t.get("splash", [0, 0, 0])[tier])
	else:
		var st := Save.stats(spec)
		damage = st.damage * GameData.SPEC_MUL
		soldier_hp = st.hp * GameData.SPEC_MUL
		rate = 1.0 / float(spec.atk_speed)
		atk_range = float(spec.range) if family != "barracks" else 4.0
		splash = (1.8 + (0.4 if evo >= 1 else 0.0)) if spec.id == "runestone" else 0.0
		if evo >= 2 and spec.id in ["runestone", "sunspear_lancer"]: damage *= 1.3
		if evo >= 2 and spec.id == "boulder_golem": soldier_hp *= 1.4
		if evo >= 2 and spec.id == "thistle_archer": atk_range *= 1.25
	damage *= dmg_up * battle.mods.champ_dmg
	atk_range *= range_up
	if family == "mage": rate /= 1.0 + float(um.get("mage_rate", 0.0))
	if family == "artillery": splash *= 1.0 + float(um.get("artillery_splash", 0.0))
	if family == "barracks":
		damage *= 1.0 + float(um.get("barracks_dmg", 0.0))
		soldier_hp *= (1.0 + float(um.get("barracks_hp", 0.0))) * battle.mods.champ_hp

# ── upgrades ────────────────────────────────────────────────
func cost_next() -> int:
	if not spec.is_empty() or tier >= 2: return -1
	return int(GameData.TOWERS[family].cost[tier + 1])

func can_specialize() -> bool:
	return spec.is_empty() and tier >= 2

func sell_value() -> int:
	return int(spent * GameData.SELL_REFUND)

func upgrade() -> void:
	spent += cost_next()
	tier += 1
	_refresh()

func specialize(def: Dictionary) -> void:
	spent += GameData.spec_cost(def)
	spec = def
	evo = Save.evo(def.id)
	_refresh()

func _refresh() -> void:
	_rebuild()
	_apply_stats()
	battle.ring_fx(position, 1.4, Color("ffcf3d"))
	if family == "barracks":
		for s in soldiers:
			if s != null and s.alive:
				s.alive = false
				s.visible = false
		_sync_soldiers(false)

func _soldier_count() -> int:
	if spec.is_empty(): return 3
	var n := int(spec.count)
	if evo >= 2 and spec.id in ["pyre_knight", "wolf_pack"]: n += 1
	return n

func unit_def() -> Dictionary:
	if not spec.is_empty(): return spec
	return {"id": "footman", "role": "melee", "atk_speed": 1.0, "color": Color("3a6ab0") if tier < 2 else Color("b0402a"), "count": 3}

func _sync_soldiers(instant: bool) -> void:
	soldiers.clear()
	respawn.clear()
	for k in _soldier_count():
		soldiers.append(null)
		respawn.append(0.0)
		_spawn_soldier(k, instant)

func _spawn_soldier(k: int, instant: bool) -> void:
	var s = SoldierScript.new()
	battle.add_child(s)
	var n := soldiers.size()
	var off := Vector3((k - (n - 1) / 2.0) * 0.85, 0, (k % 2) * 0.45)
	s.setup(battle, self, unit_def(), rally + off, (rally + off) if instant else position, soldier_hp, damage)
	soldiers[k] = s
	battle.soldiers.append(s)

func remove() -> void:
	alive = false
	for s in soldiers:
		if s != null and is_instance_valid(s):
			s.alive = false

# ── behaviour ───────────────────────────────────────────────
func step(dt: float) -> void:
	if not alive: return
	if family == "barracks":
		var wait := 6.0 if spec.get("id", "") == "wolf_pack" else 10.0
		wait *= 1.0 - float(um.get("barracks_respawn", 0.0))
		for k in soldiers.size():
			var s = soldiers[k]
			if s == null or not s.alive:
				respawn[k] += dt
				if respawn[k] >= wait:
					respawn[k] = 0.0
					_spawn_soldier(k, false)
		return
	cd -= dt
	if cd <= 0.0 and _act():
		cd = rate

func _shot_origin() -> Vector3:
	return position + Vector3(0, AssetLib.tower_top(family, tier) + 1.0, 0)

func _face(t) -> void:
	if shooter:
		shooter.rotation.y = atan2(t.position.x - position.x, t.position.z - position.z)
		shooter.play("attack")

func _act() -> bool:
	var rng: float = atk_range * battle.range_mul()
	var sid: String = spec.get("id", "")
	match family:
		"archer":
			var t = battle.nearest_enemy(position, rng)
			if t == null: return false
			_face(t)
			var shots := 2 if (sid == "thistle_archer" and evo >= 1) else 1
			var slow := (0.4 + 0.15 * evo) if sid == "frost_warden" else 0.0
			for k in shots:
				battle.spawn_projectile(_shot_origin(), t, damage, "champion", {
					"color": Color("fff0c0") if sid == "" else spec.color, "slow": slow, "speed": 20.0,
					"pierce": int(um.get("archer_pierce", 0.0))})
			return true
		"mage":
			if sid == "sister_vale":
				var heal_amt: float = 12.0 + damage * 0.8
				var ally = battle.most_wounded_ally(position, rng)
				if ally != null:
					if shooter: shooter.play("cast")
					if evo >= 1:
						for a in battle.allies_near(position, rng): a.heal(heal_amt * 0.5)
						battle.ring_fx(position, rng * 0.6, Color("7ed957"))
					ally.heal(heal_amt)
					battle.float_text(ally.position, "+%d" % int(heal_amt), Color("7ed957"))
					return true
			var t = battle.nearest_enemy(position, rng)
			if t == null: return false
			_face(t)
			var chain := (2 + evo) if sid == "stormcaller" else 0
			var slow := float(um.get("mage_slow", 0.0))
			if sid == "sister_vale" and evo >= 2: slow = maxf(slow, 0.35)
			battle.spawn_projectile(_shot_origin(), t, damage, "champion", {
				"color": Color("d8a8ff") if sid == "" else spec.color, "chain": chain, "slow": slow,
				"speed": 15.0, "true_dmg": true})
			return true
		"artillery":
			if sid == "ashen_queen":
				var hit: Array = battle.enemies_near(position, rng * (1.2 if evo >= 1 else 1.0))
				if hit.is_empty(): return false
				if shooter: shooter.play("cast")
				battle.ring_fx(position, rng, Color("ff8a3d"))
				for e in hit:
					battle.hit_enemy(e, damage, {"source": "champion", "burn": 6.0 if evo < 2 else 14.0})
				return true
			var t = battle.nearest_ground_enemy(position, rng)
			if t == null: return false
			var lead: Vector3 = t.position + (t.position - t.prev_pos) * 30.0
			battle.lob(position + Vector3(0, 1.4, 0), lead, damage, splash, {
				"true_dmg": sid == "runestone", "burn": float(um.get("artillery_burn", 0.0)),
				"color": spec.color if sid != "" else Color("2a2e38")})
			return true
	return false
