extends RefCounted
## UIKit — chunky cartoon widgets: carved-wood buttons, parchment panels,
## thick outlined text. Buttons react on press-down for a snappy mobile feel.

const Icon := preload("res://scripts/ui/icon.gd")
const FONT_PATH := "res://assets/fonts/LilitaOne.woff2"

# Palette — warm wood, parchment, gold (storybook fantasy).
const WOOD := Color("7a4a24")
const WOOD_HI := Color("9a6230")
const WOOD_DARK := Color("3d2210")
const PARCH := Color("f0dcae")
const PARCH_DARK := Color("d4b47a")
const INK := Color("4a2a10")
const NIGHT := Color("2a1608")
const PANEL := WOOD
const PANEL_HI := WOOD_HI
const STROKE := WOOD_DARK
const TEXT := Color("fff6e0")
const DIM := Color("e6cf9e")
const EMBER := Color("ff8a2a")
const EMBER_HI := Color("ffe08a")
const AETHER := Color("4cc2ff")
const GOOD := Color("6fcf3f")
const DANGER := Color("e8452c")
const GOLD := Color("ffcf3d")
const STONE := Color("8d93a6")

static var _font: Font

static func font() -> Font:
	if _font == null:
		# Raw file first: works on a fresh clone before the editor has imported
		# anything. Exported builds only ship the imported resource.
		if FileAccess.file_exists(FONT_PATH):
			var f := FontFile.new()
			if f.load_dynamic_font(FONT_PATH) == OK:
				_font = f
		if _font == null and ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH)
		if _font == null:
			_font = ThemeDB.fallback_font
	return _font

static func box(bg: Color, border: Color = STROKE, radius := 18, bw := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16; s.content_margin_right = 16
	s.content_margin_top = 10; s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 6)
	return s

## Cartoon button face: light top edge + thick dark bottom "lip".
static func face(col: Color, pressed := false) -> StyleBoxFlat:
	var s := box(col, col.darkened(0.55), 20, 4)
	s.border_width_bottom = 4 if pressed else 10
	s.border_width_top = 6 if pressed else 4
	s.border_color = col.darkened(0.55)
	s.shadow_offset = Vector2(0, 3 if pressed else 6)
	return s

static func label(text: String, size := 28, color: Color = TEXT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", NIGHT)
	l.add_theme_constant_override("outline_size", maxi(4, size / 5))
	# Short captions never wrap (inside HBoxes a wrapping label collapses to
	# zero width and stacks letters vertically); paragraphs do.
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if (text.length() > 24 or text.contains("\n")) else TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Dark ink text for parchment surfaces (no outline).
static func ink(text: String, size := 26, color: Color = INK, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, align)
	l.add_theme_constant_override("outline_size", 0)
	return l

static func button(text: String, cb: Callable, color: Color = EMBER, size := Vector2(420, 96), font_size := 40) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", font_size)
	for k in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, TEXT)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	b.add_theme_color_override("font_outline_color", NIGHT)
	b.add_theme_constant_override("outline_size", maxi(5, font_size / 5))
	b.add_theme_stylebox_override("normal", face(color))
	b.add_theme_stylebox_override("hover", face(color.lightened(0.06)))
	b.add_theme_stylebox_override("pressed", face(color.darkened(0.1), true))
	b.add_theme_stylebox_override("disabled", face(Color("6a5a4a")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pivot_offset = size / 2.0
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	b.pressed.connect(func():
		Sfx.play("click")
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.93, 0.93), 0.05)
		tw.tween_property(b, "scale", Vector2.ONE, 0.08)
		cb.call())
	return b

## Round wooden button holding a drawn icon (+ optional caption under it).
static func icon_button(kind: String, cb: Callable, caption := "", size := 96.0, col: Color = WOOD) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var b := button("", cb, col, Vector2(size, size), 20)
	for st in ["normal", "hover", "pressed"]:
		var sb: StyleBoxFlat = b.get_theme_stylebox(st)
		sb.set_corner_radius_all(int(size / 2.0))
	var ic := Icon.make(kind, size * 0.6)
	ic.position = Vector2(size * 0.2, size * 0.16)
	ic.size = Vector2(size * 0.6, size * 0.6)
	b.add_child(ic)
	b.set_meta("icon", ic)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	if caption != "":
		var l := label(caption, 20, TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.add_child(l)
	v.set_meta("button", b)
	return v

## Sound + music toggles (top-left on title/map like the classics).
static func sound_toggles() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	for key in ["sfx", "music"]:
		var k: String = key
		var holder: Array = []
		var w := icon_button("sound" if k == "sfx" else "music", func():
			Save.settings[k] = not Save.settings[k]
			Save.save_settings()
			if k == "music": Sfx.set_music(Save.settings.music)
			holder[0].set_off(not Save.settings[k]), "", 72.0)
		var ic = w.get_meta("button").get_meta("icon")
		ic.set_off(not Save.settings[k])
		holder.append(ic)
		h.add_child(w)
	return h

static func panel(bg: Color = PANEL, border: Color = STROKE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border))
	return p

## Parchment sheet with a wooden frame.
static func parchment_panel(frame := true) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(PARCH, WOOD if frame else PARCH_DARK, 22, 10 if frame else 4)
	s.content_margin_left = 24; s.content_margin_right = 24
	s.content_margin_top = 18; s.content_margin_bottom = 18
	p.add_theme_stylebox_override("panel", s)
	return p

## Wooden board panel.
static func wood_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(WOOD, WOOD_DARK, 22, 8)
	s.content_margin_left = 20; s.content_margin_right = 20
	s.content_margin_top = 16; s.content_margin_bottom = 16
	p.add_theme_stylebox_override("panel", s)
	return p

## Hanging wooden title plaque.
static func plaque(text: String, size := 40) -> Control:
	var p := wood_panel()
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := label(text, size, EMBER_HI)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(l)
	return p

static var _parch_tex: Texture2D
static var _sky_tex: Texture2D

## Parchment texture with burnt edges, baked once into a small image.
static func parchment_texture() -> Texture2D:
	if _parch_tex:
		return _parch_tex
	var w := 90
	var h := 160
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.seed = 7
	n.frequency = 0.08
	var base := Color("ecd6a4")
	var edge := Color("8a5a2a")
	for y in h:
		for x in w:
			var u := float(x) / (w - 1) * 2.0 - 1.0
			var v := float(y) / (h - 1) * 2.0 - 1.0
			var vig := clampf(maxf(absf(u), absf(v)) * 1.0 + n.get_noise_2d(x * 3.0, y * 3.0) * 0.12 - 0.72, 0.0, 1.0) / 0.28
			var c := base.lerp(Color("d8bb84"), (n.get_noise_2d(x, y) + 1.0) * 0.3)
			img.set_pixel(x, y, c.lerp(edge, clampf(vig, 0.0, 1.0) * 0.85))
	_parch_tex = ImageTexture.create_from_image(img)
	return _parch_tex

static func parchment_backdrop(parent: Control) -> void:
	parent.add_child(_bg_rect(Color("3d2210")))
	var r := TextureRect.new()
	r.texture = parchment_texture()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

static func _bg_rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Bright storybook sky (cheap: one tiny gradient texture).
static func backdrop(parent: Control, accent: Color = EMBER) -> void:
	var g := Gradient.new()
	g.set_color(0, Color("5ab8f0"))
	g.set_color(1, Color("bfe6ff"))
	g.add_point(0.82, accent.lerp(Color("ffe8b0"), 0.7))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

## Elastic "pop" in for a control (cartoon UI feel).
static func pop_in(c: Control, delay := 0.0) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(0.6, 0.6)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(delay)

## Small wooden counter: icon + number.
static func counter(kind: String, value: String, col: Color = TEXT) -> PanelContainer:
	var p := wood_panel()
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 6
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 6
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(h)
	h.add_child(Icon.make(kind, 44))
	var l := label(value, 32, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	p.set_meta("label", l)
	return p

static func currency_bar() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 14)
	h.add_child(counter("coin", str(int(Save.data.gold)), GOLD))
	h.add_child(counter("star", "%d" % Save.free_stars(), EMBER_HI))
	return h

static func full_rect(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)

## Dimmed modal layer that swallows taps.
static func modal(parent: Control) -> ColorRect:
	var o := ColorRect.new()
	o.color = Color(0.08, 0.04, 0.0, 0.72)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(o)
	return o

## Art slot: loads res://assets/art/<rel> (generated by pipeline/tools/generate_art.py).
## Returns null when the image hasn't been generated yet.
static var _art_cache: Dictionary = {}
static func art(rel: String) -> Texture2D:
	if _art_cache.has(rel):
		return _art_cache[rel]
	var path := "res://assets/art/" + rel
	var tex: Texture2D = null
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img: tex = ImageTexture.create_from_image(img)
	if tex == null and ResourceLoader.exists(path):
		tex = load(path)
	_art_cache[rel] = tex
	return tex

## Realm picture: painted key art wins, else the rendered battlefield thumbnail.
static func realm_pic(id: String) -> Texture2D:
	var t := art("realms/%s.png" % id)
	return t if t else art("thumbs/%s.png" % id)

static func art_rect(tex: Texture2D, cover := true) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
