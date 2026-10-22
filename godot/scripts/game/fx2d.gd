extends RefCounted
## Hand-drawn 2D effects (Kingdom-Rush look): projectiles, impacts, rings,
## puddles, lightning. Each effect reads its frames from
##     assets/art/fx/<name>_<k>.png   (k = 0.., drawn art from the pipeline)
## and, until that art exists, falls back to the placeholder drawings in
## assets/art/fx_fallback/<name>.png (made by pipeline/tools/make_fx_fallback.py).
##
## Effect names: arrow, bolt, orb, cannonball, burst, smoke, ring, puddle,
## zap, shadow.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

static var _frames := {}

## Frames for an effect: drawn art if present, else the procedural fallback.
static func frames(name: String) -> Array[Texture2D]:
	if _frames.has(name):
		return _frames[name]
	var list: Array[Texture2D] = []
	for k in 12:
		var t := UIKit.art("fx/%s_%d.png" % [name, k])
		if t == null: break
		list.append(t)
	if list.is_empty():
		var fb := UIKit.art("fx_fallback/%s.png" % name)
		if fb == null:
			fb = UIKit.art("fx_fallback/orb.png")
		list.append(fb)
	_frames[name] = list
	return list

static func drawn(name: String) -> bool:
	return frames(name).size() > 1 or UIKit.art("fx/%s_0.png" % name) != null

## A sprite showing `name`, `size` world units wide.
## mode: "billboard" (faces camera), "ground" (lies flat), "free" (caller orients).
static func sprite(name: String, size: float, mode := "billboard", col := Color.WHITE) -> Sprite3D:
	var tex: Texture2D = frames(name)[0]
	var s := Sprite3D.new()
	s.texture = tex
	s.shaded = false
	s.double_sided = true
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.pixel_size = size / float(tex.get_width())
	s.modulate = col
	match mode:
		"billboard":
			s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		"ground":
			s.rotation.x = -PI / 2.0
	return s

## Points a "free" sprite (drawn pointing right) along `dir`, facing the camera.
static func orient(s: Sprite3D, dir: Vector3, cam: Camera3D) -> void:
	if cam == null or dir.length_squared() < 0.000001: return
	var back := cam.global_transform.basis.z
	var x := (dir - back * dir.dot(back)).normalized()
	if x.length_squared() < 0.5: return
	var y := back.cross(x).normalized()
	var k := s.scale
	s.global_transform.basis = Basis(x, y, back) * Basis.from_scale(k)

## One-shot effect: plays the drawn frames, or pops/fades the fallback.
static func play(parent: Node, name: String, pos: Vector3, size: float, mode := "billboard", col := Color.WHITE, dur := 0.35) -> Sprite3D:
	var s := sprite(name, size, mode, col)
	s.position = pos
	parent.add_child(s)
	var list := frames(name)
	var tw := s.create_tween()
	if list.size() > 1:
		var step := dur / float(list.size())
		for i in range(1, list.size()):
			tw.tween_interval(step)
			tw.tween_callback(func(): s.texture = list[i])
		tw.tween_interval(step)
	else:
		var base := s.scale
		s.scale = base * 0.35
		tw.tween_property(s, "scale", base, dur * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 0.0, dur * 0.55)
	tw.tween_callback(s.queue_free)
	return s
