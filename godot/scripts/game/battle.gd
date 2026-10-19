extends Node3D
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const WorldBuilder := preload("res://scripts/game/world_builder.gd")
## Battle — the 3D battlefield where the three influences fuse:
##  · Kingdom Rush: enemies march the roads; you BUILD defenses on stone spots
##    with gold from kills; barracks soldiers block the road.
##  · Clash Royale: collectible champions (levels, evolutions) become tower specializations.
##  · Archero: pilot your hero; draft a Boon after every wave.
## Each realm adds its own hazard so no two maps play alike.

const BASTION_POS := Vector3(0, 0, 6.0)
const STEP := 1.0 / 60.0
const HudScript := preload("res://scripts/ui/hud.gd")
const EnemyScript := preload("res://scripts/game/enemy.gd")
const ChampionScript := preload("res://scripts/game/champion.gd")
const WardenScript := preload("res://scripts/game/warden.gd")
const ProjectileScript := preload("res://scripts/game/projectile.gd")
const FX := preload("res://scripts/game/fx2d.gd")
const TroopScript := preload("res://scripts/game/troop.gd")

var realm: Dictionary
var deck: Array = []
var world: WorldBuilder
var cam: Camera3D
var hud
var warden
var enemies: Array = []
var champions: Array = []      # defenses on pads
var soldiers: Array = []
var troops: Array = []
var courage := GameData.COURAGE_START
var selected_troop := -1
var troop_mul := 1.0
var projectiles: Array = []
var pad_owner: Array = []      # pad index → defense or null
var selected_pad := -1
var upgrade_mods := {}
var builds := 0
var bosses_killed := 0
var integrity_max := GameData.BASTION_MAX
var between := false           # waiting for the player to call the next wave
var between_t := 0.0
var mods: Dictionary
var state := "intro"   # intro | playing | boon | paused | over
var integrity := GameData.BASTION_MAX
var wave_index := -1
var wave_time := 0.0
var pending: Array = []      # [{t, enemy, lane}]
var gold := 0
var kills := 0
var auto := false
var _auto_t := 0.0
var _shake := 0.0
var _cam_base := Vector3.ZERO
var _sim_acc := 0.0

# Shared render resources (created once per battle).
var proj_mesh: SphereMesh
var bar_bg_mat: StandardMaterial3D
var bar_fg_mat: StandardMaterial3D
var bar_ally_mat: StandardMaterial3D

# Hazard state.
var hazard_t := 4.0
var storm_t := 0.0      # blizzard / sandstorm active time
var telegraphs: Array = []   # [{node, t, pos, r, kind}]
var beam: MeshInstance3D
var beam_angle := 0.0

func _ready() -> void:
	var p: Dictionary = Nav.params
	realm = GameData.realm(p.get("realm_id", "broken_gate"))
	deck = p.get("deck", Save.data.deck).duplicate()
	auto = p.get("auto", false) or OS.get_cmdline_user_args().has("--auto")
	if auto:
		Engine.time_scale = 4.0
		# Simulated progression so automated runs resemble a real player profile.
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--level="):
				var lv := int(a.substr(8))
				Save.data.hero.level = mini(lv * 2 - 1, GameData.HERO_MAX_LEVEL)
				for id in Save.data.champions:
					Save.data.champions[id].level = clampi(lv, 1, GameData.MAX_LEVEL)
				Save.data.cleared = []
				for r in GameData.realms:
					if r.index < realm.index: Save.data.cleared.append(r.id)
				var stars := mini(lv * 3 - 3, 30)
				for u in GameData.UPGRADES:
					var t := 0
					while t < 4 and stars >= int(GameData.UPGRADE_COSTS[t]):
						stars -= int(GameData.UPGRADE_COSTS[t]); t += 1
					Save.data.upgrades[u.id] = t
	mods = GameData.fresh_mods()
	upgrade_mods = Save.upgrade_mods()
	integrity_max = GameData.BASTION_MAX + float(upgrade_mods.get("bastion_hp", 0.0))
	integrity = integrity_max
	troop_mul = (1.0 + 0.06 * realm.index) * (1.0 + float(upgrade_mods.get("barracks_hp", 0.0)) * 0.5)
	gold = 300 + realm.index * 50 + maxi(0, realm.lanes - 2) * 60 + int(upgrade_mods.get("start_gold", 0.0))
	_shared_resources()
	world = WorldBuilder.new()
	world.build(realm, self)
	for i in world.pads.size(): pad_owner.append(null)
	_camera()
	if not world.painted:
		var bastion := AssetLib.make("bastion", "bastion", Color.WHITE, 3.2)
		bastion.position = BASTION_POS + Vector3(0, 0, 0.8)
		add_child(bastion)
	warden = WardenScript.new()
	warden.position = BASTION_POS + Vector3(0, 0, -3.5)
	add_child(warden)
	warden.setup(self)
	if realm.hazard == "sunbeam":
		_make_beam()
	hud = HudScript.new()
	add_child(hud)
	hud.setup(self)
	if p.get("nohud", false) or OS.get_cmdline_user_args().has("--nohud"):
		hud.visible = false
		hud.root.visible = false
	hud.banner(realm.name.to_upper(), realm.subtitle, UIKit.EMBER_HI)
	hud.hazard_hint(_hazard_text())
	Sfx.play_realm_music(realm)
	state = "playing"
	_start_between(30.0 if not auto else 0.5)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _shared_resources() -> void:
	proj_mesh = SphereMesh.new()
	proj_mesh.radius = 0.16; proj_mesh.height = 0.32
	proj_mesh.radial_segments = 8; proj_mesh.rings = 4
	bar_bg_mat = _bar_mat(Color(0, 0, 0, 0.7))
	bar_fg_mat = _bar_mat(Color("ff5470"))
	bar_ally_mat = _bar_mat(Color("54e08a"))

func _bar_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if c.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	m.no_depth_test = true
	m.render_priority = 1
	return m

func _camera() -> void:
	cam = Camera3D.new()
	if world.painted:
		# Fixed 2D-style view over the painted map (orthographic, like Kingdom Rush).
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.size = WorldBuilder.HALF_W * 2.0
		var pitch := deg_to_rad(WorldBuilder.MAP_PITCH)
		var center := world.map_to_world(Vector2(0.5, 0.5))
		cam.position = center + Vector3(0, sin(pitch), cos(pitch)) * 40.0
		cam.rotation = Vector3(-pitch, 0, 0)
		cam.far = 200.0
		add_child(cam)
		cam.current = true
		_cam_base = cam.position
		return
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 44.0
	var tilt: float = {"spiral": 1.0, "converge": -1.0, "serpent": 0.5}.get(realm.layout, 0.0)
	cam.position = Vector3(0, 24.0 + tilt, 13.6)
	add_child(cam)
	cam.look_at(Vector3(0, 0, -4.4))
	cam.current = true
	_cam_base = cam.position

# ── Hazards ─────────────────────────────────────────────────
func _hazard_text() -> String:
	return {
		"none": "Toque numa PLATAFORMA de pedra para construir · toque no chão para mover o herói",
		"embers": "BRASAS CAEM DO CÉU — saia dos círculos (elas queimam inimigos também)",
		"mud_fog": "NEBLINA reduz o alcance · LAMA atrasa quem pisa",
		"ballista": "A BALISTA mira em VOCÊ — continue se mexendo",
		"portals": "PORTAIS abrem no meio das pistas",
		"blizzard": "GELO escorregadio · NEVASCAS congelam tudo",
		"sandstorm": "TEMPESTADES DE AREIA cortam o alcance e aceleram os inimigos",
		"eruptions": "ERUPÇÕES atingem TODOS — atraia inimigos para elas",
		"snares": "RAÍZES prendem quem fica parado nelas",
		"sunbeam": "O RAIO DE SOL fortalece aliados e queima inimigos",
	}.get(realm.hazard, "")

func range_mul() -> float:
	var m := 1.0
	if realm.hazard == "mud_fog": m *= 0.85
	if realm.hazard == "sandstorm" and storm_t > 0.0: m *= 0.55
	return m

func enemy_speed_mul(e) -> float:
	var m := 1.0
	if storm_t > 0.0:
		m *= 0.5 if realm.hazard == "blizzard" else 1.3
	if realm.hazard == "mud_fog" and e.def.kind != "flyer":
		for z in world.mud_zones:
			if e.position.distance_to(z) < 1.3:
				m *= 0.6
				break
	return m

func warden_speed_mul() -> float:
	var m := 1.0
	if realm.hazard == "blizzard" and storm_t > 0.0: m *= 0.5
	if realm.hazard == "mud_fog":
		for z in world.mud_zones:
			if warden.position.distance_to(z) < 1.3:
				m *= 0.6
				break
	return m

func _hazards(dt: float) -> void:
	storm_t = maxf(0.0, storm_t - dt)
	hazard_t -= dt
	if hazard_t <= 0.0:
		match realm.hazard:
			"embers":
				hazard_t = 6.0
				for k in 2: _telegraph(_random_field_point(), 1.6, "ember", 1.3)
			"ballista":
				hazard_t = 4.5
				_telegraph(warden.position, 1.4, "bolt", 1.2)
			"portals":
				hazard_t = 11.0
				var lane: Curve3D = world.lanes[randi() % world.lanes.size()]
				var d := lane.get_baked_length() * randf_range(0.35, 0.6)
				ring_fx(lane.sample_baked(d), 2.0, Color("a46aff"))
				for k in 2: spawn_enemy("void_spawn", lane, 1.0 + wave_index * 0.06, d - k * 0.8)
			"blizzard":
				hazard_t = 14.0; storm_t = 3.5
				hud.flash_warning("NEVASCA!")
			"sandstorm":
				hazard_t = 15.0; storm_t = 4.0
				hud.flash_warning("TEMPESTADE DE AREIA!")
			"eruptions":
				hazard_t = 5.0
				for k in 3: _telegraph(_random_field_point(), 1.8, "meteor", 1.4)
			"snares":
				hazard_t = 5.0
				_telegraph(warden.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), 1.3, "snare", 1.0)
			_:
				hazard_t = 999.0
	for tg in telegraphs.duplicate():
		tg.t -= dt
		tg.node.scale = Vector3.ONE * (1.0 + sin(tg.t * 20.0) * 0.06)
		if tg.t <= 0.0:
			_resolve(tg)
			telegraphs.erase(tg)
			tg.node.queue_free()
	if beam:
		beam_angle += dt * 0.5
		beam.rotation.y = beam_angle
		for e in enemies:
			if e.alive and _in_beam(e.position):
				e.apply_burn(20.0)

func _in_beam(p: Vector3) -> bool:
	var o := Vector3(0, 0, -8)
	var dir := Vector3(sin(beam_angle), 0, cos(beam_angle))
	var rel := p - o
	var along := rel.dot(dir)
	return absf(along) < 14.0 and (rel - dir * along).length() < 1.1

func _make_beam() -> void:
	beam = MeshInstance3D.new()
	var m := BoxMesh.new(); m.size = Vector3(2.0, 0.05, 28.0)
	beam.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 0.95, 0.6, 0.35)
	beam.material_override = mat
	beam.position = Vector3(0, 0.06, -8)
	add_child(beam)

func _random_field_point() -> Vector3:
	if randf() < 0.5:
		var lane: Curve3D = world.lanes[randi() % world.lanes.size()]
		return lane.sample_baked(lane.get_baked_length() * randf_range(0.2, 0.85))
	return Vector3(randf_range(-5.5, 5.5), 0, randf_range(-18, 2))

func _telegraph(pos: Vector3, r: float, kind: String, t: float) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new(); c.top_radius = r; c.bottom_radius = r; c.height = 0.03; c.radial_segments = 24
	mi.mesh = c
	var col: Color = {"ember": Color("ff7a2a"), "bolt": Color("ff3a4a"), "meteor": Color("ff5a1a"), "snare": Color("9be24d")}.get(kind, Color.RED)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.45)
	mi.material_override = mat
	mi.position = Vector3(pos.x, 0.05, pos.z)
	add_child(mi)
	telegraphs.append({"node": mi, "t": t, "pos": pos, "r": r, "kind": kind})

func _resolve(tg: Dictionary) -> void:
	var p: Vector3 = tg.pos
	var r: float = tg.r
	var w_in: bool = Vector2(warden.position.x - p.x, warden.position.z - p.z).length() < r
	match tg.kind:
		"ember", "meteor":
			ring_fx(p, r, Color("ff7a2a"))
			shake(0.2)
			var power := 1.0 if tg.kind == "ember" else 1.8
			for e in enemies_near(p, r):
				hit_enemy(e, 60.0 * power, {"source": "hazard", "burn": 8.0})
			for c in soldiers + troops:
				if c.alive and c.position.distance_to(p) < r:
					c.take_damage(30.0 * power)
			if w_in: warden.take_damage(25.0 * power)
		"bolt":
			ring_fx(p, r, Color("ff3a4a"))
			if w_in: warden.take_damage(35.0)
		"snare":
			if w_in:
				warden.rooted_t = 1.5
				float_text(warden.position, "PRESO!", Color("9be24d"))

func boss_slam(boss, r: float) -> void:
	ring_fx(boss.position, r, Color("ff5470"))
	shake(0.4)
	for c in soldiers + troops:
		if c.alive and c.position.distance_to(boss.position) < r:
			c.take_damage(boss.def.damage)
			c.stun_t = 2.0
	if warden.position.distance_to(boss.position) < r:
		warden.take_damage(boss.def.damage * 0.5)

func enemy_heal_pulse(src, amount: float) -> void:
	ring_fx(src.position, 3.0, Color("9be24d"))
	# Healers can't heal each other — kill them first and the group falls apart.
	for e in enemies_near(src.position, 3.0):
		if e.def.has("heal"): continue
		e.hp = minf(e.max_hp, e.hp + amount * (1.0 + e.hp_scale * 0.5))

# ── Waves ───────────────────────────────────────────────────
func _next_wave() -> void:
	wave_index += 1
	var waves: Array = realm.wave_list
	if wave_index >= waves.size():
		_end(true)
		return
	if wave_index > 0:
		var rep: float = mods.repair + float(upgrade_mods.get("repair", 0.0))
		if rep > 0.0:
			integrity = minf(integrity_max, integrity + rep)
	wave_time = 0.0
	pending.clear()
	var is_boss := false
	for grp in waves[wave_index]:
		for k in int(grp.count):
			pending.append({"t": grp.at + k * grp.gap, "enemy": grp.enemy, "lane": int(grp.lane) % world.lanes.size()})
		if GameData.enemies[grp.enemy].kind == "boss":
			is_boss = true
	hud.set_wave(wave_index + 1, waves.size())
	if is_boss:
		Sfx.play("boss")
		hud.banner("CHEFE!", GameData.enemies[realm.boss].name, UIKit.DANGER)

func spawn_enemy(id: String, lane: Curve3D, hp_scale: float, start_dist := 0.0) -> void:
	Save.mark_seen(id)
	var e = EnemyScript.new()
	add_child(e)
	e.setup(self, id, lane, hp_scale, maxf(0.0, start_dist))
	enemies.append(e)

func _wave_done() -> bool:
	if not pending.is_empty():
		return false
	for e in enemies:
		if e.alive: return false
	return true

# ── Main loop (fixed sub-steps) ─────────────────────────────
func _process(delta: float) -> void:
	_update_camera(delta)
	if state != "playing":
		return
	_sim_acc = minf(_sim_acc + delta, 0.1)
	while _sim_acc >= STEP and state == "playing":
		_sim_acc -= STEP
		_step(STEP)
		if between:
			between_t -= STEP
			if between_t <= 0.0:
				call_wave()
	hud.refresh()
	if state == "playing" and not between and _wave_done():
		if wave_index >= realm.wave_list.size() - 1:
			_end(true)
		else:
			_offer_boon()

func _step(dt: float) -> void:
	wave_time += dt
	for s in pending.duplicate():
		if wave_time >= s.t:
			pending.erase(s)
			spawn_enemy(s.enemy, world.lanes[s.lane], ((1.0 + wave_index * 0.02) if GameData.enemies[s.enemy].kind == "boss" else (1.0 + wave_index * 0.08)) * (1.2 + realm.index * 0.05))
	courage = minf(GameData.COURAGE_MAX, courage + GameData.COURAGE_REGEN * dt)
	_refresh_auras()
	warden.step(dt)
	for c in champions: c.step(dt)
	for c in soldiers: c.step(dt)
	for c in troops: c.step(dt)
	for e in enemies: e.step(dt)
	for p in projectiles: p.step(dt)
	_hazards(dt)
	# Settle deaths.
	for e in enemies.duplicate():
		if e.alive: continue
		enemies.erase(e)
		if e.silent:
			e.queue_free()
			continue
		if not e.reached:
			kills += 1
			var bounty := int(e.def.bounty * 1.5 * mods.gold)
			gold += bounty
			warden.add_ult(40.0 if e.is_boss else 4.0)
			if e.is_boss: bosses_killed += 1
			Sfx.play("enemy_die", 0.7 if e.is_boss else 1.0)
			if e.is_boss:
				ring_fx(e.position, 5.0, Color("ffe6a6"))
				shake(0.5)
			if e.def.has("split"):
				for k in int(e.def.split[1]):
					spawn_enemy(e.def.split[0], e.curve, 1.0 + wave_index * 0.1, e.dist - k * 0.5)
		_die_fx(e)
	for c in soldiers.duplicate():
		if not c.alive:
			soldiers.erase(c)
			_die_fx(c)
	for c in troops.duplicate():
		if not c.alive:
			troops.erase(c)
			_die_fx(c)
	for p in projectiles.duplicate():
		if not p.alive:
			projectiles.erase(p)
			p.queue_free()
	if auto:
		_auto_play(dt)
func _die_fx(n: Node3D) -> void:
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3(1.3, 0.05, 1.3), 0.18)
	tw.tween_callback(n.queue_free)

# ── Combat API used by entities ─────────────────────────────
func spawn_projectile(from: Vector3, target, dmg: float, src: String, opts: Dictionary = {}) -> void:
	var p = ProjectileScript.new()
	add_child(p)
	p.setup(self, from, target, dmg, src, opts)
	projectiles.append(p)

func hit_enemy(e, dmg: float, opts: Dictionary) -> void:
	if not e.alive: return
	var src: String = opts.get("source", "warden")
	if beam and src in ["warden", "champion"]:
		var shooter_pos: Vector3 = warden.position if src == "warden" else e.position
		if _in_beam(shooter_pos): dmg *= 1.5
	var dealt: float = e.take_damage(dmg, opts.get("true_dmg", false))
	if opts.get("crit", false):
		float_text(e.position, str(int(dealt)), Color("ffe6a6"))
	if opts.get("burn", 0.0) > 0.0: e.apply_burn(opts.burn)
	if opts.get("slow", 0.0) > 0.0: e.apply_slow(opts.slow)
	if src == "warden" and mods.lifesteal > 0.0:
		warden.heal(dealt * mods.lifesteal)
	var chain: int = opts.get("chain", 0)
	if chain > 0:
		var n := 0
		for o in enemies_near(e.position, 4.0):
			if o == e or n >= chain: continue
			n += 1
			hit_enemy(o, dmg * 0.5, {"source": src})

func damage_bastion(d: float) -> void:
	if state == "over": return
	integrity = maxf(0.0, integrity - d * GameData.BASTION_MAX / 100.0)
	Sfx.play("hurt", 0.7)
	shake(0.2)
	if integrity <= 0.0:
		_end(false)

func nearest_enemy(p: Vector3, r: float):
	var best = null
	var bd := r * r
	for e in enemies:
		if not e.alive: continue
		var d := Vector2(e.position.x - p.x, e.position.z - p.z).length_squared()
		if d < bd:
			bd = d; best = e
	return best

func nearest_ground_enemy(p: Vector3, r: float):
	var best = null
	var bd := r * r
	for e in enemies:
		if not e.alive or e.def.kind == "flyer": continue
		var d := Vector2(e.position.x - p.x, e.position.z - p.z).length_squared()
		if d < bd:
			bd = d; best = e
	return best

## Artillery shell: arcs to `to` (with its shadow sliding on the ground),
## then explodes (ground enemies only). Poison lobs leave a puddle.
func lob(from: Vector3, to: Vector3, dmg: float, r: float, opts: Dictionary) -> void:
	var poison: float = opts.get("poison", 0.0)
	var shell: Sprite3D
	if poison > 0.0:
		shell = FX.sprite("orb", 0.6, "billboard", opts.get("color", Color("7ed957")))
	else:
		var tint: Color = opts.get("color", Color("2a2e38"))
		shell = FX.sprite("cannonball", 0.55, "billboard", Color.WHITE if tint == Color("2a2e38") else tint.lightened(0.35))
	shell.position = from
	add_child(shell)
	var dest := Vector3(to.x, 0.2, to.z)
	var shadow := FX.sprite("shadow", 0.7, "ground")
	shadow.position = Vector3(from.x, 0.03, from.z)
	add_child(shadow)
	var flight := 0.65
	var tw := shell.create_tween()
	tw.tween_method(func(t: float):
		shell.position = from.lerp(dest, t) + Vector3(0, sin(t * PI) * 3.0, 0)
		shell.rotation.z = -t * TAU
		shadow.position = Vector3(lerpf(from.x, dest.x, t), 0.03, lerpf(from.z, dest.z, t))
		shadow.scale = Vector3.ONE * lerpf(0.6, 1.0, absf(t - 0.5) * 2.0), 0.0, 1.0, flight)
	tw.tween_callback(func():
		shell.queue_free()
		shadow.queue_free()
		if state == "over": return
		if poison > 0.0:
			_puddle(dest, r)
		else:
			FX.play(self, "burst", dest + Vector3(0, 0.5, 0), r * 1.1, "billboard", Color.WHITE, 0.3)
			FX.play(self, "smoke", dest + Vector3(0, 0.8, 0), r * 1.3, "billboard", Color.WHITE, 0.6)
		ring_fx(dest, r, Color("ffb03a") if poison <= 0.0 else Color("9be24d"))
		for e in enemies_near(dest, r):
			if e.def.kind == "flyer": continue
			if poison > 0.0:
				e.apply_burn(poison)
				e.apply_slow(0.35)
			else:
				hit_enemy(e, dmg, {"source": "champion", "true_dmg": opts.get("true_dmg", false), "burn": opts.get("burn", 0.0)}))
	Sfx.play("hit", 0.7)

func _puddle(p: Vector3, r: float) -> void:
	var s := FX.sprite("puddle", r * 2.0, "ground")
	s.position = Vector3(p.x, 0.04, p.z)
	add_child(s)
	var base := s.scale
	s.scale = base * 0.3
	var tw := s.create_tween()
	tw.tween_property(s, "scale", base, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(s, "scale", base * 0.1, 0.4)
	tw.tween_callback(s.queue_free)

## Lightning: hits the target, then leaps to `jumps` more enemies nearby.
func zap(from: Vector3, first, dmg: float, jumps: int) -> void:
	var hit: Array = [first]
	var cur = first
	for k in jumps:
		var nxt = null
		var bd := 3.5
		for e in enemies:
			if not e.alive or hit.has(e): continue
			var d: float = e.position.distance_to(cur.position)
			if d < bd:
				bd = d; nxt = e
		if nxt == null: break
		hit.append(nxt)
		cur = nxt
	var prev := from
	for i in hit.size():
		var e = hit[i]
		var to: Vector3 = e.hit_point()
		_bolt(prev, to)
		prev = to
		hit_enemy(e, dmg * pow(0.8, i), {"source": "champion", "true_dmg": true})
	Sfx.play("shoot", 1.6)

func _bolt(a: Vector3, b: Vector3) -> void:
	var len := a.distance_to(b)
	if len < 0.01: return
	var s := FX.sprite("zap", 1.0, "free")
	s.scale = Vector3(len, 1.0, 1.0)
	s.position = (a + b) / 2.0
	add_child(s)
	FX.orient(s, b - a, cam)
	FX.play(self, "burst", b, 0.7, "billboard", Color("bfeaff"), 0.18)
	var tw := s.create_tween()
	tw.tween_interval(0.08)
	tw.tween_callback(func(): s.flip_v = true)
	tw.tween_interval(0.08)
	tw.tween_callback(s.queue_free)

func enemies_near(p: Vector3, r: float) -> Array:
	var out: Array = []
	for e in enemies:
		if e.alive and Vector2(e.position.x - p.x, e.position.z - p.z).length() < r + e.radius:
			out.append(e)
	return out

## Auras: every monster near a haste/ward/rage source gets the buff this step.
func _refresh_auras() -> void:
	var sources: Array = []
	for e in enemies:
		e.buff_haste = false; e.buff_ward = false; e.buff_rage = false
		if e.alive and e.def.has("aura"): sources.append(e)
	for s in sources:
		for e in enemies:
			if not e.alive or e.position.distance_to(s.position) > 3.5: continue
			match s.def.aura:
				"haste": e.buff_haste = true
				"ward": e.buff_ward = true
				"rage": e.buff_rage = true
	# a boss in its final phase drives every monster into a rage
	for e in enemies:
		if e.is_boss and e.stage >= 3 and e.alive:
			for o in enemies: o.buff_rage = true
			break

## Freezes towers near p for t seconds. Returns how many were hit.
func disable_towers_near(p: Vector3, r: float, t: float, max_n := 99) -> int:
	var n := 0
	for c in champions:
		if n >= max_n: break
		if c.alive and c.position.distance_to(p) < r and c.family != "goldmine":
			c.disable(t)
			n += 1
	if n > 0:
		float_text(p, "TORRES CONGELADAS!", Color("8fe9ff"))
	return n

## Closest thing a monster can shoot: soldiers, troops or the hero.
func nearest_ally(p: Vector3, r: float):
	var best = null
	var bd := r
	for c in soldiers + troops:
		if c.alive:
			var d: float = c.position.distance_to(p)
			if d < bd: bd = d; best = c
	if not warden.downed and warden.position.distance_to(p) < bd:
		best = warden
	return best

func allies_near(p: Vector3, r: float) -> Array:
	var out: Array = []
	for c in soldiers + troops:
		if c.alive and c.position.distance_to(p) < r: out.append(c)
	if not warden.downed and warden.position.distance_to(p) < r: out.append(warden)
	return out

func most_wounded_ally(p: Vector3, r: float):
	var best = null
	var bf := 0.98
	for c in soldiers + troops:
		if c.alive and c.position.distance_to(p) < r and c.hp / c.max_hp < bf:
			bf = c.hp / c.max_hp; best = c
	if not warden.downed and warden.position.distance_to(p) < r and warden.hp / warden.max_hp < bf:
		best = warden
	return best

# ── FX (kept deliberately light) ────────────────────────────
func ring_fx(p: Vector3, r: float, col: Color) -> void:
	# Drawn shockwave ring lying on the ground: pops out to radius r and fades.
	var s := FX.sprite("ring", 2.0, "ground", col)
	s.position = Vector3(p.x, 0.06, p.z)
	add_child(s)
	var base := s.scale
	s.scale = base * 0.15
	var tw := s.create_tween()
	tw.tween_property(s, "scale", base * r, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.3).set_delay(0.12)
	tw.tween_callback(s.queue_free)

func float_text(p: Vector3, text: String, col: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = UIKit.font()
	l.font_size = 72
	l.modulate = col
	l.outline_size = 14
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = p + Vector3(0, 2.2, 0)
	l.pixel_size = 0.01
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

func banner_small(text: String) -> void:
	hud.flash_warning(text)

func shake(amount: float) -> void:
	if Save.settings.shake:
		_shake = maxf(_shake, amount)

func _update_camera(delta: float) -> void:
	if cam == null: return
	_shake = maxf(0.0, _shake - delta * 1.5)
	cam.position = _cam_base + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.6

# ── Build spots ─────────────────────────────────────────
func screen_to_ground(screen: Vector2) -> Vector3:
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	if absf(d.y) < 0.0001: return Vector3.INF
	var t := -o.y / d.y
	return o + d * t

func pad_at(p: Vector3) -> int:
	var best := -1
	var bd := 1.5
	for i in world.pads.size():
		var q: Vector3 = world.pads[i]
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		if d < bd:
			bd = d; best = i
	return best

func rally_point_for(pad_pos: Vector3) -> Vector3:
	return world.rally_point(pad_pos)

func build_cost(family: String) -> int:
	return int(GameData.TOWERS[family].cost[0])

func select_pad(i: int) -> void:
	selected_pad = i
	hud.show_build(i)
	Sfx.play("click")

func build(i: int, family: String) -> bool:
	var cost := build_cost(family)
	if i < 0 or pad_owner[i] != null or gold < cost or not GameData.tower_unlocked(family):
		Sfx.play("back")
		return false
	gold -= cost
	var c = ChampionScript.new()
	add_child(c)
	c.setup(self, family, i, world.pads[i], cost)
	champions.append(c)
	pad_owner[i] = c
	builds += 1
	ring_fx(world.pads[i], 1.3, GameData.TOWERS[family].color)
	Sfx.play("deploy")
	hud.hide_build()
	return true

func upgrade_pad(i: int) -> bool:
	var c = pad_owner[i]
	if c == null or c.cost_next() < 0 or gold < c.cost_next():
		Sfx.play("back")
		return false
	gold -= c.cost_next()
	c.upgrade()
	Sfx.play("boon")
	hud.hide_build()
	return true

func specialize_pad(i: int, champ_id: String) -> bool:
	var c = pad_owner[i]
	var def := GameData.champion(champ_id)
	var cost := GameData.spec_cost(def)
	if c == null or not c.can_specialize() or gold < cost or not Save.champ_unlocked(champ_id):
		Sfx.play("back")
		return false
	gold -= cost
	c.specialize(def)
	banner_small(def.name.to_upper() + "!")
	Sfx.play("ult")
	hud.hide_build()
	return true

func sell_pad(i: int) -> void:
	var c = pad_owner[i]
	if c == null: return
	gold += c.sell_value()
	float_text(c.position, "+%d" % c.sell_value(), Color("ffcf3d"))
	c.remove()
	champions.erase(c)
	pad_owner[i] = null
	_die_fx(c)
	Sfx.play("coin")
	hud.hide_build()

# ── Troops: tap a card, then tap a road ─────────────────
func troop_unlocked(i: int) -> bool:
	return Save.data.cleared.size() >= int(GameData.TROOPS[i].unlock_after)

func select_troop(i: int) -> void:
	if not troop_unlocked(i) or courage < float(GameData.TROOPS[i].cost):
		Sfx.play("back")
		return
	selected_troop = -1 if selected_troop == i else i
	hud.hide_build()
	Sfx.play("click")

func deploy_troop(i: int, p: Vector3) -> bool:
	var t: Dictionary = GameData.TROOPS[i]
	if courage < float(t.cost): return false
	var best: Curve3D = null
	var bd := 2.6
	for c in world.lanes:
		var d: float = c.get_closest_point(p).distance_to(Vector3(p.x, 0, p.z))
		if d < bd:
			bd = d; best = c
	if best == null:
		float_text(p, "TOQUE NA ESTRADA", Color("ff5470"))
		Sfx.play("back")
		return false
	var off: float = best.get_closest_offset(Vector3(p.x, 0, p.z))
	off = clampf(off, 2.0, best.get_baked_length() - 1.0)
	courage -= float(t.cost)
	for k in int(t.count):
		var tr = TroopScript.new()
		add_child(tr)
		tr.setup(self, t, best, off + k * 0.5, (k - (int(t.count) - 1) / 2.0) * 0.55)
		troops.append(tr)
	ring_fx(best.sample_baked(off), 1.2, t.color)
	Sfx.play("deploy")
	selected_troop = -1
	return true

# ── Waves: between waves you build, then call the next one ──
func _start_between(t: float) -> void:
	between = true
	between_t = t
	hud.show_call(true)

## Calling early pays a bonus (like the classic "call wave" skull).
func call_wave() -> void:
	if not between: return
	var bonus := int(maxf(0.0, between_t) * 2.0) if wave_index >= 0 else 0
	if bonus > 0:
		gold += bonus
		float_text(warden.position, "+%d ouro" % bonus, Color("ffcf3d"))
	between = false
	hud.show_call(false)
	_next_wave()

# ── Boons ───────────────────────────────────────────────────
func _offer_boon() -> void:
	state = "boon"
	hud.hide_build()
	Sfx.play("boon")
	var weight := {"common": 10.0, "rare": 6.0, "epic": 3.0}
	var keyed: Array = []
	for b in GameData.boons:
		keyed.append([randf() * weight.get(b.rarity, 1.0), b])
	keyed.sort_custom(func(a, b): return a[0] > b[0])
	var pool: Array = []
	for k in keyed: pool.append(k[1])
	hud.show_boons(pool.slice(0, 3))
	if auto:
		get_tree().create_timer(0.3).timeout.connect(func(): pick_boon(pool[0]))

func pick_boon(b: Dictionary) -> void:
	if state != "boon": return
	GameData.apply_boon(mods, b)
	if mods.bonus_gold > 0.0:
		gold += int(mods.bonus_gold)
		mods.bonus_gold = 0.0
	warden.recompute()
	for c in champions: c._apply_stats()
	hud.hide_boons()
	Sfx.play("victory")
	state = "playing"
	_start_between(12.0 if not auto else 0.5)

# ── Pause / end ─────────────────────────────────────────────
func toggle_pause() -> void:
	if state == "playing":
		state = "paused"
		hud.show_pause(true)
	elif state == "paused":
		state = "playing"
		hud.show_pause(false)

func abandon() -> void:
	state = "playing"
	_end(false)

func _end(victory: bool) -> void:
	if state == "over": return
	state = "over"
	Engine.time_scale = 1.0
	Sfx.play("victory" if victory else "defeat")
	hud.banner("REINO CONQUISTADO!" if victory else "O BASTIÃO CAIU", "", UIKit.EMBER_HI if victory else UIKit.DANGER)
	var waves_done: int = wave_index + (1 if victory else 0)
	var rewards := Save.settle_run(realm.id, victory, waves_done, integrity / integrity_max, kills, builds, bosses_killed)
	if auto:
		print("AUTO_RESULT realm=%s victory=%s waves=%d/%d kills=%d gold=%d integrity=%d stars=%d builds=%d pads=%d" % [realm.id, victory, waves_done, realm.wave_list.size(), kills, gold, int(integrity), int(rewards.stars), builds, world.pads.size()])
	get_tree().create_timer(1.6).timeout.connect(func():
		Nav.go("result", {"realm_id": realm.id, "victory": victory, "waves": waves_done,
			"total": realm.wave_list.size(), "kills": kills, "rewards": rewards}, true))

# ── Input: tap a stone spot = build menu · tap ground = hero walks there ──
func _unhandled_input(event: InputEvent) -> void:
	if state != "playing": return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var g := screen_to_ground(event.position)
		if g == Vector3.INF: return
		if selected_troop >= 0:
			deploy_troop(selected_troop, g)
			return
		var i := pad_at(g)
		if i >= 0:
			select_pad(i)
		else:
			hud.hide_build()
			warden.walk_to(g)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		warden.release_ult()

# ── Auto-play (testing): builds, upgrades, specializes, walks the hero ──
func _auto_play(dt: float) -> void:
	_auto_t -= dt
	var t = nearest_enemy(warden.position, 40.0)
	warden.move_input = Vector2.ZERO
	if t != null:
		var to: Vector3 = t.position - warden.position
		to.y = 0
		var d := to.length()
		if d < 2.5:
			warden.move_input = Vector2(-to.x, -to.z).normalized()
		elif d > warden.atk_range * range_mul() * 0.85 and fmod(wave_time, 1.2) < 0.7:
			warden.move_input = Vector2(to.x, to.z).normalized()
	if warden.ult_ready(): warden.release_ult()
	if _auto_t > 0.0: return
	_auto_t = 1.0
	if not enemies.is_empty():
		for ti in range(GameData.TROOPS.size() - 1, -1, -1):
			if troop_unlocked(ti) and courage >= float(GameData.TROOPS[ti].cost):
				var lane: Curve3D = world.lanes[randi() % world.lanes.size()]
				deploy_troop(ti, lane.sample_baked(lane.get_baked_length() * 0.7))
				break
	var order: Array = range(world.pads.size())
	var mid := world.pads.size() / 2
	order.sort_custom(func(a, b): return absi(a - mid) < absi(b - mid))
	var plan := ["archer", "barracks", "mage", "artillery", "tesla", "ballista", "barracks", "cauldron", "archer", "mage", "goldmine"]
	for i in order:
		if pad_owner[i] == null:
			var fam: String = plan[builds % plan.size()]
			var tries := 0
			while not GameData.tower_unlocked(fam) and tries < 12:
				builds += 1; tries += 1
				fam = plan[builds % plan.size()]
			if gold >= build_cost(fam):
				build(i, fam)
			return
	# Cheapest affordable improvement first (upgrade or specialization).
	var best_i := -1
	var best_cost := 99999
	var best_spec := ""
	for i in order:
		var c = pad_owner[i]
		if c == null: continue
		if c.cost_next() >= 0 and c.cost_next() < best_cost:
			best_i = i; best_cost = c.cost_next(); best_spec = ""
		elif c.can_specialize():
			for sd in GameData.family_specs(c.family):
				if Save.champ_unlocked(sd.id) and GameData.spec_cost(sd) < best_cost:
					best_i = i; best_cost = GameData.spec_cost(sd); best_spec = sd.id
	if best_i >= 0 and gold >= best_cost:
		if best_spec == "": upgrade_pad(best_i)
		else: specialize_pad(best_i, best_spec)
