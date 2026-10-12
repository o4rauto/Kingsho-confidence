extends CanvasLayer
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
## Battle HUD (wood & parchment). Values are only re-set when they change.
##   top:    ♥ Bastion · gold · wave · pause
##   bottom: hero portrait + HP · "call wave" · special button
##   popup:  build menu for the tapped stone spot

var battle
var root: Control
var hp_lbl: Label
var gold_lbl: Label
var wave_lbl: Label
var hero_bar: ProgressBar
var ult_btn: Button
var ult_lbl: Label
var call_btn: Button
var boss_box: Control
var boss_bar: ProgressBar
var boss_lbl: Label
var warning_lbl: Label
var hint_lbl: Label
var build_panel: Control
var overlay: Control
var courage_bar: ProgressBar
var courage_lbl: Label
var troop_cards: Array = []
var _last := {}

func setup(b) -> void:
	battle = b
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_top()
	_bottom()
	_troop_bar()
	warning_lbl = UIKit.label("", 46, UIKit.DANGER)
	warning_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_lbl.offset_left = -340; warning_lbl.offset_right = 340; warning_lbl.offset_top = 250; warning_lbl.offset_bottom = 330
	root.add_child(warning_lbl)
	hint_lbl = UIKit.label("", 26, UIKit.EMBER_HI)
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint_lbl.offset_left = -320; hint_lbl.offset_right = 320; hint_lbl.offset_top = 150; hint_lbl.offset_bottom = 250
	root.add_child(hint_lbl)

func _top() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12; bar.offset_right = -12; bar.offset_top = 12; bar.offset_bottom = 92
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)
	var c1 := UIKit.counter("heart", "100", UIKit.TEXT)
	hp_lbl = c1.get_meta("label")
	bar.add_child(c1)
	var c2 := UIKit.counter("coin", "0", UIKit.GOLD)
	gold_lbl = c2.get_meta("label")
	bar.add_child(c2)
	var c3 := UIKit.counter("skull", "1/1", UIKit.TEXT)
	wave_lbl = c3.get_meta("label")
	bar.add_child(c3)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(sp)
	var pause := UIKit.button("II", func(): battle.toggle_pause(), UIKit.WOOD, Vector2(84, 80), 36)
	bar.add_child(pause)
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_box.offset_left = 30; boss_box.offset_right = -30; boss_box.offset_top = 100; boss_box.offset_bottom = 170
	boss_box.visible = false
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	boss_lbl = UIKit.label("", 28, UIKit.DANGER)
	boss_box.add_child(boss_lbl)
	boss_bar = _bar(UIKit.DANGER, 24)
	boss_box.add_child(boss_bar)

func _bar(color: Color, h: int) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, h)
	p.add_theme_stylebox_override("background", UIKit.box(UIKit.WOOD_DARK, UIKit.NIGHT, h / 2, 3))
	p.add_theme_stylebox_override("fill", UIKit.box(color, UIKit.NIGHT, h / 2, 3))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _bottom() -> void:
	# Hero portrait (who you are) + HP
	var hero := VBoxContainer.new()
	hero.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hero.offset_left = 14; hero.offset_right = 174; hero.offset_top = -200; hero.offset_bottom = -14
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hero)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color(GameData.hero_def(Save.active_hero()).color).darkened(0.35), UIKit.NIGHT, 70, 5))
	frame.custom_minimum_size = Vector2(140, 130)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(frame)
	var pic := TextureRect.new()
	var hid := Save.active_hero()
	pic.texture = AssetLib.icon(hid, hid != "warden" and Save.evo(hid) > 0)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(pic)
	var nm := UIKit.label("%s Nv%d" % [String(GameData.hero_def(Save.active_hero()).name).split(" ")[0], Save.hero_lv(Save.active_hero())], 22)
	hero.add_child(nm)
	hero_bar = _bar(UIKit.GOOD, 18)
	hero_bar.max_value = 1.0
	hero.add_child(hero_bar)
	# Special
	ult_btn = UIKit.button("", func(): battle.warden.release_ult(), UIKit.WOOD, Vector2(150, 150), 30)
	ult_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ult_btn.offset_left = -170; ult_btn.offset_right = -20; ult_btn.offset_top = -200; ult_btn.offset_bottom = -50
	root.add_child(ult_btn)
	var ic := Icon.make("star", 70)
	ic.position = Vector2(40, 18)
	ult_btn.add_child(ic)
	ult_lbl = UIKit.label("0%", 26)
	ult_lbl.position = Vector2(0, 92)
	ult_lbl.size = Vector2(150, 40)
	ult_btn.add_child(ult_lbl)
	var ult_name := UIKit.label(String(GameData.hero_def(Save.active_hero()).ult_name), 18, UIKit.EMBER_HI)
	ult_name.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ult_name.offset_left = -200; ult_name.offset_right = -10; ult_name.offset_top = -46; ult_name.offset_bottom = -14
	root.add_child(ult_name)
	# Call next wave
	call_btn = UIKit.button("INICIAR ONDA ▶", func(): battle.call_wave(), UIKit.DANGER, Vector2(330, 100), 34)
	call_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	call_btn.offset_left = -165; call_btn.offset_right = 165; call_btn.offset_top = -330; call_btn.offset_bottom = -230
	call_btn.visible = false
	root.add_child(call_btn)

func _troop_bar() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_left = -178; box.offset_right = 178; box.offset_top = -205; box.offset_bottom = -14
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var cb := Control.new()
	cb.custom_minimum_size = Vector2(0, 30)
	cb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cb)
	courage_bar = _bar(Color("e8452c"), 30)
	courage_bar.max_value = GameData.COURAGE_MAX
	courage_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	cb.add_child(courage_bar)
	courage_lbl = UIKit.label("CORAGEM 5", 20)
	courage_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cb.add_child(courage_lbl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	for i in GameData.TROOPS.size():
		var t: Dictionary = GameData.TROOPS[i]
		var idx := i
		var b := Button.new()
		b.custom_minimum_size = Vector2(84, 150)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(func(): battle.select_troop(idx))
		row.add_child(b)
		var pic := TextureRect.new()
		pic.texture = AssetLib.icon("troop_" + t.id)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.offset_top = 4; pic.offset_bottom = -50; pic.offset_left = 4; pic.offset_right = -4
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pic)
		var nm := UIKit.label(t.name, 15)
		nm.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		nm.offset_top = -50; nm.offset_bottom = -28
		b.add_child(nm)
		var cost := UIKit.label(str(t.cost), 22, Color("ffb0a0"))
		cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		cost.offset_top = -30; cost.offset_bottom = -6
		b.add_child(cost)
		var lock: Control = null
		if not battle.troop_unlocked(i):
			lock = Icon.make("lock", 46)
			lock.position = Vector2(19, 30)
			b.add_child(lock)
		troop_cards.append({"btn": b, "cost": float(t.cost), "unlocked": battle.troop_unlocked(i)})

## Called once per frame; only touches widgets whose value changed.
func refresh() -> void:
	_set_if("courage", int(battle.courage * 4.0), func(_v):
		courage_bar.value = battle.courage
		courage_lbl.text = "CORAGEM %d" % int(battle.courage))
	for i in troop_cards.size():
		var tc: Dictionary = troop_cards[i]
		var ok: bool = tc.unlocked and battle.courage >= tc.cost
		var key := "%d|%d" % [int(ok), int(battle.selected_troop == i)]
		if _last.get("tc%d" % i) == key: continue
		_last["tc%d" % i] = key
		var col := UIKit.EMBER if battle.selected_troop == i else (UIKit.WOOD_HI if ok else Color("5a4a3a"))
		tc.btn.add_theme_stylebox_override("normal", UIKit.face(col))
		tc.btn.add_theme_stylebox_override("hover", UIKit.face(col))
		tc.btn.add_theme_stylebox_override("pressed", UIKit.face(col.darkened(0.2), true))
		tc.btn.modulate = Color.WHITE if ok else Color(0.75, 0.75, 0.75)
	_set_if("integ", int(ceil(battle.integrity)), func(v): hp_lbl.text = str(v))
	_set_if("gold", battle.gold, func(v):
		gold_lbl.text = str(v)
		if build_panel and battle.selected_pad >= 0: show_build(battle.selected_pad))
	_set_if("whp", int(battle.warden.hp), func(_v): hero_bar.value = battle.warden.hp / battle.warden.max_hp)
	_set_if("ult", int(battle.warden.ult), func(_v):
		var ready: bool = battle.warden.ult_ready()
		ult_lbl.text = "PRONTO!" if ready else "%d%%" % int(battle.warden.ult)
		ult_btn.add_theme_stylebox_override("normal", UIKit.face(UIKit.EMBER if ready else UIKit.WOOD)))
	if battle.between:
		_set_if("call", int(ceil(battle.between_t)), func(v):
			var bonus := int(maxf(0.0, battle.between_t) * 2.0)
			call_btn.text = ("INICIAR ONDA ▶  %ds" % v) if battle.wave_index < 0 else ("PRÓXIMA ONDA  +%d ouro" % bonus))
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
	wave_lbl.text = "%d/%d" % [n, total]

func show_call(on: bool) -> void:
	call_btn.visible = on
	_last.erase("call")
	if on:
		UIKit.pop_in(call_btn)

# ── Build ring (pops around the tapped stone spot) ─────────
func show_build(i: int) -> void:
	hide_build()
	battle.selected_pad = i
	var vp := root.get_viewport_rect().size
	var p: Vector2 = battle.cam.unproject_position(battle.world.pads[i] + Vector3(0, 0.6, 0))
	p.x = clampf(p.x, 215.0, vp.x - 215.0)
	p.y = clampf(p.y, 330.0, vp.y - 300.0)
	build_panel = Control.new()
	build_panel.position = p
	build_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(build_panel)
	var ring := Panel.new()
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.1, 0.05, 0.0, 0.35)
	rs.border_color = Color("ffe08a")
	rs.set_border_width_all(5)
	rs.set_corner_radius_all(150)
	ring.add_theme_stylebox_override("panel", rs)
	ring.position = Vector2(-170, -170)
	ring.size = Vector2(340, 340)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_panel.add_child(ring)
	var c = battle.pad_owner[i]
	if c == null:
		var n := GameData.TOWER_ORDER.size()
		for k in n:
			var fam: String = GameData.TOWER_ORDER[k]
			var t: Dictionary = GameData.TOWERS[fam]
			var fam_c := fam
			var ang := -PI / 2 + k * TAU / n
			var at := Vector2(cos(ang), sin(ang)) * 158.0
			var open := GameData.tower_unlocked(fam)
			var short: String = t.name.replace("Torre de ", "").replace("Torre ", "").replace(" Venenoso", "").replace("do ", "").replace("Mina de ", "")
			var b := _ring_button(at, t.icon if open else "lock", short if open else "Reino %d" % (int(t.get("unlock_after", 0)) + 1), int(t.cost[0]), open and battle.gold >= int(t.cost[0]), t.color.darkened(0.25), func(): battle.build(i, fam_c))
			b.scale = Vector2(0.9, 0.9)
	else:
		_plaque(c.title(), Vector2(0, -205))
		if c.cost_next() >= 0:
			var nx: int = c.cost_next()
			_ring_button(Vector2(0, -120), "up" if c.tier < 2 else "star", "Melhorar" if c.tier < 2 else "MESTRE", nx, battle.gold >= nx, UIKit.GOOD.darkened(0.2) if c.tier < 2 else UIKit.GOLD.darkened(0.2), func(): battle.upgrade_pad(i))
		elif c.can_specialize():
			var specs: Array = GameData.family_specs(c.family)
			var n := specs.size()
			for k in n:
				var sd: Dictionary = specs[k]
				var ang := -PI / 2 + (k - (n - 1) / 2.0) * 0.75
				var pos := Vector2(cos(ang), sin(ang)) * 130.0
				var unlocked := Save.champ_unlocked(sd.id)
				var cost := GameData.spec_cost(sd)
				var sid: String = sd.id
				var b := _ring_button(pos, "", sd.name.split(" ")[0] if unlocked else "Bloqueado", cost, unlocked and battle.gold >= cost, sd.color.darkened(0.3) if unlocked else Color("5a4a3a"), func(): battle.specialize_pad(i, sid))
				var pic := TextureRect.new()
				pic.texture = AssetLib.icon(sid, Save.evo(sid) > 0)
				pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				pic.position = Vector2(6, 4)
				pic.size = Vector2(84, 84)
				pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
				if not unlocked: pic.modulate = Color(0, 0, 0, 0.8)
				b.add_child(pic)
		else:
			_plaque("NÍVEL MÁXIMO", Vector2(0, -120))
		_ring_button(Vector2(0, 125), "coin", "Vender", -c.sell_value(), true, UIKit.GOLD.darkened(0.35), func(): battle.sell_pad(i))
	build_panel.scale = Vector2(0.5, 0.5)
	build_panel.create_tween().tween_property(build_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Round button with an icon, a caption and a price tag (negative = refund).
func _ring_button(at: Vector2, icon: String, caption: String, price: int, ok: bool, col: Color, cb: Callable) -> Button:
	var b := UIKit.button("", func():
		if ok: cb.call()
		else: Sfx.play("back"), col if ok else Color("5a4a3a"), Vector2(96, 96), 20)
	for st in ["normal", "hover", "pressed", "disabled"]:
		(b.get_theme_stylebox(st) as StyleBoxFlat).set_corner_radius_all(48)
	b.position = at - Vector2(48, 48)
	build_panel.add_child(b)
	if icon != "":
		var ic := Icon.make(icon, 60)
		ic.position = Vector2(18, 14)
		ic.size = Vector2(60, 60)
		b.add_child(ic)
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UIKit.box(UIKit.WOOD_DARK, UIKit.NIGHT, 12, 3))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tl := UIKit.label(("+%d" % -price) if price < 0 else str(price), 22, UIKit.GOLD if ok else UIKit.DANGER)
	tag.add_child(tl)
	tag.position = Vector2(14, 80)
	b.add_child(tag)
	var cap := UIKit.label(caption, 17, UIKit.TEXT)
	cap.position = Vector2(-30, 116)
	cap.size = Vector2(156, 26)
	b.add_child(cap)
	return b

func _plaque(text: String, at: Vector2) -> void:
	var p := UIKit.wood_panel()
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 4
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 4
	p.add_child(UIKit.label(text, 24, UIKit.EMBER_HI))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_panel.add_child(p)
	p.position = at - Vector2(130, 24)
	p.custom_minimum_size = Vector2(260, 0)

func hide_build() -> void:
	if build_panel:
		build_panel.queue_free()
		build_panel = null
	if battle: battle.selected_pad = -1

# ── Messages ────────────────────────────────────────────────
func hazard_hint(text: String) -> void:
	hint_lbl.text = text
	var tw := hint_lbl.create_tween()
	tw.tween_interval(7.0)
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
	v.offset_left = -340; v.offset_right = 340; v.offset_top = -240; v.offset_bottom = -60
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UIKit.label(title, 60, color)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if sub != "":
		v.add_child(UIKit.label(sub, 28, UIKit.TEXT))
	root.add_child(v)
	UIKit.pop_in(v)
	var tw := v.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(v, "modulate:a", 0.0, 0.4)
	tw.tween_callback(v.queue_free)

func show_boons(boons: Array) -> void:
	overlay = UIKit.modal(root)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -330; p.offset_right = 330; p.offset_top = -470; p.offset_bottom = 470
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(UIKit.ink("ONDA %d VENCIDA!" % (battle.wave_index + 1), 44, Color("8a2a10")))
	v.add_child(UIKit.ink("Escolha uma bênção para %s:" % Save.hero_name(), 26))
	for k in boons.size():
		var b: Dictionary = boons[k]
		var rc: Color = GameData.RARITY_COLOR.get(b.rarity, UIKit.DIM)
		var btn := UIKit.button("%s\n%s" % [b.name, b.desc], func(): battle.pick_boon(b), rc.darkened(0.25), Vector2(0, 170), 30)
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
	overlay = UIKit.modal(root)
	var p := UIKit.wood_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -250; p.offset_right = 250; p.offset_top = -220; p.offset_bottom = 220
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	p.add_child(v)
	v.add_child(UIKit.label("PAUSADO", 60, UIKit.EMBER_HI))
	v.add_child(UIKit.sound_toggles())
	v.add_child(UIKit.button("CONTINUAR", func(): battle.toggle_pause(), UIKit.GOOD.darkened(0.15), Vector2(0, 96), 38))
	v.add_child(UIKit.button("DESISTIR", func(): battle.abandon(), UIKit.DANGER, Vector2(0, 86), 32))
