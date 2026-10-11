extends Node
const ModelRig := preload("res://scripts/game/model_rig.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## AssetLib — the bridge between the AI asset pipeline and the game.
##
## make("pyre_knight", ...) looks for res://assets/models/pyre_knight.glb.
## Found → it is instanced, auto-scaled to the gameplay height and its
## Mixamo animations are wired up. Missing → a low-poly placeholder is built
## so the game is always playable while art is still in production.

const MODEL_DIR := "res://assets/models/"
const ModelRigScript := preload("res://scripts/game/model_rig.gd")

var _mats: Dictionary = {}

func has_model(id: String) -> bool:
	var path := MODEL_DIR + id + ".glb"
	return FileAccess.file_exists(path) or ResourceLoader.exists(path)

## Loads a GLB. Raw file first (works right after dropping it in, even before
## the editor imports it); falls back to the imported scene in exported builds.
func _load_glb(path: String) -> Node3D:
	if FileAccess.file_exists(path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) == OK:
			var n := doc.generate_scene(state)
			if n is Node3D:
				return n
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path)
		return packed.instantiate() as Node3D
	return null

func mat(color: Color, emissive := 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), emissive]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emissive
	_mats[key] = m
	return m

## kind: warden | melee | ranged | tower | support | golem | wolf | queen
##       runner | brute | flyer | caster | boss | bastion
func make(id: String, kind: String, color: Color, height: float, evolved := false) -> ModelRig:
	var rig: ModelRig = ModelRigScript.new()
	rig.name = id
	if has_model(id):
		var inst := _load_glb(MODEL_DIR + id + ".glb")
		if inst:
			rig.setup_glb(inst, height * (1.15 if evolved else 1.0))
			return rig
	var body := Node3D.new()
	body.name = "Body"
	rig.add_child(body)
	var wings: Array[Node3D] = []
	match kind:
		"warden": _humanoid(body, Color("ffbf5e"), height, "bow", true)
		"melee": _humanoid(body, color, height, "sword", false)
		"ranged": _humanoid(body, color, height, "bow", false)
		"support": _humanoid(body, color, height, "staff", false)
		"queen": _humanoid(body, color, height, "crown", false)
		"tower": _tower(body, color, height)
		"golem": _golem(body, color, height)
		"wolf": _wolf(body, color, height)
		"runner": _runner(body, color, height)
		"brute": _brute(body, color, height)
		"flyer": wings = _flyer(body, color, height)
		"caster": _caster(body, color, height)
		"boss": _boss(body, color, height)
		"bastion": _bastion(body, height)
		_: _box(body, Vector3(0.6, height, 0.6), Vector3(0, height / 2, 0), color)
	if evolved:
		body.scale = Vector3.ONE * 1.15
		_sphere(body, 0.12, Vector3(0, height * 1.05, 0), Color("ffe6a6"), 3.0)
	rig.setup_placeholder(body, wings)
	return rig

# ── primitive helpers ───────────────────────────────────────
func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, emissive := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat(color, emissive)
	parent.add_child(mi)
	return mi

func _box(p: Node3D, size: Vector3, pos: Vector3, c: Color, e := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new(); m.size = size
	return _mesh(p, m, pos, c, e)

func _sphere(p: Node3D, r: float, pos: Vector3, c: Color, e := 0.0) -> MeshInstance3D:
	var m := SphereMesh.new(); m.radius = r; m.height = r * 2.0
	m.radial_segments = 12; m.rings = 6
	return _mesh(p, m, pos, c, e)

func _capsule(p: Node3D, r: float, h: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var m := CapsuleMesh.new(); m.radius = r; m.height = h
	m.radial_segments = 12; m.rings = 4
	return _mesh(p, m, pos, c)

func _cyl(p: Node3D, top: float, bottom: float, h: float, pos: Vector3, c: Color, e := 0.0, seg := 10) -> MeshInstance3D:
	var m := CylinderMesh.new(); m.top_radius = top; m.bottom_radius = bottom; m.height = h
	m.radial_segments = seg; m.rings = 1
	return _mesh(p, m, pos, c, e)

# ── placeholder archetypes ──────────────────────────────────
func _humanoid(b: Node3D, c: Color, h: float, prop: String, hero: bool) -> void:
	var skin := Color("f2c9a0")
	_capsule(b, h * 0.2, h * 0.62, Vector3(0, h * 0.36, 0), c)
	_sphere(b, h * 0.15, Vector3(0, h * 0.8, 0), skin)
	_box(b, Vector3(h * 0.07, h * 0.05, h * 0.05), Vector3(-h * 0.06, h * 0.82, h * 0.13), Color("1b1b2b"))
	_box(b, Vector3(h * 0.07, h * 0.05, h * 0.05), Vector3(h * 0.06, h * 0.82, h * 0.13), Color("1b1b2b"))
	match prop:
		"sword":
			_box(b, Vector3(h * 0.06, h * 0.55, h * 0.04), Vector3(h * 0.28, h * 0.5, h * 0.08), Color("cdd6ea"))
			_box(b, Vector3(h * 0.05, h * 0.32, h * 0.26), Vector3(-h * 0.26, h * 0.42, h * 0.05), c.darkened(0.25))
			_box(b, Vector3(h * 0.3, h * 0.08, h * 0.3), Vector3(0, h * 0.93, 0), c.darkened(0.3))
		"bow":
			var tor := TorusMesh.new(); tor.inner_radius = h * 0.24; tor.outer_radius = h * 0.28
			tor.rings = 12; tor.ring_segments = 6
			var bow := _mesh(b, tor, Vector3(h * 0.28, h * 0.5, 0.0), Color("ffe6a6") if hero else Color("8a6a4a"), 1.2 if hero else 0.0)
			bow.rotation = Vector3(0, 0, PI / 2)
			bow.scale = Vector3(1, 1, 0.35)
		"staff":
			_cyl(b, h * 0.025, h * 0.025, h * 0.95, Vector3(h * 0.27, h * 0.48, 0), Color("8a6a4a"))
			_sphere(b, h * 0.08, Vector3(h * 0.27, h * 0.98, 0), Color("54e08a"), 2.0)
		"crown":
			_cyl(b, h * 0.13, h * 0.11, h * 0.1, Vector3(0, h * 0.97, 0), Color("ffbf5e"), 1.0, 6)
			_sphere(b, h * 0.09, Vector3(h * 0.3, h * 0.55, 0), Color("ff8a3d"), 2.5)
	if hero:
		var cape := _box(b, Vector3(h * 0.36, h * 0.5, h * 0.04), Vector3(0, h * 0.42, -h * 0.17), Color("f25a2a"))
		cape.rotation.x = 0.15
		_cyl(b, h * 0.17, h * 0.17, h * 0.07, Vector3(0, h * 0.92, 0), Color("ff8a3d"), 0.0, 8)

func _tower(b: Node3D, c: Color, h: float) -> void:
	_cyl(b, h * 0.32, h * 0.38, h * 0.25, Vector3(0, h * 0.125, 0), Color("40598f"))
	var crystal := _cyl(b, 0.0, h * 0.2, h * 0.4, Vector3(0, h * 0.55, 0), c, 1.5, 4)
	var top := _cyl(b, h * 0.2, 0.0, h * 0.25, Vector3(0, h * 0.875, 0), c, 1.5, 4)
	crystal.rotation.y = PI / 4
	top.rotation.y = PI / 4

func _golem(b: Node3D, c: Color, h: float) -> void:
	_box(b, Vector3(h * 0.7, h * 0.7, h * 0.5), Vector3(0, h * 0.45, 0), c)
	_box(b, Vector3(h * 0.38, h * 0.26, h * 0.34), Vector3(0, h * 0.92, 0), c.darkened(0.1))
	_box(b, Vector3(h * 0.22, h * 0.6, h * 0.22), Vector3(-h * 0.48, h * 0.4, 0), c.darkened(0.15))
	_box(b, Vector3(h * 0.22, h * 0.6, h * 0.22), Vector3(h * 0.48, h * 0.4, 0), c.darkened(0.15))
	_sphere(b, h * 0.08, Vector3(0, h * 0.55, h * 0.26), Color("8fe9ff"), 2.5)

func _wolf(b: Node3D, c: Color, h: float) -> void:
	_box(b, Vector3(h * 0.45, h * 0.4, h * 0.95), Vector3(0, h * 0.45, 0), c)
	_box(b, Vector3(h * 0.35, h * 0.32, h * 0.4), Vector3(0, h * 0.65, h * 0.55), c.lightened(0.1))
	for x in [-0.15, 0.15]:
		for z in [-0.3, 0.3]:
			_box(b, Vector3(h * 0.1, h * 0.3, h * 0.1), Vector3(h * x, h * 0.15, h * z), c.darkened(0.3))
	_sphere(b, h * 0.04, Vector3(h * 0.09, h * 0.72, h * 0.76), Color("ff5470"), 3.0)
	_sphere(b, h * 0.04, Vector3(-h * 0.09, h * 0.72, h * 0.76), Color("ff5470"), 3.0)

func _eyes(b: Node3D, h: float, y: float, z: float, col := Color("ffcf4d")) -> void:
	_sphere(b, h * 0.06, Vector3(-h * 0.1, y, z), col, 3.0)
	_sphere(b, h * 0.06, Vector3(h * 0.1, y, z), col, 3.0)

func _runner(b: Node3D, c: Color, h: float) -> void:
	_capsule(b, h * 0.22, h * 0.85, Vector3(0, h * 0.45, 0), c)
	_eyes(b, h, h * 0.75, h * 0.2)

func _brute(b: Node3D, c: Color, h: float) -> void:
	_box(b, Vector3(h * 0.8, h * 0.75, h * 0.6), Vector3(0, h * 0.45, 0), c)
	_sphere(b, h * 0.2, Vector3(-h * 0.42, h * 0.75, 0), c.darkened(0.2))
	_sphere(b, h * 0.2, Vector3(h * 0.42, h * 0.75, 0), c.darkened(0.2))
	_eyes(b, h, h * 0.62, h * 0.31, Color("ff5470"))

func _flyer(b: Node3D, c: Color, h: float) -> Array[Node3D]:
	_sphere(b, h * 0.25, Vector3(0, h * 0.7, 0), c)
	_eyes(b, h, h * 0.75, h * 0.22)
	var out: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * h * 0.2, h * 0.72, 0)
		b.add_child(pivot)
		_box(pivot, Vector3(h * 0.5, h * 0.04, h * 0.3), Vector3(side * h * 0.25, 0, 0), c.darkened(0.3))
		out.append(pivot)
	return out

func _caster(b: Node3D, c: Color, h: float) -> void:
	_cyl(b, 0.0, h * 0.32, h * 0.95, Vector3(0, h * 0.48, 0), c, 0.0, 8)
	_sphere(b, h * 0.11, Vector3(0, h * 0.6, h * 0.16), Color("120818"))
	_eyes(b, h * 0.6, h * 0.62, h * 0.24, Color("d14bff"))
	_sphere(b, h * 0.1, Vector3(h * 0.32, h * 0.5, h * 0.1), Color("ff4d7d"), 2.5)

func _boss(b: Node3D, c: Color, h: float) -> void:
	_sphere(b, h * 0.45, Vector3(0, h * 0.5, 0), c)
	for i in 8:
		var a := float(i) / 8.0 * TAU
		var dir := Vector3(cos(a), 0.35, sin(a)).normalized()
		var spike := _cyl(b, 0.0, h * 0.1, h * 0.35, Vector3(0, h * 0.5, 0) + dir * h * 0.48, c.darkened(0.3), 0.0, 6)
		spike.basis = Basis(Quaternion(Vector3.UP, dir))
	_sphere(b, h * 0.15, Vector3(0, h * 0.55, h * 0.35), Color("ffbf5e"), 3.0)
	_eyes(b, h * 1.4, h * 0.8, h * 0.36, Color("ff5470"))

func _bastion(b: Node3D, h: float) -> void:
	var stone := Color("3a4a6e")
	_box(b, Vector3(h * 1.4, h * 0.15, h * 1.0), Vector3(0, h * 0.075, 0), Color("2c3c63"))
	_box(b, Vector3(h * 0.9, h * 0.75, h * 0.7), Vector3(0, h * 0.5, 0), stone)
	for x in [-1.0, 1.0]:
		_cyl(b, h * 0.22, h * 0.24, h * 1.0, Vector3(x * h * 0.55, h * 0.5, 0), stone.darkened(0.1))
		_cyl(b, 0.0, h * 0.28, h * 0.3, Vector3(x * h * 0.55, h * 1.15, 0), Color("8a1f4a"), 0.0, 8)
	for i in 4:
		_box(b, Vector3(h * 0.14, h * 0.14, h * 0.7), Vector3(-h * 0.33 + i * h * 0.22, h * 0.94, 0), stone.darkened(0.15))
	_box(b, Vector3(h * 0.26, h * 0.4, h * 0.05), Vector3(0, h * 0.35, h * 0.36), Color("0b0f1a"))
	_sphere(b, h * 0.13, Vector3(0, h * 1.1, 0), Color("ffbf5e"), 4.0)

# ── Portrait icons (rendered once, offscreen) ───────────────
var _icons: Dictionary = {}

func kind_for(def: Dictionary) -> String:
	match def.id:
		"boulder_golem": return "golem"
		"wolf_pack": return "wolf"
		"ashen_queen": return "queen"
	return def.role

## Returns a live ViewportTexture portrait of a champion (or "warden").
func icon(id: String, evolved := false) -> Texture2D:
	var key := "%s_%s" % [id, evolved]
	if _icons.has(key):
		return _icons[key]
	# Generated 2D portrait (ChatGPT image pipeline) wins over the 3D render.
	var painted := UIKit.art("portraits/%s.png" % id)
	if painted:
		_icons[key] = painted
		return painted
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 32
	vp.add_child(cam)
	cam.position = Vector3(0, 1.3, 4.6)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.4
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("8090c0")
	vp.add_child(env)
	var model: Node3D
	if id == "warden":
		model = make("warden", "warden", Color("ffbf5e"), 1.8)
	else:
		var def := GameData.champion(id)
		var h := 1.1 if id == "wolf_pack" else (2.0 if id == "boulder_golem" else 1.8)
		model = make(id, kind_for(def), def.color, h, evolved)
	model.rotation.y = 0.5
	vp.add_child(model)
	cam.look_at_from_position(cam.position, Vector3(0, 0.9, 0))
	var tex := vp.get_texture()
	_icons[key] = tex
	return tex
