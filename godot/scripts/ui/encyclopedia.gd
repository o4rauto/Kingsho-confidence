extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Bestiary — every Rush creature you've met: stats, traits and where it lives.

func _ready() -> void:
	var v := Screen.make(self, "BESTIÁRIO", "map", UIKit.EMBER, false)
	var seen: Array = Save.data.seen
	v.add_child(UIKit.ink("Criaturas encontradas: %d / %d" % [seen.size(), GameData.enemies.size()], 26, Color("7a5a3a")))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	for id in GameData.enemies:
		grid.add_child(_cell(id, seen.has(id)))

func _cell(id: String, known: bool) -> Control:
	var e: Dictionary = GameData.enemies[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 186)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	var col := UIKit.DANGER.darkened(0.2) if e.kind == "boss" else UIKit.WOOD
	b.add_theme_stylebox_override("normal", UIKit.face(col))
	b.add_theme_stylebox_override("hover", UIKit.face(col.lightened(0.06)))
	b.add_theme_stylebox_override("pressed", UIKit.face(col.darkened(0.2), true))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 6; v.offset_bottom = -12
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	if known:
		var icon := TextureRect.new()
		icon.texture = AssetLib.icon(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(icon)
		v.add_child(UIKit.label(e.name, 16))
		b.pressed.connect(func(): Sfx.play("click"); _detail(id))
	else:
		var q := UIKit.label("?", 80, UIKit.DIM)
		q.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(q)
		v.add_child(UIKit.label("???", 16, UIKit.DIM))
	return b

func _detail(id: String) -> void:
	var e: Dictionary = GameData.enemies[id]
	var o := UIKit.modal(self)
	var p := UIKit.parchment_panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-320, -460)
	p.custom_minimum_size = Vector2(640, 0)
	o.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(Screen.stage(id, 300))
	v.add_child(UIKit.ink(e.name, 44, Color("8a2a10")))
	v.add_child(UIKit.ink(GameData.enemy_traits(id), 24))
	v.add_child(UIKit.ink("Vida %d · Velocidade %.1f · Dano no Bastião %d" % [e.hp, e.speed, e.breach], 24))
	v.add_child(UIKit.ink("Vive em: %s" % GameData.enemy_realm(id).name, 24, Color("7a5a3a")))
	v.add_child(UIKit.button("FECHAR", func(): o.queue_free(), UIKit.WOOD, Vector2(0, 80), 30))
	UIKit.pop_in(p)
