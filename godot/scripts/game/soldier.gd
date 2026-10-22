extends Node3D
const ModelRig := preload("res://scripts/game/model_rig.gd")
## A barracks soldier: walks to its rally spot on the road, grabs the closest
## free ground enemy and BLOCKS it (the enemy stops and fights back).
## Dies → its barracks sends a replacement a few seconds later.

var battle
var home            # the barracks (champion.gd)
var def: Dictionary
var slot_pos := Vector3.ZERO
var hp := 1.0
var max_hp := 1.0
var damage := 1.0
var alive := true
var target = null
var cd := 0.0
var stun_t := 0.0
var rig: ModelRig
var speed := 3.6
var _bar: MeshInstance3D

func setup(b, barracks, champ_def: Dictionary, slot: Vector3, start: Vector3, hp_v: float, dmg: float) -> void:
	battle = b
	home = barracks
	def = champ_def
	slot_pos = slot
	position = start
	speed = 5.0 if def.id == "wolf_pack" else 3.6
	var kind: String = AssetLib.kind_for(def)
	var h := 1.2 if kind == "wolf" else (2.4 if kind == "golem" else 1.8)
	rig = AssetLib.make(def.id, kind, def.color, h, home.evo > 0)
	add_child(rig)
	rig.play("idle")
	var q := QuadMesh.new(); q.size = Vector2(0.9, 0.1)
	_bar = MeshInstance3D.new()
	_bar.mesh = q
	_bar.material_override = battle.bar_ally_mat
	_bar.position = Vector3(0, h + 0.35, 0)
	_bar.visible = false
	add_child(_bar)
	set_stats(hp_v, dmg, true)

func set_stats(hp_v: float, dmg: float, refill: bool) -> void:
	max_hp = hp_v
	damage = dmg
	if refill: hp = max_hp
	if rig: rig.scale = Vector3.ONE * (1.0 + 0.1 * home.tier)

func take_damage(d: float) -> void:
	if not alive: return
	hp -= d * (1.0 - float(battle.upgrade_mods.get("barracks_armor", 0.0)))
	_bar.visible = true
	_bar.scale.x = maxf(0.0, hp / max_hp)
	rig.play("hit")
	if hp <= 0.0:
		alive = false
		_release()

func heal(a: float) -> void:
	if not alive: return
	hp = minf(max_hp, hp + a)
	_bar.scale.x = hp / max_hp
	_bar.visible = hp < max_hp

func _release() -> void:
	if target != null and is_instance_valid(target) and target.blocker == self:
		target.blocker = null
	target = null

func _valid(e) -> bool:
	return e != null and is_instance_valid(e) and e.alive and e.def.kind != "flyer" \
		and e.position.distance_to(home.rally) < 3.6

func step(dt: float) -> void:
	if not alive: return
	if not home.alive:
		alive = false
		_release()
		return
	if stun_t > 0.0:
		stun_t -= dt
		return
	if not _valid(target):
		_release()
		target = _pick()
		if target != null and target.blocker == null:
			target.blocker = self
	if target != null:
		var to: Vector3 = target.position - position
		to.y = 0
		var reach: float = target.radius + 0.75
		if to.length() > reach:
			_move(to, dt)
		else:
			rig.play("idle")
			rig.rotation.y = atan2(to.x, to.z)
			if target.blocker == null:
				target.blocker = self
			cd -= dt
			if cd <= 0.0:
				cd = 1.0 / def.atk_speed
				_hit(target)
	else:
		var back := slot_pos - position
		back.y = 0
		if back.length() > 0.15:
			_move(back, dt)
		else:
			rig.play("idle")

func _move(to: Vector3, dt: float) -> void:
	position += to.normalized() * minf(speed * dt, to.length())
	rig.rotation.y = lerp_angle(rig.rotation.y, atan2(to.x, to.z), 0.3)
	rig.play("run")

## Closest free ground enemy near the rally point; else help a busy sibling.
func _pick():
	var best = null
	var bd := 999.0
	var help = null
	var hd := 999.0
	for e in battle.enemies:
		if not _valid(e): continue
		var d: float = e.position.distance_to(position)
		if e.blocker == null or not is_instance_valid(e.blocker) or not e.blocker.alive:
			if d < bd:
				bd = d; best = e
		elif d < hd:
			hd = d; help = e
	return best if best != null else help

func _hit(e) -> void:
	rig.play("attack")
	var opts := {"source": "champion"}
	var dmg := damage
	match def.id:
		"pyre_knight": opts["burn"] = 6.0 if home.evo < 1 else 12.0
		"wolf_pack":
			if home.evo >= 1: opts["burn"] = 5.0
		"boulder_golem":
			if home.evo >= 1: opts["slow"] = 0.8
		"sunspear_lancer":
			if home.evo >= 1 and randf() < 0.25:
				dmg *= 2.0
				opts["crit"] = true
	battle.hit_enemy(e, dmg, opts)
