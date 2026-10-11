extends Control
## World map — every realm is a flag on the parchment with a picture of its
## battlefield and its stars. Tap a flag → realm card → "BATALHAR!".
## Bottom bar: Menu · Herói · Campeões · Melhorias · Enciclopédia · Conquistas.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
const MapArt := preload("res://scripts/ui/map_art.gd")

const HAZARD_NAME := {
	"none": "Nenhum (tutorial)", "embers": "Brasas caem do céu", "mud_fog": "Lama + neblina", "ballista": "Balista mira no herói",
	"portals": "Portais no caminho", "blizzard": "Gelo + nevasca", "sandstorm": "Tempestade de areia",
	"eruptions": "Erupções", "snares": "Raízes prendem", "sunbeam": "Raio de sol giratório",
}
const LAYOUT_NAME := {
	"straight": "retas", "zigzag": "em zigue-zague", "serpent": "em serpente", "cross": "cruzadas",
	"fork": "que se dividem", "converge": "que se juntam", "braid": "trançadas", "spiral": "em espiral",
}
const NODE := Vector2(150, 196)

var area: Control
var art: MapArt
var popup: Control

func _ready() -> void:
	Sfx.play_menu_music()
	UIKit.parchment_backdrop(self)
	area = Control.new()
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.offset_top = 110; area.offset_bottom = -170; area.offset_left = 10; area.offset_right = -10
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(area)
	art = MapArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.add_child(art)
	_top_bar()
	_bottom_bar()
	area.resized.connect(_place_nodes)
	call_deferred("_place_nodes")
	if not Save.data.intro_seen and not OS.get_cmdline_user_args().has("--nointro"):
		call_deferred("_story")

func _top_bar() -> void:
	var t := UIKit.sound_toggles()
	t.position = Vector2(18, 18)
	add_child(t)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	h.position = Vector2(-430, 18)
	h.size = Vector2(412, 80)
	h.alignment = BoxContainer.ALIGNMENT_END
	add_child(h)
	h.add_child(UIKit.counter("coin", str(int(Save.data.gold)), UIKit.GOLD))
	h.add_child(UIKit.counter("star", "%d/%d" % [Save.total_stars(), GameData.realms.size() * 3], UIKit.EMBER_HI))

func _bottom_bar() -> void:
	var bar := UIKit.wood_panel()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -170; bar.offset_left = -6; bar.offset_right = 6; bar.offset_bottom = 8
	add_child(bar)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 6)
	bar.add_child(h)
	var claim := Save.claimable_count()
	for it in [["back", "MENU", func(): Nav.go("menu", {}, true)],
			["helmet", "HERÓIS", func(): Nav.go("collection", {}, true)],
			["hammer", "MELHORIAS", func(): Nav.go("upgrades", {}, true)],
			["book", "BESTIÁRIO", func(): Nav.go("encyclopedia", {}, true)],
			["trophy", "CONQUISTAS", func(): Nav.go("achievements", {}, true)]]:
		var w := UIKit.icon_button(it[0], it[2], it[1], 86.0, UIKit.WOOD_HI)
		w.custom_minimum_size = Vector2(132, 0)
		h.add_child(w)
		if it[0] == "hammer" and Save.free_stars() > 0:
			_badge(w, str(Save.free_stars()))
		if it[0] == "trophy" and claim > 0:
			_badge(w, str(claim))

func _badge(w: Control, text: String) -> void:
	var b := PanelContainer.new()
	b.add_theme_stylebox_override("panel", UIKit.box(UIKit.DANGER, UIKit.NIGHT, 20, 3))
	var l := UIKit.label(text, 20)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.add_child(l)
	b.position = Vector2(70, -6)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(b)

func _place_nodes() -> void:
	for c in area.get_children():
		if c != art: c.queue_free()
	var pts: Array[Vector2] = []
	var next_id := ""
	for r in GameData.realms:
		if Save.realm_unlocked(r.id) and not Save.realm_cleared(r.id) and next_id == "":
			next_id = r.id
	for r in GameData.realms:
		var c := Vector2(r.map.x * area.size.x, r.map.y * area.size.y)
		pts.append(c)
		if Save.realm_unlocked(r.id):
			area.add_child(_node(r, c, r.id == next_id))
		else:
			area.add_child(_locked_node(c))
	art.points = pts
	art.reached = Save.data.cleared.size()
	art.queue_redraw()

func _node(r: Dictionary, c: Vector2, is_next: bool) -> Control:
	var root := Control.new()
	root.position = c - Vector2(NODE.x / 2.0, 120)
	root.size = NODE
	var b := Button.new()
	b.flat = true
	b.size = NODE
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pressed.connect(func(): Sfx.play("click"); _open_realm(r))
	root.add_child(b)
	# Picture in a wooden frame
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(r.accent if is_next else UIKit.WOOD, UIKit.NIGHT, 14, 4))
	frame.position = Vector2(15, 0)
	frame.size = Vector2(120, 104)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	var pic := UIKit.realm_pic(r.id)
	if pic:
		var pr := UIKit.art_rect(pic)
		pr.position = Vector2(8, 8)
		pr.size = Vector2(104, 88)
		frame.add_child(pr)
	else:
		var sw := ColorRect.new()
		sw.color = r.ground
		sw.position = Vector2(8, 8); sw.size = Vector2(104, 88)
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(sw)
	# Flag on top-right of the frame
	var flag := Icon.make("flag", 54, Color("b0402a") if Save.realm_cleared(r.id) else r.accent)
	flag.position = Vector2(104, -30)
	root.add_child(flag)
	# Name plate
	var name_l := UIKit.label(r.name, 19, UIKit.TEXT)
	name_l.position = Vector2(-10, 104)
	name_l.size = Vector2(NODE.x + 20, 50)
	root.add_child(name_l)
	# Stars
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 0)
	stars.position = Vector2(0, 150)
	stars.size = Vector2(NODE.x, 40)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		stars.add_child(Icon.make("star" if i < Save.realm_stars(r.id) else "star_empty", 38))
	root.add_child(stars)
	if is_next:
		var tw := frame.create_tween().set_loops()
		frame.pivot_offset = frame.size / 2.0
		tw.tween_property(frame, "scale", Vector2(1.07, 1.07), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(frame, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
		if Save.data.cleared.is_empty():
			var bubble := UIKit.parchment_panel(false)
			var bl := UIKit.ink("COMECE AQUI!", 24, Color("b0402a"))
			bl.autowrap_mode = TextServer.AUTOWRAP_OFF
			bubble.add_child(bl)
			bubble.position = Vector2(-20, -84)
			bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(bubble)
	return root

func _locked_node(c: Vector2) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = c - Vector2(36, 60)
	root.size = Vector2(72, 72)
	var lock := Icon.make("lock", 60)
	root.add_child(lock)
	root.modulate = Color(1, 1, 1, 0.75)
	return root

func _open_realm(r: Dictionary) -> void:
	if popup: popup.queue_free()
	popup = UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-330, -560)
	p.custom_minimum_size = Vector2(660, 0)
	popup.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var pic := UIKit.realm_pic(r.id)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(UIKit.WOOD, UIKit.NIGHT, 16, 6))
	frame.custom_minimum_size = Vector2(0, 300)
	v.add_child(frame)
	if pic:
		frame.add_child(UIKit.art_rect(pic))
	v.add_child(UIKit.ink(r.name, 46, Color("8a2a10")))
	v.add_child(UIKit.ink(r.subtitle, 26, Color("7a5a3a")))
	v.add_child(UIKit.ink(r.desc, 24))
	var facts := GridContainer.new()
	facts.columns = 2
	facts.add_theme_constant_override("h_separation", 18)
	facts.add_theme_constant_override("v_separation", 4)
	v.add_child(facts)
	for row in [["Estradas", "%d %s" % [r.lanes, LAYOUT_NAME.get(r.layout, "")]], ["Perigo", HAZARD_NAME.get(r.hazard, "")],
			["Ondas", str(r.wave_list.size())], ["Chefe", GameData.enemies[r.boss].name],
			["Recompensa", "%d ouro + até 3 estrelas" % r.gold]]:
		facts.add_child(UIKit.ink(row[0] + ":", 22, Color("8a2a10"), HORIZONTAL_ALIGNMENT_RIGHT))
		facts.add_child(UIKit.ink(row[1], 22, UIKit.INK, HORIZONTAL_ALIGNMENT_LEFT))
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		stars.add_child(Icon.make("star" if i < Save.realm_stars(r.id) else "star_empty", 56))
	v.add_child(stars)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var close := UIKit.button("VOLTAR", func(): popup.queue_free(); popup = null, UIKit.WOOD, Vector2(220, 100), 32)
	var fight := UIKit.button("BATALHAR!", func(): Nav.go("battle", {"realm_id": r.id}, true), UIKit.DANGER, Vector2(0, 100), 44)
	fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(close)
	h.add_child(fight)
	UIKit.pop_in(p)

func _story() -> void:
	var o := UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-320, -440)
	p.custom_minimum_size = Vector2(640, 0)
	o.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(UIKit.ink("A DEBANDADA", 52, Color("8a2a10")))
	for line in GameData.STORY:
		v.add_child(UIKit.ink(line, 27))
	v.add_child(UIKit.ink("— %s, %s" % [Save.hero_name(), GameData.HERO.title], 24, Color("7a5a3a")))
	v.add_child(UIKit.button("À LUTA!", func():
		Save.data.intro_seen = true
		Save.flush()
		o.queue_free(), UIKit.DANGER, Vector2(0, 100), 44))
	UIKit.pop_in(p)
