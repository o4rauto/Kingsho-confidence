extends Control
## Procedural cartoon icons (drawn once, cached by the canvas). Used until
## painted icons exist in assets/art/ui/icon_<kind>.png — that file wins.

var kind := "star"
var color := Color.WHITE
var off := false          # draws a red slash (muted toggles)
var _tex: Texture2D

const INK := Color("2a1608")

static func make(k: String, size := 48.0, col := Color.WHITE) -> Control:
	var i = load("res://scripts/ui/icon.gd").new()
	i.kind = k
	i.color = col
	i.custom_minimum_size = Vector2(size, size)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i

func _ready() -> void:
	var path := "res://assets/art/ui/icon_%s.png" % kind
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img: _tex = ImageTexture.create_from_image(img)
	resized.connect(queue_redraw)

func set_off(v: bool) -> void:
	off = v
	queue_redraw()

func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	if _tex:
		draw_texture_rect(_tex, Rect2(c - Vector2(s, s) / 2.0, Vector2(s, s)), false)
		return
	var r := s * 0.42
	match kind:
		"star": _star(c, r, Color("ffd23d") if color == Color.WHITE else color)
		"star_empty": _star(c, r, Color(0, 0, 0, 0.35))
		"coin":
			draw_circle(c + Vector2(0, s * 0.04), r, INK)
			draw_circle(c, r, Color("ffcf3d"))
			draw_circle(c, r * 0.68, Color("f0a820"))
			draw_rect(Rect2(c - Vector2(r * 0.12, r * 0.4), Vector2(r * 0.24, r * 0.8)), Color("ffe58a"))
		"lock":
			draw_arc(c - Vector2(0, r * 0.2), r * 0.45, PI, TAU, 16, INK, r * 0.32)
			draw_arc(c - Vector2(0, r * 0.2), r * 0.45, PI, TAU, 16, Color("c8ccd8"), r * 0.18)
			_rbox(Rect2(c + Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 1.1)), Color("ffcf3d"))
			draw_circle(c + Vector2(0, r * 0.3), r * 0.15, INK)
		"sound":
			var pts := PackedVector2Array([c + Vector2(-r, -r * 0.35), c + Vector2(-r * 0.4, -r * 0.35), c + Vector2(r * 0.2, -r * 0.9),
				c + Vector2(r * 0.2, r * 0.9), c + Vector2(-r * 0.4, r * 0.35), c + Vector2(-r, r * 0.35)])
			_poly(pts, color)
			draw_arc(c + Vector2(r * 0.2, 0), r * 0.55, -0.9, 0.9, 10, color, r * 0.16)
			draw_arc(c + Vector2(r * 0.2, 0), r * 0.9, -0.9, 0.9, 12, color, r * 0.16)
		"music":
			draw_line(c + Vector2(-r * 0.3, r * 0.55), c + Vector2(-r * 0.3, -r * 0.8), color, r * 0.18)
			draw_line(c + Vector2(r * 0.6, r * 0.35), c + Vector2(r * 0.6, -r * 1.0), color, r * 0.18)
			draw_line(c + Vector2(-r * 0.3, -r * 0.8), c + Vector2(r * 0.6, -r * 1.0), color, r * 0.3)
			draw_circle(c + Vector2(-r * 0.55, r * 0.6), r * 0.32, color)
			draw_circle(c + Vector2(r * 0.35, r * 0.4), r * 0.32, color)
		"back":
			_poly(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(0, -r * 0.8), c + Vector2(0, -r * 0.35), c + Vector2(r, -r * 0.35),
				c + Vector2(r, r * 0.35), c + Vector2(0, r * 0.35), c + Vector2(0, r * 0.8)]), color)
		"gear":
			for i in 8:
				var a := i * TAU / 8.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * r, color, r * 0.36)
			draw_circle(c, r * 0.7, color)
			draw_circle(c, r * 0.3, INK)
		"trophy":
			_poly(PackedVector2Array([c + Vector2(-r * 0.7, -r * 0.8), c + Vector2(r * 0.7, -r * 0.8), c + Vector2(r * 0.4, r * 0.1), c + Vector2(-r * 0.4, r * 0.1)]), Color("ffcf3d"))
			draw_arc(c + Vector2(-r * 0.7, -r * 0.45), r * 0.3, PI * 0.5, PI * 1.5, 8, Color("ffcf3d"), r * 0.14)
			draw_arc(c + Vector2(r * 0.7, -r * 0.45), r * 0.3, -PI * 0.5, PI * 0.5, 8, Color("ffcf3d"), r * 0.14)
			draw_rect(Rect2(c + Vector2(-r * 0.12, r * 0.1), Vector2(r * 0.24, r * 0.45)), Color("e0a020"))
			_rbox(Rect2(c + Vector2(-r * 0.55, r * 0.55), Vector2(r * 1.1, r * 0.35)), Color("8a5a2e"))
		"book":
			_rbox(Rect2(c + Vector2(-r * 0.9, -r * 0.75), Vector2(r * 1.8, r * 1.5)), Color("b0402a"))
			draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 0.62), Vector2(r * 1.5, r * 1.15)), Color("f2e2b8"))
			draw_line(c + Vector2(0, -r * 0.62), c + Vector2(0, r * 0.53), Color("8a5a2e"), r * 0.1)
			for k in 3:
				draw_line(c + Vector2(-r * 0.6, -r * 0.35 + k * r * 0.3), c + Vector2(-r * 0.15, -r * 0.35 + k * r * 0.3), Color("8a5a2e"), r * 0.06)
				draw_line(c + Vector2(r * 0.15, -r * 0.35 + k * r * 0.3), c + Vector2(r * 0.6, -r * 0.35 + k * r * 0.3), Color("8a5a2e"), r * 0.06)
		"hammer":
			draw_line(c + Vector2(-r * 0.7, r * 0.8), c + Vector2(r * 0.25, -r * 0.15), Color("8a5a2e"), r * 0.26)
			var head := PackedVector2Array([c + Vector2(-r * 0.2, -r * 0.6), c + Vector2(r * 0.35, -r * 1.0), c + Vector2(r * 0.95, -r * 0.2), c + Vector2(r * 0.4, r * 0.2)])
			_poly(head, Color("aab4c8"))
		"bow":
			draw_arc(c + Vector2(r * 0.2, 0), r * 0.9, PI * 0.55, PI * 1.45, 16, INK, r * 0.3)
			draw_arc(c + Vector2(r * 0.2, 0), r * 0.9, PI * 0.55, PI * 1.45, 16, Color("c8843a"), r * 0.18)
			var top := c + Vector2(r * 0.2, 0) + Vector2(cos(PI * 0.55), sin(PI * 0.55)) * r * 0.9
			var bot := c + Vector2(r * 0.2, 0) + Vector2(cos(PI * 1.45), sin(PI * 1.45)) * r * 0.9
			draw_line(top, bot, Color("f2ead8"), r * 0.06)
			draw_line(c + Vector2(-r * 0.9, 0), c + Vector2(r * 0.6, 0), INK, r * 0.14)
			_poly(PackedVector2Array([c + Vector2(-r * 0.95, 0), c + Vector2(-r * 0.6, -r * 0.2), c + Vector2(-r * 0.6, r * 0.2)]), Color("dfe6f2"))
		"orb":
			draw_circle(c, r * 0.95, Color(0.64, 0.42, 1.0, 0.35))
			draw_circle(c + Vector2(0, s * 0.04), r * 0.7, INK)
			draw_circle(c, r * 0.7, Color("a46aff"))
			draw_circle(c - Vector2(r * 0.22, r * 0.22), r * 0.22, Color("e8d8ff"))
		"bomb":
			draw_circle(c + Vector2(0, r * 0.15 + s * 0.04), r * 0.72, INK)
			draw_circle(c + Vector2(0, r * 0.15), r * 0.72, Color("3a3e48"))
			draw_circle(c + Vector2(-r * 0.25, -r * 0.05), r * 0.18, Color("8a909e"))
			draw_line(c + Vector2(r * 0.35, -r * 0.4), c + Vector2(r * 0.7, -r * 0.85), Color("c8a070"), r * 0.14)
			draw_circle(c + Vector2(r * 0.72, -r * 0.88), r * 0.16, Color("ffb03a"))
		"ballista":
			draw_line(c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(r * 0.9, -r * 0.3), INK, r * 0.26)
			draw_line(c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(r * 0.9, -r * 0.3), Color("c8843a"), r * 0.14)
			draw_line(c + Vector2(0, -r * 0.9), c + Vector2(0, r * 0.9), INK, r * 0.22)
			draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.9), Color("e8d8b0"), r * 0.1)
			_poly(PackedVector2Array([c + Vector2(0, -r), c + Vector2(-r * 0.22, -r * 0.6), c + Vector2(r * 0.22, -r * 0.6)]), Color("dfe6f2"))
		"cauldron":
			draw_circle(c + Vector2(0, r * 0.2 + s * 0.04), r * 0.75, INK)
			draw_circle(c + Vector2(0, r * 0.2), r * 0.75, Color("3a3e48"))
			draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 0.35), Vector2(r * 1.5, r * 0.3)), Color("7ed957"))
			draw_circle(c + Vector2(-r * 0.2, -r * 0.55), r * 0.16, Color("b8f090"))
			draw_circle(c + Vector2(r * 0.25, -r * 0.75), r * 0.12, Color("b8f090"))
		"bolt":
			_poly(PackedVector2Array([c + Vector2(r * 0.2, -r), c + Vector2(-r * 0.6, r * 0.15), c + Vector2(-r * 0.05, r * 0.15),
				c + Vector2(-r * 0.25, r), c + Vector2(r * 0.6, -r * 0.2), c + Vector2(r * 0.05, -r * 0.2)]), Color("5ac8ff"))
		"helmet", "helmet_hero":
			draw_circle(c + Vector2(0, -r * 0.05), r * 0.8, Color("c8ccd8"))
			draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.05), Vector2(r * 1.6, r * 0.8)), Color("c8ccd8"))
			draw_rect(Rect2(c + Vector2(-r * 0.55, r * 0.05), Vector2(r * 1.1, r * 0.18)), INK)
			draw_line(c + Vector2(0, -r * 0.85), c + Vector2(0, -r * 1.05), Color("e8452c"), r * 0.3)
		"map":
			_poly(PackedVector2Array([c + Vector2(-r, -r * 0.7), c + Vector2(-r * 0.33, -r * 0.9), c + Vector2(r * 0.33, -r * 0.7), c + Vector2(r, -r * 0.9),
				c + Vector2(r, r * 0.7), c + Vector2(r * 0.33, r * 0.9), c + Vector2(-r * 0.33, r * 0.7), c + Vector2(-r, r * 0.9)]), Color("f2e2b8"))
			draw_line(c + Vector2(-r * 0.6, r * 0.4), c + Vector2(r * 0.5, -r * 0.4), Color("b0402a"), r * 0.12)
		"x":
			draw_line(c - Vector2(r, r) * 0.6, c + Vector2(r, r) * 0.6, color, r * 0.32)
			draw_line(c + Vector2(r, -r) * 0.6, c + Vector2(-r, r) * 0.6, color, r * 0.32)
		"heart":
			draw_circle(c + Vector2(-r * 0.42, -r * 0.2), r * 0.5, Color("ff4a5a"))
			draw_circle(c + Vector2(r * 0.42, -r * 0.2), r * 0.5, Color("ff4a5a"))
			_poly(PackedVector2Array([c + Vector2(-r * 0.9, -r * 0.05), c + Vector2(r * 0.9, -r * 0.05), c + Vector2(0, r * 0.9)]), Color("ff4a5a"))
		"skull":
			draw_circle(c + Vector2(0, -r * 0.15), r * 0.75, Color("f2ead8"))
			draw_rect(Rect2(c + Vector2(-r * 0.4, r * 0.3), Vector2(r * 0.8, r * 0.45)), Color("f2ead8"))
			draw_circle(c + Vector2(-r * 0.3, -r * 0.1), r * 0.2, INK)
			draw_circle(c + Vector2(r * 0.3, -r * 0.1), r * 0.2, INK)
		"sword":
			draw_line(c + Vector2(-r * 0.8, r * 0.8), c + Vector2(r * 0.8, -r * 0.8), Color("dfe6f2"), r * 0.26)
			draw_line(c + Vector2(-r * 0.75, r * 0.25), c + Vector2(-r * 0.25, r * 0.75), Color("8a5a2e"), r * 0.22)
		"shield":
			_poly(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8), c + Vector2(r * 0.7, r * 0.2), c + Vector2(0, r * 0.95), c + Vector2(-r * 0.7, r * 0.2)]), color)
		"flag":
			draw_line(c + Vector2(-r * 0.6, r * 0.95), c + Vector2(-r * 0.6, -r * 0.95), Color("6b4423"), r * 0.18)
			_poly(PackedVector2Array([c + Vector2(-r * 0.55, -r * 0.95), c + Vector2(r * 0.9, -r * 0.55), c + Vector2(-r * 0.55, -r * 0.1)]), color)
		"sell":
			_star(c, r * 0.0, color)
			draw_circle(c, r * 0.8, Color("ffcf3d"))
			draw_string(get_theme_default_font(), c + Vector2(-r * 0.3, r * 0.35), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 1.2), INK)
		"up":
			_poly(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.85, 0), c + Vector2(r * 0.35, 0), c + Vector2(r * 0.35, r * 0.9),
				c + Vector2(-r * 0.35, r * 0.9), c + Vector2(-r * 0.35, 0), c + Vector2(-r * 0.85, 0)]), Color("7ed957"))
		_:
			draw_circle(c, r, color)
	if off:
		draw_line(c + Vector2(-r, r), c + Vector2(r, -r), INK, r * 0.34)
		draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Color("ff4a3a"), r * 0.2)

func _poly(pts: PackedVector2Array, col: Color) -> void:
	var sh := PackedVector2Array()
	for p in pts: sh.append(p + Vector2(0, minf(size.x, size.y) * 0.05))
	draw_colored_polygon(sh, INK)
	draw_colored_polygon(pts, col)

func _star(c: Vector2, r: float, col: Color) -> void:
	if r <= 0.0: return
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	_poly(pts, col)

func _rbox(rect: Rect2, col: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.08), rect.size), INK)
	draw_rect(rect, col)
