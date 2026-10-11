extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
## Champions = tower SPECIALIZATIONS. In battle, a tower at level 3 can turn
## into one of its family's champions. Here you level them with GOLD (1→10);
## level 5 = ★ evolution, level 10 = ★★ (automatic). New ones join as you
## conquer realms.

var modal: Control

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	modal = null
	var v := Screen.make(self, "CAMPEÕES", Nav.params.get("back", "map"))
	v.add_child(UIKit.ink("Na batalha, uma torre nível 3 vira um destes campeões. Ouro sobe o nível; níveis 5 e 10 EVOLUEM.", 22, Color("7a5a3a")))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	sc.add_child(list)
	for fam in GameData.TOWER_ORDER:
		var t: Dictionary = GameData.TOWERS[fam]
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		list.add_child(head)
		head.add_child(Icon.make(t.icon, 56))
		head.add_child(UIKit.ink(t.name, 32, Color("8a2a10"), HORIZONTAL_ALIGNMENT_LEFT))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		list.add_child(grid)
		for def in GameData.family_specs(fam):
			grid.add_child(card(def, func(): _detail(def), 260.0))

## Champion card.
static func card(def: Dictionary, on_tap: Callable, height := 300.0) -> Button:
	var unlocked := Save.champ_unlocked(def.id)
	var rc: Color = GameData.RARITY_COLOR[def.rarity]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.add_theme_stylebox_override("normal", UIKit.face(UIKit.WOOD if unlocked else Color("5a4a3a")))
	b.add_theme_stylebox_override("hover", UIKit.face(UIKit.WOOD_HI if unlocked else Color("5a4a3a")))
	b.add_theme_stylebox_override("pressed", UIKit.face(UIKit.WOOD_DARK, true))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): Sfx.play("click"); on_tap.call())
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8; v.offset_bottom = -14; v.offset_left = 8; v.offset_right = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", UIKit.box(rc.lerp(Color("bfe0f0"), 0.55), rc.darkened(0.3), 14, 4))
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bg)
	var icon := TextureRect.new()
	icon.texture = AssetLib.icon(def.id, Save.evo(def.id) > 0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked: icon.modulate = Color(0.1, 0.08, 0.06)
	bg.add_child(icon)
	var nm := UIKit.label(def.name, 24, UIKit.TEXT if unlocked else UIKit.DIM)
	v.add_child(nm)
	if unlocked:
		var st := Save.champ(def.id)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(UIKit.label("Nv %d" % int(st.level), 24, UIKit.EMBER_HI))
		for i in Save.evo(def.id):
			row.add_child(Icon.make("star", 30))
		row.add_child(UIKit.label("  %d" % GameData.spec_cost(def), 22, UIKit.GOLD))
		row.add_child(Icon.make("coin", 26))
		v.add_child(row)
	else:
		v.add_child(UIKit.label("Conquiste %d reino(s)" % int(def.unlock_after), 20, UIKit.DIM))
	return b

func _detail(def: Dictionary) -> void:
	if modal: modal.queue_free()
	var unlocked := Save.champ_unlocked(def.id)
	var st := Save.champ(def.id)
	var lv := int(st.level)
	modal = UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 22; p.offset_right = -22; p.offset_top = 40; p.offset_bottom = -40
	modal.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var kind := AssetLib.kind_for(def)
	var model := AssetLib.make(def.id, kind, def.color, 1.1 if kind == "wolf" else 1.8, Save.evo(def.id) > 0)
	v.add_child(Screen.preview(model, 300, 1.1, 5.6))
	v.add_child(UIKit.ink(def.name, 42, Color("8a2a10")))
	v.add_child(UIKit.ink("%s · especialização de %s" % [def.title, GameData.TOWERS[def.family].name], 24, Color("7a5a3a")))
	v.add_child(UIKit.ink(def.ability, 24))
	v.add_child(UIKit.ink("\"%s\"" % def.lore, 21, Color("7a5a3a")))
	if not unlocked:
		v.add_child(UIKit.ink("Entra na sua coleção ao conquistar %d reino(s)." % int(def.unlock_after), 28, Color("b0402a")))
	else:
		# Evolution track: 1 ··· 5★ ··· 10★★
		var track := HBoxContainer.new()
		track.alignment = BoxContainer.ALIGNMENT_CENTER
		track.add_theme_constant_override("separation", 3)
		v.add_child(track)
		for i in range(1, GameData.MAX_LEVEL + 1):
			var evo_lv := GameData.EVOLVE_LEVELS.has(i)
			var dot := PanelContainer.new()
			var on := i <= lv
			dot.add_theme_stylebox_override("panel", UIKit.box(UIKit.GOOD if on else Color("c8b080"), UIKit.INK, 12, 3))
			dot.custom_minimum_size = Vector2(52 if evo_lv else 44, 52 if evo_lv else 44)
			if evo_lv:
				dot.add_child(Icon.make("star" if on else "star_empty", 36))
			else:
				dot.add_child(UIKit.label(str(i), 20))
			track.add_child(dot)
		for k in GameData.EVOLVE_LEVELS.size():
			var got := lv >= int(GameData.EVOLVE_LEVELS[k])
			v.add_child(UIKit.ink("%s Nível %d: %s" % ["★".repeat(k + 1), GameData.EVOLVE_LEVELS[k], def.evo[k]], 23, Color("2a7a1a") if got else Color("7a5a3a")))
		var s := Save.stats(def)
		v.add_child(UIKit.ink("Dano %d · Especializar na batalha: %d ouro" % [s.damage * GameData.SPEC_MUL, GameData.spec_cost(def)], 25, UIKit.INK))
		var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(spacer)
		if lv < GameData.MAX_LEVEL:
			var nxt := lv + 1
			var label := "SUBIR P/ NÍVEL %d · %d ouro" % [nxt, Save.level_cost(lv)]
			if GameData.EVOLVE_LEVELS.has(nxt):
				label = "EVOLUIR! · %d ouro" % Save.level_cost(lv)
			var lb := UIKit.button(label, func(): _do(Save.level_up(def.id), def), UIKit.GOOD, Vector2(0, 96), 32)
			lb.disabled = not Save.can_level(def.id)
			v.add_child(lb)
		else:
			v.add_child(UIKit.ink("NÍVEL MÁXIMO ★★", 32, Color("2a7a1a")))
	v.add_child(UIKit.button("FECHAR", func(): _build(), UIKit.WOOD, Vector2(0, 80), 30))
	UIKit.pop_in(p)

func _do(ok: bool, def: Dictionary) -> void:
	Sfx.play("boon" if ok else "back")
	if ok:
		_build()
		_detail(def)
