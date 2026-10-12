extends Control
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
## After the battle: stars, gold, and what you unlocked.

func _ready() -> void:
	var p: Dictionary = Nav.params
	var realm := GameData.realm(p.get("realm_id", "broken_gate"))
	var victory: bool = p.get("victory", false)
	var rw: Dictionary = p.get("rewards", {"gold": 0, "stars": 0, "new_realm": "", "new_champ": ""})
	Sfx.play_menu_music()
	UIKit.parchment_backdrop(self)
	var pic := UIKit.realm_pic(realm.id)
	if pic:
		var r := UIKit.art_rect(pic)
		UIKit.full_rect(r)
		r.modulate = Color(1, 1, 1, 0.35)
		add_child(r)
	var panel := UIKit.wood_panel()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-320, -500)
	panel.custom_minimum_size = Vector2(640, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var title := UIKit.label("VITÓRIA!" if victory else "DERROTA", 76, UIKit.EMBER_HI if victory else UIKit.DANGER)
	v.add_child(title)
	v.add_child(UIKit.label(realm.name, 30, UIKit.DIM))
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 6)
	v.add_child(stars)
	for i in 3:
		var s := Icon.make("star" if i < int(rw.stars) else "star_empty", 120)
		stars.add_child(s)
		if i < int(rw.stars):
			s.pivot_offset = Vector2(60, 60)
			s.scale = Vector2.ZERO
			var tw := s.create_tween()
			tw.tween_interval(0.3 + i * 0.3)
			tw.tween_callback(func(): Sfx.play("coin", 1.0 + i * 0.15))
			tw.tween_property(s, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if victory:
		v.add_child(UIKit.label("Estrelas: quanto menos dano o Bastião levar, mais estrelas.", 20, UIKit.DIM))
	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(gold_row)
	gold_row.add_child(Icon.make("coin", 56))
	var gl := UIKit.label("+0", 48, UIKit.GOLD)
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gold_row.add_child(gl)
	var target := float(rw.gold)
	gl.create_tween().tween_method(func(x: float): gl.text = "+%d" % int(x), 0.0, target, 0.8).set_delay(0.4)
	v.add_child(UIKit.label("Onda %d/%d · %d abates" % [int(p.get("waves", 0)), int(p.get("total", 0)), int(p.get("kills", 0))], 26, UIKit.DIM))
	if String(rw.get("new_champ", "")) != "":
		var c := GameData.champion(rw.new_champ)
		var nl := UIKit.label("NOVO CAMPEÃO: %s!" % c.name, 32, UIKit.GOOD)
		v.add_child(nl)
		UIKit.pop_in(nl, 0.9)
	if String(rw.get("new_realm", "")) != "":
		var rl := UIKit.label("NOVO REINO NO MAPA: %s" % GameData.realm(rw.new_realm).name, 28, UIKit.AETHER)
		v.add_child(rl)
		UIKit.pop_in(rl, 1.1)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var again := UIKit.button("REPETIR" if victory else "TENTAR DE NOVO", func(): Nav.go("battle", {"realm_id": realm.id}, true), UIKit.WOOD_HI, Vector2(0, 100), 32)
	var map := UIKit.button("MAPA", func(): Nav.go("map", {}, true), UIKit.GOOD.darkened(0.15) if victory else UIKit.WOOD_HI, Vector2(0, 100), 36)
	for b in [again, map]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(b)
	UIKit.pop_in(panel)
