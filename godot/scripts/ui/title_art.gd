extends Control
## Title-screen landscape, drawn once: sky, clouds, far mountains, rolling
## hills, the Bastion on its cliff (left) and the glowing rift (right).
## Replaced by assets/art/ui/menu_bg.png when that painting exists.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	# Sky bands
	var sky := [Color("4fb0ec"), Color("6cc2f2"), Color("8fd3f6"), Color("b8e4f8"), Color("ffe6b8")]
	for i in sky.size():
		draw_rect(Rect2(0, h * 0.11 * i, w, h * 0.11 + 2), sky[i])
	# Sun + clouds
	draw_circle(Vector2(w * 0.78, h * 0.13), 70, Color("fff3c4"))
	draw_circle(Vector2(w * 0.78, h * 0.13), 54, Color("ffe08a"))
	for c in [Vector2(0.15, 0.08), Vector2(0.55, 0.05), Vector2(0.9, 0.24), Vector2(0.3, 0.2)]:
		_cloud(Vector2(w * c.x, h * c.y), 1.0 + c.x * 0.3)
	# Far mountains
	_ridge(h * 0.42, 140.0, 5, Color("8aa6c8"), 3)
	_ridge(h * 0.47, 90.0, 7, Color("7a9a7a"), 11)
	# The rift (right)
	var rx := w * 0.82
	var crack := PackedVector2Array([Vector2(rx - 20, h * 0.28), Vector2(rx + 30, h * 0.36), Vector2(rx - 10, h * 0.42),
		Vector2(rx + 40, h * 0.52), Vector2(rx + 10, h * 0.52), Vector2(rx - 30, h * 0.43), Vector2(rx + 5, h * 0.37), Vector2(rx - 45, h * 0.3)])
	draw_colored_polygon(crack, Color("6a2aa8"))
	draw_polyline(crack, Color("d8a8ff"), 6, true)
	# Rolling hills
	_hill(h * 0.58, Color("5aa83a"), 0.0)
	_hill(h * 0.66, Color("6cbf45"), 1.7)
	_hill(h * 0.76, Color("4f9a33"), 3.1)
	# Dirt road winding to the bastion
	var road := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		road.append(Vector2(lerpf(w * 0.86, w * 0.2, t) + sin(t * 6.0) * 60.0, lerpf(h * 0.55, h * 0.98, t)))
	draw_polyline(road, Color("8a5a2a"), 70, true)
	draw_polyline(road, Color("d6a866"), 54, true)
	# Bastion on its cliff (left)
	var bx := w * 0.13
	var by := h * 0.6
	draw_colored_polygon(PackedVector2Array([Vector2(-10, by + 40), Vector2(bx + 150, by + 30), Vector2(bx + 120, h * 0.72), Vector2(-10, h * 0.74)]), Color("7a6a5a"))
	draw_rect(Rect2(bx - 70, by - 150, 140, 190), Color("2e1a0c"))
	draw_rect(Rect2(bx - 64, by - 144, 128, 180), Color("b0b4c0"))
	for k in 4:
		draw_rect(Rect2(bx - 70 + k * 40, by - 178, 26, 32), Color("b0b4c0"))
		draw_rect(Rect2(bx - 70 + k * 40, by - 178, 26, 6), Color("d8dce6"))
	for row in 5:
		draw_line(Vector2(bx - 64, by - 110 + row * 32), Vector2(bx + 64, by - 110 + row * 32), Color("8d93a6"), 3)
	draw_circle(Vector2(bx, by - 30), 26, Color("3d2210"))
	draw_rect(Rect2(bx - 26, by - 30, 52, 66), Color("3d2210"))
	draw_line(Vector2(bx, by - 178), Vector2(bx, by - 260), Color("5a3418"), 6)
	draw_colored_polygon(PackedVector2Array([Vector2(bx + 3, by - 258), Vector2(bx + 80, by - 236), Vector2(bx + 3, by - 214)]), Color("e8452c"))
	# The flame atop
	draw_circle(Vector2(bx + 48, by - 196), 16, Color("ff8a2a"))
	draw_circle(Vector2(bx + 48, by - 200), 9, Color("ffe08a"))
	# Foreground trees
	for t in [Vector2(0.06, 0.9), Vector2(0.94, 0.86), Vector2(0.72, 0.95), Vector2(0.38, 0.97)]:
		_tree(Vector2(w * t.x, h * t.y), 1.0 + t.y * 0.3)

func _cloud(p: Vector2, s: float) -> void:
	for o in [Vector2(-40, 8), Vector2(0, -6), Vector2(40, 8), Vector2(10, 16)]:
		draw_circle(p + o * s, 34 * s, Color(1, 1, 1, 0.92))

func _ridge(base: float, amp: float, n: int, col: Color, seed: int) -> void:
	var pts := PackedVector2Array([Vector2(0, size.y)])
	for i in n * 2 + 1:
		var x := size.x * float(i) / (n * 2)
		var peak := (i % 2 == 1)
		var j := sin(float(i * seed)) * 0.35 + 0.8
		pts.append(Vector2(x, base - (amp * j if peak else amp * 0.15)))
	pts.append(Vector2(size.x, size.y))
	draw_colored_polygon(pts, col)
	for i in range(1, pts.size() - 1):
		if i % 2 == 0 and i + 1 < pts.size() - 1:
			# snow caps on the far range
			if col.b > 0.7:
				var p := pts[i]
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(-26, 34), p + Vector2(26, 34)]), Color("f4f8ff"))

func _hill(base: float, col: Color, phase: float) -> void:
	var pts := PackedVector2Array([Vector2(0, size.y)])
	for i in 25:
		var x := size.x * float(i) / 24.0
		pts.append(Vector2(x, base + sin(float(i) * 0.5 + phase) * 26.0))
	pts.append(Vector2(size.x, size.y))
	draw_colored_polygon(pts, col.darkened(0.25))
	var top := PackedVector2Array()
	for i in range(1, pts.size() - 1):
		top.append(pts[i] + Vector2(0, 8))
	for i in range(top.size() - 1, -1, -1):
		top.append(top[i] + Vector2(0, size.y))
	draw_colored_polygon(top, col)

func _tree(p: Vector2, s: float) -> void:
	draw_rect(Rect2(p + Vector2(-9, -40) * s, Vector2(18, 44) * s), Color("5a3418"))
	draw_circle(p + Vector2(0, -78) * s, 48 * s, Color("2e6a24"))
	draw_circle(p + Vector2(-26, -64) * s, 34 * s, Color("3f8a2e"))
	draw_circle(p + Vector2(22, -92) * s, 30 * s, Color("4f9e38"))
