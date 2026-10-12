extends Node3D
const ModelRig := preload("res://scripts/game/model_rig.gd")
## A member of the Rush. Follows its lane (flyers cut straight to the Bastion).
##
## Monsters are built to fight back against towers, troops AND the hero:
##   traits   armor, shield, regen, split, heal, burn_touch
##   attack   melee | spit (ranged at troops/hero) | slam (hits everyone around)
##            | poison (heavy bite) — used when something blocks them
##   aura     haste | ward | rage — buffs every monster nearby (synergy!)
##   special  berserk (stronger when hurt), breaker (x2 vs soldiers/troops),
##            saboteur / freeze (switches towers off for a while)
##   stages   brutes enter FÚRIA at 50% hp; bosses have 3 phases (66% / 33%)
##   evolve   some small monsters grow into a stronger one if they get far

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
var silent := false          # removed without a kill (evolved)
var is_boss := false
var slow_t := 0.0
var slow_f := 1.0
var burn_t := 0.0
var burn_dps := 0.0
var ability_t := 0.0
var charge_t := 0.0
var cast_t := 0.0
var special_t := 0.0
var blocker = null      # soldier / troop / hero holding this enemy on the road
var atk_t := 0.0
var prev_pos := Vector3.ZERO
var stage := 1
var hp_scale := 1.0
var spawn_dist := 0.0
# Aura buffs, refreshed by the battle every step.
var buff_haste := false
var buff_ward := false
var buff_rage := false
var _bar_bg: MeshInstance3D
var _bar_fg: MeshInstance3D
var _h := 1.0

func setup(b, enemy_id: String, lane: Curve3D, scale_hp: float, start_dist := 0.0) -> void:
	battle = b
	id = enemy_id
	def = GameData.enemies[enemy_id]
	curve = lane
	dist = start_dist
	spawn_dist = start_dist
	hp_scale = scale_hp
	is_boss = def.kind == "boss"
	max_hp = def.hp * scale_hp
	hp = max_hp
	shield = def.get("shield", 0.0)
	radius = def.radius
	ability_t = 4.0
	cast_t = randf_range(1.0, 3.0)
	special_t = randf_range(2.0, 4.0)
	_h = radius * (2.9 if is_boss else 3.0)
	rig = AssetLib.make(id, def.kind, def.color, _h)
	add_child(rig)
	rig.play("run")
	position = curve.sample_baked(dist) if def.kind != "flyer" else curve.sample_baked(0.0)
	if def.kind == "flyer":
		rig.position.y = 1.4
	if not is_boss:
		_make_bar(_h)
	if def.has("aura"):
		_ring(Color(GameData.AURA_COLOR[def.aura]), 3.5 * 0.5, 0.05)

func _ring(col: Color, r: float, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new(); t.inner_radius = r * 0.88; t.outer_radius = r; t.rings = 20; t.ring_segments = 4
	mi.mesh = t
	mi.material_override = AssetLib.mat(col, 1.2)
	mi.position.y = y
	mi.scale = Vector3(1, 0.3, 1)
	add_child(mi)
	return mi

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

func take_damage(dmg: float, ignore_armor := false) -> float:
	if not alive:
		return 0.0
	if not ignore_armor:
		dmg *= 1.0 - def.get("armor", 0.0)
	if buff_ward:
		dmg *= 0.7
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
	else:
		_check_stage()
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

func berserk() -> bool:
	return def.get("berserk", false) and hp < max_hp * 0.5

func dmg_mul() -> float:
	var m := 1.0
	if buff_rage: m *= 1.3
	if berserk(): m *= 1.5
	if stage >= 2 and not is_boss: m *= 1.4
	if is_boss and stage >= 3: m *= 1.5
	return m

# ── stages ──────────────────────────────────────────────────
func _check_stage() -> void:
	if is_boss:
		if stage == 1 and hp < max_hp * 0.66:
			_enter_stage(2, "%s — FASE 2!" % def.name.to_upper())
		elif stage == 2 and hp < max_hp * 0.33:
			_enter_stage(3, "%s — FÚRIA FINAL!" % def.name.to_upper())
	elif def.kind == "brute" and stage == 1 and hp < max_hp * 0.5:
		_enter_stage(2, "FÚRIA!")

func _enter_stage(s: int, text: String) -> void:
	stage = s
	var grow := 1.12 if not is_boss else 1.08
	rig.create_tween().tween_property(rig, "scale", rig.scale * grow, 0.25).set_trans(Tween.TRANS_BACK)
	_ring(Color("ff3a2a"), radius * 1.4, 0.08)
	battle.ring_fx(position, radius * 3.0, Color("ff3a2a"))
	if is_boss:
		battle.banner_small(text)
		battle.shake(0.35)
		ability_t = 0.5
		if s == 3:
			battle.disable_towers_near(position, 6.0, 3.0)
	else:
		battle.float_text(position, text, Color("ff5a3a"))

# ── main loop ───────────────────────────────────────────────
func step(dt: float) -> void:
	if not alive:
		return
	prev_pos = position
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
	if not alive: return

	var speed: float = def.speed * slow_f * battle.enemy_speed_mul(self)
	if buff_haste: speed *= 1.35
	if berserk(): speed *= 1.4
	if stage >= 2: speed *= 1.15 if is_boss else 1.3
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
		if blocker != null and (not is_instance_valid(blocker) or not blocker.alive or (blocker == battle.warden and blocker.downed)):
			blocker = null
		if blocker != null and position.distance_to(blocker.position) < radius + 1.1 and charge_t <= 0.0:
			# Held: stand and fight instead of marching.
			_face(blocker.position - position)
			rig.play("idle")
			atk_t -= dt
			if atk_t <= 0.0:
				atk_t = 1.0
				_melee(blocker)
			return
		rig.play("run")
		var prev := position
		dist += speed * dt
		var L := curve.get_baked_length()
		if dist >= L - 0.3:
			_breach()
			return
		position = curve.sample_baked(dist)
		_face(position - prev)
		if def.has("evolve") and dist / L >= float(def.evolve[1]) and dist - spawn_dist > L * 0.3:
			_evolve()

## Varied attacks against whoever blocks the road.
func _melee(target) -> void:
	rig.play("attack")
	var d: float = def.damage * 0.8 * dmg_mul() + def.get("burn_touch", 0.0)
	if def.get("breaker", false) and target != battle.warden: d *= 2.0
	match def.get("attack", "melee"):
		"slam":
			battle.ring_fx(position, 1.8, Color("c8a070"))
			for a in battle.allies_near(position, 1.9):
				a.take_damage(d * 0.75)
		"poison":
			target.take_damage(d * 1.4)
			battle.float_text(target.position, "VENENO", Color("9be24d"))
		_:
			target.take_damage(d)

func _face(dir: Vector3) -> void:
	if dir.length_squared() > 0.0001:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(dir.x, dir.z), 0.2)

func _breach() -> void:
	if battle.auto and OS.get_cmdline_user_args().has("--dbg"): print("BREACH ", id, " stage=", stage, " w=", battle.wave_index)
	alive = false
	reached = true
	battle.damage_bastion(def.breach * (1.5 if stage >= 2 and not is_boss else 1.0))

func _evolve() -> void:
	var into: String = def.evolve[0]
	alive = false
	silent = true
	battle.float_text(position, "EVOLUIU!", Color("ff9aff"))
	battle.ring_fx(position, 1.2, Color("d14bff"))
	battle.spawn_enemy(into, curve, hp_scale, dist)

func _abilities(dt: float) -> void:
	# Ranged attackers / healers.
	if def.get("attack", "") == "spit" or def.kind == "caster":
		cast_t -= dt
		if cast_t <= 0.0:
			cast_t = 2.6
			if def.has("heal"):
				battle.enemy_heal_pulse(self, def.heal)
			else:
				var t = battle.nearest_ally(position, 5.5)
				if t != null:
					rig.play("cast")
					battle.spawn_projectile(position + Vector3(0, 1, 0), t, def.damage * dmg_mul(), "enemy", {"color": def.color.lightened(0.3)})
	# Saboteurs / frost breath: switch towers off.
	if def.get("saboteur", false):
		special_t -= dt
		if special_t <= 0.0:
			special_t = 6.0
			if battle.disable_towers_near(position, 4.5, 2.5, 1) > 0:
				rig.play("cast")
	if not is_boss:
		return
	ability_t -= dt
	if ability_t > 0.0:
		return
	var fast := 0.6 if stage >= 2 else 1.0
	match def.get("ability", ""):
		"charge":
			charge_t = 2.0; ability_t = 8.0 * fast
			blocker = null
			battle.banner_small("%s INVESTE!" % def.name.to_upper())
		"summon":
			ability_t = 7.0 * fast
			for k in (3 if stage < 3 else 5):
				battle.spawn_enemy(def.summon, curve, 1.0 + battle.wave_index * 0.1, maxf(0.0, dist - 1.0 - k))
		"shield":
			ability_t = 10.0 * fast
			shield = def.shield * (1.0 if stage < 3 else 1.5)
			battle.banner_small("ESCUDO!")
		"slam":
			ability_t = 6.0 * fast
			battle.boss_slam(self, 4.5 + stage * 0.5)
		"split":
			ability_t = 9.0 * fast
			for k in 2 + stage:
				battle.spawn_enemy(def.split[0], curve, 1.0 + battle.wave_index * 0.1, maxf(0.0, dist - 0.5 - k * 0.6))
		_:
			ability_t = 999.0
