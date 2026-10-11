extends Control
const Screen := preload("res://scripts/ui/screen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
## Collection — level up with shards + gold, evolve with cores, unlock new champions.

var modal: Control

func _ready() -> void:
	var v := Screen.make(self, "CAMPEÕES", "menu", UIKit.AETHER)
	v.add_child(UIKit.currency_bar())
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	sc.add_child(grid)
	for def in GameData.champions:
		grid.add_child(_cell(def))

func _cell(def: Dictionary) -> Control:
	var st := Save.champ(def.id)
	var rc: Color = GameData.RARITY_COLOR[def.rarity]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 330)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_stylebox_override("normal", UIKit.box(UIKit.PANEL_HI if st.unlocked else UIKit.NIGHT, rc, 22, 4))
	b.add_theme_stylebox_override("pressed", UIKit.box(UIKit.PANEL, rc, 22, 4))
	b.add_theme_stylebox_override("hover", UIKit.box(UIKit.PANEL_HI, rc, 22, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): Sfx.play("click"); _detail(def))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var icon := TextureRect.new()
	icon.texture = AssetLib.icon(def.id, st.evolved)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not st.unlocked: icon.modulate = Color(0.1, 0.1, 0.15)
	v.add_child(icon)
	var lines: Array = [UIKit.label(def.name, 26, UIKit.TEXT if st.unlocked else UIKit.DIM)]
	if st.unlocked:
		var ready := Save.can_level(def.id) or Save.can_evolve(def.id)
		lines.append(UIKit.label("Nv %d%s · %d/%d frag%s" % [int(st.level), " ★" if st.evolved else "", int(st.shards), Save.level_shard_cost(int(st.level)), "  !" if ready else ""], 20, UIKit.GOOD if ready else UIKit.DIM))
	else:
		lines.append(UIKit.label("BLOQUEADO %d/%d frag" % [int(st.shards), Save.unlock_cost(def.rarity)], 20, UIKit.DIM))
	for l in lines:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	return b

func _detail(def: Dictionary) -> void:
	if modal: modal.queue_free()
	var st := Save.champ(def.id)
	var rc: Color = GameData.RARITY_COLOR[def.rarity]
	modal = ColorRect.new()
	(modal as ColorRect).color = Color(0.02, 0.03, 0.06, 0.9)
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var p := UIKit.panel(UIKit.PANEL, rc)
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 30; p.offset_right = -30; p.offset_top = 90; p.offset_bottom = -90
	modal.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var icon := TextureRect.new()
	icon.texture = AssetLib.icon(def.id, st.evolved)
	icon.custom_minimum_size = Vector2(0, 340)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(icon)
	v.add_child(UIKit.label(def.name, 48))
	v.add_child(UIKit.label("%s · %s" % [def.title, def.rarity.to_upper()], 24, rc))
	v.add_child(UIKit.label("\"%s\"" % def.lore, 22, UIKit.DIM))
	v.add_child(UIKit.label(def.ability, 24))
	var s := Save.stats(def)
	v.add_child(UIKit.label("VIDA %d · DANO %d · CUSTO %d · PODER %d" % [s.hp, s.damage, def.cost, s.power], 24, UIKit.EMBER_HI))
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	if not st.unlocked:
		var ub := UIKit.button("DESBLOQUEAR · %d frag" % Save.unlock_cost(def.rarity), func(): _do(Save.unlock(def)), UIKit.EMBER, Vector2(0, 90), 32)
		ub.disabled = not Save.can_unlock(def)
		v.add_child(ub)
	else:
		v.add_child(UIKit.label("Nível %d / %d" % [int(st.level), GameData.MAX_LEVEL], 30))
		if int(st.level) < GameData.MAX_LEVEL:
			var lb := UIKit.button("SUBIR NÍVEL · %d frag · %d ouro" % [Save.level_shard_cost(int(st.level)), Save.level_gold_cost(int(st.level))], func(): _do(Save.level_up(def.id)), UIKit.GOOD, Vector2(0, 90), 28)
			lb.disabled = not Save.can_level(def.id)
			v.add_child(lb)
		if not st.evolved:
			var label := "EVOLUIR · %d núcleos · %d ouro" % [Save.EVOLVE_CORES, Save.EVOLVE_GOLD] if int(st.level) >= GameData.EVOLVE_LEVEL else "Evolui no nível %d" % GameData.EVOLVE_LEVEL
			var eb := UIKit.button(label, func(): _do(Save.evolve(def.id)), UIKit.EMBER, Vector2(0, 90), 28)
			eb.disabled = not Save.can_evolve(def.id)
			v.add_child(eb)
	v.add_child(UIKit.button("FECHAR", func(): modal.queue_free(); modal = null, UIKit.PANEL_HI, Vector2(0, 80), 30))
	UIKit.pop_in(p)

func _do(ok: bool) -> void:
	Sfx.play("boon" if ok else "back")
	if ok: Nav.go("collection")
