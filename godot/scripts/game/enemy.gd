extends Node3D
class_name Enemy
## A member of the Rush. Follows its lane (flyers cut straight to the Bastion),
## carries traits (armor, shield, regen, split, heal, burn_touch) and, for
## bosses, a signature ability (charge, summon, shield, slam, split).

var battle  # Battle
var id: String
var def: Dictionary
var rig: ModelRig
var curve: Curve3D
var dist := 0.0
var hp := 1.0
var max_hp := 1.0
var shield := 0.0
var radius := 0.5
var alive := true
var reached := false
var is_boss := false
var slow_t := 0.0
var slow_f := 1.0
var burn_t := 0.0
var burn_dps := 0.0
var ability_t := 0.0
var charge_t := 0.0
var cast_t := 0.0
var _bar_bg: MeshInstance3D
var _bar_fg: MeshInstance3D

func setup(b, enemy_id: String, lane: Curve3D, hp_scale: float, start_dist := 0.0) -> void:
	battle = b
	id = enemy_id
	def = GameData.enemies[enemy_id]
	curve = lane
	dist = start_dist
	is_boss = def.kind == "boss"
	max_hp = def.hp * hp_scale
	hp = max_hp
	shield = def.get("shield", 0.0)
	radius = def.radius
	ability_t = 4.0
	cast_t = randf_range(1.0, 3.0)
	var h: float = radius * (2.6 if is_boss else 2.4)
	rig = AssetLib.make(id, def.kind, def.color, h)
	add_child(rig)
	rig.play("run")
	position = curve.sample_baked(dist) if def.kind != "flyer" else curve.sample_baked(0.0)
	if def.kind == "flyer":
		rig.position.y = 1.4
	if not is_boss:
		_make_bar(h)

func _make_bar(h: float) -> void:
	_bar_bg = MeshInstance3D.new()
	var q := QuadMesh.new(); q.size = Vector2(1.0, 0.12)
	_bar_bg.mesh = q
	_bar_bg.material_override = battle.bar_bg_mat
	_bar_bg.position = Vector3(0, h + (1.6 if def.kind == "flyer" else 0.3), 0)
	_bar_bg.visible = false
	add_child(_bar_bg)
	_bar_fg = MeshInstance3D.new()
	_bar_fg.mesh = q
	_bar_fg.material_override = battle.bar_fg_mat
	_bar_fg.position = _bar_bg.position + Vector3(0, 0, 0.01)
	_bar_fg.visible = false
	add_child(_bar_fg)

func take_damage(dmg: float) -> float:
	if not alive:
		return 0.0
	dmg *= 1.0 - def.get("armor", 0.0)
	if shield > 0.0:
		var absorbed := minf(shield, dmg)
		shield -= absorbed
		dmg -= absorbed
	hp -= dmg
	rig.play("hit")
	if _bar_fg:
		_bar_bg.visible = true
		_bar_fg.visible = true
		_bar_fg.scale.x = maxf(0.0, hp / max_hp)
	if hp <= 0.0:
		alive = false
	return dmg

func apply_slow(f: float) -> void:
	slow_f = minf(slow_f, 1.0 - f)
	slow_t = 1.4

func apply_burn(dps: float) -> void:
	burn_dps = maxf(burn_dps, dps)
	burn_t = 3.0

## World-space centre of the hitbox (flyers hover above the ground).
func hit_point() -> Vector3:
	return position + Vector3(0, rig.position.y + radius, 0)

func hp_frac() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)

func step(dt: float) -> void:
	if not alive:
		return
	if slow_t > 0.0:
		slow_t -= dt
		if slow_t <= 0.0: slow_f = 1.0
	if burn_t > 0.0:
		burn_t -= dt
		hp -= burn_dps * dt
		if hp <= 0.0:
			alive = false
			return
	var regen: float = def.get("regen", 0.0)
	if regen > 0.0:
		hp = minf(max_hp, hp + regen * dt)
	_abilities(dt)

	var speed: float = def.speed * slow_f * battle.enemy_speed_mul(self)
	if charge_t > 0.0:
		charge_t -= dt
		speed *= 2.6
	if def.kind == "flyer":
		var to: Vector3 = battle.BASTION_POS - position
		to.y = 0
		if to.length() < 1.2:
			_breach()
			return
		position += to.normalized() * speed * dt
		_face(to)
	else:
		var prev := position
		dist += speed * dt
		if dist >= curve.get_baked_length() - 0.3:
			_breach()
			return
		position = curve.sample_baked(dist)
		_face(position - prev)

func _face(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(dir.x, dir.z), 0.2)

func _breach() -> void:
	alive = false
	reached = true
	battle.damage_bastion(def.breach)

func _abilities(dt: float) -> void:
	# Casters: hexes at the Warden, or heal allies.
	if def.kind == "caster":
		cast_t -= dt
		if cast_t <= 0.0:
			cast_t = 2.8
			if def.has("heal"):
				battle.enemy_heal_pulse(self, def.heal)
			elif battle.warden.alive and position.distance_to(battle.warden.position) < 12.0:
				rig.play("cast")
				battle.spawn_projectile(position + Vector3(0, 1, 0), battle.warden, def.damage, "enemy")
	if not is_boss:
		return
	ability_t -= dt
	if ability_t > 0.0:
		return
	match def.get("ability", ""):
		"charge":
			charge_t = 2.0; ability_t = 8.0
			battle.banner_small("%s CHARGES!" % def.name.to_upper())
		"summon":
			ability_t = 7.0
			for k in 3:
				battle.spawn_enemy(def.summon, curve, 1.0 + battle.wave_index * 0.1, maxf(0.0, dist - 1.0 - k))
		"shield":
			ability_t = 10.0
			shield = def.shield
			battle.banner_small("SHIELDED!")
		"slam":
			ability_t = 6.0
			battle.boss_slam(self, 4.5)
		_:
			ability_t = 999.0
