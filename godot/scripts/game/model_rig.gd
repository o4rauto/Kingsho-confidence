extends Node3D
## Wraps either an imported GLB (AI → Blender → Mixamo pipeline) or a
## procedural placeholder, behind one tiny animation API:
##     rig.play("idle" | "run" | "attack" | "hit" | "die" | "cast")
## GLB animation names are matched loosely, so Mixamo exports such as
## "Armature|mixamo.com|Layer0" renamed to "Run" / "run_forward" all work.
## See /pipeline/04_mixamo_animations.md for the naming convention.

var anim_player: AnimationPlayer
var is_placeholder := true
var current := ""
var _t := 0.0
var _base_y := 0.0
var _attack_t := 0.0
var _hit_t := 0.0
var _body: Node3D  # placeholder part that squashes/bobs
var _wings: Array[Node3D] = []

func setup_glb(scene_root: Node3D, target_height: float) -> void:
	is_placeholder = false
	add_child(scene_root)
	_normalize(scene_root, target_height)
	anim_player = _find_anim(scene_root)
	play("idle")

func setup_placeholder(body: Node3D, wings: Array[Node3D] = []) -> void:
	is_placeholder = true
	_body = body
	_wings = wings
	_base_y = body.position.y

func play(name: String) -> void:
	if name == "attack" or name == "cast":
		_attack_t = 0.18
	elif name == "hit":
		_hit_t = 0.12
	if anim_player:
		var found := _match_anim(name)
		if found != "" and (found != anim_player.current_animation or name == "attack"):
			anim_player.play(found, 0.15)
			if name in ["idle", "run", "fly"]:
				var a := anim_player.get_animation(found)
				if a: a.loop_mode = Animation.LOOP_LINEAR
	if name in ["idle", "run", "fly", "die"]:
		current = name

func _process(delta: float) -> void:
	if not is_placeholder or _body == null:
		return
	_t += delta
	_attack_t = maxf(0.0, _attack_t - delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	var speed := 14.0 if current == "run" else 3.0
	var amp := 0.08 if current == "run" else 0.025
	_body.position.y = _base_y + absf(sin(_t * speed)) * amp
	var s := 1.0 + (0.18 if _attack_t > 0.0 else 0.0) - (0.12 if _hit_t > 0.0 else 0.0)
	_body.scale = Vector3(s, 2.0 - s, s)
	for i in _wings.size():
		_wings[i].rotation.z = sin(_t * 18.0) * 0.7 * (1.0 if i % 2 == 0 else -1.0)
	if current == "die":
		rotation.z = minf(rotation.z + delta * 6.0, PI / 2)

func _match_anim(name: String) -> String:
	if anim_player == null:
		return ""
	var aliases := {
		"idle": ["idle", "breath", "stand"],
		"run": ["run", "walk", "sprint", "jog"],
		"fly": ["fly", "flap", "run"],
		"attack": ["attack", "slash", "shoot", "punch", "cast", "throw"],
		"cast": ["cast", "spell", "attack"],
		"hit": ["hit", "react", "damage"],
		"die": ["die", "death", "dying"],
	}
	var names := anim_player.get_animation_list()
	for key in aliases.get(name, [name]):
		for n in names:
			if String(n).to_lower().contains(key):
				return n
	return ""

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r: return r
	return null

func _normalize(root: Node3D, target_height: float) -> void:
	var aabb := _aabb(root, Transform3D.IDENTITY)
	if aabb.size.y <= 0.0001:
		return
	var k := target_height / aabb.size.y
	root.scale = Vector3.ONE * k
	# Put the feet on y=0 and centre on x/z.
	root.position = Vector3(-aabb.get_center().x * k, -aabb.position.y * k, -aabb.get_center().z * k)

func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var a := _aabb(c, t)
		if a.size != Vector3.ZERO:
			out = a if first else out.merge(a)
			first = false
	return out
