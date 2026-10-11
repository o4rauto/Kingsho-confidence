extends RefCounted
class_name WorldBuilder
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
var rng := RandomNumberGenerator.new()

func build(r: Dictionary, parent: Node3D) -> void:
	realm = r
	root = parent
	rng.seed = hash(r.id)
	_environment()
	_ground()
	_lanes()
	_set_pieces()
	_scatter_props()
	_weather()

# ── Sky, light, fog ─────────────────────────────────────────
func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = realm.sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = realm.ambient
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = realm.fog
	env.fog_density = {"night": 0.03, "storm": 0.025, "toxic": 0.03, "void": 0.02, "lava": 0.02, "day": 0.005, "noon": 0.004, "dawn": 0.005}.get(realm.tod, 0.012)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = realm.sun
	sun.light_energy = {"night": 0.6, "storm": 0.7, "void": 0.7, "toxic": 0.8, "noon": 1.15, "day": 1.0, "dawn": 1.0}.get(realm.tod, 1.1)
	sun.rotation_degrees = Vector3(realm.sun_angle, -30.0 + rng.randf_range(-20, 20), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	root.add_child(sun)

# ── Ground ──────────────────────────────────────────────────
func _ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = {"desert": 0.02, "ice": 0.03, "volcano": 0.08}.get(realm.biome, 0.05)
	var ramp := Gradient.new()
	ramp.set_color(0, realm.ground2)
	ramp.set_color(1, realm.ground)
	var tex := NoiseTexture2D.new()
	tex.width = 256; tex.height = 256
	tex.noise = noise
	tex.color_ramp = ramp
	tex.seamless = true
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(7, 12, 1)
	m.roughness = 0.2 if realm.biome == "ice" else 0.95
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
		root.add_child(_strip(pts, width, realm.lane, 0.012 + i * 0.002))
		root.add_child(_strip(pts, width * 0.18, realm.lane.lightened(0.2), 0.02 + i * 0.002))
	if realm.hazard == "mud_fog":
		for i in n:
			for k in 3:
				var t := 0.25 + k * 0.22 + rng.randf() * 0.05
				var p := lanes[i].sample_baked(lanes[i].get_baked_length() * t)
				mud_zones.append(p)
				_disc(p + Vector3(0, 0.03, 0), 1.3, Color("3a2a14"), 0.0)

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
	var m := CylinderMesh.new()
	m.top_radius = r; m.bottom_radius = r; m.height = 0.04; m.radial_segments = 20
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = AssetLib.mat(col, emissive)
	mi.position = pos
	root.add_child(mi)
	return mi

# ── Biome set pieces (one signature landmark per realm) ─────
func _set_pieces() -> void:
	match realm.biome:
		"ruins":  # the broken gate arch over the lanes
			for x in [-5.2, 5.2]:
				_prop_cyl(Vector3(x, 0, -10), 0.55, 4.5, Color("6a6070"))
			var lintel := _prop_box(Vector3(-2.8, 4.3, -10), Vector3(5.5, 0.8, 0.9), Color("6a6070"))
			lintel.rotation.z = -0.12
		"forest":
			for i in 6:
				var p := Vector3((-1.0 if i % 2 == 0 else 1.0) * rng.randf_range(4.5, 6.5), 0, -20 + i * 4.0)
				_tree(p, true)
		"swamp":
			for i in 5:
				var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-20, 0))
				if dist_to_lanes(p) > 2.0:
					_disc(p, rng.randf_range(1.2, 2.2), Color("1a3a4a"), 0.3)
		"keep":
			for x in [-6.4, 6.4]:
				_prop_box(Vector3(x, 1.2, -9), Vector3(0.9, 2.4, 28), Color("4a4a5a"))
				for z in [-20.0, -10.0, 0.0]:
					_prop_cyl(Vector3(x, 0, z), 1.0, 3.6, Color("3a3a4a"))
					_sphere(Vector3(x, 4.0, z), 0.25, Color("ff8a3d"), 4.0)
		"rift":
			for i in 7:
				var s := _prop_crystal(Vector3(rng.randf_range(-6, 6), rng.randf_range(1.5, 3.5), rng.randf_range(-22, 0)), Color("a46aff"), rng.randf_range(0.6, 1.4))
				s.rotation = Vector3(rng.randf(), rng.randf(), rng.randf())
		"ice":
			_disc(Vector3(-4.5, 0.02, -12), 2.4, Color("cfe8ff"), 0.2)
			for i in 8:
				_prop_crystal(Vector3((-1.0 if i % 2 else 1.0) * rng.randf_range(4.5, 6.3), 0.6, -22 + i * 3.0), Color("bdf2ff"), rng.randf_range(0.6, 1.2))
		"desert":
			_disc(Vector3(4.6, 0.02, -6), 1.8, Color("3ab0c8"), 0.3)  # oasis
			for i in 4:
				_prop_box(Vector3((-1.0 if i % 2 else 1.0) * 5.8, 1.6, -21 + i * 5.0), Vector3(0.6, 3.2, 0.6), Color("c8a060")).rotation.y = 0.785
		"volcano":
			for i in 6:
				var p := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-22, 0))
				if dist_to_lanes(p) > 1.8:
					_disc(p, rng.randf_range(0.8, 1.6), Color("ff5a1a"), 3.0)
		"mire":
			for i in 7:
				var p := Vector3((-1.0 if i % 2 else 1.0) * rng.randf_range(4.2, 6.3), 0, -22 + i * 3.2)
				_prop_cyl(p, 0.25, 2.2, Color("d8d0b0"))
				_sphere(p + Vector3(0, 2.3, 0), 1.0, Color("7a3aa8"), 1.0).scale = Vector3(1, 0.4, 1)
		"sunspire":
			_prop_cyl(Vector3(0, 0, -12), 1.2, 6.0, Color("e8d8a8"))
			_prop_crystal(Vector3(0, 7.2, -12), Color("fff0b0"), 1.6)
			for i in 6:
				_prop_cyl(Vector3((-1.0 if i % 2 else 1.0) * 5.8, 0, -22 + i * 4.2), 0.4, rng.randf_range(1.5, 3.5), Color("d8c090"))

func _scatter_props() -> void:
	var count := 26
	for i in count:
		var p := Vector3(rng.randf_range(-HALF_W - 3.0, HALF_W + 3.0), 0, rng.randf_range(-26, 2))
		if dist_to_lanes(p) < 1.6 or p.distance_to(BASTION) < 4.0:
			continue
		match realm.biome:
			"ruins": _prop_box(p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7) * rng.randf_range(0.6, 1.4), Color("5a5060")).rotation.y = rng.randf() * TAU
			"forest": _tree(p, rng.randf() < 0.2)
			"swamp": _prop_cyl(p, 0.12, rng.randf_range(1.5, 2.8), Color("3a2e22"))
			"keep": _prop_box(p + Vector3(0, 0.25, 0), Vector3(0.5, 0.5, 0.5), Color("4a3a2a"))
			"rift": _prop_crystal(p + Vector3(0, 0.3, 0), Color("6a2aa8"), 0.5)
			"ice": _tree(p, false, Color("e8f4ff"))
			"desert": _sphere(p, rng.randf_range(0.8, 1.6), realm.ground).scale = Vector3(1.6, 0.35, 1.0)
			"volcano": _prop_box(p + Vector3(0, 0.3, 0), Vector3(0.8, 0.7, 0.8) * rng.randf_range(0.6, 1.6), Color("1a1414")).rotation.y = rng.randf() * TAU
			"mire": _sphere(p, rng.randf_range(0.3, 0.6), Color("9be24d"), 1.5)
			"sunspire": _prop_box(p + Vector3(0, 0.2, 0), Vector3(0.6, 0.4, 0.6), Color("d8c090")).rotation.y = rng.randf() * TAU

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
	root.add_child(n)
	return n

func _prop_box(pos: Vector3, size: Vector3, col: Color) -> Node3D:
	var m := BoxMesh.new(); m.size = size
	var mi := MeshInstance3D.new(); mi.mesh = m; mi.material_override = AssetLib.mat(col)
	return _place(mi, pos)

func _prop_cyl(base: Vector3, r: float, h: float, col: Color) -> Node3D:
	var m := CylinderMesh.new(); m.top_radius = r * 0.85; m.bottom_radius = r; m.height = h; m.radial_segments = 10
	var mi := MeshInstance3D.new(); mi.mesh = m; mi.material_override = AssetLib.mat(col)
	return _place(mi, base + Vector3(0, h / 2.0, 0))

func _sphere(pos: Vector3, r: float, col: Color, e := 0.0) -> Node3D:
	var m := SphereMesh.new(); m.radius = r; m.height = r * 2; m.radial_segments = 12; m.rings = 6
	var mi := MeshInstance3D.new(); mi.mesh = m; mi.material_override = AssetLib.mat(col, e)
	return _place(mi, pos)

func _prop_crystal(pos: Vector3, col: Color, s: float) -> Node3D:
	var custom := _slot("crystal")
	if custom: return _place(custom, pos)
	var m := CylinderMesh.new(); m.top_radius = 0.0; m.bottom_radius = 0.35 * s; m.height = 1.4 * s; m.radial_segments = 4
	var mi := MeshInstance3D.new(); mi.mesh = m; mi.material_override = AssetLib.mat(col, 1.2)
	return _place(mi, pos)

func _tree(base: Vector3, burning: bool, leaf := Color("2e6a2a")) -> void:
	var custom := _slot("tree")
	if custom:
		_place(custom, base)
		return
	var h := rng.randf_range(2.2, 3.4)
	_prop_cyl(base, 0.18, h * 0.4, Color("4a2e1a"))
	for k in 3:
		var m := CylinderMesh.new()
		m.top_radius = 0.0; m.bottom_radius = 1.0 - k * 0.22; m.height = h * 0.45; m.radial_segments = 8
		var mi := MeshInstance3D.new(); mi.mesh = m
		var col := leaf.darkened(k * 0.08)
		if burning and k == 2:
			mi.material_override = AssetLib.mat(Color("ff7a2a"), 2.5)
		else:
			mi.material_override = AssetLib.mat(col)
		_place(mi, base + Vector3(0, h * 0.4 + k * h * 0.22, 0))
