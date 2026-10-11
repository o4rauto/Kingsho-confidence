extends RefCounted
class_name UIKit
## UIKit — chunky, touch-friendly widgets with a consistent look.
## Buttons react on press-down for snappy mobile feel.

const FONT_PATH := "res://assets/fonts/LilitaOne.woff2"
const NIGHT := Color("0b1020")
const PANEL := Color("111a30")
const PANEL_HI := Color("1b2745")
const STROKE := Color("2c3c63")
const TEXT := Color("eaf0ff")
const DIM := Color("94a3c8")
const EMBER := Color("ff8a3d")
const EMBER_HI := Color("ffe6a6")
const AETHER := Color("37b6ff")
const GOOD := Color("54e08a")
const DANGER := Color("ff5470")
const GOLD := Color("ffcf4d")

static var _font: Font

static func font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else ThemeDB.fallback_font
	return _font

static func box(bg: Color, border: Color = STROKE, radius := 22, bw := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16; s.content_margin_right = 16
	s.content_margin_top = 10; s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 5)
	return s

static func label(text: String, size := 28, color: Color = TEXT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", maxi(2, size / 7))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func button(text: String, cb: Callable, color: Color = EMBER, size := Vector2(420, 96), font_size := 40) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", font_size)
	var dark := color.get_luminance() > 0.55
	b.add_theme_color_override("font_color", NIGHT if dark else TEXT)
	b.add_theme_color_override("font_pressed_color", NIGHT if dark else TEXT)
	b.add_theme_color_override("font_hover_color", NIGHT if dark else TEXT)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.add_theme_stylebox_override("normal", box(color, color.darkened(0.35), 26, 4))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.08), color.darkened(0.35), 26, 4))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.15), color.darkened(0.45), 26, 4))
	b.add_theme_stylebox_override("disabled", box(PANEL, STROKE, 26, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pivot_offset = size / 2.0
	b.pressed.connect(func():
		Sfx.play("click")
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.05)
		tw.tween_property(b, "scale", Vector2.ONE, 0.08)
		cb.call())
	return b

static func panel(bg: Color = PANEL, border: Color = STROKE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border))
	return p

## Full-screen night backdrop (cheap: one gradient texture).
static func backdrop(parent: Control, accent: Color = EMBER) -> void:
	var g := Gradient.new()
	g.set_color(0, Color("131c33"))
	g.set_color(1, Color("05070f"))
	g.add_point(0.75, accent.darkened(0.75))
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

static func currency_bar() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 14)
	for item in [["OURO", Save.data.gold, GOLD, "gold"], ["FRAG", Save.data.shards, AETHER, "shards"], ["NÚCLEO", Save.data.cores, EMBER, "cores"]]:
		var p := panel(NIGHT)
		p.custom_minimum_size = Vector2(190, 64)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(row)
		var icon := art("ui/currency_%s.png" % item[3])
		var txt := label("%d" % int(item[1]) if icon else "%s %d" % [item[0], int(item[1])], 28 if icon else 24, item[2])
		txt.autowrap_mode = TextServer.AUTOWRAP_OFF
		if icon:
			var ir := art_rect(icon, false)
			ir.custom_minimum_size = Vector2(44, 44)
			row.add_child(ir)
		row.add_child(txt)
		h.add_child(p)
	return h

static func full_rect(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)

## Art slot: loads res://assets/art/<rel> (generated by pipeline/tools/generate_art.py).
## Returns null when the image hasn't been generated yet.
static var _art_cache: Dictionary = {}
static func art(rel: String) -> Texture2D:
	if _art_cache.has(rel):
		return _art_cache[rel]
	var path := "res://assets/art/" + rel
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img: tex = ImageTexture.create_from_image(img)
	_art_cache[rel] = tex
	return tex

static func art_rect(tex: Texture2D, cover := true) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
