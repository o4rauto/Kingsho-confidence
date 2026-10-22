extends Node3D
## Wraps either an imported GLB (AI → Blender → Mixamo pipeline) or a
## procedural chibi character, behind one tiny animation API:
##     rig.play("idle" | "run" | "attack" | "hit" | "die" | "cast" | "fly")
## GLB animation names are matched loosely ("Armature|Run", "run_forward"…).
##
## Chibi characters are animated procedurally and always BLENDED (never snap):
##   idle   — breathing, gentle arm sway
##   run    — hop-bob, forward lean, legs and arms swing in opposition
##   attack — wind-up then a fast strike with the weapon arm + body lunge
##   cast   — both arms raise, body lifts
##   hit    — squash and recoil backwards
##   die    — topples over, sinks and shrinks

var anim_player: AnimationPlayer
var is_placeholder := true
var is_sprite := false
var sprite: Sprite3D
var _flip := false
var _frames := {}          # anim -> Array[Texture2D] (hand-drawn frames)
var _still: Texture2D
var _fanim := ""
var _ft := 0.0
const FRAME_BODY := 256.0
const FPS := {"idle": 6.0, "walk": 10.0, "fly": 12.0, "attack": 12.0, "cast": 10.0, "hit": 14.0, "die": 9.0}
var current := "idle"
var _t := 0.0
var _phase := 0.0
var _base_y := 0.0
var _attack_t := 0.0
var _cast_t := 0.0
var _hit_t := 0.0
var _die_t := 0.0
var _run_w := 0.0
var _body: Node3D  # placeholder part that squashes/bobs
var _wings: Array[Node3D] = []
var _limbs := {}         # name -> Node3D
var _rest := {}          # name -> Vector3 rest rotation
var _height := 1.0
var _oneshot := 0.0      # GLB: seconds left of an attack/cast/hit clip; idle/run wait for it

const ATTACK_TIME := 0.32
const CAST_TIME := 0.5
const HIT_TIME := 0.18

func setup_glb(scene_root: Node3D, target_height: float) -> void:
	is_placeholder = false
	add_child(scene_root)
	_normalize(scene_root, target_height)
	anim_player = _find_anim(scene_root)
	play("idle")

## 2D drawn character (Kingdom-Rush look): a billboard standing on the ground,
## animated with squash & stretch, hops, lunges and tints.
func setup_sprite(tex: Texture2D, height: float, shadow: Material, frames := {}) -> void:
	is_placeholder = false
	is_sprite = true
	_height = height
	_frames = frames
	_still = tex
	sprite = Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.double_sided = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var th := float(tex.get_height())
	sprite.pixel_size = height / th
	sprite.centered = true
	sprite.offset = Vector2(0, th / 2.0)
	add_child(sprite)
	var blob := MeshInstance3D.new()
	var c := CylinderMesh.new(); c.top_radius = 0.45; c.bottom_radius = 0.45; c.height = 0.01; c.radial_segments = 16
	blob.mesh = c
	blob.material_override = shadow
	blob.position.y = 0.03
	var w := clampf(height * 0.38, 0.4, 2.2)
	blob.scale = Vector3(w, 1, w * 0.6)
	add_child(blob)
	_t = randf() * 10.0

func setup_placeholder(body: Node3D, wings: Array[Node3D] = [], limbs := {}) -> void:
	is_placeholder = true
	_body = body
	_wings = wings
	_limbs = limbs
	for k in limbs:
		_rest[k] = (limbs[k] as Node3D).rotation
	_base_y = body.position.y
	_t = randf() * 10.0
	var aabb := _aabb(body, Transform3D.IDENTITY)
	_height = maxf(0.3, aabb.size.y)

func play(name: String) -> void:
	if name == "attack":
		_attack_t = ATTACK_TIME
	elif name == "cast":
		_cast_t = CAST_TIME
	elif name == "hit":
		_hit_t = HIT_TIME
	if anim_player:
		# callers ask for idle/run every frame while fighting: let a one-shot clip finish first
		if name in ["idle", "run", "fly"] and _oneshot > 0.0:
			current = name
			return
		var found := _match_anim(name)
		if found != "" and (found != anim_player.current_animation or name in ["attack", "cast", "hit"]):
			anim_player.play(found, 0.15)
			var a := anim_player.get_animation(found)
			if name in ["idle", "run", "fly"]:
				if a: a.loop_mode = Animation.LOOP_LINEAR
			elif name in ["attack", "cast", "hit"] and a:
				_oneshot = a.length
	if name in ["idle", "run", "fly", "die"]:
		current = name

func _process(delta: float) -> void:
	if is_sprite:
		_animate_sprite(delta)
		return
	if _oneshot > 0.0:
		_oneshot -= delta
		if _oneshot <= 0.0 and current not in ["die", ""]:
			var back := current
			current = ""
			play(back)
	if not is_placeholder or _body == null:
		return
	_t += delta
	_attack_t = maxf(0.0, _attack_t - delta)
	_cast_t = maxf(0.0, _cast_t - delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	var running := current == "run" or current == "fly"
	_run_w = move_toward(_run_w, 1.0 if running else 0.0, delta * 6.0)
	_phase += delta * lerpf(2.0, 10.0, _run_w)
	var h := _height

	# Body: breathing + hop, lean, lunge, recoil.
	var breathe := sin(_t * 2.2) * 0.012 * h
	var hop := absf(sin(_phase)) * 0.07 * h * _run_w
	var atk := _attack_curve()
	var cast_k := sin(clampf(1.0 - _cast_t / CAST_TIME, 0.0, 1.0) * PI) if _cast_t > 0.0 else 0.0
	var hit_k := _hit_t / HIT_TIME
	_body.position.y = _base_y + breathe + hop + cast_k * 0.06 * h
	_body.position.z = atk * 0.12 * h - hit_k * 0.08 * h
	_body.rotation.x = 0.14 * _run_w + atk * 0.18 - hit_k * 0.3
	_body.rotation.z = sin(_phase) * 0.05 * _run_w
	var sq := 1.0 + sin(_t * 2.2) * 0.015 - hit_k * 0.12 + absf(cos(_phase)) * 0.04 * _run_w
	_body.scale = _body.scale.lerp(Vector3(2.0 - sq, sq, 2.0 - sq) * _body_scale_base(), minf(1.0, delta * 20.0))

	# Limbs swing in opposition; weapon arm strikes; both arms rise to cast.
	var swing := sin(_phase)
	_set_limb("leg_l", Vector3(swing * 0.75 * _run_w, 0, 0), delta)
	_set_limb("leg_r", Vector3(-swing * 0.75 * _run_w, 0, 0), delta)
	var idle_sway := sin(_t * 2.2) * 0.08
	_set_limb("arm_l", Vector3(-swing * 0.6 * _run_w + idle_sway - cast_k * 2.3, 0, 0), delta)
	_set_limb("arm_r", Vector3(swing * 0.6 * _run_w - idle_sway - cast_k * 2.3 - atk * 2.0 + _windup() * 1.2, 0, 0), delta)

	for i in _wings.size():
		_wings[i].rotation.z = sin(_t * 16.0) * 0.8 * (1.0 if i % 2 == 0 else -1.0)
	if current == "die":
		_die_t += delta
		rotation.z = lerpf(rotation.z, PI / 2.2, minf(1.0, delta * 8.0))
		position.y = lerpf(position.y, -0.2 * h, minf(1.0, delta * 3.0))

func _animate_sprite(delta: float) -> void:
	_t += delta
	_attack_t = maxf(0.0, _attack_t - delta)
	_cast_t = maxf(0.0, _cast_t - delta)
	_hit_t = maxf(0.0, _hit_t - delta)
	var running := current == "run" or current == "fly"
	_run_w = move_toward(_run_w, 1.0 if running else 0.0, delta * 6.0)
	_phase += delta * lerpf(2.4, 11.0, _run_w)
	# Facing: game code turns the rig; the art faces right, so flip when going left.
	var fx := sin(rotation.y)
	if absf(fx) > 0.2: _flip = fx < 0.0
	sprite.flip_h = _flip
	var dir := -1.0 if _flip else 1.0
	var atk := _attack_curve()
	var cast_k := sin(clampf(1.0 - _cast_t / CAST_TIME, 0.0, 1.0) * PI) if _cast_t > 0.0 else 0.0
	var hit_k := _hit_t / HIT_TIME
	var hop := absf(sin(_phase)) * 0.09 * _height * _run_w
	var breathe := sin(_t * 2.4) * 0.025
	var sy := 1.0 + breathe - hit_k * 0.18 + cast_k * 0.12 + absf(cos(_phase)) * 0.06 * _run_w
	var sx := 1.0 - breathe * 0.6 + hit_k * 0.15 + atk * 0.08 + sin(_phase) * 0.05 * _run_w
	sprite.scale = sprite.scale.lerp(Vector3(sx, sy, 1.0), minf(1.0, delta * 22.0))
	sprite.position = Vector3(atk * 0.25 * _height * dir - hit_k * 0.1 * dir, hop, 0)
	if not _frames.is_empty():
		_step_frames(delta)
	var tint := Color.WHITE
	if _hit_t > 0.0: tint = Color(1.0, 0.55, 0.55)
	elif _cast_t > 0.0: tint = Color(1.0, 1.0, 0.75)
	if current == "die":
		_die_t += delta
		if _frames.has("die"):
			tint.a = clampf(1.6 - _die_t * 1.5, 0.0, 1.0)
		else:
			tint.a = clampf(1.0 - _die_t * 3.0, 0.0, 1.0)
			sprite.scale = Vector3(1.3, maxf(0.05, 1.0 - _die_t * 4.0), 1.0)
	sprite.modulate = tint

## Which drawn animation is showing right now (one-shots win over loops).
func _want_anim() -> String:
	if current == "die": return "die"
	if _attack_t > 0.0 and _frames.has("attack"): return "attack"
	if _cast_t > 0.0: return "cast" if _frames.has("cast") else ("attack" if _frames.has("attack") else "")
	if _hit_t > 0.0 and _frames.has("hit"): return "hit"
	if current == "fly" and _frames.has("fly"): return "fly"
	if current == "run" or current == "fly": return "walk" if _frames.has("walk") else ("fly" if _frames.has("fly") else "")
	return "idle"

func _step_frames(delta: float) -> void:
	var a := _want_anim()
	if a != _fanim:
		_fanim = a
		_ft = 0.0
	else:
		_ft += delta
	var list: Array = _frames.get(a, [])
	var tex: Texture2D = _still
	if not list.is_empty():
		var i := int(_ft * FPS.get(a, 10.0))
		i = mini(i, list.size() - 1) if a in ["die", "attack", "cast", "hit"] else i % list.size()
		tex = list[i]
	if sprite.texture != tex:
		sprite.texture = tex
		var th := float(tex.get_height())
		# Frames are normalised so the body is FRAME_BODY px tall (split_sheet.py).
		sprite.pixel_size = _height / (th if tex == _still else FRAME_BODY)
		sprite.offset = Vector2(0, th / 2.0)

var _scale_base := Vector3.ZERO
func _body_scale_base() -> Vector3:
	if _scale_base == Vector3.ZERO:
		_scale_base = _body.scale
	return _scale_base

## 0 → 1 → 0 over the attack: slow wind-up, snappy strike, ease back.
func _attack_curve() -> float:
	if _attack_t <= 0.0: return 0.0
	var k := 1.0 - _attack_t / ATTACK_TIME
	if k < 0.35: return -k / 0.35 * 0.4          # wind-up (lean back)
	if k < 0.55: return lerpf(-0.4, 1.0, (k - 0.35) / 0.2)   # strike
	return lerpf(1.0, 0.0, (k - 0.55) / 0.45)    # recover

func _windup() -> float:
	if _attack_t <= 0.0: return 0.0
	var k := 1.0 - _attack_t / ATTACK_TIME
	return k / 0.35 if k < 0.35 else maxf(0.0, 1.0 - (k - 0.35) / 0.1)

func _set_limb(name: String, add: Vector3, delta: float) -> void:
	var n: Node3D = _limbs.get(name)
	if n == null: return
	var target: Vector3 = _rest[name] + add
	n.rotation = n.rotation.lerp(target, minf(1.0, delta * 18.0))

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
