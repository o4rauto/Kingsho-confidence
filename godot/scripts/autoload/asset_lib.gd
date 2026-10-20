extends Node
const ModelRig := preload("res://scripts/game/model_rig.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## AssetLib — the bridge between the AI asset pipeline and the game.
##
## make("pyre_knight", ...) looks for res://assets/models/pyre_knight.glb.
## Found → it is instanced, auto-scaled to the gameplay height and its
## Mixamo animations are wired up. Missing → a hand-designed chibi character
## (big head, big eyes, brows, outline, toon shading) is built from parts and
## BAKED into a single vertex-coloured mesh: one draw call (+1 for the ink
## outline) per character, so crowds stay cheap on weak phones.

const MODEL_DIR := "res://assets/models/"
const ModelRigScript := preload("res://scripts/game/model_rig.gd")
const SKIN := Color("f6c9a0")
const INK := Color("1e1008")

var _mats: Dictionary = {}
var _bake_cache: Dictionary = {}
var _skip_static := false
var _dummy: MeshInstance3D
var _vc_mat: StandardMaterial3D

func _ready() -> void:
	_dummy = MeshInstance3D.new()

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
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emissive * 0.35
	_mats[key] = m
	return m

## Shared material for baked characters: vertex colours, toon light, ink outline.
func baked_mat() -> StandardMaterial3D:
	if _vc_mat == null:
		_vc_mat = StandardMaterial3D.new()
		_vc_mat.vertex_color_use_as_albedo = true
		_vc_mat.vertex_color_is_srgb = true
		_vc_mat.roughness = 1.0
		_vc_mat.metallic_specular = 0.0
		_vc_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		_vc_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		var ol := StandardMaterial3D.new()
		ol.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ol.cull_mode = BaseMaterial3D.CULL_FRONT
		ol.grow = true
		ol.grow_amount = 0.022
		ol.albedo_color = INK
		_vc_mat.next_pass = ol
	return _vc_mat

## Dá a um modelo 3D importado (GLB) a mesma linguagem visual dos personagens
## assados: luz toon + contorno de tinta por casco invertido. Sem isso o modelo
## fica sem contorno e some no meio da arte desenhada.
func aplicar_toon(n: Node, grossura := 0.03) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var base: Material = mi.mesh.surface_get_material(i)
				if base is StandardMaterial3D:
					var sm := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
					sm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
					sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
					sm.roughness = 1.0
					var ol := StandardMaterial3D.new()
					ol.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					ol.cull_mode = BaseMaterial3D.CULL_FRONT
					ol.grow = true
					ol.grow_amount = grossura
					ol.albedo_color = INK
					sm.next_pass = ol
					mi.set_surface_override_material(i, sm)
	for c in n.get_children():
		aplicar_toon(c, grossura)

## kind: warden | melee | ranged | tower | support | golem | wolf | queen
##       runner | brute | flyer | caster | boss | bastion
## Drawn (2D) art for a character id, or null.
func sprite_art(id: String) -> Texture2D:
	var alias := {"footman": "troop_militia", "bowman": "troop_bowmen"}
	return UIKit.art("portraits/%s.png" % alias.get(id, id))

var _shadow_mat: StandardMaterial3D
## Hand-drawn frame-by-frame animations: assets/art/anims/<id>/<anim>_<k>.png
## (anim = idle | walk | attack | cast | hit | die | fly). Missing ones fall
## back to the single drawing + procedural squash & stretch.
const ANIMS := ["idle", "walk", "attack", "cast", "hit", "die", "fly"]
var _frames_cache := {}
func anim_frames(id: String) -> Dictionary:
	if _frames_cache.has(id):
		return _frames_cache[id]
	var out := {}
	var alias := {"footman": "troop_militia", "bowman": "troop_bowmen"}
	var key: String = alias.get(id, id)
	for a in ANIMS:
		var list: Array[Texture2D] = []
		for k in 16:
			var t := UIKit.art("anims/%s/%s_%d.png" % [key, a, k])
			if t == null: break
			list.append(t)
		if not list.is_empty():
			out[a] = list
	_frames_cache[id] = out
	return out

func shadow_mat() -> StandardMaterial3D:
	if _shadow_mat == null:
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.albedo_color = Color(0.05, 0.03, 0.0, 0.32)
	return _shadow_mat

func make(id: String, kind: String, color: Color, height: float, evolved := false) -> ModelRig:
	var rig: ModelRig = ModelRigScript.new()
	rig.name = id
	var drawn := sprite_art(id)
	if drawn and not has_model(id):
		rig.setup_sprite(drawn, height * (1.35 if evolved else 1.2), shadow_mat(), anim_frames(id))
		return rig
	if has_model(id):
		var inst := _load_glb(MODEL_DIR + id + ".glb")
		if inst:
			rig.setup_glb(inst, height * (1.15 if evolved else 1.0))
			return rig
	var body := Node3D.new()
	body.name = "Body"
	rig.add_child(body)
	var key := "%s|%s|%s|%.2f|%s" % [id, kind, color.to_html(), height, evolved]
	var cached: ArrayMesh = _bake_cache.get(key)
	_skip_static = cached != null
	var wings := _build(id, kind, body, color, height, evolved)
	_skip_static = false
	if cached == null:
		cached = _bake(body)
		_bake_cache[key] = cached
	var mi := MeshInstance3D.new()
	mi.mesh = cached
	mi.material_override = baked_mat()
	body.add_child(mi)
	var limbs := {}
	_find_limbs(body, limbs)
	for ln in limbs:
		var lk: String = key + "|" + ln
		var lm: ArrayMesh = _bake_cache.get(lk)
		if lm == null:
			lm = _bake(limbs[ln])
			_bake_cache[lk] = lm
		var lmi := MeshInstance3D.new()
		lmi.mesh = lm
		lmi.material_override = baked_mat()
		limbs[ln].add_child(lmi)
	if evolved:
		body.scale = Vector3.ONE * 1.12
	rig.setup_placeholder(body, wings, limbs)
	return rig

func _find_limbs(n: Node, out: Dictionary) -> void:
	for c in n.get_children():
		if c.has_meta("limb"):
			out[c.get_meta("limb")] = c
		_find_limbs(c, out)

func _build(id: String, kind: String, body: Node3D, color: Color, h: float, evolved: bool) -> Array[Node3D]:
	var wings: Array[Node3D] = []
	match id:
		"warden": _hero(body, h, color)
		"pyre_knight": _knight(body, h, color, evolved)
		"thistle_archer": _archer(body, h, color, evolved)
		"sister_vale": _priestess(body, h, color, evolved)
		"wolf_pack": _wolf(body, h, color, evolved)
		"frost_warden": _ice_queen(body, h, color, evolved)
		"boulder_golem": _golem(body, h, color, evolved)
		"stormcaller": _wizard(body, h, color, evolved)
		"sunspear_lancer": _lancer(body, h, color, evolved)
		"ashen_queen": _queen(body, h, color, evolved)
		"runestone": _rune_sentinel(body, h, color, evolved)
		"footman": _footman(body, h, color)
		"bowman": _bowman(body, h, color)
		"bastion": _bastion(body, h)
		_:
			match kind:
				"runner": _imp(body, h, color, id)
				"brute": _ogre(body, h, color, false)
				"boss": _ogre(body, h, color, true)
				"flyer": wings = _bat(body, h, color)
				"caster": _hexer(body, h, color)
				"bastion": _bastion(body, h)
				_: _ball(body, h * 0.4, Vector3(0, h * 0.4, 0), color)
	return wings

# ── baking ──────────────────────────────────────────────────
func _bake(body: Node3D) -> ArrayMesh:
	var data := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(), "i": PackedInt32Array()}
	var doomed: Array = []
	_collect(body, Transform3D.IDENTITY, data, doomed)
	for d in doomed:
		d.get_parent().remove_child(d)
		d.free()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = data.v
	arr[Mesh.ARRAY_NORMAL] = data.n
	arr[Mesh.ARRAY_COLOR] = data.c
	arr[Mesh.ARRAY_INDEX] = data.i
	var m := ArrayMesh.new()
	if data.v.size() > 0:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

func _collect(n: Node, xf: Transform3D, data: Dictionary, doomed: Array) -> void:
	for c in n.get_children():
		if c.has_meta("dynamic") or c.has_meta("limb"):
			continue
		var cx: Transform3D = xf * (c as Node3D).transform if c is Node3D else xf
		_collect(c, cx, data, doomed)
		if c is MeshInstance3D and c.has_meta("bake"):
			var mesh: Mesh = (c as MeshInstance3D).mesh
			var a: Array = (mesh as PrimitiveMesh).get_mesh_arrays() if mesh is PrimitiveMesh else mesh.surface_get_arrays(0)
			var col: Color = c.get_meta("bake")
			var base: int = data.v.size()
			var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			var nb := cx.basis.inverse().transposed()
			for k in vs.size():
				data.v.append(cx * vs[k])
				data.n.append((nb * ns[k]).normalized())
				data.c.append(col)
			var ix = a[Mesh.ARRAY_INDEX]
			if ix == null or (ix as PackedInt32Array).is_empty():
				for k in vs.size(): data.i.append(base + k)
			else:
				for k in ix: data.i.append(base + k)
			doomed.append(c)

# ── primitive helpers (baked unless emissive or under a "dynamic" pivot) ──
func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, emissive := 0.0) -> MeshInstance3D:
	var dynamic_parent := parent.has_meta("dynamic")
	var bakeable := emissive <= 0.0 and not dynamic_parent
	if bakeable and _skip_static:
		return _dummy
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	if bakeable:
		mi.set_meta("bake", color)
	else:
		mi.material_override = mat(color, emissive)
	parent.add_child(mi)
	return mi

func _box(p: Node3D, size: Vector3, pos: Vector3, c: Color, e := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new(); m.size = size
	return _mesh(p, m, pos, c, e)

func _ball(p: Node3D, r: float, pos: Vector3, c: Color, e := 0.0, sc := Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new(); m.radius = r; m.height = r * 2.0
	m.radial_segments = 14; m.rings = 7
	var mi := _mesh(p, m, pos, c, e)
	mi.scale = sc
	return mi

## Backwards-compatible name used by older code.
func _sphere(p: Node3D, r: float, pos: Vector3, c: Color, e := 0.0) -> MeshInstance3D:
	return _ball(p, r, pos, c, e)

func _capsule(p: Node3D, r: float, h: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var m := CapsuleMesh.new(); m.radius = r; m.height = maxf(h, r * 2.0)
	m.radial_segments = 12; m.rings = 4
	return _mesh(p, m, pos, c)

func _cyl(p: Node3D, top: float, bottom: float, h: float, pos: Vector3, c: Color, e := 0.0, seg := 12) -> MeshInstance3D:
	var m := CylinderMesh.new(); m.top_radius = top; m.bottom_radius = bottom; m.height = h
	m.radial_segments = seg; m.rings = 1
	return _mesh(p, m, pos, c, e)

func _cone(p: Node3D, r: float, h: float, pos: Vector3, c: Color, e := 0.0, seg := 10) -> MeshInstance3D:
	return _cyl(p, 0.0, r, h, pos, c, e, seg)

func _torus(p: Node3D, inner: float, outer: float, pos: Vector3, c: Color, e := 0.0) -> MeshInstance3D:
	var t := TorusMesh.new(); t.inner_radius = inner; t.outer_radius = outer; t.rings = 16; t.ring_segments = 6
	return _mesh(p, t, pos, c, e)

## A pivot whose contents are baked into their OWN mesh so the rig can swing it.
func _limb(parent: Node3D, limb: String, pos: Vector3, rot := Vector3.ZERO) -> Node3D:
	var n := _pivot(parent, pos, rot)
	n.name = limb
	n.set_meta("limb", limb)
	return n

func _pivot(parent: Node3D, pos: Vector3, rot := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	return n

## Cartoon face on a head sphere centred at `c` with radius `r` (facing +Z).
## mood: happy | angry | calm | sly | fierce
func _face(b: Node3D, c: Vector3, r: float, mood := "happy", eye_col := Color.WHITE, skin := SKIN) -> void:
	var ex := r * 0.36
	var ey := c.y + r * 0.08
	var ez := c.z + r * 0.8
	var er := r * 0.27
	for s in [-1.0, 1.0]:
		if mood == "calm":
			_box(b, Vector3(er * 1.5, er * 0.28, er * 0.4), Vector3(c.x + s * ex, ey - er * 0.2, ez + er * 0.2), INK)
		else:
			_ball(b, er, Vector3(c.x + s * ex, ey, ez), eye_col, 0.0, Vector3(0.9, 1.15, 0.6))
			_ball(b, er * 0.55, Vector3(c.x + s * ex * 0.92, ey - er * 0.1, ez + er * 0.42), INK, 0.0, Vector3(1, 1.2, 0.6))
			_ball(b, er * 0.2, Vector3(c.x + s * ex * 0.85 + er * 0.18, ey + er * 0.25, ez + er * 0.62), Color.WHITE)
		# eyebrows carry the personality
		var tilt: float = {"happy": 0.15, "angry": -0.45, "calm": 0.0, "sly": -0.25, "fierce": -0.6}.get(mood, 0.0)
		var brow := _box(b, Vector3(er * 1.5, er * 0.32, er * 0.4), Vector3(c.x + s * ex, ey + er * 1.35, ez + er * 0.1), INK.lightened(0.15))
		brow.rotation.z = tilt * s * -1.0
	# nose + mouth
	_ball(b, r * 0.1, Vector3(c.x, ey - r * 0.22, ez + r * 0.18), skin.darkened(0.12))
	match mood:
		"happy", "calm":
			var m := _torus(b, r * 0.16, r * 0.22, Vector3(c.x, ey - r * 0.42, ez - r * 0.02), INK)
			m.rotation = Vector3(PI / 2 - 0.35, 0, 0)
			m.scale = Vector3(1, 1, 0.45)
		"angry", "fierce":
			_box(b, Vector3(r * 0.42, r * 0.12, r * 0.1), Vector3(c.x, ey - r * 0.45, ez + r * 0.0), INK)
			if mood == "fierce":
				for s in [-1.0, 1.0]:
					_cone(b, r * 0.05, r * 0.14, Vector3(c.x + s * r * 0.15, ey - r * 0.36, ez + r * 0.05), Color.WHITE).rotation.x = PI
		"sly":
			var sm := _box(b, Vector3(r * 0.4, r * 0.1, r * 0.1), Vector3(c.x + r * 0.05, ey - r * 0.42, ez), INK)
			sm.rotation.z = 0.25

## Chibi biped body: feet, short legs, round torso, arms with mitten hands.
func _chibi(b: Node3D, h: float, outfit: Color, boots: Color, hands: Color, belt := Color("6b4423"), arms_out := 0.35) -> Dictionary:
	for s in [-1.0, 1.0]:
		var leg := _limb(b, "leg_l" if s < 0 else "leg_r", Vector3(s * h * 0.1, h * 0.2, 0))
		_ball(leg, h * 0.075, Vector3(0, -h * 0.16, h * 0.03), boots, 0.0, Vector3(1, 0.7, 1.35))
		_cyl(leg, h * 0.05, h * 0.055, h * 0.14, Vector3(0, -h * 0.08, 0), boots.lightened(0.1))
	_ball(b, h * 0.19, Vector3(0, h * 0.32, 0), outfit, 0.0, Vector3(1.0, 1.0, 0.85))
	_cyl(b, h * 0.185, h * 0.19, h * 0.05, Vector3(0, h * 0.25, 0), belt)
	_box(b, Vector3(h * 0.06, h * 0.05, h * 0.03), Vector3(0, h * 0.25, h * 0.17), Color("ffcf3d"))
	var arm_l := _limb(b, "arm_l", Vector3(-h * 0.17, h * 0.4, 0), Vector3(0, 0, -arms_out))
	var arm_r := _limb(b, "arm_r", Vector3(h * 0.17, h * 0.4, 0), Vector3(0, 0, arms_out))
	for arm in [arm_l, arm_r]:
		_capsule(arm, h * 0.05, h * 0.18, Vector3(0, -h * 0.08, 0), outfit.darkened(0.08))
		_ball(arm, h * 0.06, Vector3(0, -h * 0.19, 0), hands)
	return {"head": Vector3(0, h * 0.66, 0), "hr": h * 0.23, "hand_l": arm_l, "hand_r": arm_r}

func _head(b: Node3D, d: Dictionary, skin := SKIN) -> void:
	_ball(b, d.hr, d.head, skin)
	for s in [-1.0, 1.0]:
		_ball(b, d.hr * 0.22, d.head + Vector3(s * d.hr * 0.95, -d.hr * 0.05, 0), skin.darkened(0.05), 0.0, Vector3(0.6, 1, 1))

# ── heroes & champions ──────────────────────────────────────
func _hero(b: Node3D, h: float, cape: Color) -> void:
	var d := _chibi(b, h, Color("e8b040"), Color("6b4423"), Color("8a5a2e"))
	_head(b, d)
	_face(b, d.head, d.hr, "happy")
	# spiky ember hair
	var hair := Color("e8542c")
	_ball(b, d.hr * 1.02, d.head + Vector3(0, d.hr * 0.3, -d.hr * 0.3), hair, 0.0, Vector3(1.06, 0.75, 0.95))
	for i in 7:
		var a := -1.2 + i * 0.4
		var sp := _cone(b, d.hr * 0.3, d.hr * 0.75, d.head + Vector3(sin(a) * d.hr * 0.7, d.hr * 0.75, -cos(a) * d.hr * 0.25), hair)
		sp.rotation = Vector3(-0.5, 0, -a * 0.9)
	_cyl(b, d.hr * 1.0, d.hr * 1.0, d.hr * 0.16, d.head + Vector3(0, d.hr * 0.42, 0), Color("ffcf3d"))
	# cape, chest plate, pauldrons, bow & quiver
	var cp := _ball(b, h * 0.24, Vector3(0, h * 0.33, -h * 0.12), cape, 0.0, Vector3(1.0, 1.25, 0.35))
	cp.rotation.x = 0.12
	_ball(b, h * 0.15, Vector3(0, h * 0.36, h * 0.07), Color("ffd86a"), 0.0, Vector3(1.0, 0.9, 0.7))
	for s in [-1.0, 1.0]:
		_ball(b, h * 0.075, Vector3(s * h * 0.18, h * 0.46, 0), Color("ffcf3d"))
	_cyl(b, h * 0.05, h * 0.05, h * 0.3, Vector3(h * 0.08, h * 0.4, -h * 0.17), Color("8a5a2e")).rotation.z = 0.4
	var bow := _torus(d.hand_l, h * 0.17, h * 0.2, Vector3(-h * 0.02, -h * 0.2, h * 0.08), Color("ffe08a"))
	bow.rotation = Vector3(0, PI / 2, 0)
	bow.scale = Vector3(1, 1, 0.55)
	_ball(d.hand_r, h * 0.04, Vector3(0, -h * 0.29, 0), Color("ff8a2a"), 2.5)

func _knight(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var steel := Color("c8d0de")
	var d := _chibi(b, h, steel, Color("5a5f70"), steel.darkened(0.1), col.darkened(0.2))
	_head(b, d)
	_face(b, d.head, d.hr, "fierce")
	# great helm with an open face + ember plume
	var helm := _ball(b, d.hr * 1.1, d.head + Vector3(0, d.hr * 0.3, -d.hr * 0.28), steel, 0.0, Vector3(1.06, 0.8, 0.95))
	helm.rotation.x = -0.15
	_box(b, Vector3(d.hr * 0.2, d.hr * 0.6, d.hr * 0.2), d.head + Vector3(0, d.hr * 0.05, d.hr * 0.98), steel.darkened(0.1))
	for i in 4:
		_ball(b, d.hr * (0.3 - i * 0.04), d.head + Vector3(0, d.hr * (1.05 + i * 0.12), -d.hr * (0.1 + i * 0.25)), col if not evolved else Color("ffcf3d"))
	_box(b, Vector3(h * 0.3, h * 0.2, h * 0.04), Vector3(0, h * 0.33, h * 0.17), col)
	# tower shield + flaming sword
	var sh := _cyl(d.hand_l, h * 0.17, h * 0.17, h * 0.05, Vector3(0, -h * 0.18, h * 0.07), col.darkened(0.15), 0.0, 16)
	sh.rotation.x = PI / 2
	_cyl(d.hand_l, h * 0.12, h * 0.12, h * 0.06, Vector3(0, -h * 0.18, h * 0.08), Color("ffcf3d"), 0.0, 16).rotation.x = PI / 2
	_box(d.hand_r, Vector3(h * 0.05, h * 0.4, h * 0.03), Vector3(0, -h * 0.02, h * 0.04), Color("e8eef8"))
	_box(d.hand_r, Vector3(h * 0.16, h * 0.04, h * 0.05), Vector3(0, -h * 0.2, h * 0.04), Color("8a5a2e"))
	_ball(d.hand_r, h * 0.04, Vector3(0, h * 0.2, h * 0.04), Color("ff7a2a"), 2.5)

func _archer(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var d := _chibi(b, h, col.darkened(0.15), Color("6b4423"), SKIN, Color("8a5a2e"))
	_head(b, d)
	_face(b, d.head, d.hr, "sly")
	# hood with a pointy tip + long braid
	var hood := _ball(b, d.hr * 1.12, d.head + Vector3(0, d.hr * 0.15, -d.hr * 0.36), col, 0.0, Vector3(1.06, 1.02, 0.92))
	hood.rotation.x = -0.2
	var tip := _cone(b, d.hr * 0.4, d.hr * 0.9, d.head + Vector3(0, d.hr * 0.6, -d.hr * 0.9), col)
	tip.rotation.x = -1.2
	var hair := Color("c8642a")
	for i in 4:
		_ball(b, d.hr * (0.2 - i * 0.02), d.head + Vector3(d.hr * 0.55, -d.hr * (0.55 + i * 0.3), -d.hr * 0.45), hair)
	_ball(b, d.hr * 0.6, d.head + Vector3(0, d.hr * 0.2, d.hr * 0.55), hair, 0.0, Vector3(1.4, 0.45, 0.6))
	for s in [-1.0, 1.0]:
		_ball(b, d.hr * 0.06, d.head + Vector3(s * d.hr * 0.45, -d.hr * 0.25, d.hr * 0.86), Color("e08a6a"))
	var bow := _torus(d.hand_l, h * 0.2, h * 0.23, Vector3(0, -h * 0.2, h * 0.08), Color("8a5a2e") if not evolved else Color("ffcf3d"))
	bow.rotation = Vector3(0, PI / 2, 0)
	bow.scale = Vector3(1, 1, 0.5)
	var q := _cyl(b, h * 0.05, h * 0.06, h * 0.28, Vector3(-h * 0.06, h * 0.42, -h * 0.17), Color("6b4423"))
	q.rotation.z = -0.45
	for i in 3:
		_box(b, Vector3(h * 0.015, h * 0.1, h * 0.04), Vector3(-h * 0.13 + i * h * 0.02, h * 0.6, -h * 0.17), Color("e8452c"))

func _priestess(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var robe := Color("f4ead2")
	var d := _chibi(b, h, robe, Color("c8b080"), SKIN, col.darkened(0.3))
	_cone(b, h * 0.26, h * 0.32, Vector3(0, h * 0.16, 0), robe)
	_head(b, d)
	_face(b, d.head, d.hr, "calm")
	var veil := _ball(b, d.hr * 1.14, d.head + Vector3(0, d.hr * 0.1, -d.hr * 0.4), Color("3a6ab0"), 0.0, Vector3(1.06, 1.08, 0.92))
	veil.rotation.x = -0.1
	_box(b, Vector3(d.hr * 1.6, d.hr * 0.22, d.hr * 0.3), d.head + Vector3(0, d.hr * 0.7, d.hr * 0.45), Color("f4ead2"))
	_torus(b, d.hr * 0.75, d.hr * 0.88, d.head + Vector3(0, d.hr * 1.2, -d.hr * 0.1), Color("ffe08a"), 2.0 if evolved else 1.4)
	_box(b, Vector3(h * 0.04, h * 0.14, h * 0.02), Vector3(0, h * 0.36, h * 0.19), Color("ffcf3d"))
	_box(b, Vector3(h * 0.1, h * 0.035, h * 0.02), Vector3(0, h * 0.39, h * 0.19), Color("ffcf3d"))
	_cyl(d.hand_r, h * 0.022, h * 0.022, h * 0.85, Vector3(0, h * 0.05, h * 0.04), Color("8a5a2e"))
	_ball(d.hand_r, h * 0.07, Vector3(0, h * 0.5, h * 0.04), Color("9df07a"), 2.0)

func _wolf(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var fur := col
	_ball(b, h * 0.36, Vector3(0, h * 0.42, -h * 0.05), fur, 0.0, Vector3(0.9, 0.85, 1.25))
	_ball(b, h * 0.22, Vector3(0, h * 0.38, h * 0.22), fur.lightened(0.35), 0.0, Vector3(1.0, 0.9, 0.8))
	var names := {"-1|-0.28": "leg_l", "1|-0.28": "leg_r", "-1|0.24": "arm_r", "1|0.24": "arm_l"}
	for s in [-1.0, 1.0]:
		for z in [-0.28, 0.24]:
			var leg := _limb(b, names["%d|%s" % [int(s), str(z)]], Vector3(s * h * 0.18, h * 0.28, h * z))
			_capsule(leg, h * 0.075, h * 0.3, Vector3(0, -h * 0.14, 0), fur.darkened(0.15))
			_ball(leg, h * 0.085, Vector3(0, -h * 0.25, h * 0.03), fur.darkened(0.3), 0.0, Vector3(1, 0.6, 1.3))
	var hc := Vector3(0, h * 0.72, h * 0.32)
	var hr := h * 0.3
	_ball(b, hr, hc, fur)
	_ball(b, hr * 0.48, hc + Vector3(0, -hr * 0.3, hr * 0.85), fur.lightened(0.4), 0.0, Vector3(1.1, 0.8, 1.2))
	_ball(b, hr * 0.17, hc + Vector3(0, -hr * 0.12, hr * 1.38), INK)
	for s in [-1.0, 1.0]:
		var ear := _cone(b, hr * 0.38, hr * 0.8, hc + Vector3(s * hr * 0.6, hr * 0.85, -hr * 0.1), fur.darkened(0.1), 0.0, 6)
		ear.rotation.z = -s * 0.35
		_ball(b, hr * 0.26, hc + Vector3(s * hr * 0.38, hr * 0.18, hr * 0.78), Color("ffe08a") if not evolved else Color("ff7a2a"), 0.0, Vector3(1, 1.1, 0.6))
		_ball(b, hr * 0.13, hc + Vector3(s * hr * 0.36, hr * 0.16, hr * 0.94), INK)
		var brow := _box(b, Vector3(hr * 0.42, hr * 0.1, hr * 0.12), hc + Vector3(s * hr * 0.38, hr * 0.48, hr * 0.84), fur.darkened(0.45))
		brow.rotation.z = s * 0.4
	var tail := _cone(b, h * 0.1, h * 0.45, Vector3(0, h * 0.62, -h * 0.55), fur.lightened(0.2), 0.0, 8)
	tail.rotation.x = -0.9
	if evolved:
		_cyl(b, hr * 0.62, hr * 0.62, hr * 0.15, hc + Vector3(0, -hr * 0.85, -hr * 0.1), Color("e8452c"))

func _ice_queen(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var gown := Color("7fc8f0")
	var d := _chibi(b, h, gown, Color("e8f4ff"), Color("e8f4ff"), Color("ffffff"))
	_cone(b, h * 0.3, h * 0.36, Vector3(0, h * 0.18, 0), gown.lightened(0.2), 0.0, 12)
	_head(b, d, Color("f0e4f4"))
	_face(b, d.head, d.hr, "sly", Color("dff6ff"), Color("f0e4f4"))
	var hair := Color("f4fbff")
	_ball(b, d.hr * 1.08, d.head + Vector3(0, d.hr * 0.15, -d.hr * 0.4), hair, 0.0, Vector3(1.06, 1.0, 0.92))
	_ball(b, d.hr * 0.75, d.head + Vector3(0, -d.hr * 0.55, -d.hr * 0.55), hair, 0.0, Vector3(1.2, 1.3, 0.7))
	for i in 5:
		var a := -0.9 + i * 0.45
		_cone(b, d.hr * 0.12, d.hr * (0.55 if i == 2 else 0.4), d.head + Vector3(sin(a) * d.hr * 0.75, d.hr * 1.0, -cos(a) * d.hr * 0.15), Color("bdf2ff"), 1.6 if evolved else 0.9, 4)
	_ball(d.hand_r, h * 0.08, Vector3(0, -h * 0.25, 0.04), Color("bdf2ff"), 1.8)

func _golem(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var rock := col
	_ball(b, h * 0.36, Vector3(0, h * 0.42, 0), rock, 0.0, Vector3(1.2, 1.0, 0.95))
	_ball(b, h * 0.2, Vector3(-h * 0.18, h * 0.62, h * 0.12), rock.lightened(0.08))
	_ball(b, h * 0.17, Vector3(h * 0.2, h * 0.3, h * 0.2), rock.darkened(0.08))
	for s in [-1.0, 1.0]:
		_ball(b, h * 0.15, Vector3(s * h * 0.46, h * 0.56, 0), rock.darkened(0.12))
		_ball(b, h * 0.13, Vector3(s * h * 0.55, h * 0.3, h * 0.05), rock.darkened(0.05), 0.0, Vector3(1, 1.3, 1))
		_ball(b, h * 0.15, Vector3(s * h * 0.55, h * 0.1, h * 0.08), rock.lightened(0.05))
		_ball(b, h * 0.12, Vector3(s * h * 0.18, h * 0.06, 0), rock.darkened(0.2), 0.0, Vector3(1.2, 0.7, 1.3))
	var hc := Vector3(0, h * 0.78, h * 0.1)
	_ball(b, h * 0.16, hc, rock.lightened(0.05), 0.0, Vector3(1.2, 0.9, 1))
	for s in [-1.0, 1.0]:
		_ball(b, h * 0.04, hc + Vector3(s * h * 0.06, 0, h * 0.14), Color("8fe9ff"), 3.0)
		var brow := _box(b, Vector3(h * 0.08, h * 0.03, h * 0.04), hc + Vector3(s * h * 0.06, h * 0.05, h * 0.14), rock.darkened(0.4))
		brow.rotation.z = s * 0.4
	_ball(b, h * 0.18, Vector3(0, h * 0.86, -h * 0.04), Color("5aa83a"), 0.0, Vector3(1.2, 0.4, 1.0))
	_ball(b, h * 0.12, Vector3(-h * 0.3, h * 0.6, -h * 0.2), Color("5aa83a"), 0.0, Vector3(1, 0.4, 1))
	if evolved:
		_ball(b, h * 0.06, Vector3(0, h * 0.5, h * 0.33), Color("8fe9ff"), 3.0)

func _wizard(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var robe := col.darkened(0.2)
	var d := _chibi(b, h, robe, Color("3a2a5a"), SKIN, Color("ffcf3d"))
	_cone(b, h * 0.27, h * 0.34, Vector3(0, h * 0.17, 0), robe, 0.0, 12)
	_head(b, d)
	_face(b, d.head, d.hr, "angry")
	# huge beard and pointy hat
	_cone(b, d.hr * 0.75, d.hr * 1.4, d.head + Vector3(0, -d.hr * 0.9, d.hr * 0.55), Color("f4f4f8"), 0.0, 10).rotation.x = PI + 0.25
	_ball(b, d.hr * 0.5, d.head + Vector3(0, -d.hr * 0.35, d.hr * 0.65), Color("f4f4f8"), 0.0, Vector3(1.4, 0.7, 0.6))
	_cyl(b, d.hr * 1.5, d.hr * 1.5, d.hr * 0.12, d.head + Vector3(0, d.hr * 0.55, 0), col.darkened(0.35), 0.0, 16)
	var hat := _cone(b, d.hr * 0.95, d.hr * 1.9, d.head + Vector3(0, d.hr * 1.45, -d.hr * 0.15), col.darkened(0.35), 0.0, 12)
	hat.rotation.x = -0.3
	_ball(b, d.hr * 0.16, d.head + Vector3(0, d.hr * 2.2, -d.hr * 0.6), Color("ffe08a"), 1.5)
	_cyl(d.hand_r, h * 0.024, h * 0.024, h * 0.85, Vector3(0, h * 0.05, h * 0.04), Color("6b4423"))
	_ball(d.hand_r, h * 0.08, Vector3(0, h * 0.5, h * 0.04), Color("bfe0ff"), 2.6 if evolved else 2.0)

func _lancer(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var gold := Color("ffcf3d")
	var d := _chibi(b, h, Color("f0e0b0"), Color("8a5a2e"), SKIN, gold)
	_head(b, d, Color("d89a6a"))
	_face(b, d.head, d.hr, "fierce", Color.WHITE, Color("d89a6a"))
	_ball(b, d.hr * 1.08, d.head + Vector3(0, d.hr * 0.32, -d.hr * 0.28), gold, 0.0, Vector3(1.06, 0.78, 0.95))
	for i in 7:
		var a := -PI / 2 + i * PI / 6
		var ray := _cone(b, d.hr * 0.12, d.hr * 0.6, d.head + Vector3(cos(a) * d.hr * 0.55, d.hr * 0.95 + sin(a + PI / 2) * d.hr * 0.25, -d.hr * 0.35), gold.lightened(0.2))
		ray.rotation.z = -a - PI / 2
	_ball(b, h * 0.17, Vector3(0, h * 0.35, h * 0.06), col, 0.0, Vector3(1, 0.9, 0.7))
	var spear := _pivot(d.hand_r, Vector3(0, -h * 0.18, h * 0.05), Vector3(0.5, 0, 0))
	_cyl(spear, h * 0.022, h * 0.022, h * 1.1, Vector3(0, h * 0.3, 0), Color("8a5a2e"))
	_cone(spear, h * 0.06, h * 0.2, Vector3(0, h * 0.95, 0), Color("e8eef8") if not evolved else gold, 0.0, 6)
	var sh := _cyl(d.hand_l, h * 0.14, h * 0.14, h * 0.04, Vector3(0, -h * 0.18, h * 0.07), gold, 0.0, 16)
	sh.rotation.x = PI / 2

func _queen(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	var dress := Color("8a1f2a")
	var d := _chibi(b, h, dress, Color("3a1010"), Color("2a1418"), Color("ffcf3d"))
	_cone(b, h * 0.3, h * 0.38, Vector3(0, h * 0.19, 0), dress.darkened(0.15), 0.0, 14)
	_head(b, d, Color("f2d0b0"))
	_face(b, d.head, d.hr, "sly", Color("ffe0c0"), Color("f2d0b0"))
	var hair := Color("ff6a2a")
	_ball(b, d.hr * 1.1, d.head + Vector3(0, d.hr * 0.15, -d.hr * 0.42), hair, 0.0, Vector3(1.1, 1.05, 0.92))
	for i in 5:
		_cone(b, d.hr * 0.3, d.hr * 0.9, d.head + Vector3(-d.hr * 0.8 + i * d.hr * 0.4, -d.hr * 0.2, -d.hr * 0.7), hair).rotation.x = PI - 0.3
	_cyl(b, d.hr * 0.6, d.hr * 0.55, d.hr * 0.4, d.head + Vector3(0, d.hr * 0.95, 0), Color("ffcf3d"), 0.0, 8)
	for i in 4:
		var a := i * TAU / 4.0
		_ball(b, d.hr * 0.1, d.head + Vector3(cos(a) * d.hr * 0.6, d.hr * 1.15, sin(a) * d.hr * 0.6), Color("ff3a3a"), 1.2)
	_ball(b, h * 0.2, Vector3(0, h * 0.44, -h * 0.12), Color("2a1418"), 0.0, Vector3(1.3, 1.0, 0.5))
	_cyl(d.hand_r, h * 0.022, h * 0.022, h * 0.6, Vector3(0, h * 0.0, h * 0.04), Color("ffcf3d"))
	_ball(d.hand_r, h * 0.08, Vector3(0, h * 0.32, h * 0.04), Color("ff6a1a"), 3.0 if evolved else 2.2)

func _rune_sentinel(b: Node3D, h: float, col: Color, evolved: bool) -> void:
	# A living rune-stone with a stubborn face, floating shards around it.
	_cyl(b, h * 0.32, h * 0.38, h * 0.18, Vector3(0, h * 0.09, 0), Color("8d8678"), 0.0, 8)
	var stone := _box(b, Vector3(h * 0.46, h * 0.62, h * 0.36), Vector3(0, h * 0.5, 0), Color("7a8498"))
	stone.rotation.y = 0.1
	_ball(b, h * 0.25, Vector3(0, h * 0.82, 0), Color("7a8498"), 0.0, Vector3(0.95, 0.6, 0.75))
	_face(b, Vector3(0, h * 0.62, h * 0.0), h * 0.22, "angry", Color("bfe8ff"), Color("9aa4b8"))
	_box(b, Vector3(h * 0.3, h * 0.06, h * 0.02), Vector3(0, h * 0.36, h * 0.19), col, 2.0)
	_box(b, Vector3(h * 0.06, h * 0.22, h * 0.02), Vector3(0, h * 0.36, h * 0.19), col, 2.0)
	for i in 3:
		var a := i * TAU / 3.0
		_ball(b, h * 0.07, Vector3(cos(a) * h * 0.42, h * 0.75, sin(a) * h * 0.42), col, 1.6 if evolved else 1.0)

func _footman(b: Node3D, h: float, col: Color) -> void:
	var steel := Color("b8c0d0")
	var d := _chibi(b, h, col, Color("5a3418"), SKIN, Color("6b4423"))
	_head(b, d)
	_face(b, d.head, d.hr, "angry")
	_ball(b, d.hr * 1.08, d.head + Vector3(0, d.hr * 0.35, -d.hr * 0.2), steel, 0.0, Vector3(1.06, 0.7, 0.98))
	_cyl(b, d.hr * 1.2, d.hr * 1.2, d.hr * 0.1, d.head + Vector3(0, d.hr * 0.2, 0), steel.darkened(0.1), 0.0, 14)
	_box(d.hand_r, Vector3(h * 0.045, h * 0.34, h * 0.03), Vector3(0, -h * 0.02, h * 0.04), Color("e8eef8"))
	var sh := _cyl(d.hand_l, h * 0.13, h * 0.13, h * 0.04, Vector3(0, -h * 0.18, h * 0.07), col.darkened(0.2), 0.0, 14)
	sh.rotation.x = PI / 2

func _bowman(b: Node3D, h: float, col: Color) -> void:
	var d := _chibi(b, h, col, Color("5a3418"), SKIN, Color("6b4423"))
	_head(b, d)
	_face(b, d.head, d.hr, "happy")
	_ball(b, d.hr * 1.08, d.head + Vector3(0, d.hr * 0.2, -d.hr * 0.35), col.darkened(0.15), 0.0, Vector3(1.06, 0.95, 0.92))
	_cone(b, d.hr * 0.5, d.hr * 0.6, d.head + Vector3(0, d.hr * 0.9, 0), Color("6b4423")).rotation.x = -0.2
	var bow := _torus(d.hand_l, h * 0.19, h * 0.22, Vector3(0, -h * 0.2, h * 0.08), Color("8a5a2e"))
	bow.rotation = Vector3(0, PI / 2, 0)
	bow.scale = Vector3(1, 1, 0.5)

# ── the Rush ────────────────────────────────────────────────
func _imp(b: Node3D, h: float, c: Color, id: String) -> void:
	# Spirits (wisps) are flames with faces; the rest are grinning goblin-imps.
	if id.contains("wisp") or id == "void_mite":
		_ball(b, h * 0.3, Vector3(0, h * 0.36, 0), c, 0.0, Vector3(1, 1, 0.95))
		_cone(b, h * 0.24, h * 0.5, Vector3(0, h * 0.75, -h * 0.05), c.lightened(0.15)).rotation.x = -0.35
		_cone(b, h * 0.12, h * 0.3, Vector3(h * 0.16, h * 0.65, -h * 0.02), c.lightened(0.3)).rotation.z = -0.5
		_face(b, Vector3(0, h * 0.38, 0), h * 0.3, "sly", Color.WHITE, c)
		return
	var d := _chibi(b, h, c.darkened(0.25), c.darkened(0.45), c.lightened(0.1), Color("3a2a1a"), 0.55)
	var skin := c.lightened(0.15)
	_head(b, d, skin)
	_face(b, d.head, d.hr, "fierce", Color("fff2a0"), skin)
	for s in [-1.0, 1.0]:
		var ear := _cone(b, d.hr * 0.3, d.hr * 1.0, d.head + Vector3(s * d.hr * 1.05, d.hr * 0.2, 0), skin, 0.0, 6)
		ear.rotation.z = -s * 1.2
		var horn := _cone(b, d.hr * 0.14, d.hr * 0.45, d.head + Vector3(s * d.hr * 0.45, d.hr * 0.95, 0), Color("f0e6c8"), 0.0, 6)
		horn.rotation.z = -s * 0.3
	if id in ["drowned", "husk", "sentry"]:
		_ball(b, d.hr * 1.05, d.head + Vector3(0, d.hr * 0.3, -d.hr * 0.05), Color("6a707e"), 0.0, Vector3(1.05, 0.65, 1.05))
	_box(d.hand_r, Vector3(h * 0.04, h * 0.24, h * 0.03), Vector3(0, -h * 0.05, h * 0.04), Color("c8ccd8"))

func _ogre(b: Node3D, h: float, c: Color, boss: bool) -> void:
	var skin := c.lightened(0.12)
	for s in [-1.0, 1.0]:
		var leg := _limb(b, "leg_l" if s < 0 else "leg_r", Vector3(s * h * 0.17, h * 0.22, 0))
		_ball(leg, h * 0.1, Vector3(0, -h * 0.17, h * 0.03), c.darkened(0.4), 0.0, Vector3(1, 0.6, 1.3))
		_capsule(leg, h * 0.08, h * 0.2, Vector3(0, -h * 0.08, 0), skin.darkened(0.1))
	_ball(b, h * 0.33, Vector3(0, h * 0.42, 0), skin, 0.0, Vector3(1.15, 1.0, 0.95))
	_ball(b, h * 0.22, Vector3(0, h * 0.36, h * 0.16), skin.lightened(0.18), 0.0, Vector3(1.0, 0.9, 0.6))
	_cyl(b, h * 0.32, h * 0.34, h * 0.08, Vector3(0, h * 0.24, 0), Color("6b4423"))
	var arms: Array[Node3D] = []
	for s in [-1.0, 1.0]:
		var arm := _limb(b, "arm_l" if s < 0 else "arm_r", Vector3(s * h * 0.36, h * 0.56, 0))
		arms.append(arm)
		_ball(arm, h * 0.13, Vector3.ZERO, skin.darkened(0.08))
		_capsule(arm, h * 0.09, h * 0.3, Vector3(s * h * 0.06, -h * 0.18, h * 0.04), skin)
		_ball(arm, h * 0.11, Vector3(s * h * 0.08, -h * 0.36, h * 0.06), skin.darkened(0.1))
	var hc := Vector3(0, h * 0.74, h * 0.06)
	var hr := h * 0.19
	_ball(b, hr, hc, skin)
	_face(b, hc, hr, "angry", Color("ffe08a"), skin)
	for s in [-1.0, 1.0]:
		var tusk := _cone(b, hr * 0.14, hr * 0.5, hc + Vector3(s * hr * 0.35, -hr * 0.45, hr * 0.8), Color("fff6dc"), 0.0, 6)
		tusk.rotation.x = -0.3
	_box(arms[1], Vector3(h * 0.07, h * 0.42, h * 0.07), Vector3(h * 0.12, -h * 0.26, h * 0.2), Color("6b4423")).rotation.x = 0.4
	_ball(arms[1], h * 0.1, Vector3(h * 0.12, -h * 0.06, h * 0.3), Color("5a3418"))
	if boss:
		for s in [-1.0, 1.0]:
			var horn := _cone(b, hr * 0.3, hr * 1.2, hc + Vector3(s * hr * 0.7, hr * 0.9, 0), Color("2a1418"), 0.0, 8)
			horn.rotation.z = -s * 0.5
		_cyl(b, hr * 0.7, hr * 0.6, hr * 0.4, hc + Vector3(0, hr * 0.95, 0), Color("ffcf3d"), 0.0, 8)
		for i in 6:
			var a := i * TAU / 6.0
			var sp := _cone(b, h * 0.05, h * 0.16, Vector3(cos(a) * h * 0.28, h * 0.6, sin(a) * h * 0.22 - h * 0.05), Color("2a1418"), 0.0, 6)
			sp.rotation = Vector3(sin(a) * 0.8, 0, -cos(a) * 0.8)
		_ball(b, h * 0.07, Vector3(0, h * 0.5, h * 0.3), Color("ff3a3a"), 2.5)

func _bat(b: Node3D, h: float, c: Color) -> Array[Node3D]:
	var bc := Vector3(0, h * 0.7, 0)
	_ball(b, h * 0.28, bc, c)
	_ball(b, h * 0.16, bc + Vector3(0, -h * 0.08, h * 0.16), c.lightened(0.25), 0.0, Vector3(1.2, 0.9, 0.6))
	_face(b, bc + Vector3(0, h * 0.04, 0), h * 0.28, "fierce", Color("ffe08a"), c)
	for s in [-1.0, 1.0]:
		var ear := _cone(b, h * 0.09, h * 0.22, bc + Vector3(s * h * 0.15, h * 0.3, 0), c.darkened(0.2), 0.0, 6)
		ear.rotation.z = -s * 0.3
		_ball(b, h * 0.05, bc + Vector3(s * h * 0.1, -h * 0.28, 0), c.darkened(0.3))
	var out: Array[Node3D] = []
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.set_meta("dynamic", true)
		pivot.position = bc + Vector3(s * h * 0.22, h * 0.05, 0)
		b.add_child(pivot)
		var w := _box(pivot, Vector3(h * 0.5, h * 0.03, h * 0.32), Vector3(s * h * 0.25, 0, 0), c.darkened(0.35))
		w.material_override = mat(c.darkened(0.35))
		for k in 2:
			_box(pivot, Vector3(h * 0.04, h * 0.04, h * 0.3), Vector3(s * h * (0.15 + k * 0.18), h * 0.02, 0), c.darkened(0.5))
		out.append(pivot)
	return out

func _hexer(b: Node3D, h: float, c: Color) -> void:
	_cone(b, h * 0.32, h * 0.7, Vector3(0, h * 0.35, 0), c.darkened(0.2), 0.0, 12)
	_ball(b, h * 0.26, Vector3(0, h * 0.72, 0), c.darkened(0.3), 0.0, Vector3(1, 1.05, 1))
	var hood := _cone(b, h * 0.22, h * 0.4, Vector3(0, h * 0.98, -h * 0.08), c.darkened(0.3), 0.0, 10)
	hood.rotation.x = -0.5
	_ball(b, h * 0.18, Vector3(0, h * 0.7, h * 0.1), Color("1a0e1e"), 0.0, Vector3(1, 1, 0.6))
	for s in [-1.0, 1.0]:
		_ball(b, h * 0.045, Vector3(s * h * 0.07, h * 0.72, h * 0.2), Color("ff9aff"), 3.0)
		_ball(b, h * 0.07, Vector3(s * h * 0.3, h * 0.45, h * 0.06), c.lightened(0.2))
	_ball(b, h * 0.08, Vector3(h * 0.34, h * 0.62, h * 0.14), Color("d14bff"), 2.5)

func _bastion(b: Node3D, h: float) -> void:
	var stone := Color("b0a898")
	var dark := Color("7d7668")
	var roof := Color("d8452c")
	_cyl(b, h * 0.95, h * 1.05, h * 0.16, Vector3(0, h * 0.08, 0), Color("8a7a62"), 0.0, 16)
	_box(b, Vector3(h * 1.1, h * 0.62, h * 0.7), Vector3(0, h * 0.45, 0), stone)
	for i in 6:
		_box(b, Vector3(h * 0.13, h * 0.13, h * 0.74), Vector3(-h * 0.48 + i * h * 0.19, h * 0.82, 0), stone.lightened(0.05))
	for x in [-1.0, 1.0]:
		_cyl(b, h * 0.24, h * 0.27, h * 1.05, Vector3(x * h * 0.6, h * 0.55, 0), stone.darkened(0.05), 0.0, 14)
		_cyl(b, h * 0.3, h * 0.3, h * 0.08, Vector3(x * h * 0.6, h * 1.1, 0), dark, 0.0, 14)
		_cone(b, h * 0.32, h * 0.5, Vector3(x * h * 0.6, h * 1.38, 0), roof, 0.0, 14)
		_box(b, Vector3(h * 0.08, h * 0.14, h * 0.02), Vector3(x * h * 0.6, h * 0.75, h * 0.26), INK)
		_cyl(b, h * 0.01, h * 0.01, h * 0.35, Vector3(x * h * 0.6, h * 1.78, 0), Color("6b4423"))
		_box(b, Vector3(h * 0.2, h * 0.12, h * 0.02), Vector3(x * h * 0.6 + h * 0.1, h * 1.86, 0), Color("ffcf3d"))
	# central keep
	_box(b, Vector3(h * 0.5, h * 0.5, h * 0.5), Vector3(0, h * 0.95, -h * 0.05), stone.lightened(0.05))
	_cone(b, h * 0.42, h * 0.5, Vector3(0, h * 1.45, -h * 0.05), Color("3a6ab0"), 0.0, 4).rotation.y = PI / 4
	# gate
	_box(b, Vector3(h * 0.32, h * 0.38, h * 0.06), Vector3(0, h * 0.32, h * 0.34), Color("6b4423"))
	_cyl(b, h * 0.16, h * 0.16, h * 0.06, Vector3(0, h * 0.5, h * 0.34), Color("6b4423"), 0.0, 12).rotation.x = PI / 2
	for k in 3:
		_box(b, Vector3(h * 0.02, h * 0.36, h * 0.07), Vector3(-h * 0.1 + k * h * 0.1, h * 0.32, h * 0.35), Color("3a3e48"))
	# the Last Flame
	_ball(b, h * 0.13, Vector3(0, h * 1.8, -h * 0.05), Color("ffb03a"), 4.0)

# ── towers (Kingdom-Rush-like: wood → stone → stone & gold) ──
## family: archer | barracks | mage | artillery · tier 0..2 · spec: champion id or ""
func make_tower(family: String, tier: int, spec := "") -> Node3D:
	var root := Node3D.new()
	# Modelo 3D tem prioridade sobre o desenho 2D:
	# assets/models/tower_<família>_<tier>.glb (tier chega 0..2, os arquivos são 1..3).
	# Já saem do Blender na altura certa e com a origem no chão: é só instanciar.
	var mpath := MODEL_DIR + "tower_%s_%d.glb" % [family, tier + 1]
	if FileAccess.file_exists(mpath):
		var inst := _load_glb(mpath)
		if inst:
			aplicar_toon(inst)
			root.add_child(inst)
			root.set_meta("modelo3d", true)
			return root
	var art := UIKit.art("towers/%s.png" % family)
	if art:
		var spr := Sprite3D.new()
		spr.texture = art
		spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		spr.shaded = false
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var h: float = [3.1, 3.5, 3.9][tier]
		spr.pixel_size = h / float(art.get_height())
		spr.offset = Vector2(0, art.get_height() / 2.0)
		if tier == 2: spr.modulate = Color(1.08, 1.04, 0.92)
		root.add_child(spr)
		root.set_meta("drawn", true)
		return root
	var body := Node3D.new()
	root.add_child(body)
	var key := "tower|%s|%d|%s" % [family, tier, spec]
	var cached: ArrayMesh = _bake_cache.get(key)
	_skip_static = cached != null
	var accent: Color = GameData.TOWERS[family].color
	if spec != "":
		accent = GameData.champion(spec).color
	match family:
		"archer": _tower_archer(body, tier, accent, spec != "")
		"barracks": _tower_barracks(body, tier, accent, spec != "")
		"mage": _tower_mage(body, tier, accent, spec != "")
		"artillery": _tower_artillery(body, tier, accent, spec)
		"ballista": _tower_ballista(body, tier, accent)
		"cauldron": _tower_cauldron(body, tier, accent)
		"tesla": _tower_tesla(body, tier, accent)
		"goldmine": _tower_goldmine(body, tier, accent)
	_skip_static = false
	if cached == null:
		cached = _bake(body)
		_bake_cache[key] = cached
	var mi := MeshInstance3D.new()
	mi.mesh = cached
	mi.material_override = baked_mat()
	body.add_child(mi)
	return root

## Height (y) where the tower's shooter stands.
func tower_top(family: String, tier: int) -> float:
	match family:
		"archer": return [1.35, 1.6, 1.85][tier]
		"mage": return [1.7, 1.95, 2.2][tier]
		"tesla": return [1.9, 2.2, 2.5][tier]
	return 0.35

func _tower_archer(b: Node3D, tier: int, accent: Color, spec: bool) -> void:
	var wood := Color("a8703c")
	var stone := Color("a8a090")
	var top := tower_top("archer", tier)
	if tier == 0:
		for x in [-0.5, 0.5]:
			for z in [-0.5, 0.5]:
				_cyl(b, 0.08, 0.1, top, Vector3(x, top / 2.0, z), wood.darkened(0.15), 0.0, 6)
		_box(b, Vector3(1.0, 0.08, 0.08), Vector3(0, top * 0.45, 0.5), wood)
		_box(b, Vector3(1.0, 0.08, 0.08), Vector3(0, top * 0.45, -0.5), wood)
	else:
		_cyl(b, 0.62, 0.78, top, Vector3(0, top / 2.0, 0), stone, 0.0, 10)
		for k in 3:
			_cyl(b, 0.64 + k * 0.03, 0.64 + k * 0.03, 0.05, Vector3(0, top * (0.25 + k * 0.25), 0), stone.darkened(0.12), 0.0, 10)
		_box(b, Vector3(0.18, 0.3, 0.05), Vector3(0, top * 0.55, 0.66), INK)
	_cyl(b, 0.85, 0.75, 0.16, Vector3(0, top + 0.02, 0), wood, 0.0, 10)
	for i in 8:
		var a := i * TAU / 8.0
		_box(b, Vector3(0.16, 0.26, 0.12), Vector3(cos(a) * 0.75, top + 0.2, sin(a) * 0.75), wood.lightened(0.1) if tier < 2 else Color("ffcf3d")).rotation.y = -a
	_cyl(b, 0.015, 0.015, 0.9, Vector3(0.62, top + 0.5, -0.4), Color("5a3418"), 0.0, 6)
	_box(b, Vector3(0.4, 0.26, 0.03), Vector3(0.82, top + 0.82, -0.4), accent)
	if spec:
		_torus(b, 0.8, 0.88, Vector3(0, top + 0.1, 0), accent, 0.8)

func _tower_barracks(b: Node3D, tier: int, accent: Color, spec: bool) -> void:
	var wall := Color("c8a06a") if tier == 0 else Color("a8a090")
	var roof := accent.darkened(0.15) if not spec else accent
	var w := 1.2 + tier * 0.1
	_box(b, Vector3(w, 0.75, w * 0.85), Vector3(0, 0.62, 0), wall)
	_box(b, Vector3(0.36, 0.48, 0.05), Vector3(0, 0.5, w * 0.43), Color("6b4423"))
	_cyl(b, 0.18, 0.18, 0.05, Vector3(0, 0.74, w * 0.43), Color("6b4423"), 0.0, 10).rotation.x = PI / 2
	for s in [-1.0, 1.0]:
		_box(b, Vector3(0.16, 0.18, 0.05), Vector3(s * w * 0.3, 0.75, w * 0.43), Color("3a6ab0"))
	var r := _cone(b, w * 0.85, 0.75 + tier * 0.1, Vector3(0, 1.36 + tier * 0.05, 0), roof, 0.0, 4)
	r.rotation.y = PI / 4
	r.scale = Vector3(1, 1, 0.9)
	if tier >= 1:
		_cyl(b, 0.2, 0.22, 1.5, Vector3(w * 0.55, 0.75, -w * 0.3), Color("c8c0b0"), 0.0, 8)
		_cone(b, 0.28, 0.4, Vector3(w * 0.55, 1.7, -w * 0.3), roof, 0.0, 8)
	if tier >= 2:
		_box(b, Vector3(w + 0.04, 0.06, w * 0.85 + 0.04), Vector3(0, 0.98, 0), Color("ffcf3d"))
	_cyl(b, 0.015, 0.015, 1.0, Vector3(-w * 0.45, 1.45, w * 0.3), Color("5a3418"), 0.0, 6)
	_box(b, Vector3(0.38, 0.26, 0.03), Vector3(-w * 0.45 + 0.2, 1.8, w * 0.3), accent)

func _tower_mage(b: Node3D, tier: int, accent: Color, spec: bool) -> void:
	var stone := Color("9a8fb0")
	var top := tower_top("mage", tier)
	_cyl(b, 0.55, 0.75, top, Vector3(0, top / 2.0, 0), stone, 0.0, 8)
	for k in 2 + tier:
		_box(b, Vector3(0.14, 0.22, 0.05), Vector3(0, top * (0.3 + k * 0.2), 0.6 - k * 0.03), accent.darkened(0.2))
	_cyl(b, 0.7, 0.6, 0.14, Vector3(0, top, 0), stone.darkened(0.1), 0.0, 8)
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4
		_cone(b, 0.12, 0.45, Vector3(cos(a) * 0.55, top + 0.25, sin(a) * 0.55), accent.darkened(0.25), 0.0, 6)
	_ball(b, 0.26 + tier * 0.04, Vector3(0, top + 0.55, 0), accent, 2.0 if spec else 1.2)
	if tier >= 2:
		_torus(b, 0.36, 0.42, Vector3(0, top + 0.55, 0), Color("ffcf3d"), 0.6).rotation.x = PI / 2

func _tower_artillery(b: Node3D, tier: int, accent: Color, spec: String) -> void:
	var stone := Color("a8a090")
	var wood := Color("8a5a2e")
	_cyl(b, 0.85, 0.95, 0.5, Vector3(0, 0.25, 0), stone if tier > 0 else Color("b8a080"), 0.0, 12)
	for i in 10:
		var a := i * TAU / 10.0
		_box(b, Vector3(0.18, 0.2, 0.14), Vector3(cos(a) * 0.86, 0.58, sin(a) * 0.86), stone.darkened(0.08)).rotation.y = -a
	if spec == "runestone":
		var st := _box(b, Vector3(0.5, 0.7, 0.4), Vector3(0, 0.95, 0), Color("9aa4b8"))
		st.rotation.y = 0.2
		_box(b, Vector3(0.3, 0.06, 0.02), Vector3(0, 0.95, 0.21), accent, 2.0)
		_box(b, Vector3(0.06, 0.3, 0.02), Vector3(0, 0.95, 0.21), accent, 2.0)
		return
	if spec == "ashen_queen":
		_cyl(b, 0.55, 0.6, 0.2, Vector3(0, 0.6, 0), Color("3a2a2a"), 0.0, 10)
		for i in 5:
			var a := i * TAU / 5.0
			_cone(b, 0.12, 0.35, Vector3(cos(a) * 0.45, 0.85, sin(a) * 0.45), Color("ff6a1a"), 2.0, 6)
		return
	# mortar on a wooden cradle
	for s in [-1.0, 1.0]:
		_box(b, Vector3(0.12, 0.3, 0.6), Vector3(s * 0.3, 0.75, 0), wood)
	var barrel := _cyl(b, 0.28 + tier * 0.04, 0.34 + tier * 0.04, 0.7 + tier * 0.08, Vector3(0, 0.95, 0.05), Color("4a4e58"), 0.0, 12)
	barrel.rotation.x = -0.6
	_torus(b, 0.27 + tier * 0.04, 0.33 + tier * 0.04, Vector3(0, 1.2, 0.22), Color("ffcf3d") if tier == 2 else Color("6a707e"))
	for k in 3:
		_ball(b, 0.11, Vector3(-0.5 + k * 0.13, 0.6, 0.45), Color("2a2e38"))

func _tower_ballista(b: Node3D, tier: int, accent: Color) -> void:
	var wood := Color("a8703c")
	var stone := Color("a8a090")
	var hgt := 0.7 + tier * 0.2
	_cyl(b, 0.8, 0.9, hgt, Vector3(0, hgt / 2.0, 0), stone if tier > 0 else Color("c8a06a"), 0.0, 8)
	_cyl(b, 0.85, 0.85, 0.1, Vector3(0, hgt, 0), wood, 0.0, 8)
	var top := hgt + 0.1
	_box(b, Vector3(0.3, 0.4, 0.3), Vector3(0, top + 0.2, 0), wood.darkened(0.2))
	_box(b, Vector3(0.18, 0.16, 1.4), Vector3(0, top + 0.45, 0.1), wood)
	for s in [-1.0, 1.0]:
		var arm := _box(b, Vector3(0.9, 0.12, 0.12), Vector3(s * 0.42, top + 0.5, 0.55), wood.darkened(0.1))
		arm.rotation.y = s * 0.35
	_box(b, Vector3(1.4, 0.03, 0.03), Vector3(0, top + 0.5, 0.25), Color("f2ead8"))
	_cone(b, 0.08, 0.3, Vector3(0, top + 0.55, 0.95), Color("dfe6f2"), 0.0, 6).rotation.x = PI / 2
	if tier >= 2:
		for i in 8:
			var a := i * TAU / 8.0
			_box(b, Vector3(0.18, 0.22, 0.14), Vector3(cos(a) * 0.82, hgt + 0.15, sin(a) * 0.82), Color("ffcf3d")).rotation.y = -a
	_cyl(b, 0.015, 0.015, 0.9, Vector3(-0.6, top + 0.4, -0.4), Color("5a3418"), 0.0, 6)
	_box(b, Vector3(0.38, 0.26, 0.03), Vector3(-0.4, top + 0.72, -0.4), accent)

func _tower_cauldron(b: Node3D, tier: int, accent: Color) -> void:
	var wall := Color("8a7a68") if tier == 0 else Color("7a7a8a")
	_cyl(b, 0.85, 0.95, 0.45, Vector3(0, 0.22, 0), wall, 0.0, 10)
	for s in [-1.0, 1.0]:
		_cyl(b, 0.06, 0.06, 1.2 + tier * 0.1, Vector3(s * 0.7, 0.6, 0), Color("6b4423"), 0.0, 6)
	_box(b, Vector3(1.6, 0.08, 0.08), Vector3(0, 1.2 + tier * 0.1, 0), Color("6b4423"))
	var pot_r := 0.5 + tier * 0.06
	_ball(b, pot_r, Vector3(0, 0.75, 0), Color("3a3e48"), 0.0, Vector3(1, 0.85, 1))
	_torus(b, pot_r * 0.8, pot_r * 0.95, Vector3(0, 0.75 + pot_r * 0.6, 0), Color("4a4e58"))
	_cyl(b, pot_r * 0.8, pot_r * 0.8, 0.05, Vector3(0, 0.75 + pot_r * 0.62, 0), accent, 1.6, 14)
	for k in 3:
		_ball(b, 0.08 + k * 0.03, Vector3(-0.15 + k * 0.15, 0.95 + pot_r * 0.6 + k * 0.12, 0), accent.lightened(0.3), 1.2)
	for k in 3:
		var a := k * TAU / 3.0
		_cone(b, 0.12, 0.3, Vector3(cos(a) * 0.4, 0.55, sin(a) * 0.4), Color("ff8a2a"), 1.8, 6)
	if tier >= 2:
		_ball(b, 0.14, Vector3(0.55, 0.6, 0.55), Color("f4ead2"))
		_ball(b, 0.1, Vector3(0.62, 0.6, 0.62), INK)

func _tower_tesla(b: Node3D, tier: int, accent: Color) -> void:
	var metal := Color("7a8498")
	var top := tower_top("tesla", tier)
	_cyl(b, 0.8, 0.9, 0.35, Vector3(0, 0.17, 0), Color("a8a090"), 0.0, 8)
	_cyl(b, 0.18, 0.4, top, Vector3(0, top / 2.0 + 0.2, 0), metal, 0.0, 8)
	for k in 3 + tier:
		_torus(b, 0.32 - k * 0.03, 0.42 - k * 0.03, Vector3(0, 0.6 + k * (top - 0.4) / (3 + tier), 0), Color("c8843a"))
	for s in [-1.0, 1.0]:
		var rod := _cyl(b, 0.04, 0.04, 0.8, Vector3(s * 0.45, top * 0.7, 0), metal.darkened(0.2), 0.0, 6)
		rod.rotation.z = s * 0.4
	_ball(b, 0.26 + tier * 0.04, Vector3(0, top + 0.35, 0), accent, 2.6)
	_torus(b, 0.36, 0.42, Vector3(0, top + 0.35, 0), Color("ffcf3d") if tier == 2 else metal, 0.0).rotation.x = PI / 2

func _tower_goldmine(b: Node3D, tier: int, accent: Color) -> void:
	var rock := Color("8a7a6a")
	_ball(b, 1.0, Vector3(0, 0.3, -0.2), rock, 0.0, Vector3(1.1, 0.8, 0.9))
	_ball(b, 0.6, Vector3(0.6, 0.5, -0.3), rock.lightened(0.08))
	_box(b, Vector3(0.7, 0.75, 0.3), Vector3(0, 0.38, 0.62), INK)
	for s in [-1.0, 1.0]:
		_box(b, Vector3(0.12, 0.9, 0.14), Vector3(s * 0.4, 0.45, 0.7), Color("8a5a2e"))
	_box(b, Vector3(0.95, 0.14, 0.16), Vector3(0, 0.9, 0.7), Color("8a5a2e"))
	# mine cart full of gold
	_box(b, Vector3(0.6, 0.3, 0.42), Vector3(0.75, 0.3, 0.9), Color("6a707e"))
	for x in [0.55, 0.95]:
		_cyl(b, 0.1, 0.1, 0.46, Vector3(x, 0.12, 0.9), INK, 0.0, 8).rotation.x = PI / 2
	for k in 3 + tier * 2:
		_ball(b, 0.11, Vector3(0.6 + (k % 3) * 0.13, 0.5 + int(k / 3) * 0.08, 0.85 + (k % 2) * 0.1), Color("ffcf3d"), 0.6)
	var pick := _box(b, Vector3(0.05, 0.6, 0.05), Vector3(-0.7, 0.35, 0.8), Color("8a5a2e"))
	pick.rotation.z = 0.5
	_box(b, Vector3(0.4, 0.06, 0.06), Vector3(-0.85, 0.62, 0.8), Color("a8b0c0")).rotation.z = 0.5
	if tier >= 1:
		_cone(b, 0.4, 0.5, Vector3(-0.5, 1.15, -0.3), Color("b0402a"), 0.0, 4)
		_box(b, Vector3(0.6, 0.5, 0.6), Vector3(-0.5, 0.65, -0.3), Color("c8a06a"))
	if tier >= 2:
		_ball(b, 0.2, Vector3(0, 1.35, -0.2), Color("ffcf3d"), 1.2)

# ── Portrait icons (rendered once, offscreen) ───────────────
var _icons: Dictionary = {}

func kind_for(def: Dictionary) -> String:
	match def.id:
		"boulder_golem": return "golem"
		"wolf_pack": return "wolf"
		"ashen_queen": return "queen"
	return def.role

## Returns a portrait texture: painted art (ChatGPT pipeline) if present,
## else a one-off render of the 3D model.
func icon(id: String, evolved := false) -> Texture2D:
	var key := "%s_%s" % [id, evolved]
	if id == "warden":
		key += Save.hero_cape().to_html()
	if _icons.has(key):
		return _icons[key]
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
	cam.fov = 30
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.2
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d0dcf0")
	env.environment.ambient_light_energy = 0.9
	vp.add_child(env)
	var model: Node3D
	var look_y := 0.95
	if id.begins_with("troop_"):
		var td: Dictionary = {}
		for t in GameData.TROOPS:
			if "troop_" + t.id == id: td = t
		var mk := "wolf" if td.model == "wolf_pack" else ("melee" if td.model == "pyre_knight" else "")
		model = make(td.model, mk, td.color, 1.25 if td.model == "wolf_pack" else 1.8)
	elif id.begins_with("tower_"):
		var parts := id.split("_")
		model = make_tower(parts[1], 0)
		look_y = 0.9
	elif id == "warden":
		model = make("warden", "warden", Save.hero_cape(), 1.8)
	elif GameData.enemies.has(id):
		var e: Dictionary = GameData.enemies[id]
		model = make(id, e.kind, e.color, 1.8 if e.kind != "flyer" else 1.4)
		if e.kind == "flyer": model.position.y = -0.4
	else:
		var def := GameData.champion(id)
		var h := 1.2 if id == "wolf_pack" else 1.8
		model = make(id, kind_for(def), def.color, h, evolved)
	model.rotation.y = 0.45
	vp.add_child(model)
	cam.position = Vector3(0, 1.35, 4.2)
	cam.look_at_from_position(cam.position, Vector3(0, look_y, 0))
	var tex := vp.get_texture()
	_icons[key] = tex
	return tex
