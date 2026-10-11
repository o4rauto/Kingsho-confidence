extends Node
## Nav — scene switching with parameters, behind the "castle gates" transition:
## two iron-bound wooden doors slam shut, the crest stamps in, the next screen
## loads behind them, then they swing open. Cheap: two drawn panels + tweens.

const GateScript := preload("res://scripts/ui/gate.gd")

var params: Dictionary = {}
var gate: CanvasLayer
var _busy := false

func _ready() -> void:
	gate = GateScript.new()
	add_child(gate)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): _shot = a.substr(7)
		elif a.begins_with("--frames="): _shot_frames = int(a.substr(9))
		elif a.begins_with("--scene="): call_deferred("go", a.substr(8), _arg_params(), false)
		elif a.begins_with("--export-data="): call_deferred("_export_data", a.substr(14))

## gates=true plays the door transition (use it between big sections).
func go(scene: String, p: Dictionary = {}, gates := false) -> void:
	params = p
	if gates and not _busy:
		_busy = true
		gate.close(func():
			get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene)
			get_tree().create_timer(0.25).timeout.connect(func():
				gate.open(func(): _busy = false)))
		return
	# Deferred so it is safe to call from input callbacks / signals.
	get_tree().call_deferred("change_scene_to_file", "res://scenes/%s.tscn" % scene)

# ── Automated capture (dev/CI only) ─────────────────────────
# godot --path . -- --shot=/tmp/a.png --frames=90 [--scene=battle --realm=broken_gate]
var _shot := ""
var _frames := 0
var _shot_frames := 90

func _arg_params() -> Dictionary:
	var p := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--realm="): p["realm_id"] = a.substr(8)
		if a.begins_with("--auto"): p["auto"] = true
		if a == "--nohud": p["nohud"] = true
		if a.begins_with("--slot="): Save.use_slot(int(a.substr(7)))
	if p.has("realm_id"): p["deck"] = Save.data.deck.duplicate()
	return p

func _process(_d: float) -> void:
	if _shot == "":
		return
	_frames += 1
	if _frames == _shot_frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(_shot)
		print("SHOT saved ", _shot)
		get_tree().quit()

## Dumps all game content to JSON (feeds /pipeline/tools/generate_art.py).
func _export_data(path: String) -> void:
	var out := {"champions": [], "enemies": [], "realms": [], "boons": []}
	for c in GameData.champions:
		out.champions.append({"id": c.id, "name": c.name, "title": c.title, "role": c.role, "rarity": c.rarity,
			"color": c.color.to_html(false), "lore": c.lore, "ability": c.ability})
	for id in GameData.enemies:
		var e: Dictionary = GameData.enemies[id]
		out.enemies.append({"id": id, "name": e.name, "kind": e.kind, "color": e.color.to_html(false)})
	for r in GameData.realms:
		out.realms.append({"id": r.id, "name": r.name, "subtitle": r.subtitle, "biome": r.biome, "tod": r.tod,
			"weather": r.weather, "hazard": r.hazard, "accent": r.accent.to_html(false), "boss": r.boss, "roster": r.roster})
	for b in GameData.boons:
		out.boons.append({"id": b.id, "name": b.name, "desc": b.desc, "rarity": b.rarity})
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	print("EXPORTED ", path)
	get_tree().quit()
