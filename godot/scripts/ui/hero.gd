extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Hero screen — who you are: name (editable), cape colour, story, level & stats.

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	var v := Screen.make(self, "SEU HERÓI", "map")
	var list := Screen.scroll(v)
	var model := AssetLib.make("warden", "warden", Save.hero_cape(), 1.9)
	list.add_child(Screen.preview(model, 360, 1.2, 6.2))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	list.add_child(name_row)
	name_row.add_child(UIKit.ink("Nome:", 30, UIKit.INK))
	var edit := LineEdit.new()
	edit.text = Save.hero_name()
	edit.max_length = 14
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 76)
	edit.add_theme_font_override("font", UIKit.font())
	edit.add_theme_font_size_override("font_size", 38)
	edit.add_theme_color_override("font_color", UIKit.TEXT)
	edit.add_theme_stylebox_override("normal", UIKit.box(UIKit.WOOD, UIKit.NIGHT, 16, 4))
	edit.add_theme_stylebox_override("focus", UIKit.box(UIKit.WOOD_HI, UIKit.GOLD, 16, 4))
	edit.text_changed.connect(func(t: String):
		Save.data.hero.name = t
		Save.flush())
	name_row.add_child(edit)
	list.add_child(UIKit.ink(GameData.HERO.title, 28, Color("8a2a10")))

	list.add_child(UIKit.ink("Cor da capa", 26))
	var capes := HBoxContainer.new()
	capes.alignment = BoxContainer.ALIGNMENT_CENTER
	capes.add_theme_constant_override("separation", 12)
	list.add_child(capes)
	for i in GameData.CAPES.size():
		var col: Color = GameData.CAPES[i][1]
		var idx := i
		var b := UIKit.button("✓" if int(Save.data.hero.cape) == i else "", func():
			Save.data.hero.cape = idx
			Save.flush()
			_build(), col, Vector2(86, 86), 40)
		capes.add_child(b)

	var lv := Save.hero_level()
	var st := Save.hero_stats()
	var card := UIKit.wood_panel()
	list.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)
	cv.add_child(UIKit.label("NÍVEL %d / %d" % [lv, GameData.HERO_MAX_LEVEL], 38, UIKit.EMBER_HI))
	var nxt := Save.hero_stats(mini(lv + 1, GameData.HERO_MAX_LEVEL))
	cv.add_child(UIKit.label("Vida %d  →  %d" % [st.hp, nxt.hp], 28))
	cv.add_child(UIKit.label("Dano %.1f  →  %.1f" % [st.damage, nxt.damage], 28))
	cv.add_child(UIKit.label("Alcance %.1f · Velocidade %.1f" % [st.range, st.speed], 24, UIKit.DIM))
	if lv < GameData.HERO_MAX_LEVEL:
		var up := UIKit.button("TREINAR  ·  %d ouro" % Save.hero_cost(), func():
			if Save.hero_level_up():
				Sfx.play("boon")
				_build()
			else:
				Sfx.play("back"), UIKit.GOOD, Vector2(0, 96), 34)
		up.disabled = int(Save.data.gold) < Save.hero_cost()
		cv.add_child(up)

	var ult := UIKit.parchment_panel(false)
	list.add_child(ult)
	var uv := VBoxContainer.new()
	ult.add_child(uv)
	uv.add_child(UIKit.ink("Especial: " + GameData.HERO.ult_name, 30, Color("8a2a10")))
	uv.add_child(UIKit.ink(GameData.HERO.ult_desc, 24))
	uv.add_child(UIKit.ink("Na batalha: toque no chão para andar. Ele atira sozinho quando para.", 22, Color("7a5a3a")))

	var lore := UIKit.parchment_panel(false)
	list.add_child(lore)
	var lv2 := VBoxContainer.new()
	lore.add_child(lv2)
	lv2.add_child(UIKit.ink("A história de %s" % Save.hero_name(), 30, Color("8a2a10")))
	lv2.add_child(UIKit.ink(GameData.HERO.lore.replace("Kael", Save.hero_name()), 24))
