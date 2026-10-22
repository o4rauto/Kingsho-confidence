extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Icon := preload("res://scripts/ui/icon.gd")
## Achievements — progress bars and a gold reward to collect for each.

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	var v := Screen.make(self, "CONQUISTAS", "map")
	var list := Screen.scroll(v)
	for a in GameData.ACHIEVEMENTS:
		list.add_child(_row(a))

func _row(a: Dictionary) -> Control:
	var done := Save.achievement_done(a)
	var claimed: bool = Save.data.claimed.has(a.id)
	var p := UIKit.wood_panel()
	if claimed: p.modulate = Color(0.75, 0.75, 0.75)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	h.add_child(Icon.make("trophy" if done else "lock", 72))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UIKit.label(a.name, 30, UIKit.EMBER_HI if done else UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	info.add_child(UIKit.label(a.desc, 21, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var val := mini(Save.stat_value(a.stat), int(a.target))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = int(a.target)
	bar.value = val
	bar.custom_minimum_size = Vector2(0, 22)
	bar.add_theme_stylebox_override("background", UIKit.box(UIKit.WOOD_DARK, UIKit.NIGHT, 10, 2))
	bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.GOOD, UIKit.NIGHT, 10, 2))
	info.add_child(bar)
	info.add_child(UIKit.label("%d / %d" % [val, int(a.target)], 18, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	if claimed:
		h.add_child(UIKit.label("✓", 48, UIKit.GOOD))
	else:
		var b := UIKit.button("+%d" % int(a.gold), func():
			if Save.claim(a):
				Sfx.play("coin")
				_build()
			else:
				Sfx.play("back"), UIKit.GOLD.darkened(0.15) if done else Color("6a5a4a"), Vector2(130, 80), 30)
		h.add_child(b)
	return p
