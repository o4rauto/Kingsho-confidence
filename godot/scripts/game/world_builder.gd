extends RefCounted
## Builds a realm's battlefield: ground, lanes (8 distinct layouts), sky,
## light, fog, weather and the biome's own set pieces. Every realm differs.
##
## Prop slots: drop res://assets/models/prop_<biome>_<name>.glb to replace a
## placeholder prop (see /pipeline/05_scenery.md).

const HALF_W := 6.6          # field half width (x)
const SPAWN_Z := -24.0       # enemies enter here
const END_Z := 4.4           # lanes end at the Bastion gate
const BASTION := Vector3(0, 0, 6.0)

var realm: Dictionary
var root: Node3D
var lanes: Array[Curve3D] = []
var lane_points: Array[PackedVector3Array] = []
var mud_zones: Array[Vector3] = []   # used by the mud hazard
var pads: Array[Vector3] = []        # stone build spots beside the roads
var pad_nodes: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var scen: Node3D                    # all static props, baked into ONE mesh at the end

func build(r: Dictionary, parent: Node3D) -> void:
	realm = r
	root = parent
	rng.seed = hash(r.id)
	scen = Node3D.new()
	root.add_child(scen)
	_environment()
	_ground()
	_lanes()
	_pads()
	_set_pieces()
	_mountains()
	_dressing()
	_scatter_props()
	_bake_scenery()
	_weather()

## Hundreds of props → one vertex-coloured mesh (+ ink outline): 2 draw calls.
func _bake_scenery() -> void:
	var mesh: ArrayMesh = AssetLib._bake(scen)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = AssetLib.baked_mat()
	scen.add_child(mi)

# ── Sky, light, fog ─────────────────────────────────────────
func _environment() -> void:
	# Bright storybook light: no fog, no filmic wash — colours stay saturated.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = realm.sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = realm.ambient
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = realm.sun
	sun.light_energy = {"night": 0.62, "storm": 0.66, "void": 0.66, "toxic": 0.7, "lava": 0.7}.get(realm.tod, 0.74)
	sun.rotation_degrees = Vector3(-55.0, -30.0 + rng.randf_range(-15, 15), 0)
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.55
	sun.directional_shadow_max_distance = 45.0
	root.add_child(sun)

# ── Ground ──────────────────────────────────────────────────
func _ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = {"desert": 0.02, "ice": 0.03, "volcano": 0.08}.get(realm.biome, 0.05)
	var ramp := Gradient.new()
	ramp.set_color(0, realm.ground2)
	ramp.set_color(1, realm.ground.lightened(0.08))
	ramp.add_point(0.55, realm.ground)
	var tex := NoiseTexture2D.new()
	tex.width = 256; tex.height = 256
	tex.noise = noise
	tex.color_ramp = ramp
	tex.seamless = true
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(7, 12, 1)
	m.roughness = 1.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 120)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	mi.position = Vector3(0, 0, -8)
	root.add_child(mi)

# ── Lanes: 8 layouts ────────────────────────────────────────
func _lane_fn(i: int, n: int, t: float) -> Vector2:
	# Returns (x, z) for lane i of n at progress t ∈ [0,1].
	var z := lerpf(SPAWN_Z, END_Z, t)
	var slot := 0.0 if n == 1 else lerpf(-1.0, 1.0, float(i) / (n - 1))
	var converge := pow(t, 3.0)  # all lanes funnel into the gate
	var x := 0.0
	match realm.layout:
		"straight":
			x = slot * 3.6
		"zigzag":
			x = slot * 3.0 + sin(t * TAU * 2.0) * 2.6 * (1.0 if i % 2 == 0 else -1.0)
		"serpent":
			x = slot * 1.8 + sin(t * TAU * 1.5) * (4.8 if n == 1 else 3.0)
		"cross":
			x = cos(t * TAU * 1.25) * 4.2 * (1.0 if i % 2 == 0 else -1.0)
		"fork":
			x = slot * 4.2 * smoothstep(0.15, 0.45, t)
		"converge":
			x = slot * 5.4 * (1.0 - smoothstep(0.1, 0.55, t)) + slot * 0.9
		"braid":
			x = sin(t * TAU * 2.0 + float(i) * TAU / n) * 3.6
		"spiral":
			var a := t * TAU * 1.6 + float(i) * TAU / n
			var rad := 4.6 * (1.0 - t * 0.6)
			x = cos(a) * rad
			z = lerpf(SPAWN_Z + 2.0, END_Z, t) + sin(a) * 2.2 * (1.0 - t)
	x = lerpf(x, slot * 0.7, converge)
	return Vector2(clampf(x, -HALF_W + 0.6, HALF_W - 0.6), z)

func _lanes() -> void:
	var n: int = realm.lanes
	var width: float = {"desert": 1.2, "ice": 1.8, "sunspire": 1.5, "keep": 1.6}.get(realm.biome, 1.4)
	for i in n:
		var pts := PackedVector3Array()
		var samples := 70
		for s in samples + 1:
			var p := _lane_fn(i, n, float(s) / samples)
			pts.append(Vector3(p.x, 0, p.y))
		pts.insert(0, Vector3(pts[0].x, 0, SPAWN_Z - 4.0))
		pts.append(Vector3(0, 0, BASTION.z - 0.8))
		var c := Curve3D.new()
		for p in pts:
			c.add_point(p)
		lanes.append(c)
		lane_points.append(pts)
		root.add_child(_strip(pts, width + 0.45, realm.lane.darkened(0.35), 0.01 + i * 0.003))
		root.add_child(_strip(pts, width, realm.lane, 0.014 + i * 0.003))
		root.add_child(_strip(pts, width * 0.3, realm.lane.lightened(0.12), 0.018 + i * 0.003))
	if realm.hazard == "mud_fog":
		for i in n:
			for k in 3:
				var t := 0.25 + k * 0.22 + rng.randf() * 0.05
				var p := lanes[i].sample_baked(lanes[i].get_baked_length() * t)
				mud_zones.append(p)
				_disc(p + Vector3(0, 0.03, 0), 1.3, Color("3a2a14"), 0.0)

## Build spots: beside the roads, spread out, never on a road.
func _pads() -> void:
	var cands: Array[Vector3] = []
	for c in lanes:
		var L := c.get_baked_length()
		var t := 0.16
		while t < 0.9:
			var p := c.sample_baked(L * t)
			var q := c.sample_baked(minf(L, L * t + 0.5))
			var dir := (q - p).normalized()
			var side := Vector3(-dir.z, 0, dir.x)
			for off in [-2.3, 2.3, -3.3, 3.3]:
				var cand: Vector3 = p + side * off
				if absf(cand.x) < HALF_W - 0.9 and cand.z > SPAWN_Z + 5.0 and cand.z < END_Z - 1.2 \
						and dist_to_lanes(cand) > 1.65 and cand.distance_to(BASTION) > 3.6:
					cands.append(cand)
			t += 0.05
	# deterministic shuffle, then greedy spacing
	for i in range(cands.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cands[i]; cands[i] = cands[j]; cands[j] = tmp
	var want: int = mini(11, 7 + int(realm.lanes))
	for cnd in cands:
		if pads.size() >= want: break
		var ok := true
		for p in pads:
			if p.distance_to(cnd) < 2.6:
				ok = false
				break
		if ok: pads.append(cnd)
	pads.sort_custom(func(a, b): return a.z > b.z)
	for p in pads:
		var n := Node3D.new()
		n.position = p
		root.add_child(n)
		pad_nodes.append(n)
		AssetLib._cyl(scen, 1.05, 1.15, 0.22, p + Vector3(0, 0.11, 0), Color("8a8478"), 0.0, 16)
		AssetLib._cyl(scen, 0.9, 0.9, 0.08, p + Vector3(0, 0.24, 0), Color("d8ceb8"), 0.0, 16)
		for k in 6:
			var ang := k * TAU / 6.0 + 0.3
			var st := AssetLib._box(scen, Vector3(0.3, 0.16, 0.22), p + Vector3(cos(ang) * 1.0, 0.3, sin(ang) * 1.0), Color("a89e8c"))
			st.rotation.y = -ang

func near_pad(p: Vector3, r: float) -> bool:
	for q in pads:
		if Vector2(q.x - p.x, q.z - p.z).length() < r: return true
	return false

## Where a barracks on this pad sends its soldiers: the nearest road point.
func rally_point(pad_pos: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var bd := 999.0
	for c in lanes:
		var p := c.get_closest_point(pad_pos)
		var d := p.distance_to(pad_pos)
		if d < bd and p.z < END_Z - 0.5:
			bd = d; best = p
	return Vector3(best.x, 0, best.z)

func _strip(pts: PackedVector3Array, w: float, col: Color, y: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pts.size() - 1:
		var a := pts[k]; var b := pts[k + 1]
		var dir := (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x) * w * 0.5
		var a1 := a - side + Vector3(0, y, 0); var a2 := a + side + Vector3(0, y, 0)
		var b1 := b - side + Vector3(0, y, 0); var b2 := b + side + Vector3(0, y, 0)
		for v in [a1, b1, a2, a2, b1, b2]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = AssetLib.mat(col)
	return mi

## Distance from a point to the nearest lane (for prop placement).
func dist_to_lanes(p: Vector3) -> float:
	var best := 999.0
	for c in lanes:
		best = minf(best, c.get_closest_point(p).distance_to(p))
	return best

func _disc(pos: Vector3, r: float, col: Color, emissive: float) -> MeshInstance3D:
	return AssetLib._cyl(scen, r, r, 0.04, pos, col, emissive, 20)

# ── Biome set pieces (one signature landmark per realm) ─────
func _set_pieces() -> void:
	match realm.biome:
		"ruins":  # the broken gate arch over the lanes
			for x in [-5.2, 5.2]:
				_prop_cyl(Vector3(x, 0, -10), 0.55, 4.5, Color("a8a090"))
			var lintel := _prop_box(Vector3(-2.8, 4.3, -10), Vector3(5.5, 0.8, 0.9), Color("a8a090"))
			lintel.rotation.z = -0.12
		"forest":
			for i in 6:
				var p := Vector3((-1.0 if i % 2 == 0 else 1.0) * rng.randf_range(4.5, 6.5), 0, -20 + i * 4.0)
				if not near_pad(p, 1.8) and dist_to_lanes(p) > 1.4: _tree(p, true)
		"swamp":
			for i in 5:
				var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-20, 0))
				if dist_to_lanes(p) > 2.0:
					_pond(p, rng.randf_range(1.2, 2.0), rng.randf() < 0.5)
		"keep":
			for x in [-6.4, 6.4]:
				_prop_box(Vector3(x * 1.12, 1.2, -9), Vector3(0.9, 2.4, 28), Color("9a96a0"))
				for z in [-20.0, -10.0, 0.0]:
					_prop_cyl(Vector3(x * 1.12, 0, z), 1.0, 3.6, Color("8a8694"))
					_cone(Vector3(x * 1.12, 3.6, z), 1.15, 1.4, Color("b0402a"))
					_sphere(Vector3(x, 4.0, z), 0.25, Color("ff8a3d"), 4.0)
		"rift":
			for i in 7:
				var s := _prop_crystal(Vector3(rng.randf_range(-6, 6), rng.randf_range(1.5, 3.5), rng.randf_range(-22, 0)), Color("a46aff"), rng.randf_range(0.6, 1.4))
				s.rotation = Vector3(rng.randf(), rng.randf(), rng.randf())
		"ice":
			_disc(_free_spot(Vector3(-4.5, 0.02, -12)), 2.2, Color("dff2ff"), 0.0)
			for i in 8:
				_prop_crystal(Vector3((-1.0 if i % 2 else 1.0) * rng.randf_range(4.5, 6.3), 0.6, -22 + i * 3.0), Color("bdf2ff"), rng.randf_range(0.6, 1.2))
		"desert":
			_pond(_free_spot(Vector3(4.6, 0, -6)), 1.8, true)  # oasis
			for i in 4:
				var ob := Vector3((-1.0 if i % 2 else 1.0) * 6.6, 0, -21 + i * 5.0)
				if not near_pad(ob, 1.5):
					_prop_box(ob + Vector3(0, 1.6, 0), Vector3(0.6, 3.2, 0.6), Color("e0b070")).rotation.y = 0.785
		"volcano":
			for i in 6:
				var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-22, 0))
				if dist_to_lanes(p) > 1.8:
					_disc(p, rng.randf_range(0.8, 1.6), Color("ff5a1a"), 3.0)
		"mire":
			for i in 7:
				var p := Vector3((-1.0 if i % 2 else 1.0) * rng.randf_range(4.2, 6.3), 0, -22 + i * 3.2)
				if near_pad(p, 1.6): continue
				_prop_cyl(p, 0.25, 2.2, Color("f0e6c8"))
				_sphere(p + Vector3(0, 2.3, 0), 1.0, Color("b04ad8")).scale = Vector3(1, 0.4, 1)
		"sunspire":
			_prop_cyl(Vector3(0, 0, -12), 1.2, 6.0, Color("e8d8a8"))
			_prop_crystal(Vector3(0, 7.2, -12), Color("fff0b0"), 1.6)
			for i in 6:
				var cp := Vector3((-1.0 if i % 2 else 1.0) * 6.4, 0, -22 + i * 4.2)
				if not near_pad(cp, 1.4): _prop_cyl(cp, 0.4, rng.randf_range(1.5, 3.5), Color("f0e2c0"))

func _scatter_props() -> void:
	var count := 34
	for i in count:
		var p := Vector3(rng.randf_range(-HALF_W - 3.0, HALF_W + 3.0), 0, rng.randf_range(-26, 3))
		if dist_to_lanes(p) < 1.5 or p.distance_to(BASTION) < 4.0 or near_pad(p, 1.6):
			continue
		var roll := rng.randf()
		match realm.biome:
			"ruins":
				if roll < 0.45: _tree(p, false)
				elif roll < 0.75: _rock(p, Color("9a948c"))
				else: _bush(p, Color("5aa83a"))
			"forest":
				if roll < 0.7: _tree(p, roll < 0.18, [Color("d8742a"), Color("c8a030"), Color("6a9a2a"), Color("b8452a")][rng.randi() % 4])
				else: _bush(p, Color("4f9a33"))
			"swamp":
				if roll < 0.4: _reeds(p)
				elif roll < 0.7: _disc(p + Vector3(0, 0.03, 0), rng.randf_range(0.4, 0.7), Color("6ab04a"), 0.0)
				else: _tree(p, false, Color("4a7a4a"))
			"keep":
				if roll < 0.5: _rock(p, Color("8d93a6"))
				else: _crate(p)
			"rift": _prop_crystal(p + Vector3(0, 0.3, 0), Color("b07aff"), rng.randf_range(0.4, 0.8))
			"ice":
				if roll < 0.65: _pine(p, true)
				else: _rock(p, Color("cfe0f0"))
			"desert":
				if roll < 0.45: _cactus(p)
				else: _rock(p, Color("d8a860"))
			"volcano":
				if roll < 0.7: _rock(p, Color("4a3a36"))
				else: _disc(p + Vector3(0, 0.03, 0), rng.randf_range(0.4, 0.8), Color("ff6a1a"), 2.0)
			"mire":
				if roll < 0.6: _mushroom(p)
				else: _bush(p, Color("6aa83a"))
			"sunspire":
				if roll < 0.5: _prop_cyl(p, 0.3, rng.randf_range(0.6, 1.8), Color("f0e2c0"))
				else: _bush(p, Color("8ac04a"))

func _rock(p: Vector3, col: Color) -> void:
	var r := rng.randf_range(0.35, 0.7)
	var n := _sphere(p + Vector3(0, r * 0.3, 0), r, col.lerp(col.darkened(0.2), rng.randf()))
	n.scale = Vector3(1.2, 0.65, 1.0)
	n.rotation.y = rng.randf() * TAU

func _bush(p: Vector3, col: Color) -> void:
	for k in 3:
		_sphere(p + Vector3(k * 0.28 - 0.28, 0.25, (k % 2) * 0.2), 0.32 + (k % 2) * 0.08, col.lightened(k * 0.06))
	if rng.randf() < 0.5:
		_sphere(p + Vector3(0.1, 0.55, 0.15), 0.07, [Color("ff5a7a"), Color("ffe08a"), Color("ffffff")][rng.randi() % 3])

func _reeds(p: Vector3) -> void:
	for k in 4:
		_prop_cyl(p + Vector3(k * 0.12 - 0.2, 0, (k % 2) * 0.12), 0.04, rng.randf_range(0.7, 1.2), Color("6a8a3a"))

func _crate(p: Vector3) -> void:
	_prop_box(p + Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.6), Color("a8703c")).rotation.y = rng.randf() * TAU

func _pine(p: Vector3, snow: bool) -> void:
	_prop_cyl(p, 0.12, 0.5, Color("6a4428"))
	for k in 3:
		_cone(p + Vector3(0, 0.35 + k * 0.42, 0), 0.75 - k * 0.18, 0.8, Color("f0f6ff") if (snow and k == 2) else Color("2f7a4a").lightened(k * 0.06))

func _cactus(p: Vector3) -> void:
	var col := Color("5aa83a")
	_prop_cyl(p, 0.2, 1.2, col)
	_sphere(p + Vector3(0, 1.2, 0), 0.2, col)
	_prop_cyl(p + Vector3(0.3, 0.5, 0), 0.12, 0.45, col)
	_sphere(p + Vector3(0.3, 0.95, 0), 0.12, col)
	_sphere(p + Vector3(0, 1.42, 0), 0.08, Color("ff5a7a"))

func _mushroom(p: Vector3) -> void:
	var h := rng.randf_range(0.5, 1.1)
	_prop_cyl(p, 0.1, h, Color("f0e6c8"))
	var cap := _sphere(p + Vector3(0, h, 0), h * 0.45, [Color("b04ad8"), Color("e8452c"), Color("9be24d")][rng.randi() % 3])
	cap.scale = Vector3(1.2, 0.55, 1.2)

# ── Mountains around the battlefield (every biome has its own) ──
func _mountains() -> void:
	var rock: Color = {"ruins": Color("8a9a7a"), "forest": Color("5f8a4a"), "swamp": Color("5a7a6a"), "keep": Color("8d8a9a"),
		"rift": Color("6a4a9a"), "ice": Color("a8c0dc"), "desert": Color("b0703a"), "volcano": Color("5a4440"),
		"mire": Color("4f7a3a"), "sunspire": Color("e0c890")}.get(realm.biome, Color("8a9a7a"))
	var cap: Color = {"ice": Color("ffffff"), "volcano": Color("ff6a1a"), "rift": Color("d8a8ff"), "desert": Color("e8a050"),
		"sunspire": Color("fff0c0"), "forest": Color("3f8a34"), "mire": Color("8ac04a")}.get(realm.biome, Color("f4f8ff"))
	var spots: Array[Vector3] = []
	for i in 9:
		spots.append(Vector3(-16.0 + i * 4.0 + rng.randf_range(-0.8, 0.8), 0, -36.0 - rng.randf_range(0, 3)))
	for side in [-1.0, 1.0]:
		for k in 4:
			spots.append(Vector3(side * rng.randf_range(15.5, 18.0), 0, -30.0 + k * 6.0))
	for p in spots:
		var h := rng.randf_range(5.0, 9.0) * (1.0 if p.z < -33.0 else 0.8)
		var r := h * rng.randf_range(0.55, 0.75)
		var col := rock.lerp(rock.darkened(0.25), rng.randf())
		_cone(p, r, h, col, 7).rotation.y = rng.randf() * TAU
		_cone(p + Vector3(r * 0.4, 0, r * 0.3), r * 0.6, h * 0.6, col.lightened(0.08), 7)
		var capm := AssetLib._cyl(scen, 0.0, r * 0.32, h * 0.3, p + Vector3(0, h * 0.85, 0), cap, 1.5 if realm.biome == "volcano" else 0.0, 7)
		capm.rotation.y = rng.randf() * TAU

# ── Set dressing: carts, boats, fences, barrels, wells, flowers… ──
func _free_spot(want: Vector3) -> Vector3:
	var p := want
	for k in 12:
		if dist_to_lanes(p) > 2.6 and not near_pad(p, 2.4):
			return p
		p = want + Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3))
	return p

func _spot(min_lane := 1.6) -> Vector3:
	for k in 20:
		var p := Vector3(rng.randf_range(-HALF_W - 2.5, HALF_W + 2.5), 0, rng.randf_range(-25, 2.5))
		if dist_to_lanes(p) > min_lane and not near_pad(p, 1.7) and p.distance_to(BASTION) > 4.2:
			return p
	return Vector3.INF

func _dressing() -> void:
	var b: String = realm.biome
	var plan: Dictionary = {
		"ruins": {"cart": 2, "fence": 3, "barrel": 3, "hay": 3, "well": 1, "pond": 1, "flowers": 10, "grass": 18, "sign": 1},
		"forest": {"log": 4, "cart": 1, "pond": 1, "flowers": 8, "grass": 16, "fence": 1, "hay": 1},
		"swamp": {"pond": 3, "log": 3, "sign": 1, "grass": 12, "barrel": 2},
		"keep": {"cart": 2, "barrel": 5, "tent": 2, "sign": 2, "fence": 2, "lamp": 3},
		"rift": {"pillar": 5, "lamp": 2, "grass": 6},
		"ice": {"snowman": 2, "cart": 1, "pond": 1, "barrel": 2, "fence": 1},
		"desert": {"tent": 3, "cart": 2, "vase": 5, "pond": 1, "sign": 1},
		"volcano": {"cart": 2, "barrel": 3, "lavapool": 3, "sign": 1},
		"mire": {"pond": 2, "log": 4, "grass": 10, "lamp": 2},
		"sunspire": {"statue": 3, "pillar": 4, "flowers": 12, "grass": 10, "lamp": 2},
	}.get(b, {})
	for kind in plan:
		for k in int(plan[kind]):
			var p := _spot(2.4 if kind in ["pond", "cart", "tent", "well", "statue"] else 1.6)
			if p == Vector3.INF: continue
			match kind:
				"cart": _cart(p)
				"fence": _fence(p)
				"barrel": _barrel(p)
				"hay": _hay(p)
				"well": _well(p)
				"pond": _pond(p, rng.randf_range(1.1, 1.6), true)
				"flowers": _flowers(p)
				"grass": _grass(p)
				"sign": _signpost(p)
				"log": _log(p)
				"tent": _tent(p)
				"lamp": _lamp(p)
				"pillar": _pillar(p)
				"snowman": _snowman(p)
				"vase": _vase(p)
				"lavapool": _disc(p + Vector3(0, 0.03, 0), rng.randf_range(0.6, 1.0), Color("ff6a1a"), 2.5)
				"statue": _statue(p)

func _cart(p: Vector3) -> void:
	var yaw := rng.randf() * TAU
	var piv := Node3D.new()
	piv.position = p
	piv.rotation.y = yaw
	scen.add_child(piv)
	var wood := Color("a8703c")
	AssetLib._box(piv, Vector3(1.3, 0.35, 0.8), Vector3(0, 0.6, 0), wood)
	AssetLib._box(piv, Vector3(1.3, 0.3, 0.06), Vector3(0, 0.88, 0.38), wood.darkened(0.15))
	AssetLib._box(piv, Vector3(1.3, 0.3, 0.06), Vector3(0, 0.88, -0.38), wood.darkened(0.15))
	for x in [-0.4, 0.4]:
		for z in [-0.48, 0.48]:
			var w := AssetLib._cyl(piv, 0.32, 0.32, 0.1, Vector3(x, 0.32, z), Color("6b4423"), 0.0, 12)
			w.rotation.x = PI / 2
			AssetLib._cyl(piv, 0.1, 0.1, 0.12, Vector3(x, 0.32, z), Color("3a3e48"), 0.0, 8).rotation.x = PI / 2
	for s in [-1.0, 1.0]:
		AssetLib._box(piv, Vector3(0.9, 0.06, 0.06), Vector3(1.05, 0.5, s * 0.25), wood.darkened(0.2))
	var load_col: Color = [Color("f0c84a"), Color("c8a070"), Color("e8452c")][rng.randi() % 3]
	for k in 3:
		AssetLib._ball(piv, 0.26, Vector3(-0.35 + k * 0.35, 0.95, 0), load_col.lerp(Color.WHITE, k * 0.1))

func _boat(p: Vector3) -> void:
	var piv := Node3D.new()
	piv.position = p
	piv.rotation.y = rng.randf() * TAU
	scen.add_child(piv)
	AssetLib._ball(piv, 0.6, Vector3(0, 0.1, 0), Color("8a5a2e"), 0.0, Vector3(1.5, 0.45, 0.7))
	AssetLib._box(piv, Vector3(1.4, 0.06, 0.6), Vector3(0, 0.3, 0), Color("c8945a"))
	AssetLib._cyl(piv, 0.03, 0.03, 1.2, Vector3(0, 0.9, 0), Color("6b4423"), 0.0, 6)
	AssetLib._box(piv, Vector3(0.04, 0.7, 0.6), Vector3(0.05, 1.0, 0), Color("f4ead2"))
	AssetLib._box(piv, Vector3(0.05, 0.16, 0.3), Vector3(0.05, 1.5, 0.15), realm.accent)

func _pond(p: Vector3, r: float, with_boat: bool) -> void:
	var water: Color = {"swamp": Color("3f8a8a"), "mire": Color("4a7a5a"), "ice": Color("bfe6ff"), "desert": Color("3ab0d8")}.get(realm.biome, Color("4aa0d8"))
	_disc(p + Vector3(0, 0.02, 0), r + 0.25, Color("c8a870") if realm.biome != "ice" else Color("f0f8ff"), 0.0)
	_disc(p + Vector3(0, 0.04, 0), r, water, 0.0)
	_disc(p + Vector3(r * 0.3, 0.05, -r * 0.2), r * 0.25, water.lightened(0.3), 0.0)
	for k in 4:
		var a := rng.randf() * TAU
		_sphere(p + Vector3(cos(a) * (r + 0.2), 0.12, sin(a) * (r + 0.2)), 0.22, Color("9a948c"))
	if with_boat and r > 1.0:
		_boat(p + Vector3(rng.randf_range(-0.3, 0.3), 0.05, rng.randf_range(-0.3, 0.3)))
	else:
		_disc(p + Vector3(-r * 0.3, 0.06, r * 0.3), 0.25, Color("5aa83a"), 0.0)

func _fence(p: Vector3) -> void:
	var yaw := rng.randf() * PI
	var dir := Vector3(cos(yaw), 0, sin(yaw))
	for k in 4:
		_prop_cyl(p + dir * (k * 0.6), 0.06, 0.6, Color("8a5a2e"))
	for y in [0.3, 0.5]:
		var r := AssetLib._box(scen, Vector3(1.9, 0.07, 0.05), p + dir * 0.9 + Vector3(0, y, 0), Color("a8703c"))
		r.rotation.y = -yaw

func _barrel(p: Vector3) -> void:
	for k in rng.randi_range(1, 3):
		var q := p + Vector3(k * 0.45, 0, (k % 2) * 0.3)
		AssetLib._cyl(scen, 0.22, 0.24, 0.55, q + Vector3(0, 0.28, 0), Color("a8703c"), 0.0, 10)
		for y in [0.12, 0.44]:
			AssetLib._cyl(scen, 0.245, 0.245, 0.05, q + Vector3(0, y, 0), Color("4a4e58"), 0.0, 10)

func _hay(p: Vector3) -> void:
	AssetLib._cyl(scen, 0.45, 0.5, 0.55, p + Vector3(0, 0.28, 0), Color("f0c84a"), 0.0, 12)
	_sphere(p + Vector3(0, 0.55, 0), 0.42, Color("e8b83a")).scale = Vector3(1, 0.5, 1)

func _well(p: Vector3) -> void:
	AssetLib._cyl(scen, 0.6, 0.65, 0.5, p + Vector3(0, 0.25, 0), Color("a8a090"), 0.0, 12)
	_disc(p + Vector3(0, 0.51, 0), 0.45, Color("2a4a6a"), 0.0)
	for s in [-1.0, 1.0]:
		_prop_cyl(p + Vector3(s * 0.55, 0, 0), 0.05, 1.3, Color("8a5a2e"))
	_cone(p + Vector3(0, 1.25, 0), 0.85, 0.5, Color("b0402a"), 4).rotation.y = PI / 4

func _flowers(p: Vector3) -> void:
	var cols := [Color("ff5a7a"), Color("ffe08a"), Color("ffffff"), Color("b07aff"), Color("ff8a2a")]
	for k in 5:
		var q := p + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
		_prop_cyl(q, 0.02, 0.22, Color("3f8a34"))
		_sphere(q + Vector3(0, 0.25, 0), 0.07, cols[rng.randi() % cols.size()])

func _grass(p: Vector3) -> void:
	var g: Color = realm.ground.lightened(0.12)
	for k in 4:
		var c := _cone(p + Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25)), 0.06, rng.randf_range(0.25, 0.4), g, 4)
		c.rotation.z = rng.randf_range(-0.3, 0.3)

func _signpost(p: Vector3) -> void:
	_prop_cyl(p, 0.06, 1.1, Color("8a5a2e"))
	var b := AssetLib._box(scen, Vector3(0.8, 0.26, 0.06), p + Vector3(0.2, 0.95, 0), Color("c8945a"))
	b.rotation.y = rng.randf() * TAU

func _log(p: Vector3) -> void:
	var l := AssetLib._cyl(scen, 0.22, 0.22, 1.4, p + Vector3(0, 0.22, 0), Color("8a5a2e"), 0.0, 10)
	l.rotation = Vector3(0, rng.randf() * TAU, PI / 2)

func _tent(p: Vector3) -> void:
	var col: Color = [Color("e8452c"), Color("3a6ab0"), Color("f0e2c0")][rng.randi() % 3]
	var t := _cone(p, 1.0, 1.4, col, 6)
	t.rotation.y = rng.randf() * TAU
	_prop_cyl(p + Vector3(0, 1.3, 0), 0.03, 0.5, Color("6b4423"))
	AssetLib._box(scen, Vector3(0.3, 0.18, 0.02), p + Vector3(0.16, 1.7, 0), realm.accent)

func _lamp(p: Vector3) -> void:
	_prop_cyl(p, 0.06, 1.4, Color("3a3e48"))
	_sphere(p + Vector3(0, 1.5, 0), 0.16, realm.accent.lightened(0.3), 2.0)

func _pillar(p: Vector3) -> void:
	var h := rng.randf_range(0.8, 2.2)
	_prop_cyl(p, 0.32, h, Color("d8ceb8") if realm.biome == "sunspire" else Color("8a7aa8"))
	AssetLib._box(scen, Vector3(0.8, 0.18, 0.8), p + Vector3(0, h, 0), Color("c8bea8") if realm.biome == "sunspire" else Color("7a6a98"))

func _snowman(p: Vector3) -> void:
	_sphere(p + Vector3(0, 0.35, 0), 0.38, Color("ffffff"))
	_sphere(p + Vector3(0, 0.85, 0), 0.27, Color("ffffff"))
	_sphere(p + Vector3(0, 1.2, 0), 0.19, Color("ffffff"))
	_cone(p + Vector3(0, 1.2, 0.17), 0.04, 0.2, Color("ff8a2a"), 6).rotation.x = PI / 2
	AssetLib._cyl(scen, 0.14, 0.14, 0.22, p + Vector3(0, 1.42, 0), Color("2a2e38"), 0.0, 10)

func _vase(p: Vector3) -> void:
	_sphere(p + Vector3(0, 0.3, 0), 0.3, Color("c87a3a")).scale = Vector3(1, 1.1, 1)
	AssetLib._cyl(scen, 0.14, 0.16, 0.2, p + Vector3(0, 0.66, 0), Color("b06a2a"), 0.0, 10)

func _statue(p: Vector3) -> void:
	AssetLib._box(scen, Vector3(0.9, 0.5, 0.9), p + Vector3(0, 0.25, 0), Color("c8bea8"))
	_sphere(p + Vector3(0, 0.95, 0), 0.32, Color("e8dcc0")).scale = Vector3(1, 1.4, 0.9)
	_sphere(p + Vector3(0, 1.5, 0), 0.22, Color("e8dcc0"))
	AssetLib._cyl(scen, 0.02, 0.02, 1.0, p + Vector3(0.32, 1.2, 0), Color("ffcf3d"), 0.0, 6)

# ── Weather particles (cheap CPU particles, ~70 quads) ──────
func _weather() -> void:
	var w: String = realm.weather
	var cfg := {
		"dust": [Color(1, 0.9, 0.8, 0.5), Vector3(0.3, -0.1, 0.2), 0.06],
		"embers": [Color(1.0, 0.5, 0.15), Vector3(0, 0.6, 0.1), 0.07],
		"fireflies": [Color(0.8, 1.0, 0.4), Vector3(0, 0.05, 0), 0.06],
		"rain": [Color(0.7, 0.75, 0.9, 0.6), Vector3(0.5, -14.0, 0.5), 0.05],
		"void": [Color(0.7, 0.4, 1.0), Vector3(0, 0.4, 0), 0.08],
		"snow": [Color(1, 1, 1), Vector3(0.6, -1.5, 0.3), 0.08],
		"sand": [Color(0.95, 0.8, 0.5, 0.7), Vector3(5.0, -0.3, 1.0), 0.05],
		"ash": [Color(0.4, 0.38, 0.38), Vector3(0.2, -0.8, 0.1), 0.07],
		"spores": [Color(0.7, 1.0, 0.3), Vector3(0, 0.3, 0), 0.08],
		"motes": [Color(1, 0.95, 0.7), Vector3(0, 0.5, 0), 0.07],
	}
	if not cfg.has(w):
		return
	var c: Array = cfg[w]
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(c[2], c[2] * (6.0 if w == "rain" else 1.0))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c[0]
	m.vertex_color_use_as_albedo = false
	q.material = m
	p.mesh = q
	p.amount = 90 if w in ["rain", "snow", "sand"] else 60
	p.lifetime = 0.9 if w == "rain" else 5.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(9, 4, 16)
	p.position = Vector3(0, 4.5, -9)
	p.direction = c[1].normalized() if c[1].length() > 0 else Vector3.UP
	p.spread = 25.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = c[1].length() * 0.6
	p.initial_velocity_max = c[1].length() * 1.2 + 0.2
	p.preprocess = 4.0
	root.add_child(p)

# ── prop primitives (each is a GLB slot) ────────────────────
func _slot(name: String) -> Node3D:
	var id := "prop_%s_%s" % [realm.biome, name]
	if AssetLib.has_model(id):
		return AssetLib.make(id, "", Color.WHITE, 2.0)
	return null

func _place(n: Node3D, pos: Vector3) -> Node3D:
	n.position = pos
	scen.add_child(n)
	return n

func _prop_box(pos: Vector3, size: Vector3, col: Color) -> Node3D:
	return AssetLib._box(scen, size, pos, col)

func _prop_cyl(base: Vector3, r: float, h: float, col: Color) -> Node3D:
	return AssetLib._cyl(scen, r * 0.85, r, h, base + Vector3(0, h / 2.0, 0), col)

func _sphere(pos: Vector3, r: float, col: Color, e := 0.0) -> Node3D:
	return AssetLib._ball(scen, r, pos, col, e)

func _cone(base: Vector3, r: float, h: float, col: Color, seg := 10) -> Node3D:
	return AssetLib._cyl(scen, 0.0, r, h, base + Vector3(0, h / 2.0, 0), col, 0.0, seg)

func _prop_crystal(pos: Vector3, col: Color, s: float) -> Node3D:
	var custom := _slot("crystal")
	if custom: return _place(custom, pos)
	return AssetLib._cyl(scen, 0.0, 0.35 * s, 1.4 * s, pos, col, 1.2, 4)

func _tree(base: Vector3, burning: bool, leaf := Color("3f9a34")) -> void:
	var custom := _slot("tree")
	if custom:
		_place(custom, base)
		return
	var h := rng.randf_range(1.6, 2.4)
	_prop_cyl(base, 0.16, h * 0.55, Color("7a4a24"))
	var top := base + Vector3(0, h * 0.75, 0)
	var col := leaf.lerp(leaf.lightened(0.2), rng.randf())
	_sphere(top, h * 0.36, col)
	_sphere(top + Vector3(h * 0.22, -h * 0.1, h * 0.05), h * 0.24, col.darkened(0.1))
	_sphere(top + Vector3(-h * 0.2, -h * 0.05, -h * 0.08), h * 0.26, col.lightened(0.08))
	if burning:
		_sphere(top + Vector3(0, h * 0.28, 0), h * 0.16, Color("ff7a2a"), 2.5)
