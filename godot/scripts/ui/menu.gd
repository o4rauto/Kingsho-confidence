extends Control
## Title screen: painted landscape, big crest logo, JOGAR → local save slots
## (3 slots) → castle gates → world map.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const TitleArt := preload("res://scripts/ui/title_art.gd")
const Screen := preload("res://scripts/ui/screen.gd")

var _slots: Control
var _logo: Control

func _ready() -> void:
	Sfx.play_menu_music()
	var bg := UIKit.art("ui/menu_bg.png")
	if bg:
		var r := UIKit.art_rect(bg)
		UIKit.full_rect(r)
		add_child(r)
	else:
		var art := TitleArt.new()
		UIKit.full_rect(art)
		add_child(art)
		_build_heroes()   # painted art already has its own scene

	var top := UIKit.sound_toggles()
	top.position = Vector2(20, 24)
	add_child(top)

	_logo = _make_logo()
	add_child(_logo)
	UIKit.pop_in(_logo, 0.05)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	col.anchor_top = 1.0; col.anchor_bottom = 1.0
	col.offset_left = -230; col.offset_right = 230; col.offset_top = -420; col.offset_bottom = -170
	col.add_theme_constant_override("separation", 22)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)
	var play := UIKit.button("JOGAR", _open_slots, UIKit.WOOD, Vector2(460, 124), 64)
	col.add_child(play)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	for b in [UIKit.button("AJUSTES", func(): Nav.go("settings", {}, true), UIKit.WOOD_DARK, Vector2(222, 80), 30),
			UIKit.button("CRÉDITOS", _credits, UIKit.WOOD_DARK, Vector2(222, 80), 30)]:
		row.add_child(b)
	UIKit.pop_in(play, 0.3)

	var ver := UIKit.label("v0.3", 22, UIKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-120, -50)
	ver.size = Vector2(100, 40)
	add_child(ver)
	if Nav.params.get("slots", false):
		_open_slots()

func _make_logo() -> Control:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
	holder.position = Vector2(-330, 120)
	holder.size = Vector2(660, 360)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo := UIKit.art("ui/logo.png")
	if logo:
		var r := UIKit.art_rect(logo, false)
		UIKit.full_rect(r)
		holder.add_child(r)
		return holder
	var crest := LogoArt.new()
	crest.size = holder.size
	holder.add_child(crest)
	var v := VBoxContainer.new()
	UIKit.full_rect(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -34)
	holder.add_child(v)
	var t1 := UIKit.label("BASTION", 118, Color("e9edf5"))
	var t2 := UIKit.label("RUSH", 132, Color("ff7a1a"))
	for t in [t1, t2]:
		t.autowrap_mode = TextServer.AUTOWRAP_OFF
		t.add_theme_constant_override("outline_size", 30)
		t.add_theme_color_override("font_outline_color", Color("2a1608"))
		v.add_child(t)
	return holder

## Hero (left) facing a Rush brute (right), drawn, standing in the landscape.
func _build_heroes() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.anchor_left = 0.0; row.anchor_right = 1.0
	row.anchor_top = 0.5; row.anchor_bottom = 0.86
	add_child(row)
	for spec in [["warden", false], ["ravager", true]]:
		var f := Screen.figure(spec[0], false, false, spec[1])
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(f)

func _open_slots() -> void:
	if _slots: _slots.queue_free()
	_slots = UIKit.modal(self)
	var p := UIKit.wood_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-320, -400)
	p.custom_minimum_size = Vector2(640, 0)
	_slots.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	p.add_child(v)
	v.add_child(UIKit.label("SAVE LOCAL", 46, UIKit.EMBER_HI))
	for i in range(1, Save.SLOTS + 1):
		v.add_child(_slot_row(i))
	v.add_child(UIKit.button("FECHAR", func(): _slots.queue_free(); _slots = null, UIKit.WOOD_DARK, Vector2(0, 76), 30))
	UIKit.pop_in(p)

func _slot_row(i: int) -> Control:
	var info := Save.slot_summary(i)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var text := "NOVO JOGO"
	if not info.is_empty():
		text = "%s   ★ %d   Reinos %d/10" % [info.hero, info.stars, info.cleared]
	var b := UIKit.button(text, func(): _choose(i), UIKit.WOOD_HI if info.is_empty() else UIKit.GOOD.darkened(0.15), Vector2(0, 104), 32 if info.is_empty() else 26)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(b)
	if not info.is_empty():
		var del := UIKit.icon_button("x", func(): _confirm_delete(i), "", 90.0, UIKit.DANGER)
		h.add_child(del)
	return h

func _choose(i: int) -> void:
	Save.use_slot(i)
	Sfx.play("deploy")
	Nav.go("map", {}, true)

func _confirm_delete(i: int) -> void:
	var o := UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-280, -170)
	p.custom_minimum_size = Vector2(560, 0)
	o.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(UIKit.ink("Apagar o save %d para sempre?" % i, 34))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var yes := UIKit.button("APAGAR", func():
		Save.delete_slot(i)
		o.queue_free()
		_open_slots(), UIKit.DANGER, Vector2(240, 84), 30)
	var no := UIKit.button("CANCELAR", func(): o.queue_free(), UIKit.WOOD, Vector2(240, 84), 30)
	h.add_child(yes)
	h.add_child(no)

func _credits() -> void:
	var o := UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-300, -300)
	p.custom_minimum_size = Vector2(600, 0)
	o.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(UIKit.ink("BASTION RUSH", 48, Color("b0402a")))
	v.add_child(UIKit.ink("Direção e design: você\nCódigo e sistemas: Claude\nArte: pipeline de IA (imagens → 3D → Blender → Mixamo)\nFonte: Lilita One (OFL)\nMotor: Godot 4", 26))
	v.add_child(UIKit.button("FECHAR", func(): o.queue_free(), UIKit.WOOD, Vector2(0, 80), 30))
	UIKit.pop_in(p)

## Crest behind the title: crossed swords, a round shield, chains.
class LogoArt extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c := size / 2.0
		var ink := Color("2a1608")
		for s in [-1.0, 1.0]:
			var a := c + Vector2(-230 * s, 150)
			var b := c + Vector2(200 * s, -170)
			draw_line(a, b, ink, 34)
			draw_line(a, b, Color("cfd6e4"), 20)
			draw_line(a + (b - a) * 0.12 + Vector2(-40, -30) * s, a + (b - a) * 0.12 + Vector2(40, 30) * s, ink, 26)
			draw_line(a + (b - a) * 0.12 + Vector2(-36, -27) * s, a + (b - a) * 0.12 + Vector2(36, 27) * s, Color("c8902a"), 14)
		draw_circle(c, 190, ink)
		draw_circle(c, 178, Color("8a5630"))
		draw_circle(c, 150, Color("6a3e1c"))
		for i in 12:
			var ang := i * TAU / 12.0
			draw_circle(c + Vector2(cos(ang), sin(ang)) * 164, 9, Color("cfd6e4"))
