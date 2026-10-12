extends Node3D
const ModelRig := preload("res://scripts/game/model_rig.gd")
## Your hero: Kael or any unlocked champion (chosen on the Heroes screen).
## Tap the ground to walk there. Standing still, ranged heroes shoot and
## melee heroes grab the closest monster and BLOCK it. Each hero charges its
## own special. Never dies — knocked down, he gets back up at the Bastion.

var battle
var rig: ModelRig
var hp := 100.0
var max_hp := 100.0
var alive := true
var ult := 0.0
var move_input := Vector2.ZERO     # optional (auto-play)
var target_pos := Vector3.INF      # tap-to-move destination
var vel := Vector3.ZERO
var fire_cd := 0.0
var iframes := 0.0
var downed := false
var down_t := 0.0
var rooted_t := 0.0
var damage := 14.0
var atk_range := 9.0
var speed := 6.5
var fire_interval := 0.52
var hero_id := "warden"
var hdef: Dictionary = {}
var melee := false
var foe = null
var heal_t := 0.0
var _marker: MeshInstance3D

func setup(b) -> void:
	battle = b
	hero_id = Save.active_hero()
	hdef = GameData.hero_def(hero_id)
	recompute(true)
	if hero_id == "warden":
		rig = AssetLib.make("warden", "warden", Save.hero_cape(), 2.3)
	else:
		var kind: String = AssetLib.kind_for(hdef)
		rig = AssetLib.make(hero_id, kind, hdef.color, 1.5 if kind == "wolf" else 2.3, Save.evo(hero_id) > 0)
	add_child(rig)
	var aura := MeshInstance3D.new()
	var t := TorusMesh.new(); t.inner_radius = 0.75; t.outer_radius = 0.95; t.rings = 24; t.ring_segments = 4
	aura.mesh = t
	aura.material_override = AssetLib.mat(Color("ffcf3d"), 1.2)
	aura.position.y = 0.06
	aura.scale = Vector3(1, 0.3, 1)
	add_child(aura)
	var tag := Label3D.new()
	tag.text = hdef.name
	tag.font = load("res://scripts/ui/ui_kit.gd").font()
	tag.font_size = 54
	tag.outline_size = 14
	tag.modulate = Color("ffe08a")
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.pixel_size = 0.01
	tag.position = Vector3(0, 2.75, 0)
	add_child(tag)
	_marker = MeshInstance3D.new()
	var mt := TorusMesh.new(); mt.inner_radius = 0.4; mt.outer_radius = 0.55; mt.rings = 16; mt.ring_segments = 4
	_marker.mesh = mt
	_marker.material_override = AssetLib.mat(Color("7ed957"), 1.5)
	_marker.visible = false
	battle.add_child.call_deferred(_marker)

## Re-derive stats from hero level + star upgrades + run boons (keeps hp ratio).
func recompute(full := false) -> void:
	var st := Save.hero_battle_stats(hero_id)
	var m: Dictionary = battle.mods
	var frac := 1.0 if full else hp / max_hp
	melee = st.melee
	max_hp = st.hp + m.warden_hp
	hp = max_hp * frac
	damage = st.damage * m.warden_dmg
	atk_range = st.range * (1.0 if melee else m.warden_range)
	speed = st.speed * m.warden_speed
	fire_interval = st.fire_cd / m.warden_aspd

func walk_to(p: Vector3) -> void:
	if downed: return
	target_pos = Vector3(clampf(p.x, -6.2, 6.2), 0, clampf(p.z, -20.0, 3.2))
	_marker.position = target_pos + Vector3(0, 0.08, 0)
	_marker.visible = true
	_marker.scale = Vector3(1.6, 0.3, 1.6)
	_marker.create_tween().tween_property(_marker, "scale", Vector3(1, 0.3, 1), 0.2)

func ult_ready() -> bool:
	return ult >= GameData.HERO.ult_max

func add_ult(n: float) -> void:
	ult = minf(GameData.HERO.ult_max, ult + n * (1.0 + float(battle.upgrade_mods.get("hero_ult", 0.0))))

func heal(a: float) -> void:
	if not downed:
		hp = minf(max_hp, hp + a)

func take_damage(d: float) -> void:
	if downed or iframes > 0.0:
		return
	hp -= d
	iframes = 0.5
	rig.play("hit")
	Sfx.play("hurt")
	Sfx.haptic(30)
	battle.shake(0.15)
	if hp <= 0.0:
		downed = true
		down_t = 4.0
		hp = 0.0
		rig.visible = false
		target_pos = Vector3.INF
		_marker.visible = false
		battle.banner_small("%s CAIU!" % String(hdef.name).to_upper())

func release_ult() -> void:
	if not ult_ready() or downed:
		return
	ult = 0.0
	Sfx.play("ult")
	battle.shake(0.35)
	battle.banner_small(String(hdef.get("ult_name", "ESPECIAL")).to_upper() + "!")
	var near = battle.nearest_enemy(position, 14.0)
	match hero_id:
		"warden":
			battle.ring_fx(position, 6.0, Color("ffe6a6"))
			for i in 16:
				var a := float(i) / 16.0 * TAU
				battle.spawn_projectile(position + Vector3(0, 1, 0), null, damage * 1.6, "warden",
					{"dir": Vector3(cos(a), 0, sin(a)), "pierce": 3, "crit": true, "burn": battle.mods.burn})
			_area(position, 6.0, damage * 2.4, {"slow": 0.6})
		"pyre_knight":
			_area(position, 5.0, damage * 2.2, {"burn": 15.0}, Color("ff7a2a"))
			hp = minf(max_hp, hp + max_hp * 0.3)
		"thistle_archer":
			var c: Vector3 = near.position if near else position + Vector3(0, 0, -5)
			_area(c, 4.0, damage * 3.0, {}, Color("54d06a"))
		"sister_vale":
			battle.ring_fx(position, 9.0, Color("7ed957"))
			for a in battle.allies_near(position, 30.0): a.heal(a.max_hp * 0.6)
			heal(max_hp * 0.6)
			battle.integrity = minf(battle.integrity_max, battle.integrity + 10.0)
		"wolf_pack":
			for k in 3:
				var lane: Curve3D = battle.world.lanes[k % battle.world.lanes.size()]
				battle.courage += float(GameData.TROOPS[2].cost)
				battle.deploy_troop(2, lane.get_closest_point(position))
		"frost_warden":
			battle.ring_fx(position, 6.0, Color("8fe9ff"))
			for e in battle.enemies_near(position, 6.0):
				e.apply_slow(0.95)
				e.slow_t = 3.0
				battle.hit_enemy(e, damage * 1.5, {"source": "warden"})
		"boulder_golem":
			battle.ring_fx(position, 6.0, Color("c8a070"))
			battle.shake(0.5)
			for e in battle.enemies_near(position, 6.0):
				e.apply_slow(1.0)
				e.slow_t = 2.0
				battle.hit_enemy(e, damage * 2.5, {"source": "warden"})
		"stormcaller":
			if near: battle.zap(position + Vector3(0, 2, 0), near, damage * 3.0, 8)
		"sunspear_lancer":
			var dir := Vector3(0, 0, -1)
			if near: dir = (near.position - position).normalized()
			for k in 6:
				_area(position + dir * (k + 1.0), 1.4, damage * 1.2, {})
			position = Vector3(clampf(position.x + dir.x * 5.0, -6.2, 6.2), 0, clampf(position.z + dir.z * 5.0, -20.0, 3.2))
		"ashen_queen":
			_area(position, 7.0, damage * 3.0, {"burn": 20.0}, Color("ff5a1a"))
		"runestone":
			if near: battle.lob(position + Vector3(0, 2, 0), near.position, damage * 5.0, 3.0, {"true_dmg": true, "color": Color("37b6ff")})

func _area(c: Vector3, r: float, dmg: float, opts: Dictionary, col := Color("ffe6a6")) -> void:
	battle.ring_fx(c, r, col)
	var o := opts.duplicate()
	o["source"] = "warden"
	o["crit"] = true
	for e in battle.enemies_near(c, r):
		battle.hit_enemy(e, dmg, o)

func step(dt: float) -> void:
	iframes = maxf(0.0, iframes - dt)
	if downed:
		down_t -= dt
		if down_t <= 0.0:
			downed = false
			hp = max_hp * 0.6
			iframes = 1.4
			position = battle.BASTION_POS + Vector3(0, 0, -3.0)
			rig.visible = true
			battle.banner_small("%s VOLTOU!" % String(hdef.name).to_upper())
		return
	rooted_t = maxf(0.0, rooted_t - dt)
	var dir := Vector3(move_input.x, 0, move_input.y)
	if target_pos != Vector3.INF:
		var to := target_pos - position
		to.y = 0
		if to.length() < 0.2:
			target_pos = Vector3.INF
			_marker.visible = false
			dir = Vector3.ZERO
		else:
			dir = to.normalized() * minf(1.0, to.length() * 2.0)
	var want: Vector3 = dir * speed * battle.warden_speed_mul()
	if rooted_t > 0.0:
		want = Vector3.ZERO
	# Ice realms: slippery momentum. Elsewhere: snappy.
	var grip := 3.0 if battle.realm.hazard == "blizzard" else 18.0
	vel = vel.lerp(want, minf(1.0, grip * dt))
	position += vel * dt
	position.x = clampf(position.x, -6.2, 6.2)
	position.z = clampf(position.z, -20.0, 3.2)
	var moving := dir.length() > 0.15
	if vel.length() > 0.3:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(vel.x, vel.z), 0.25)
	rig.play("run" if moving else "idle")
	fire_cd -= dt
	if moving:
		fire_cd = maxf(fire_cd, fire_interval * 0.5)
	elif fire_cd <= 0.0 and _fire():
		fire_cd = fire_interval

func _fire() -> bool:
	if hero_id == "sister_vale":
		var ally = battle.most_wounded_ally(position, 6.0)
		if ally != null and ally != self:
			rig.play("cast")
			ally.heal(12.0 + damage)
			battle.float_text(ally.position, "+%d" % int(12 + damage), Color("7ed957"))
			add_ult(4.0)
			return true
	var t = battle.nearest_enemy(position, atk_range * (1.0 if melee else battle.range_mul()))
	if melee:
		t = battle.nearest_ground_enemy(position, atk_range + 0.6)
	if t == null:
		return false
	rig.rotation.y = atan2(t.position.x - position.x, t.position.z - position.z)
	rig.play("attack")
	var m: Dictionary = battle.mods
	if melee:
		if t.blocker == null or not is_instance_valid(t.blocker) or not t.blocker.alive:
			t.blocker = self
		var crit: bool = randf() < m.crit
		var opts := {"source": "warden", "crit": crit}
		if hero_id == "pyre_knight": opts["burn"] = 8.0
		battle.hit_enemy(t, damage * (m.crit_mul if crit else 1.0), opts)
		add_ult(4.0)
		Sfx.play("hit")
		return true
	if hero_id == "ashen_queen":
		_area(position, atk_range, damage, {"burn": 6.0}, Color("ff8a3d"))
		add_ult(3.0)
		return true
	if hero_id == "runestone":
		battle.lob(position + Vector3(0, 1.6, 0), t.position, damage, 1.8, {"true_dmg": true, "color": Color("37b6ff")})
		add_ult(3.0)
		return true
	if hero_id == "stormcaller":
		battle.zap(position + Vector3(0, 1.8, 0), t, damage, 2)
		add_ult(3.0)
		return true
	var shots := 1 + int(m.multishot)
	var base := Vector3(t.position.x - position.x, 0, t.position.z - position.z).normalized()
	for i in shots:
		var off := 0.0 if shots == 1 else (i - (shots - 1) / 2.0) * 0.16
		var crit: bool = randf() < m.crit
		battle.spawn_projectile(position + Vector3(0, 1.1, 0), t, damage * (m.crit_mul if crit else 1.0), "warden", {
			"dir": base.rotated(Vector3.UP, off), "pierce": int(m.pierce), "crit": crit,
			"burn": m.burn, "slow": maxf(m.slow, 0.45 if hero_id == "frost_warden" else 0.0), "chain": int(m.chain),
			"color": Color("ffe6a6") if crit else hdef.color})
	add_ult(3.0)
	Sfx.play("shoot")
	return true
