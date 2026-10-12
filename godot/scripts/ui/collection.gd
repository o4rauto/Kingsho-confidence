extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
## Heroes — pick the champion YOU control in battle. Each one fights its own
## way (melee blocks the road, ranged shoots, Sister Vale heals) and has its
## own special. Level them with gold; levels 5 and 10 EVOLVE them.

var modal: Control

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	modal = null
	var v := Screen.make(self, "HERÓIS", "map")
	v.add_child(UIKit.ink("Escolha quem você controla na batalha. Ouro sobe o nível; níveis 5 e 10 EVOLUEM.", 22, Color("7a5a3a")))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	for id in GameData.HERO_IDS:
		var hid: String = id
		grid.add_child(card(hid, func(): _detail(hid)))

func _unlocked(id: String) -> bool:
	return id == "warden" or Save.champ_unlocked(id)

func card(id: String, on_tap: Callable) -> Button:
	var def := GameData.hero_def(id)
	var unlocked := _unlocked(id)
	var active := Save.active_hero() == id
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 250)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	var col: Color = UIKit.EMBER if active else (UIKit.WOOD if unlocked else Color("5a4a3a"))
	b.add_theme_stylebox_override("normal", UIKit.face(col))
	b.add_theme_stylebox_override("hover", UIKit.face(col.lightened(0.05)))
	b.add_theme_stylebox_override("pressed", UIKit.face(col.darkened(0.2), true))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): Sfx.play("click"); on_tap.call())
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8; v.offset_bottom = -14; v.offset_left = 6; v.offset_right = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var rc: Color = GameData.RARITY_COLOR.get(def.rarity, UIKit.DIM)
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", UIKit.box(rc.lerp(Color("bfe0f0"), 0.55), rc.darkened(0.3), 14, 4))
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bg)
	var icon := TextureRect.new()
	icon.texture = AssetLib.icon(id, id != "warden" and Save.evo(id) > 0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked: icon.modulate = Color(0.1, 0.08, 0.06)
	bg.add_child(icon)
	var nm := UIKit.label(def.name, 19, UIKit.TEXT if unlocked else UIKit.DIM)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	if active:
		v.add_child(UIKit.label("EM CAMPO", 18, UIKit.EMBER_HI))
	elif unlocked:
		v.add_child(UIKit.label("Nv %d" % Save.hero_lv(id), 18, UIKit.EMBER_HI))
	else:
		v.add_child(UIKit.label("Reino %d" % (int(def.unlock_after) + 1), 18, UIKit.DIM))
	return b

func _detail(id: String) -> void:
	if modal: modal.queue_free()
	var def := GameData.hero_def(id)
	var unlocked := _unlocked(id)
	modal = UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 20; p.offset_right = -20; p.offset_top = 30; p.offset_bottom = -30
	modal.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var model: Node3D
	if id == "warden":
		model = AssetLib.make("warden", "warden", Save.hero_cape(), 1.8)
	else:
		var kind := AssetLib.kind_for(def)
		model = AssetLib.make(id, kind, def.color, 1.2 if kind == "wolf" else 1.8, Save.evo(id) > 0)
	v.add_child(Screen.preview(model, 280, 1.1, 5.6))
	v.add_child(UIKit.ink(def.name, 40, Color("8a2a10")))
	v.add_child(UIKit.ink(String(def.title), 22, Color("7a5a3a")))
	v.add_child(UIKit.ink(def.ability, 23))
	v.add_child(UIKit.ink("ESPECIAL — %s: %s" % [def.ult_name, def.ult_desc], 23, Color("b0402a")))
	if not unlocked:
		v.add_child(UIKit.ink("Liberado ao conquistar %d reino(s)." % int(def.unlock_after), 28, Color("b0402a")))
	else:
		var st := Save.hero_battle_stats(id)
		v.add_child(UIKit.ink("Vida %d · Dano %d · %s" % [st.hp, st.damage, "corpo a corpo" if st.melee else "à distância"], 24, UIKit.INK))
		var lv := Save.hero_lv(id)
		if id != "warden":
			var track := HBoxContainer.new()
			track.alignment = BoxContainer.ALIGNMENT_CENTER
			track.add_theme_constant_override("separation", 3)
			v.add_child(track)
			for i in range(1, GameData.MAX_LEVEL + 1):
				var evo_lv := GameData.EVOLVE_LEVELS.has(i)
				var dot := PanelContainer.new()
				var on := i <= lv
				dot.add_theme_stylebox_override("panel", UIKit.box(UIKit.GOOD if on else Color("c8b080"), UIKit.INK, 12, 3))
				dot.custom_minimum_size = Vector2(50 if evo_lv else 42, 50 if evo_lv else 42)
				if evo_lv:
					dot.add_child(Icon.make("star" if on else "star_empty", 34))
				else:
					dot.add_child(UIKit.label(str(i), 19))
				track.add_child(dot)
		var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(spacer)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		v.add_child(row)
		var maxl: int = GameData.HERO_MAX_LEVEL if id == "warden" else GameData.MAX_LEVEL
		if lv < maxl:
			var cost: int = Save.hero_cost() if id == "warden" else Save.level_cost(lv)
			var lb := UIKit.button("TREINAR\n%d ouro" % cost, func():
				var ok: bool = Save.hero_level_up() if id == "warden" else Save.level_up(id)
				Sfx.play("boon" if ok else "back")
				if ok:
					_build()
					_detail(id), UIKit.GOOD.darkened(0.15), Vector2(0, 100), 26)
			lb.disabled = int(Save.data.gold) < cost
			lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lb)
		var active := Save.active_hero() == id
		var pick := UIKit.button("EM CAMPO" if active else "ESCOLHER", func():
			Save.data.hero.active = id
			Save.flush()
			Sfx.play("deploy")
			_build(), UIKit.EMBER if not active else Color("6a5a4a"), Vector2(0, 100), 30)
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(pick)
		if id == "warden":
			v.add_child(UIKit.button("PERSONALIZAR NOME E CAPA", func(): Nav.go("hero", {}, true), UIKit.WOOD, Vector2(0, 76), 26))
	v.add_child(UIKit.button("FECHAR", func(): _build(), UIKit.WOOD, Vector2(0, 72), 28))
	UIKit.pop_in(p)
