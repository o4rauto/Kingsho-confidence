extends Node3D
const ModelRig := preload("res://scripts/game/model_rig.gd")
## A troop you SEND up a road (Clash-Royale style): it marches against the
## flow toward the rift, stops to fight whatever it meets (melee troops block
## the monster, ranged troops shoot from behind) and vanishes at the far end.

var battle
var def: Dictionary
var curve: Curve3D
var dist := 0.0
var side := 0.0
var hp := 1.0
var max_hp := 1.0
var damage := 1.0
var alive := true
var target = null
var cd := 0.0
var stun_t := 0.0
var rig: ModelRig
var _bar: MeshInstance3D

func setup(b, tdef: Dictionary, lane: Curve3D, start: float, lateral: float) -> void:
	battle = b
	def = tdef
	curve = lane
	dist = start
	side = lateral
	var mul: float = battle.troop_mul
	max_hp = float(def.hp) * mul
	hp = max_hp
	damage = float(def.damage) * mul
	var model: String = def.model
	var kind := "wolf" if model == "wolf_pack" else ("melee" if model == "pyre_knight" else "")
	var h := 1.2 if kind == "wolf" else (2.0 if model == "pyre_knight" else 1.7)
	rig = AssetLib.make(model, kind, def.color, h)
	add_child(rig)
	rig.play("run")
	var q := QuadMesh.new(); q.size = Vector2(0.9, 0.1)
	_bar = MeshInstance3D.new()
	_bar.mesh = q
	_bar.material_override = battle.bar_ally_mat
	_bar.position = Vector3(0, h + 0.35, 0)
	_bar.visible = false
	add_child(_bar)
	position = _lane_pos()
	scale = Vector3.ONE * 0.3
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func ranged() -> bool:
	return float(def.range) > 0.0

func _lane_pos() -> Vector3:
	var p := curve.sample_baked(dist)
	var q := curve.sample_baked(maxf(0.0, dist - 0.4))
	var dir := (q - p).normalized()
	return p + Vector3(-dir.z, 0, dir.x) * side

func take_damage(d: float) -> void:
	if not alive: return
	hp -= d
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

func _release() -> void:
	if target != null and is_instance_valid(target) and target.blocker == self:
		target.blocker = null
	target = null

func _valid(e) -> bool:
	if e == null or not is_instance_valid(e) or not e.alive: return false
	if ranged(): return e.position.distance_to(position) < float(def.range) * battle.range_mul()
	return e.def.kind != "flyer" and e.position.distance_to(position) < 2.6

func step(dt: float) -> void:
	if not alive: return
	if stun_t > 0.0:
		stun_t -= dt
		return
	if not _valid(target):
		_release()
		target = _pick()
	cd -= dt
	if target != null:
		var to: Vector3 = target.position - position
		to.y = 0
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(to.x, to.z), 0.3)
		if ranged():
			rig.play("idle")
			if cd <= 0.0:
				cd = 1.0 / float(def.atk)
				rig.play("attack")
				battle.spawn_projectile(position + Vector3(0, 1.2, 0), target, damage, "champion", {"color": Color("fff0c0"), "speed": 18.0})
			return
		var reach: float = target.radius + 0.75
		if to.length() > reach:
			position += to.normalized() * minf(float(def.speed) * dt, to.length())
			rig.play("run")
		else:
			rig.play("idle")
			if target.blocker == null: target.blocker = self
			if cd <= 0.0:
				cd = 1.0 / float(def.atk)
				rig.play("attack")
				battle.hit_enemy(target, damage, {"source": "champion"})
		return
	# March up the road toward the rift.
	dist -= float(def.speed) * dt
	if dist <= 1.0:
		alive = false
		battle.gold += 5
		return
	var prev := position
	position = position.lerp(_lane_pos(), minf(1.0, dt * 6.0))
	var mv := position - prev
	if mv.length_squared() > 0.00001:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(mv.x, mv.z), 0.25)
	rig.play("run")

func _pick():
	var best = null
	var bd := 999.0
	for e in battle.enemies:
		if not _valid(e): continue
		var free: bool = e.blocker == null or not is_instance_valid(e.blocker) or not e.blocker.alive
		var d: float = e.position.distance_to(position) - (1.0 if free else 0.0)
		if d < bd:
			bd = d; best = e
	return best
