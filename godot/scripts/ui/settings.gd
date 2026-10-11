extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Settings — audio, feedback, record and reset.

func _ready() -> void:
	var v := Screen.make(self, "AJUSTES", "menu", UIKit.AETHER)
	var s: Dictionary = Save.data.settings
	for row in [["Efeitos sonoros", "sfx"], ["Música", "music"], ["Vibração", "haptics"], ["Tremor de tela", "shake"]]:
		var key: String = row[1]
		var b := UIKit.button("%s: %s" % [row[0], "LIGADO" if s[key] else "DESLIGADO"], func(): _toggle(key), UIKit.PANEL_HI if s[key] else UIKit.NIGHT, Vector2(0, 96), 32)
		v.add_child(b)
	var st: Dictionary = Save.data.stats
	var rec := UIKit.panel()
	rec.add_child(UIKit.label("Partidas %d · Abates %d · Vitórias %d · Reinos %d/%d" % [int(st.runs), int(st.kills), int(st.victories), Save.data.cleared.size(), GameData.realms.size()], 24, UIKit.DIM))
	v.add_child(rec)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	v.add_child(UIKit.button("APAGAR TODO O PROGRESSO", _confirm_wipe, UIKit.DANGER, Vector2(0, 90), 28))

func _toggle(key: String) -> void:
	Save.data.settings[key] = not Save.data.settings[key]
	Save.flush()
	if key == "music": Sfx.set_music(Save.data.settings.music)
	Nav.go("settings")

func _confirm_wipe() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Apagar campeões, ouro e progresso para sempre?"
	d.ok_button_text = "Apagar"
	d.cancel_button_text = "Cancelar"
	d.confirmed.connect(func(): Save.wipe(); Nav.go("menu"))
	add_child(d)
	d.popup_centered()
