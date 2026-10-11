extends Control
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## After-action report with count-up rewards.

func _ready() -> void:
	var p: Dictionary = Nav.params
	var realm := GameData.realm(p.get("realm_id", "broken_gate"))
	var victory: bool = p.get("victory", false)
	var rw: Dictionary = p.get("rewards", {"gold": 0, "shards": 0, "cores": 0, "new_realm": ""})
	Sfx.play_menu_music()
	UIKit.backdrop(self, UIKit.EMBER if victory else UIKit.DANGER)
	var v := VBoxContainer.new()
	UIKit.full_rect(v)
	v.offset_left = 40; v.offset_right = -40; v.offset_top = 150; v.offset_bottom = -60
	v.add_theme_constant_override("separation", 22)
	add_child(v)
	var title := UIKit.label("REINO CONQUISTADO!" if victory else "O BASTIÃO CAIU", 60, UIKit.EMBER_HI if victory else UIKit.DANGER)
	v.add_child(title)
	UIKit.pop_in(title)
	v.add_child(UIKit.label(realm.name, 30, UIKit.DIM))
	var panel := UIKit.panel()
	v.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	panel.add_child(list)
	list.add_child(UIKit.label("ESPÓLIOS" if victory else "O QUE SOBROU", 32, UIKit.EMBER))
	for row in [["Ouro", rw.gold, UIKit.GOLD], ["Fragmentos", rw.shards, UIKit.AETHER], ["Núcleos", rw.cores, UIKit.EMBER]]:
		var l := UIKit.label("%s  +0" % row[0], 38, row[2])
		list.add_child(l)
		var target: int = int(row[1])
		var name: String = row[0]
		var tw := l.create_tween()
		tw.tween_method(func(x: float): l.text = "%s  +%d" % [name, int(x)], 0.0, float(target), 0.8).set_delay(0.3)
	list.add_child(UIKit.label("Onda %d/%d · %d abates" % [int(p.get("waves", 0)), int(p.get("total", 0)), int(p.get("kills", 0))], 26, UIKit.DIM))
	if rw.get("new_realm", "") != "":
		var nl := UIKit.label("NOVO REINO: %s" % GameData.realm(rw.new_realm).name, 32, UIKit.AETHER)
		v.add_child(nl)
		UIKit.pop_in(nl, 0.6)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	v.add_child(UIKit.button("JOGAR DE NOVO" if victory else "TENTAR DE NOVO", func(): Nav.go("loadout", {"realm_id": realm.id}), UIKit.EMBER, Vector2(0, 104), 42))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	for b in [UIKit.button("REINOS", func(): Nav.go("realm_select"), UIKit.PANEL_HI, Vector2(0, 90), 32), UIKit.button("MENU", func(): Nav.go("menu"), UIKit.PANEL_HI, Vector2(0, 90), 32)]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(b)
