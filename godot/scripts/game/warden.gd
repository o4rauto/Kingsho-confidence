extends Node3D
const ModelRig := preload("res://scripts/game/model_rig.gd")
## The hero you pilot (the Archero half). Drag to move; auto-fires at the
## nearest foe only while standing still. Charges an ultimate. Never dies —
## it is knocked down and revives at the Bastion.

var battle
var rig: ModelRig
var hp := 100.0
var max_hp := 100.0
var alive := true
var ult := 0.0
var move_input := Vector2.ZERO
var vel := Vector3.ZERO
var fire_cd := 0.0
var iframes := 0.0
var downed := false
var down_t := 0.0
var rooted_t := 0.0
var damage := 14.0
var atk_range := 9.0
var speed := 6.5
var fire_interval := 0.52

func setup(b) -> void:
	battle = b
	recompute(true)
	rig = AssetLib.make("warden", "warden", Color("ffbf5e"), 1.8)
	add_child(rig)
	var aura := MeshInstance3D.new()
	var disc := CylinderMesh.new(); disc.top_radius = 0.9; disc.bottom_radius = 0.9; disc.height = 0.02
	aura.mesh = disc
	aura.material_override = AssetLib.mat(Color("ff8a3d"), 1.5)
	aura.position.y = 0.03
	add_child(aura)

## Re-derive stats from Warden level + run boons (keeps hp ratio).
func recompute(full := false) -> void:
	var lvl: int = int(Save.data.warden_level)
	var m: Dictionary = battle.mods
	var frac := 1.0 if full else hp / max_hp
	max_hp = GameData.WARDEN.max_hp * (1.0 + (lvl - 1) * 0.07) + m.warden_hp
	hp = max_hp * frac
	damage = GameData.WARDEN.damage * (1.0 + (lvl - 1) * 0.09) * m.warden_dmg
	atk_range = GameData.WARDEN.range * m.warden_range
	speed = GameData.WARDEN.speed * m.warden_speed
	fire_interval = GameData.WARDEN.fire_cd / m.warden_aspd

func ult_ready() -> bool:
	return ult >= GameData.WARDEN.ult_max

func add_ult(n: float) -> void:
	ult = minf(GameData.WARDEN.ult_max, ult + n)

func heal(a: float) -> void:
	if not downed:
		hp = minf(max_hp, hp + a)

func take_damage(d: float) -> void:
	if downed or iframes > 0.0:
		return
	hp -= d
	iframes = 0.5
	rig.play("hit")
	Sfx.play("hurt")
	Sfx.haptic(30)
	battle.shake(0.15)
	if hp <= 0.0:
		downed = true
		down_t = 2.6
		hp = 0.0
		rig.visible = false
		battle.banner_small("WARDEN DOWN")

func release_ult() -> void:
	if not ult_ready() or downed:
		return
	ult = 0.0
	Sfx.play("ult")
	battle.shake(0.35)
	battle.ring_fx(position, 6.0, Color("ffe6a6"))
	for i in 16:
		var a := float(i) / 16.0 * TAU
		battle.spawn_projectile(position + Vector3(0, 1, 0), null, damage * 1.6, "warden",
			{"dir": Vector3(cos(a), 0, sin(a)), "pierce": 3, "crit": true, "burn": battle.mods.burn})
	for e in battle.enemies_near(position, 6.0):
		battle.hit_enemy(e, damage * 2.4, {"source": "warden", "crit": true, "slow": 0.5})

func step(dt: float) -> void:
	iframes = maxf(0.0, iframes - dt)
	if downed:
		down_t -= dt
		if down_t <= 0.0:
			downed = false
			hp = max_hp * 0.6
			iframes = 1.4
			position = battle.BASTION_POS + Vector3(0, 0, -3.0)
			rig.visible = true
			battle.banner_small("RISE AGAIN")
		return
	rooted_t = maxf(0.0, rooted_t - dt)
	var want: Vector3 = Vector3(move_input.x, 0, move_input.y) * speed * battle.warden_speed_mul()
	if rooted_t > 0.0:
		want = Vector3.ZERO
	# Ice realms: slippery momentum. Elsewhere: snappy.
	var grip := 2.2 if battle.realm.hazard == "blizzard" else 18.0
	vel = vel.lerp(want, minf(1.0, grip * dt))
	position += vel * dt
	position.x = clampf(position.x, -6.2, 6.2)
	position.z = clampf(position.z, -20.0, 3.2)
	var moving := move_input.length() > 0.15
	if vel.length() > 0.3:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(vel.x, vel.z), 0.25)
	rig.play("run" if moving else "idle")
	fire_cd -= dt
	if moving:
		fire_cd = maxf(fire_cd, fire_interval * 0.5)
	elif fire_cd <= 0.0 and _fire():
		fire_cd = fire_interval

func _fire() -> bool:
	var t = battle.nearest_enemy(position, atk_range * battle.range_mul())
	if t == null:
		return false
	rig.rotation.y = atan2(t.position.x - position.x, t.position.z - position.z)
	rig.play("attack")
	var m: Dictionary = battle.mods
	var shots := 1 + int(m.multishot)
	var base := Vector3(t.position.x - position.x, 0, t.position.z - position.z).normalized()
	for i in shots:
		var off := 0.0 if shots == 1 else (i - (shots - 1) / 2.0) * 0.16
		var crit: bool = randf() < m.crit
		battle.spawn_projectile(position + Vector3(0, 1.1, 0), t, damage * (m.crit_mul if crit else 1.0), "warden", {
			"dir": base.rotated(Vector3.UP, off), "pierce": int(m.pierce), "crit": crit,
			"burn": m.burn, "slow": m.slow, "chain": int(m.chain), "color": Color("ffe6a6") if crit else Color("ffbf5e")})
	add_ult(3.0)
	Sfx.play("shoot")
	return true
