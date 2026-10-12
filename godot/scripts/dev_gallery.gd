extends Node3D
## Dev-only lineup of every character / tower (used for screenshots):
##   godot --path . -- --scene=dev_gallery --gallery=heroes|enemies|towers

func _ready() -> void:
	var which := "heroes"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gallery="): which = a.substr(10)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("8fd3ff")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d0dcf0")
	env.environment.ambient_light_energy = 0.45
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.shadow_enabled = true
	sun.light_energy = 0.8
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(40, 40)
	ground.mesh = pm
	ground.material_override = AssetLib.mat(Color("74b843"))
	add_child(ground)
	var items: Array = []
	match which:
		"heroes":
			items.append(AssetLib.make("warden", "warden", Save.hero_cape(), 1.8))
			for c in GameData.champions:
				items.append(AssetLib.make(c.id, AssetLib.kind_for(c), c.color, 1.2 if c.id == "wolf_pack" else 1.8, false))
			items.append(AssetLib.make("footman", "", Color("3a6ab0"), 1.5))
			items.append(AssetLib.make("bowman", "", Color("3fae4f"), 1.5))
		"enemies":
			for id in GameData.enemies:
				var e: Dictionary = GameData.enemies[id]
				var r := AssetLib.make(id, e.kind, e.color, e.radius * 2.4)
				if e.kind == "flyer": r.position.y = 0.0
				items.append(r)
		"towers":
			for f in GameData.TOWER_ORDER:
				for t in 3:
					items.append(AssetLib.make_tower(f, t))
			for c in GameData.champions:
				items.append(AssetLib.make_tower(c.family, 2, c.id))
	var cols := 4 if which != "enemies" else 6
	var gap := 2.3 if which != "enemies" else 2.6
	for i in items.size():
		var n: Node3D = items[i]
		n.position += Vector3((i % cols - (cols - 1) / 2.0) * gap, 0, int(i / cols) * gap * 1.1 - 4.0)
		n.rotation.y = 0.35
		add_child(n)
	var cam := Camera3D.new()
	cam.fov = 42
	add_child(cam)
	var rows := int(ceil(items.size() / float(cols)))
	cam.position = Vector3(0, 3.0 + rows * 0.9, 3.0 + rows * 2.0)
	cam.look_at(Vector3(0, 0.8, rows * gap * 0.55 - 4.0))
