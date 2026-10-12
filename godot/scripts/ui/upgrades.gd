extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
## Upgrades — a tree of 6 columns × 4 tiers bought with the stars you win.
## Tap a node to read it, then buy. Redistribute any time for free.

const NODE := 92.0
var sel_col := 0
var sel_tier := 0

func _ready() -> void:
	# Start on the first thing you can afford.
	for c in GameData.UPGRADES.size():
		var lv := Save.upgrade_level(GameData.UPGRADES[c].id)
		if lv < 4:
			sel_col = c
			sel_tier = lv
			break
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	var v := Screen.make(self, "MELHORIAS", "map", UIKit.EMBER, false)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	head.add_child(Icon.make("star", 60))
	head.add_child(UIKit.label("%d" % Save.free_stars(), 48, UIKit.EMBER_HI))
	head.add_child(UIKit.ink("estrelas para gastar", 26, UIKit.INK))

	var board := UIKit.wood_panel()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(board)
	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 4)
	board.add_child(cols)
	for c in GameData.UPGRADES.size():
		cols.add_child(_column(c))
	v.add_child(_info())
	v.add_child(UIKit.button("REDISTRIBUIR ESTRELAS", func():
		Save.reset_upgrades()
		Sfx.play("back")
		_build(), UIKit.WOOD, Vector2(0, 76), 28))

func _column(c: int) -> Control:
	var u: Dictionary = GameData.UPGRADES[c]
	var lv := Save.upgrade_level(u.id)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.custom_minimum_size = Vector2(108, 0)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UIKit.box(u.color.darkened(0.2), UIKit.NIGHT, 40, 4))
	top.custom_minimum_size = Vector2(80, 80)
	top.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(Icon.make(u.icon, 54))
	col.add_child(top)
	var name_l := UIKit.label(u.name, 19, UIKit.EMBER_HI)
	col.add_child(name_l)
	for t in 4:
		# connector
		var line := ColorRect.new()
		line.color = Color("ffcf3d") if t < lv else Color("3d2210")
		line.custom_minimum_size = Vector2(10, 28)
		line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(line)
		var bought := t < lv
		var next := t == lv
		var afford := next and Save.free_stars() >= int(GameData.UPGRADE_COSTS[t])
		var color: Color = Color("ffcf3d") if bought else (u.color if afford else (Color("8a7a6a") if next else Color("4a3a2a")))
		var cc := c
		var tt := t
		var b := UIKit.button("", func():
			sel_col = cc
			sel_tier = tt
			_build(), color, Vector2(NODE, NODE), 20)
		for st in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st)
			sb.set_corner_radius_all(int(NODE / 2))
			if c == sel_col and t == sel_tier:
				sb.border_color = Color.WHITE
				sb.set_border_width_all(6)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var ic := Icon.make(u.icon if not bought else "star", 52)
		ic.position = Vector2(20, 14)
		ic.size = Vector2(52, 52)
		if not bought and not next: ic.modulate = Color(0.4, 0.35, 0.3)
		b.add_child(ic)
		var num := UIKit.label(["I", "II", "III", "IV"][t], 18, UIKit.TEXT)
		num.position = Vector2(0, 62)
		num.size = Vector2(NODE, 24)
		b.add_child(num)
		col.add_child(b)
	return col

func _info() -> Control:
	var u: Dictionary = GameData.UPGRADES[sel_col]
	var tier: Dictionary = u.tiers[sel_tier]
	var lv := Save.upgrade_level(u.id)
	var cost: int = GameData.UPGRADE_COSTS[sel_tier]
	var p := UIKit.parchment_panel()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UIKit.ink("%s %s · %s" % [u.name, ["I", "II", "III", "IV"][sel_tier], tier.name], 30, Color("8a2a10"), HORIZONTAL_ALIGNMENT_LEFT))
	info.add_child(UIKit.ink(tier.desc, 26, UIKit.INK, HORIZONTAL_ALIGNMENT_LEFT))
	if sel_tier < lv:
		h.add_child(UIKit.label("COMPRADO", 28, UIKit.GOOD))
	elif sel_tier > lv:
		info.add_child(UIKit.ink("Compre o nível anterior primeiro.", 22, Color("7a5a3a"), HORIZONTAL_ALIGNMENT_LEFT))
	else:
		var b := UIKit.button("%d ★" % cost, func():
			if Save.buy_upgrade(u.id):
				Sfx.play("boon")
				sel_tier = mini(3, sel_tier + 1)
				_build()
			else:
				Sfx.play("back"), UIKit.GOOD.darkened(0.15) if Save.free_stars() >= cost else Color("6a5a4a"), Vector2(170, 96), 38)
		h.add_child(b)
	return p
