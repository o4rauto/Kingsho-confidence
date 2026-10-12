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

## A turntable 3D preview (hero / champion) inside a framed box.
static func preview(model: Node3D, height := 380.0, cam_h := 1.2, dist := 4.4) -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color("bfe0f0"), UIKit.WOOD, 20, 8))
	frame.custom_minimum_size = Vector2(0, height)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(svc)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	svc.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 34
	vp.add_child(cam)
	cam.position = Vector3(0, cam_h + 0.3, dist)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d0dcf0")
	env.environment.ambient_light_energy = 0.9
	vp.add_child(env)
	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new(); cyl.top_radius = 0.9; cyl.bottom_radius = 1.0; cyl.height = 0.2
	pedestal.mesh = cyl
	pedestal.material_override = AssetLib.mat(Color("8a5a2e"))
	pedestal.position.y = -0.1
	vp.add_child(pedestal)
	var spin := Spinner.new()
	vp.add_child(spin)
	spin.add_child(model)
	cam.transform = cam.transform.looking_at(Vector3(0, cam_h * 0.75, 0))
	return frame

class Spinner extends Node3D:
	func _process(d: float) -> void:
		rotation.y += d * 0.7
