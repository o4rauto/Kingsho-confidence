extends CanvasLayer
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Battle HUD. Values are only re-set when they change (cheap on weak GPUs).

var battle
var root: Control
var integrity_bar: ProgressBar
var integrity_lbl: Label
var wave_lbl: Label
var gold_lbl: Label
var aether_bar: ProgressBar
var aether_lbl: Label
var warden_bar: ProgressBar
var ult_btn: Button
var boss_box: Control
var boss_bar: ProgressBar
var boss_lbl: Label
var warning_lbl: Label
var hint_lbl: Label
var cards: Array = []       # [{btn, cd, sel, cost}]
var overlay: Control
var joy: Control
var auto_vec := Vector2.ZERO
var _joy_origin := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _joy_on := false
var _last := {}

func setup(b) -> void:
	battle = b
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_top_bar()
	_bottom()
	_side()
	joy = JoyView.new()
	joy.set_anchors_preset(Control.PRESET_FULL_RECT)
	joy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(joy)
	warning_lbl = UIKit.label("", 44, UIKit.DANGER)
	warning_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_lbl.position = Vector2(-330, 250)
	warning_lbl.size = Vector2(660, 80)
	warning_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(warning_lbl)
	hint_lbl = UIKit.label("", 24, UIKit.EMBER_HI)
	hint_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint_lbl.position = Vector2(-320, 150)
	hint_lbl.size = Vector2(640, 90)
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint_lbl)

func _bar(color: Color, h: int) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, h)
	p.add_theme_stylebox_override("background", UIKit.box(Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.6), h / 2, 0))
	p.add_theme_stylebox_override("fill", UIKit.box(color, color.darkened(0.3), h / 2, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _top_bar() -> void:
	var top := UIKit.panel(Color(0.04, 0.06, 0.12, 0.85))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 12; top.offset_right = -12; top.offset_top = 12; top.offset_bottom = 110
	root.add_child(top)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	top.add_child(h)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	integrity_lbl = UIKit.label("BASTIÃO 100", 24, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	left.add_child(integrity_lbl)
	integrity_bar = _bar(UIKit.GOOD, 20)
	integrity_bar.max_value = GameData.BASTION_MAX
	left.add_child(integrity_bar)
	var pause := UIKit.button("II", func(): battle.toggle_pause(), UIKit.PANEL_HI, Vector2(80, 76), 34)
	h.add_child(pause)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	wave_lbl = UIKit.label("ONDA 1", 30, UIKit.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(wave_lbl)
	gold_lbl = UIKit.label("OURO 0", 24, UIKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(gold_lbl)
	# Boss bar
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_box.offset_left = 30; boss_box.offset_right = -30; boss_box.offset_top = 120; boss_box.offset_bottom = 190
	boss_box.visible = false
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	boss_lbl = UIKit.label("", 26, UIKit.DANGER)
	boss_box.add_child(boss_lbl)
	boss_bar = _bar(UIKit.DANGER, 22)
	boss_box.add_child(boss_bar)

func _bottom() -> void:
	var tray := UIKit.panel(Color(0.04, 0.06, 0.12, 0.92))
	tray.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tray.offset_top = -270; tray.offset_left = 8; tray.offset_right = -8; tray.offset_bottom = -8
	root.add_child(tray)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	tray.add_child(v)
	var ab := Control.new()
	ab.custom_minimum_size = Vector2(0, 34)
	v.add_child(ab)
	aether_bar = _bar(UIKit.AETHER, 34)
	aether_bar.max_value = GameData.AETHER_MAX
	aether_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	ab.add_child(aether_bar)
	aether_lbl = UIKit.label("AETHER 5/10", 24, UIKit.TEXT)
	aether_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ab.add_child(aether_lbl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	for i in battle.deck.size():
		var def := GameData.champion(battle.deck[i])
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 190)
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		var rc: Color = GameData.RARITY_COLOR[def.rarity]
		btn.add_theme_stylebox_override("normal", UIKit.box(UIKit.PANEL_HI, rc, 18, 4))
		btn.add_theme_stylebox_override("hover", UIKit.box(UIKit.PANEL_HI, rc, 18, 4))
		btn.add_theme_stylebox_override("pressed", UIKit.box(UIKit.PANEL, rc, 18, 4))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var idx: int = i
		btn.pressed.connect(func(): battle.select_card(idx))
		row.add_child(btn)
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.offset_top = 10; inner.offset_bottom = -8
		btn.add_child(inner)
		var swatch := TextureRect.new()
		swatch.texture = AssetLib.icon(def.id, Save.champ(def.id).evolved)
		swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		swatch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		swatch.custom_minimum_size = Vector2(0, 92)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var swrap := MarginContainer.new()
		swrap.add_theme_constant_override("margin_left", 22); swrap.add_theme_constant_override("margin_right", 22)
		swrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swrap.add_child(swatch)
		inner.add_child(swrap)
		var cost := UIKit.label(str(def.cost), 32, UIKit.AETHER)
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(cost)
		var nm := UIKit.label(def.name, 20, UIKit.TEXT)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(nm)
		var cd := ColorRect.new()
		cd.color = Color(0, 0, 0, 0.6)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		btn.add_child(cd)
		var sel := Panel.new()
		var ss := StyleBoxFlat.new()
		ss.draw_center = false
		ss.border_color = UIKit.EMBER_HI
		ss.set_border_width_all(8)
		ss.set_corner_radius_all(18)
		sel.add_theme_stylebox_override("panel", ss)
		sel.set_anchors_preset(Control.PRESET_FULL_RECT)
		sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sel.visible = false
		btn.add_child(sel)
		cards.append({"btn": btn, "cd": cd, "sel": sel, "cost": def.cost, "max_cd": 4.0 + def.cost * 0.6})

func _side() -> void:
	warden_bar = _bar(UIKit.EMBER, 22)
	warden_bar.max_value = 1.0
	warden_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	warden_bar.position = Vector2(20, -320)
	warden_bar.size = Vector2(240, 22)
	warden_bar.anchor_top = 1.0; warden_bar.anchor_bottom = 1.0
	warden_bar.offset_top = -316; warden_bar.offset_bottom = -294; warden_bar.offset_left = 20; warden_bar.offset_right = 260
	root.add_child(warden_bar)
	ult_btn = UIKit.button("ULT", func(): battle.warden.release_ult(), UIKit.PANEL, Vector2(130, 130), 38)
	ult_btn.anchor_left = 1.0; ult_btn.anchor_right = 1.0; ult_btn.anchor_top = 1.0; ult_btn.anchor_bottom = 1.0
	ult_btn.offset_left = -150; ult_btn.offset_right = -20; ult_btn.offset_top = -420; ult_btn.offset_bottom = -290
	root.add_child(ult_btn)

## Called once per frame; only touches widgets whose value changed.
func refresh() -> void:
	_set_if("integ", int(ceil(battle.integrity)), func(v):
		integrity_bar.value = v
		integrity_lbl.text = "BASTIÃO %d" % v
		var c := UIKit.GOOD if v > 50 else (UIKit.GOLD if v > 25 else UIKit.DANGER)
		integrity_bar.add_theme_stylebox_override("fill", UIKit.box(c, c.darkened(0.3), 10, 0)))
	_set_if("gold", battle.gold, func(v): gold_lbl.text = "OURO %d" % v)
	_set_if("aether", int(battle.aether * 4.0), func(_v):
		aether_bar.value = battle.aether
		aether_lbl.text = "AETHER %d/%d" % [int(battle.aether), int(GameData.AETHER_MAX)])
	_set_if("whp", int(battle.warden.hp), func(_v): warden_bar.value = battle.warden.hp / battle.warden.max_hp)
	_set_if("ult", int(battle.warden.ult), func(_v):
		var ready: bool = battle.warden.ult_ready()
		ult_btn.text = "ULT!" if ready else "%d%%" % int(battle.warden.ult)
		ult_btn.add_theme_stylebox_override("normal", UIKit.box(UIKit.EMBER if ready else UIKit.PANEL, UIKit.EMBER, 65, 4)))
	for i in cards.size():
		var c: Dictionary = cards[i]
		var cdv: float = battle.card_cd[i]
		var affordable: bool = battle.aether >= c.cost and cdv <= 0.0
		var key := "%d|%d|%d" % [int(affordable), int(battle.selected_card == i), int(ceil(cdv / c.max_cd * 10.0))]
		if _last.get("card%d" % i) == key: continue
		_last["card%d" % i] = key
		c.btn.modulate = Color.WHITE if affordable else Color(0.6, 0.6, 0.7)
		c.sel.visible = battle.selected_card == i
		var frac: float = cdv / c.max_cd
		c.cd.offset_top = -c.btn.size.y * frac
	var boss = null
	for e in battle.enemies:
		if e.is_boss and e.alive: boss = e
	boss_box.visible = boss != null
	if boss:
		boss_lbl.text = boss.def.name.to_upper() + (" [ESCUDO]" if boss.shield > 0.0 else "")
		boss_bar.value = boss.hp_frac() * 100.0

func _set_if(key: String, v, apply: Callable) -> void:
	if _last.get(key) == v: return
	_last[key] = v
	apply.call(v)

func set_wave(n: int, total: int) -> void:
	wave_lbl.text = "ONDA %d/%d" % [n, total]
	UIKit.pop_in(wave_lbl)

func hazard_hint(text: String) -> void:
	hint_lbl.text = text
	var tw := hint_lbl.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(hint_lbl, "modulate:a", 0.0, 0.8)

func flash_warning(text: String) -> void:
	warning_lbl.text = text
	warning_lbl.modulate.a = 1.0
	UIKit.pop_in(warning_lbl)
	var tw := warning_lbl.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(warning_lbl, "modulate:a", 0.0, 0.5)

func banner(title: String, sub: String, color: Color) -> void:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-340, -200)
	v.size = Vector2(680, 200)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UIKit.label(title, 64, color))
	if sub != "":
		v.add_child(UIKit.label(sub, 28, UIKit.DIM))
	root.add_child(v)
	UIKit.pop_in(v)
	var tw := v.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(v, "modulate:a", 0.0, 0.4)
	tw.tween_callback(v.queue_free)

func _dim_overlay() -> Control:
	overlay = ColorRect.new()
	(overlay as ColorRect).color = Color(0.02, 0.03, 0.06, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	return overlay

func show_boons(boons: Array) -> void:
	var o := _dim_overlay()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 40; v.offset_right = -40; v.offset_top = 220; v.offset_bottom = -200
	v.add_theme_constant_override("separation", 22)
	o.add_child(v)
	v.add_child(UIKit.label("ESCOLHA UMA BÊNÇÃO", 48, UIKit.EMBER_HI))
	v.add_child(UIKit.label("Onda %d vencida" % (battle.wave_index + 1), 26, UIKit.DIM))
	for k in boons.size():
		var b: Dictionary = boons[k]
		var rc: Color = GameData.RARITY_COLOR.get(b.rarity, UIKit.DIM)
		var btn := UIKit.button("%s\n%s" % [b.name, b.desc], func(): battle.pick_boon(b), UIKit.PANEL_HI, Vector2(620, 150), 32)
		btn.add_theme_stylebox_override("normal", UIKit.box(UIKit.PANEL_HI, rc, 24, 5))
		var bi := UIKit.art("boons/%s.png" % b.id)
		if bi:
			btn.icon = bi
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 110)
		v.add_child(btn)
		UIKit.pop_in(btn, 0.08 * k)

func hide_boons() -> void:
	if overlay: overlay.queue_free()
	overlay = null

func show_pause(on: bool) -> void:
	if not on:
		hide_boons()
		return
	var o := _dim_overlay()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-230, -200)
	v.add_theme_constant_override("separation", 24)
	o.add_child(v)
	v.add_child(UIKit.label("PAUSADO", 64, UIKit.TEXT))
	v.add_child(UIKit.button("CONTINUAR", func(): battle.toggle_pause(), UIKit.EMBER, Vector2(460, 100), 40))
	v.add_child(UIKit.button("DESISTIR", func(): battle.abandon(), UIKit.PANEL_HI, Vector2(460, 90), 34))

# ── Floating joystick ──────────────────────────────────────
func joystick_start(p: Vector2) -> void:
	_joy_on = true
	_joy_origin = p
	_joy_pos = p
	joy.set_state(true, _joy_origin, _joy_pos)

func joystick_move(p: Vector2) -> void:
	if not _joy_on: return
	_joy_pos = p
	joy.set_state(true, _joy_origin, _joy_pos)

func joystick_end() -> void:
	_joy_on = false
	joy.set_state(false, _joy_origin, _joy_pos)

func joystick_vector() -> Vector2:
	if auto_vec != Vector2.ZERO: return auto_vec
	if not _joy_on: return Vector2.ZERO
	var d := (_joy_pos - _joy_origin) / 90.0
	return d.limit_length(1.0)

class JoyView extends Control:
	var on := false
	var o := Vector2.ZERO
	var p := Vector2.ZERO
	func set_state(v: bool, origin: Vector2, pos: Vector2) -> void:
		on = v; o = origin; p = pos
		queue_redraw()
	func _draw() -> void:
		if not on: return
		draw_circle(o, 90, Color(0, 0, 0, 0.35))
		draw_arc(o, 90, 0, TAU, 40, Color(1, 0.6, 0.3, 0.6), 4)
		draw_circle(o + (p - o).limit_length(90), 40, Color(1, 0.6, 0.3, 0.85))
