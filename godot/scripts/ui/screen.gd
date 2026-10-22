extends RefCounted
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Shared layout for sub-screens: parchment page, back button, hanging plaque.

## Builds backdrop + header and returns the content VBox.
static func make(root: Control, title: String, back_to: String, _accent: Color = UIKit.EMBER, show_gold := true) -> VBoxContainer:
	UIKit.parchment_backdrop(root)
	var v := VBoxContainer.new()
	UIKit.full_rect(v)
	v.offset_left = 22; v.offset_right = -22; v.offset_top = 22; v.offset_bottom = -22
	v.add_theme_constant_override("separation", 14)
	root.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(UIKit.icon_button("back", func(): Sfx.play("back"); Nav.go(back_to, {}, true), "", 84.0))
	var t := UIKit.plaque(title, 40)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	if show_gold:
		var g := UIKit.counter("coin", str(int(Save.data.gold)), UIKit.GOLD)
		g.custom_minimum_size = Vector2(150, 0)
		root.set_meta("gold_counter", g)
		h.add_child(g)
	return v

static func refresh_gold(root: Control) -> void:
	if root.has_meta("gold_counter"):
		root.get_meta("gold_counter").get_meta("label").text = str(int(Save.data.gold))

static func scroll(parent: Control) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	sc.add_child(list)
	return list

## A character on a wooden stump inside a framed box: its 3D model when there is one, else the drawing.
static func stage(id: String, height := 380.0, evolved := false) -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color("bfe0f0"), UIKit.WOOD, 20, 8))
	frame.custom_minimum_size = Vector2(0, height)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(turntable(id, evolved) if AssetLib.has_model(id) else figure(id, evolved))
	return frame

## The 3D model turning slowly on a wooden stump (own small world, simple light); every few
## seconds it shows off its melee swing and its ranged/special clip.
static func turntable(id: String, evolved := false) -> Control:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	svc.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.transform = Transform3D.IDENTITY.looking_at(Vector3(0, -0.3, -1.0)).translated(Vector3(0, 3.0, 10.0))
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	sun.light_energy = 1.0
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e0e8f4")
	env.environment.ambient_light_energy = 0.95
	vp.add_child(env)
	var stump := MeshInstance3D.new()
	var cyl := CylinderMesh.new(); cyl.top_radius = 0.8; cyl.bottom_radius = 0.9; cyl.height = 0.22
	stump.mesh = cyl
	stump.material_override = AssetLib.mat(Color("8a5a2e"))
	stump.position.y = -0.11
	vp.add_child(stump)
	var ring := MeshInstance3D.new()
	var top := CylinderMesh.new(); top.top_radius = 0.66; top.bottom_radius = 0.66; top.height = 0.01
	ring.mesh = top
	ring.material_override = AssetLib.mat(Color("c79a5e"))
	ring.position.y = 0.005
	vp.add_child(ring)
	var spin := Turntable.new()
	vp.add_child(spin)
	spin.rig = AssetLib.make(id, "hero", Color.WHITE, 1.75, evolved)
	spin.add_child(spin.rig)
	spin.cam = cam
	var box: AABB = spin.rig._aabb(spin.rig, Transform3D.IDENTITY)
	spin.reach = maxf(0.9, Vector2(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.z), absf(box.end.z))).length())
	spin.tall = box.end.y + 0.25
	return svc

class Turntable extends Node3D:
	var rig
	var cam: Camera3D
	var reach := 1.0   # radius the model sweeps while turning (stump included)
	var tall := 2.0
	var _t := 0.0
	var _n := 0

	func _process(d: float) -> void:
		rotation.y += d * 0.6
		# fit the turning model to the frame, whatever its aspect (portrait cards or wide stages)
		var sz := get_viewport().get_visible_rect().size
		var aspect := sz.x / maxf(1.0, sz.y)
		cam.size = maxf(tall, 2.0 * reach / aspect) * 1.2
		cam.position.y = tall * 0.45 + 3.0   # the view ray drops 0.3 per unit over the 10 units to the model
		_t += d
		if _t > 3.5 and rig:
			_t = 0.0
			_n += 1
			rig.play("attack" if _n % 2 == 1 else "cast")

## The bare drawing (portraits/<id>.png, or its drawn idle/walk/fly frames) with an
## oval shadow; the still drawing breathes with a gentle squash.
static func figure(id: String, evolved := false, pedestal := true, flip := false) -> Control:
	var f := Figure.new()
	f.still = AssetLib.icon(id, evolved)
	var anims: Dictionary = AssetLib.anim_frames(id)
	for a in ["idle", "walk", "fly"]:
		if anims.has(a):
			f.frames = anims[a]
			break
	f.pedestal = pedestal
	f.flip = flip
	return f

class Figure extends Control:
	const FRAME_BODY := 256.0   # body height of every frame in anims/ (split_sheet.py)
	const INK := Color("2b1a10")
	var still: Texture2D
	var frames: Array = []
	var pedestal := true
	var flip := false
	var _art := TextureRect.new()
	var _k := 0
	var _feet := Vector2.ZERO
	var _rx := 0.0
	var _r := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_art.texture = frames[0] if not frames.is_empty() else still
		_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art.stretch_mode = TextureRect.STRETCH_SCALE
		_art.flip_h = flip
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_art)
		resized.connect(_layout)
		_layout()
		if frames.size() > 1:
			var t := Timer.new()
			t.wait_time = 0.125
			t.autostart = true
			t.timeout.connect(_next)
			add_child(t)
		else:
			var tw := _art.create_tween().set_loops()
			tw.tween_property(_art, "scale", Vector2(0.985, 1.035), 0.9).set_trans(Tween.TRANS_SINE)
			tw.tween_property(_art, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)

	func _next() -> void:
		_k = (_k + 1) % frames.size()
		_art.texture = frames[_k]

	func _layout() -> void:
		var tex := _art.texture
		if tex == null or size.x < 2.0 or size.y < 2.0: return
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var body := FRAME_BODY if not frames.is_empty() else th
		var top := 0.82 if pedestal else 0.94
		var k := minf(size.y * (top - 0.1) / body, size.x * 0.8 / tw)
		k = minf(k, size.y * (top - 0.04) / th)
		_feet = Vector2(size.x * 0.5, size.y * top)
		_art.size = Vector2(tw, th) * k
		_art.position = _feet - Vector2(_art.size.x * 0.5, _art.size.y)
		_art.pivot_offset = Vector2(_art.size.x * 0.5, _art.size.y)
		_rx = minf(_art.size.x * 0.42, size.x * 0.3)
		_r = minf(_rx * 1.35, (size.y * (1.0 - top) - 6.0) / (1.9 * 0.22))
		queue_redraw()

	func _draw() -> void:
		if _rx <= 0.0: return
		if pedestal:
			var ry := _r * 0.22
			var drop := ry * 0.9
			var low := _feet + Vector2(0, drop)
			_oval(low, _r + 4, ry + 4, INK)
			draw_rect(Rect2(_feet.x - _r - 4, _feet.y, (_r + 4) * 2, drop), INK)
			_oval(low, _r, ry, Color("6a3e1c"))
			draw_rect(Rect2(_feet.x - _r, _feet.y, _r * 2, drop), Color("6a3e1c"))
			_oval(_feet, _r + 4, ry + 4, INK)
			_oval(_feet, _r, ry, Color("a8743e"))
			_oval(_feet, _r * 0.62, ry * 0.62, Color("8a5a2e"))
			_oval(_feet, _r * 0.56, ry * 0.56, Color("a8743e"))
		_oval(_feet, _rx, _rx * 0.26, Color(0.08, 0.04, 0.0, 0.35))

	func _oval(c: Vector2, rx: float, ry: float, col: Color) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
		draw_circle(Vector2.ZERO, rx, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
