extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Settings — audio, feedback and the record of the current save.

func _ready() -> void:
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	var v := Screen.make(self, "AJUSTES", "menu", UIKit.EMBER, false)
	var s: Dictionary = Save.settings
	for row in [["Efeitos sonoros", "sfx"], ["Música", "music"], ["Vibração", "haptics"], ["Tremor de tela", "shake"]]:
		var key: String = row[1]
		var b := UIKit.button("%s: %s" % [row[0], "LIGADO" if s[key] else "DESLIGADO"], func(): _toggle(key), UIKit.GOOD.darkened(0.2) if s[key] else Color("6a5a4a"), Vector2(0, 96), 32)
		v.add_child(b)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	v.add_child(UIKit.ink("Os saves ficam no aparelho (3 espaços). Para apagar um, use o X na tela de saves.", 24, Color("7a5a3a")))

func _toggle(key: String) -> void:
	Save.settings[key] = not Save.settings[key]
	Save.save_settings()
	if key == "music": Sfx.set_music(Save.settings.music)
	_build()
