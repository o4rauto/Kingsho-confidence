extends RefCounted
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Shared layout helpers for menu screens.

## Builds backdrop + header (back button, title) and returns the content VBox.
static func make(root: Control, title: String, back_to: String, accent: Color = UIKit.EMBER) -> VBoxContainer:
	UIKit.backdrop(root, accent)
	var v := VBoxContainer.new()
	UIKit.full_rect(v)
	v.offset_left = 24; v.offset_right = -24; v.offset_top = 36; v.offset_bottom = -24
	v.add_theme_constant_override("separation", 16)
	root.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	h.add_child(UIKit.button("<", func(): Sfx.play("back"); Nav.go(back_to), UIKit.PANEL_HI, Vector2(96, 86), 44))
	var t := UIKit.label(title, 46, UIKit.TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var pad := Control.new(); pad.custom_minimum_size = Vector2(96, 0)
	h.add_child(pad)
	return v

static func scroll(parent: Control) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	sc.add_child(list)
	return list
