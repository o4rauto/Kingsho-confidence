extends Node3D
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const WorldBuilder := preload("res://scripts/game/world_builder.gd")
## Battle — the 3D battlefield where the three influences fuse:
##  · Kingdom Rush: enemies march lanes toward your Bastion.
##  · Clash Royale: regenerating Aether deploys champion cards.
##  · Archero: pilot the Warden; draft a Boon after every wave.
## Each realm adds its own hazard so no two maps play alike.

const BASTION_POS := Vector3(0, 0, 6.0)
const STEP := 1.0 / 60.0
const HudScript := preload("res://scripts/ui/hud.gd")
const EnemyScript := preload("res://scripts/game/enemy.gd")
const ChampionScript := preload("res://scripts/game/champion.gd")
const WardenScript := preload("res://scripts/game/warden.gd")
const ProjectileScript := preload("res://scripts/game/projectile.gd")

var realm: Dictionary
var deck: Array = []
var world: WorldBuilder
var cam: Camera3D
var hud
var warden
var enemies: Array = []
var champions: Array = []
var projectiles: Array = []
var mods: Dictionary
var state := "intro"   # intro | playing | boon | paused | over
var integrity := GameData.BASTION_MAX
var aether := GameData.AETHER_START
var wave_index := -1
var wave_time := 0.0
var pending: Array = []      # [{t, enemy, lane}]
var gold := 0
var kills := 0
var selected_card := -1
var card_cd: Array = []
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
				Save.data.warden_level = lv
				for id in Save.data.champions:
					Save.data.champions[id].level = mini(lv, GameData.MAX_LEVEL)
	mods = GameData.fresh_mods()
	card_cd = []
	for i in deck.size(): card_cd.append(0.0)
	_shared_resources()
	world = WorldBuilder.new()
	world.build(realm, self)
	_camera()
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
	hud.banner(realm.name.to_upper(), realm.subtitle, UIKit.EMBER_HI)
	hud.hazard_hint(_hazard_text())
	Sfx.play_realm_music(realm)
	get_tree().create_timer(1.6).timeout.connect(func():
		state = "playing"
		_next_wave())

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
		"none": "Arraste para mover · fique parado para atirar · toque numa carta e depois no chão",
		"embers": "BRASAS CAEM DO CÉU — saia dos círculos (elas queimam inimigos também)",
		"mud_fog": "NEBLINA reduz o alcance · LAMA atrasa quem pisa",
		"ballista": "A BALISTA mira em VOCÊ — continue se mexendo",
		"portals": "PORTAIS abrem no meio das pistas",
		"blizzard": "GELO escorregadio · NEVASCAS congelam tudo",
		"sandstorm": "TEMPESTADES DE AREIA cortam o alcance · o OÁSIS dá +Aether",
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
				for k in 3: spawn_enemy("void_spawn", lane, 1.0 + wave_index * 0.1, d - k * 0.8)
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
			for c in champions:
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
	for c in champions:
		if c.alive and c.position.distance_to(boss.position) < r:
			c.take_damage(boss.def.damage)
			c.stun_t = 2.0
	if warden.position.distance_to(boss.position) < r:
		warden.take_damage(boss.def.damage * 0.5)

func enemy_heal_pulse(src, amount: float) -> void:
	ring_fx(src.position, 3.0, Color("9be24d"))
	for e in enemies_near(src.position, 3.0):
		e.hp = minf(e.max_hp, e.hp + amount)

# ── Waves ───────────────────────────────────────────────────
func _next_wave() -> void:
	wave_index += 1
	var waves: Array = realm.wave_list
	if wave_index >= waves.size():
		_end(true)
		return
	if wave_index > 0:
		aether = minf(GameData.AETHER_MAX, aether + GameData.AETHER_WAVE_BONUS)
		if mods.repair > 0.0:
			integrity = minf(GameData.BASTION_MAX, integrity + mods.repair)
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
	hud.refresh()
	if state == "playing" and _wave_done():
		if wave_index >= realm.wave_list.size() - 1:
			_end(true)
		else:
			_offer_boon()

func _step(dt: float) -> void:
	wave_time += dt
	for s in pending.duplicate():
		if wave_time >= s.t:
			pending.erase(s)
			spawn_enemy(s.enemy, world.lanes[s.lane], ((1.0 + wave_index * 0.02) if GameData.enemies[s.enemy].kind == "boss" else (1.0 + wave_index * 0.09)) * (1.0 + realm.index * 0.04))
	warden.move_input = hud.joystick_vector()
	warden.step(dt)
	for c in champions: c.step(dt)
	for e in enemies: e.step(dt)
	for p in projectiles: p.step(dt)
	_hazards(dt)
	# Settle deaths.
	for e in enemies.duplicate():
		if e.alive: continue
		enemies.erase(e)
		if not e.reached:
			kills += 1
			var bounty := int(e.def.bounty * mods.gold)
			gold += bounty
			warden.add_ult(40.0 if e.is_boss else 4.0)
			Sfx.play("enemy_die", 0.7 if e.is_boss else 1.0)
			if e.is_boss:
				ring_fx(e.position, 5.0, Color("ffe6a6"))
				shake(0.5)
			if e.def.has("split"):
				for k in int(e.def.split[1]):
					spawn_enemy(e.def.split[0], e.curve, 1.0 + wave_index * 0.1, e.dist - k * 0.5)
		_die_fx(e)
	for c in champions.duplicate():
		if not c.alive:
			champions.erase(c)
			_die_fx(c)
	for p in projectiles.duplicate():
		if not p.alive:
			projectiles.erase(p)
			p.queue_free()
	aether = minf(GameData.AETHER_MAX, aether + GameData.AETHER_REGEN * mods.aether_regen * (1.25 if realm.hazard == "sandstorm" else 1.0) * dt)
	for i in card_cd.size():
		card_cd[i] = maxf(0.0, card_cd[i] - dt)
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
	var dealt: float = e.take_damage(dmg)
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
	integrity = maxf(0.0, integrity - d)
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

func enemies_near(p: Vector3, r: float) -> Array:
	var out: Array = []
	for e in enemies:
		if e.alive and Vector2(e.position.x - p.x, e.position.z - p.z).length() < r + e.radius:
			out.append(e)
	return out

func most_wounded_ally(p: Vector3, r: float):
	var best = null
	var bf := 0.98
	for c in champions:
		if c.alive and c.position.distance_to(p) < r and c.hp / c.max_hp < bf:
			bf = c.hp / c.max_hp; best = c
	if not warden.downed and warden.position.distance_to(p) < r and warden.hp / warden.max_hp < bf:
		best = warden
	return best

# ── FX (kept deliberately light) ────────────────────────────
func ring_fx(p: Vector3, r: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new(); t.inner_radius = 0.9; t.outer_radius = 1.0; t.rings = 24; t.ring_segments = 4
	mi.mesh = t
	mi.material_override = AssetLib.mat(col, 2.0)
	mi.position = Vector3(p.x, 0.15, p.z)
	mi.scale = Vector3(0.2, 0.2, 0.2)
	add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(r, 0.3, r), 0.3)
	tw.tween_callback(mi.queue_free)

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
	if Save.data.settings.shake:
		_shake = maxf(_shake, amount)

func _update_camera(delta: float) -> void:
	if cam == null: return
	_shake = maxf(0.0, _shake - delta * 1.5)
	cam.position = _cam_base + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.6

# ── Deploy ──────────────────────────────────────────────────
func select_card(i: int) -> void:
	if state != "playing": return
	var def := GameData.champion(deck[i])
	if card_cd[i] > 0.0 or aether < def.cost:
		Sfx.play("back")
		return
	selected_card = -1 if selected_card == i else i
	Sfx.play("click")

func screen_to_ground(screen: Vector2) -> Vector3:
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	if absf(d.y) < 0.0001: return Vector3.INF
	var t := -o.y / d.y
	return o + d * t

func valid_deploy(p: Vector3) -> bool:
	if p == Vector3.INF: return false
	if absf(p.x) > 6.3 or p.z < -21.0 or p.z > 3.5: return false
	if p.distance_to(BASTION_POS) < 2.2: return false
	for c in champions:
		if c.alive and c.position.distance_to(p) < 1.1: return false
	return true

func try_deploy(p: Vector3) -> bool:
	if selected_card < 0: return false
	var i := selected_card
	var def := GameData.champion(deck[i])
	if not valid_deploy(p) or aether < def.cost:
		Sfx.play("back")
		float_text(p if p != Vector3.INF else warden.position, "INVÁLIDO", Color("ff5470"))
		return false
	aether -= def.cost
	card_cd[i] = 4.0 + def.cost * 0.6
	var stats := Save.stats(def)
	var evolved: bool = Save.champ(def.id).evolved
	for k in int(def.count):
		var c = ChampionScript.new()
		add_child(c)
		var off := Vector3((k - (def.count - 1) / 2.0) * 0.9, 0, 0)
		c.setup(self, def, Vector3(p.x, 0, p.z) + off, stats, evolved)
		champions.append(c)
	ring_fx(p, 1.2, def.color)
	Sfx.play("deploy")
	selected_card = -1
	return true

# ── Boons ───────────────────────────────────────────────────
func _offer_boon() -> void:
	state = "boon"
	selected_card = -1
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
	warden.recompute()
	hud.hide_boons()
	Sfx.play("victory")
	state = "playing"
	_next_wave()

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
	var rewards := Save.settle_run(realm.id, victory, waves_done, gold, kills)
	if auto:
		print("AUTO_RESULT realm=%s victory=%s waves=%d/%d kills=%d gold=%d integrity=%d" % [realm.id, victory, waves_done, realm.wave_list.size(), kills, gold, int(integrity)])
	get_tree().create_timer(1.6).timeout.connect(func():
		Nav.go("result", {"realm_id": realm.id, "victory": victory, "waves": waves_done,
			"total": realm.wave_list.size(), "kills": kills, "rewards": rewards}))

# ── Input: drag = joystick, tap = deploy (HUD widgets consume their own taps) ──
func _unhandled_input(event: InputEvent) -> void:
	if state != "playing": return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected_card >= 0:
				try_deploy(screen_to_ground(event.position))
			else:
				hud.joystick_start(event.position)
		else:
			hud.joystick_end()
	elif event is InputEventMouseMotion:
		hud.joystick_move(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		warden.release_ult()

# ── Auto-play (testing): deploys cards, kites, picks boons ──
func _auto_play(dt: float) -> void:
	_auto_t -= dt
	# Human-like kiting: close in to firing range, back off when crowded,
	# then stand still to shoot (the Warden only fires while stationary).
	var t = nearest_enemy(warden.position, 40.0)
	hud.auto_vec = Vector2.ZERO
	if t != null:
		var to: Vector3 = t.position - warden.position
		to.y = 0
		var d := to.length()
		if d < 2.5:
			hud.auto_vec = Vector2(-to.x, -to.z).normalized()
		elif d > warden.atk_range * range_mul() * 0.85 and fmod(wave_time, 1.2) < 0.7:
			hud.auto_vec = Vector2(to.x, to.z).normalized()
	if warden.ult_ready(): warden.release_ult()
	if _auto_t > 0.0: return
	_auto_t = 1.5
	var order := range(deck.size())
	order.shuffle()
	for i in order:
		var def := GameData.champion(deck[i])
		if card_cd[i] <= 0.0 and aether >= def.cost:
			var lane: Curve3D = world.lanes[randi() % world.lanes.size()]
			var p := lane.sample_baked(lane.get_baked_length() * randf_range(0.62, 0.9)) + Vector3(randf_range(-1.6, 1.6), 0, 0)
			selected_card = i
			if not try_deploy(p): selected_card = -1
			return
