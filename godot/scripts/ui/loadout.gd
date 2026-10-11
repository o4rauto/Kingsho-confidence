extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Loadout — the Warden + a deck of four champions. Tap a slot to swap.

var realm: Dictionary
var slots_box: GridContainer
var tray: Control
var picking := -1

func _ready() -> void:
	realm = GameData.realm(Nav.params.get("realm_id", "broken_gate"))
	var v := Screen.make(self, "SEU BANDO", "realm_select", realm.accent)
	v.add_child(UIKit.label("Rumo a: %s" % realm.name, 30, realm.accent))
	v.add_child(_warden_card())
	v.add_child(UIKit.label("Toque num espaço para trocar o campeão", 22, UIKit.DIM))
	slots_box = GridContainer.new()
	slots_box.columns = 2
	slots_box.add_theme_constant_override("h_separation", 16)
	slots_box.add_theme_constant_override("v_separation", 16)
	slots_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(slots_box)
	_render_slots()
	var start := UIKit.button("COMEÇAR A DEFESA", func():
		Sfx.play("deploy")
		Nav.go("battle", {"realm_id": realm.id, "deck": Save.data.deck.duplicate()}), UIKit.EMBER, Vector2(0, 110), 44)
	v.add_child(start)

func _warden_card() -> Control:
	var p := UIKit.panel(Color("2a1c14"), UIKit.EMBER)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var icon := TextureRect.new()
	icon.texture = AssetLib.icon("warden")
	icon.custom_minimum_size = Vector2(130, 130)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UIKit.label("A WARDEN · Nível %d" % int(Save.data.warden_level), 32, UIKit.EMBER_HI, HORIZONTAL_ALIGNMENT_LEFT))
	info.add_child(UIKit.label("Você: mova, mire e solte o ULT", 22, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var up := UIKit.button("MELHORAR · %d ouro" % Save.warden_cost(), func():
		if Save.upgrade_warden():
			Sfx.play("boon")
			Nav.go("loadout", {"realm_id": realm.id})
		else:
			Sfx.play("back"), UIKit.GOOD, Vector2(0, 64), 26)
	up.disabled = Save.data.gold < Save.warden_cost()
	info.add_child(up)
	return p

func _render_slots() -> void:
	for c in slots_box.get_children(): c.queue_free()
	for i in GameData.DECK_SIZE:
		var id: String = Save.data.deck[i] if i < Save.data.deck.size() else ""
		slots_box.add_child(_slot(i, id))

func _slot(i: int, id: String) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 300)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var def := GameData.champion(id) if id != "" else {}
	var rc: Color = GameData.RARITY_COLOR[def.rarity] if id != "" else UIKit.STROKE
	b.add_theme_stylebox_override("normal", UIKit.box(UIKit.PANEL_HI, rc, 22, 4))
	b.add_theme_stylebox_override("pressed", UIKit.box(UIKit.PANEL, rc, 22, 4))
	b.add_theme_stylebox_override("hover", UIKit.box(UIKit.PANEL_HI, rc, 22, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): Sfx.play("click"); _open_tray(i))
	if id != "":
		var st := Save.champ(id)
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var icon := TextureRect.new()
		icon.texture = AssetLib.icon(id, st.evolved)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(icon)
		for l in [UIKit.label(def.name, 26), UIKit.label("Nv %d%s · custo %d" % [int(st.level), " ★" if st.evolved else "", def.cost], 20, UIKit.DIM)]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(l)
	return b

func _open_tray(slot: int) -> void:
	picking = slot
	if tray: tray.queue_free()
	tray = ColorRect.new()
	(tray as ColorRect).color = Color(0.02, 0.03, 0.06, 0.92)
	tray.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tray)
	var v := VBoxContainer.new()
	UIKit.full_rect(v)
	v.offset_left = 24; v.offset_right = -24; v.offset_top = 60; v.offset_bottom = -30
	v.add_theme_constant_override("separation", 14)
	tray.add_child(v)
	v.add_child(UIKit.label("ESCOLHA UM CAMPEÃO", 42))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(grid)
	for def in GameData.champions:
		if not Save.champ(def.id).unlocked: continue
		var b := _slot(-1, def.id)
		b.custom_minimum_size = Vector2(0, 260)
		for conn in b.pressed.get_connections(): b.pressed.disconnect(conn.callable)
		var cid: String = def.id
		b.pressed.connect(func(): _assign(cid))
		grid.add_child(b)
	v.add_child(UIKit.button("FECHAR", func(): tray.queue_free(); tray = null, UIKit.PANEL_HI, Vector2(0, 86), 34))

func _assign(id: String) -> void:
	var deck: Array = Save.data.deck
	var existing := deck.find(id)
	if existing >= 0:
		deck[existing] = deck[picking]
	deck[picking] = id
	Save.flush()
	Sfx.play("deploy")
	tray.queue_free()
	tray = null
	_render_slots()
