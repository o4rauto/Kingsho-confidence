extends CanvasLayer
## Castle-gate transition: two wooden doors close, the crest stamps, they open.
## Each door is drawn once (cached canvas); only positions are tweened.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

var root: Control
var left: Control
var right: Control
var crest: Control

func _ready() -> void:
	layer = 100
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	left = Door.new()
	right = Door.new()
	right.mirrored = true
	for d in [left, right]:
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.visible = false
		root.add_child(d)
	crest = _make_crest()
	crest.visible = false
	root.add_child(crest)

func _make_crest() -> Control:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -18)
	var logo := UIKit.art("ui/logo.png")
	if logo:
		var r := UIKit.art_rect(logo, false)
		r.custom_minimum_size = Vector2(420, 260)
		v.add_child(r)
	else:
		var t1 := UIKit.label("BASTION", 84, Color("dfe4ee"))
		var t2 := UIKit.label("RUSH", 92, UIKit.EMBER)
		for t in [t1, t2]:
			t.autowrap_mode = TextServer.AUTOWRAP_OFF
			t.add_theme_constant_override("outline_size", 22)
			v.add_child(t)
	return v

func _layout() -> void:
	var s := root.get_viewport_rect().size
	for d in [left, right]:
		d.size = Vector2(s.x / 2.0 + 2.0, s.y)
	crest.size = Vector2(s.x, 300)
	crest.position = Vector2(0, s.y / 2.0 - 150)
	crest.pivot_offset = crest.size / 2.0

func close(done: Callable) -> void:
	_layout()
	var s := root.get_viewport_rect().size
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	left.visible = true; right.visible = true
	left.position = Vector2(-s.x / 2.0, 0)
	right.position = Vector2(s.x, 0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(left, "position:x", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(right, "position:x", s.x / 2.0 - 2.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		Sfx.play("hit", 0.6)
		crest.visible = true
		crest.scale = Vector2(1.6, 1.6)
		crest.modulate.a = 0.0)
	tw.chain().tween_property(crest, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(crest, "modulate:a", 1.0, 0.12)
	tw.chain().tween_interval(0.15)
	tw.chain().tween_callback(done)

func open(done: Callable) -> void:
	var s := root.get_viewport_rect().size
	var tw := create_tween().set_parallel(true)
	tw.tween_property(crest, "modulate:a", 0.0, 0.12)
	tw.chain().tween_property(left, "position:x", -s.x / 2.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(right, "position:x", s.x, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func():
		left.visible = false; right.visible = false; crest.visible = false
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		done.call())

class Door extends Control:
	var mirrored := false
	func _ready() -> void:
		resized.connect(queue_redraw)
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var plank := w / 4.0
		draw_rect(Rect2(0, 0, w, h), Color("5a3418"))
		for i in 4:
			var col := Color("7a4a24").lerp(Color("8a5630"), float(i % 2))
			draw_rect(Rect2(i * plank + 3, 0, plank - 6, h), col)
			# grain
			for k in 6:
				var y := fmod(i * 97.0 + k * 211.0, h)
				draw_line(Vector2(i * plank + 14, y), Vector2(i * plank + plank - 18, y + 22), Color(0, 0, 0, 0.12), 3)
		var edge := w - 10.0 if not mirrored else 0.0
		draw_rect(Rect2(edge, 0, 10, h), Color("2e1a0c"))
		# iron bands with rivets and curled hinges
		for by in [h * 0.18, h * 0.82]:
			draw_rect(Rect2(0, by - 22, w, 44), Color("3a3e48"))
			draw_rect(Rect2(0, by - 22, w, 8), Color("6a707e"))
			for k in 7:
				var x := 22.0 + k * (w - 44.0) / 6.0
				draw_circle(Vector2(x, by), 7, Color("9aa0ae"))
			var hx := w * 0.82 if mirrored else w * 0.18
			draw_arc(Vector2(hx, by - 40), 26, PI * 0.2, PI * 1.6, 14, Color("3a3e48"), 12)
			draw_arc(Vector2(hx, by + 40), 26, -PI * 0.6, PI * 0.8, 14, Color("3a3e48"), 12)
		# ring handle near the seam
		var cx := w - 60.0 if not mirrored else 60.0
		draw_arc(Vector2(cx, h * 0.5 + 60), 30, 0, TAU, 20, Color("2e3038"), 12)
		draw_arc(Vector2(cx, h * 0.5 + 60), 30, 0, TAU, 20, Color("9aa0ae"), 5)
