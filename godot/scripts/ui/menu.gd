extends Control
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Main menu — title, a live 3D turntable of the Warden (shows your real
## pipeline model once assets/models/warden.glb exists), and navigation.

var _turntable: Node3D

func _ready() -> void:
	UIKit.backdrop(self, UIKit.EMBER)
	var bg := UIKit.art("ui/menu_bg.png")
	if bg:
		var r := UIKit.art_rect(bg)
		UIKit.full_rect(r)
		r.modulate = Color(0.75, 0.75, 0.8)
		add_child(r)
	_build_preview()

	var v := VBoxContainer.new()
	UIKit.full_rect(v)
	v.add_theme_constant_override("separation", 18)
	v.offset_top = 60
	v.offset_bottom = -40
	add_child(v)

	v.add_child(UIKit.currency_bar())
	var kicker := UIKit.label("A E T H E L G A R D", 24, UIKit.DIM)
	v.add_child(kicker)
	var logo := UIKit.art("ui/logo.png")
	var title: Control
	var title2: Control
	if logo:
		title = UIKit.art_rect(logo, false)
		title.custom_minimum_size = Vector2(0, 300)
		title2 = Control.new()
	else:
		title = UIKit.label("BASTION", 108, UIKit.EMBER_HI)
		title2 = UIKit.label("RUSH", 108, UIKit.EMBER)
	v.add_child(title)
	v.add_child(title2)
	v.add_child(UIKit.label("Segure a última luz contra a Debandada", 26, UIKit.DIM))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(buttons)
	var play := UIKit.button("JOGAR", func(): Nav.go("realm_select"), UIKit.EMBER, Vector2(460, 110), 52)
	buttons.add_child(play)
	buttons.add_child(UIKit.button("CAMPEÕES", func(): Nav.go("collection"), UIKit.PANEL_HI, Vector2(460, 92), 38))
	buttons.add_child(UIKit.button("AJUSTES", func(): Nav.go("settings"), UIKit.PANEL_HI, Vector2(460, 92), 38))

	var cleared: int = Save.data.cleared.size()
	v.add_child(UIKit.label("Reinos conquistados: %d/%d   ·   v0.2 (Godot)" % [cleared, GameData.realms.size()], 22, Color(1, 1, 1, 0.4)))

	UIKit.pop_in(title, 0.05)
	UIKit.pop_in(title2, 0.15)
	UIKit.pop_in(play, 0.3)

func _build_preview() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	svc.anchor_left = 0.0; svc.anchor_right = 1.0
	svc.anchor_top = 0.36; svc.anchor_bottom = 0.68
	add_child(svc)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	svc.add_child(vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.4, 4.2)
	cam.fov = 38
	vp.add_child(cam)
	cam.look_at(Vector3(0, 0.95, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_energy = 1.3
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("6f7fae")
	env.environment.ambient_light_energy = 0.7
	vp.add_child(env)
	_turntable = Node3D.new()
	vp.add_child(_turntable)
	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new(); cyl.top_radius = 0.8; cyl.bottom_radius = 0.95; cyl.height = 0.25
	pedestal.mesh = cyl
	pedestal.material_override = AssetLib.mat(Color("2c3c63"))
	pedestal.position.y = -0.125
	_turntable.add_child(pedestal)
	var warden := AssetLib.make("warden", "warden", UIKit.EMBER, 1.9)
	_turntable.add_child(warden)

func _process(delta: float) -> void:
	if _turntable:
		_turntable.rotation.y += delta * 0.6
