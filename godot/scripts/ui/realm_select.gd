extends Control
## Realm select — ten realms, each a different game: layout, biome, hazard, boss.

const HAZARD_NAME := {
	"none": "Tutorial", "embers": "Brasas caem", "mud_fog": "Lama + neblina", "ballista": "Balista mira em você",
	"portals": "Portais", "blizzard": "Gelo + nevasca", "sandstorm": "Tempestade de areia",
	"eruptions": "Erupções", "snares": "Raízes prendem", "sunbeam": "Raio de sol",
}
const LAYOUT_NAME := {
	"straight": "retas", "zigzag": "zigue-zague", "serpent": "serpente", "cross": "cruzadas",
	"fork": "bifurcação", "converge": "convergentes", "braid": "trançadas", "spiral": "espiral",
}

func _ready() -> void:
	Sfx.play_menu_music()
	var v := Screen.make(self, "ESCOLHA O REINO", "menu", UIKit.AETHER)
	var list := Screen.scroll(v)
	for r in GameData.realms:
		list.add_child(_card(r))

func _card(r: Dictionary) -> Control:
	var unlocked := Save.realm_unlocked(r.id)
	var cleared := Save.realm_cleared(r.id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.box(r.ground.darkened(0.35) if unlocked else UIKit.NIGHT, r.accent if unlocked else UIKit.STROKE, 24, 4))
	p.custom_minimum_size = Vector2(0, 230)
	var key_art := UIKit.art("realms/%s.png" % r.id)
	if key_art:
		var ka := UIKit.art_rect(key_art)
		ka.modulate = Color(0.45, 0.45, 0.5) if unlocked else Color(0.15, 0.15, 0.18)
		p.add_child(ka)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var badge := UIKit.panel(r.sky, r.accent)
	badge.custom_minimum_size = Vector2(120, 0)
	badge.add_child(UIKit.label(str(r.index + 1), 64, r.accent if unlocked else UIKit.DIM))
	h.add_child(badge)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UIKit.label(r.name, 36, UIKit.TEXT if unlocked else UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	info.add_child(UIKit.label(r.subtitle, 22, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	if unlocked:
		info.add_child(UIKit.label("%d pista(s) %s · %s" % [r.lanes, LAYOUT_NAME.get(r.layout, r.layout), HAZARD_NAME.get(r.hazard, "")], 22, r.accent, HORIZONTAL_ALIGNMENT_LEFT))
		var best: int = int(Save.data.best_wave.get(r.id, 0))
		var status := "CONQUISTADO · melhor onda %d/%d" % [best, r.wave_list.size()] if cleared else "%d ondas · Chefe: %s" % [r.wave_list.size(), GameData.enemies[r.boss].name]
		info.add_child(UIKit.label(status, 22, UIKit.GOLD if cleared else UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
		info.add_child(UIKit.label("+%d ouro · +%d fragmentos" % [r.gold, r.shards], 20, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
		var b := Button.new()
		b.flat = true
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(func(): Sfx.play("click"); Nav.go("loadout", {"realm_id": r.id}))
		p.add_child(b)
	else:
		info.add_child(UIKit.label("BLOQUEADO — conquiste %d reino(s)" % r.unlock_after, 24, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	return p
