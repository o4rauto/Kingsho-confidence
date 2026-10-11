extends Control
## The world map of Aethelgard, inked on parchment and drawn once.
## Each realm gets a landmark near its flag; a dashed road links them in order.

const INK := Color("5a3a1a")
const INK_SOFT := Color(0.35, 0.22, 0.1, 0.35)

var points: Array[Vector2] = []     # realm node centres (px), set by the map screen
var reached := 1                    # how many path segments are "walked"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	# Sea (bottom-left) with waves
	var sea := PackedVector2Array([Vector2(0, h * 0.7), Vector2(w * 0.12, h * 0.74), Vector2(w * 0.1, h * 0.82),
		Vector2(w * 0.3, h * 0.95), Vector2(w * 0.45, h), Vector2(0, h)])
	draw_colored_polygon(sea, Color(0.36, 0.62, 0.72, 0.55))
	draw_polyline(sea, INK, 3, true)
	for k in 6:
		var p := Vector2(w * (0.04 + (k % 3) * 0.09), h * (0.8 + int(k / 3) * 0.08))
		draw_arc(p, 14, PI * 1.1, PI * 1.9, 6, INK, 2)
		draw_arc(p + Vector2(26, 0), 14, PI * 1.1, PI * 1.9, 6, INK, 2)
	# Colour washes for each region (keep the parchment readable)
	_wash(Vector2(0.24, 0.86), 150, Color(0.45, 0.7, 0.3, 0.25))
	_wash(Vector2(0.56, 0.80), 150, Color(0.3, 0.55, 0.2, 0.3))
	_wash(Vector2(0.82, 0.70), 140, Color(0.25, 0.55, 0.5, 0.3))
	_wash(Vector2(0.62, 0.57), 120, Color(0.45, 0.45, 0.55, 0.25))
	_wash(Vector2(0.30, 0.56), 130, Color(0.5, 0.3, 0.7, 0.25))
	_wash(Vector2(0.14, 0.40), 150, Color(0.85, 0.92, 1.0, 0.55))
	_wash(Vector2(0.48, 0.38), 150, Color(0.95, 0.75, 0.35, 0.35))
	_wash(Vector2(0.84, 0.32), 140, Color(0.75, 0.25, 0.1, 0.3))
	_wash(Vector2(0.64, 0.17), 140, Color(0.45, 0.65, 0.2, 0.3))
	_wash(Vector2(0.36, 0.13), 150, Color(1.0, 0.85, 0.5, 0.35))
	# Landmarks
	for k in 7: _tree(Vector2(w * (0.42 + (k % 4) * 0.07), h * (0.74 + (k % 3) * 0.035)))
	for k in 5: _reed(Vector2(w * (0.72 + k * 0.05), h * (0.76 + (k % 2) * 0.02)))
	_castle(Vector2(w * 0.74, h * 0.53))
	for k in 4: _crystal(Vector2(w * (0.2 + k * 0.05), h * (0.5 + (k % 2) * 0.03)))
	for k in 4: _mountain(Vector2(w * (0.06 + k * 0.08), h * (0.33 + (k % 2) * 0.03)), 60 + (k % 2) * 16, true)
	for k in 4: _dune(Vector2(w * (0.38 + k * 0.07), h * (0.45 + (k % 2) * 0.02)))
	_volcano(Vector2(w * 0.9, h * 0.25))
	for k in 5: _mush(Vector2(w * (0.54 + k * 0.06), h * (0.1 + (k % 2) * 0.03)))
	_spire(Vector2(w * 0.2, h * 0.08))
	for k in 3: _mountain(Vector2(w * (0.5 + k * 0.1), h * 0.62), 40, false)
	# Compass rose
	var cp := Vector2(w * 0.9, h * 0.9)
	draw_circle(cp, 44, INK_SOFT)
	for i in 4:
		var a := i * PI / 2.0
		draw_colored_polygon(PackedVector2Array([cp + Vector2(cos(a), sin(a)) * 54, cp + Vector2(cos(a + 0.4), sin(a + 0.4)) * 14, cp + Vector2(cos(a - 0.4), sin(a - 0.4)) * 14]), INK)
	# The road between realms
	for i in points.size() - 1:
		_dashes(points[i], points[i + 1], i < reached)

func _wash(c: Vector2, r: float, col: Color) -> void:
	var p := Vector2(size.x * c.x, size.y * c.y)
	draw_circle(p, r, col)
	draw_circle(p + Vector2(r * 0.5, r * 0.2), r * 0.7, col)

func _dashes(a: Vector2, b: Vector2, walked: bool) -> void:
	var n := int(a.distance_to(b) / 22.0)
	var mid := (a + b) / 2.0 + (b - a).orthogonal().normalized() * 26.0
	for i in n:
		if i % 2 == 1: continue
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var p0 := _bez(a, mid, b, t0)
		var p1 := _bez(a, mid, b, t1)
		draw_line(p0, p1, Color("b0402a") if walked else INK, 7 if walked else 5)

func _bez(a: Vector2, m: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(m, t).lerp(m.lerp(b, t), t)

func _tree(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, 16), INK, 4)
	draw_circle(p + Vector2(0, -6), 16, Color("6a8a3a"))
	draw_arc(p + Vector2(0, -6), 16, 0, TAU, 14, INK, 2.5)

func _reed(p: Vector2) -> void:
	for k in 3:
		draw_line(p + Vector2(k * 6 - 6, 0), p + Vector2(k * 8 - 8, -26), INK, 2.5)
	draw_line(p + Vector2(-16, 2), p + Vector2(18, 2), Color("3a6a6a"), 3)

func _castle(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-34, -40), Vector2(68, 44)), Color("a8a4a0"))
	draw_rect(Rect2(p + Vector2(-34, -40), Vector2(68, 44)), INK, false, 3)
	for x in [-34, 18]:
		draw_rect(Rect2(p + Vector2(x, -64), Vector2(16, 24)), Color("a8a4a0"))
		draw_rect(Rect2(p + Vector2(x, -64), Vector2(16, 24)), INK, false, 3)
	draw_rect(Rect2(p + Vector2(-8, -18), Vector2(16, 22)), INK)

func _crystal(p: Vector2) -> void:
	var pts := PackedVector2Array([p + Vector2(0, -34), p + Vector2(11, -6), p + Vector2(0, 6), p + Vector2(-11, -6)])
	draw_colored_polygon(pts, Color("9a6ad8"))
	draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 2.5)

func _mountain(p: Vector2, s: float, snow: bool) -> void:
	var pts := PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -s * 1.1), p + Vector2(s, 0)])
	draw_colored_polygon(pts, Color("b8a888"))
	if snow:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.3, -s * 0.77), p + Vector2(0, -s * 1.1), p + Vector2(s * 0.3, -s * 0.77)]), Color("f8fbff"))
	draw_polyline(pts, INK, 3, true)
	draw_line(p + Vector2(0, -s * 1.1), p + Vector2(s * 0.25, -s * 0.2), INK_SOFT, 3)

func _dune(p: Vector2) -> void:
	draw_arc(p, 30, PI * 1.1, PI * 1.9, 10, INK, 3)
	draw_arc(p + Vector2(22, 10), 24, PI * 1.1, PI * 1.9, 10, INK, 2)

func _volcano(p: Vector2) -> void:
	var pts := PackedVector2Array([p + Vector2(-70, 40), p + Vector2(-18, -40), p + Vector2(18, -40), p + Vector2(70, 40)])
	draw_colored_polygon(pts, Color("7a5a4a"))
	draw_polyline(pts, INK, 3)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -40), p + Vector2(16, -40), p + Vector2(8, 0), p + Vector2(-4, 10)]), Color("ff6a2a"))
	for k in 3:
		draw_circle(p + Vector2(-10 + k * 14, -58 - k * 14), 10 + k * 3, Color(0.3, 0.25, 0.2, 0.4))

func _mush(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, -18), INK, 4)
	draw_arc(p + Vector2(0, -18), 14, PI, TAU, 10, INK, 3)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -18), p + Vector2(0, -32), p + Vector2(14, -18)]), Color("8a5ab0"))

func _spire(p: Vector2) -> void:
	var pts := PackedVector2Array([p + Vector2(-16, 60), p + Vector2(-10, -40), p + Vector2(0, -60), p + Vector2(4, -20), p + Vector2(10, -30), p + Vector2(16, 60)])
	draw_colored_polygon(pts, Color("f0e0b0"))
	draw_polyline(pts, INK, 3)
	draw_circle(p + Vector2(0, -70), 10, Color("ffcf3d"))
