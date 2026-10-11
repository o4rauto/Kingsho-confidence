extends Node3D
class_name Champion
## A deployed champion card. Holds ground and fights by role:
## melee blocks & slows, ranged/tower shoot, support heals (Ashen Queen: fire nova).

var battle
var def: Dictionary
var rig: ModelRig
var hp := 1.0
var max_hp := 1.0
var damage := 1.0
var alive := true
var cd := 0.0
var stun_t := 0.0
var _bar_fg: MeshInstance3D

func setup(b, champ_def: Dictionary, pos: Vector3, stats: Dictionary, evolved: bool) -> void:
	battle = b
	def = champ_def
	position = pos
	max_hp = stats.hp * b.mods.champ_hp
	hp = max_hp
	damage = stats.damage
	var kind: String = AssetLib.kind_for(def)
	var h := 1.0 if kind == "wolf" else (2.0 if kind == "golem" else 1.6)
	rig = AssetLib.make(def.id, kind, def.color, h, evolved)
	add_child(rig)
	rig.play("idle")
	var q := QuadMesh.new(); q.size = Vector2(1.0, 0.1)
	_bar_fg = MeshInstance3D.new()
	_bar_fg.mesh = q
	_bar_fg.material_override = b.bar_ally_mat
	_bar_fg.position = Vector3(0, h + 0.35, 0)
	_bar_fg.visible = false
	add_child(_bar_fg)
	scale = Vector3.ONE * 0.2
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func take_damage(d: float) -> void:
	if not alive: return
	hp -= d
	_bar_fg.visible = true
	_bar_fg.scale.x = maxf(0.0, hp / max_hp)
	if hp <= 0.0:
		alive = false

func heal(a: float) -> void:
	hp = minf(max_hp, hp + a)
	_bar_fg.scale.x = hp / max_hp

func step(dt: float) -> void:
	if not alive: return
	if stun_t > 0.0:
		stun_t -= dt
		return
	# Melee champions block: nearby enemies are slowed and chip at them.
	var body := 1.3 if def.role == "melee" else 0.8
	for e in battle.enemies_near(position, body):
		if def.role == "melee":
			e.apply_slow(0.35)
		take_damage(e.def.damage * (0.5 if def.role == "melee" else 0.35) * dt + e.def.get("burn_touch", 0.0) * dt)
		if not alive: return
	cd -= dt
	if cd <= 0.0 and _act():
		cd = 1.0 / def.atk_speed

func _act() -> bool:
	var dmg: float = damage * battle.mods.champ_dmg
	var rng: float = def.range * battle.range_mul()
	if def.role == "support":
		if def.id == "ashen_queen":
			var hit: Array = battle.enemies_near(position, rng)
			if hit.is_empty(): return false
			rig.play("cast")
			battle.ring_fx(position, rng, Color("ff8a3d"))
			for e in hit:
				battle.hit_enemy(e, dmg, {"source": "champion", "burn": 6.0})
			return true
		var ally = battle.most_wounded_ally(position, rng)
		if ally == null: return false
		rig.play("cast")
		ally.heal(18.0 + damage)
		battle.float_text(ally.position, "+%d" % int(18 + damage), Color("54e08a"))
		return true
	var t = battle.nearest_enemy(position, rng)
	if t == null: return false
	rig.rotation.y = atan2(t.position.x - position.x, t.position.z - position.z)
	rig.play("attack")
	if def.role == "melee":
		battle.hit_enemy(t, dmg, {"source": "champion"})
	else:
		battle.spawn_projectile(position + Vector3(0, 1.2, 0), t, dmg, "champion", {
			"color": def.color, "slow": 0.4 if def.id == "frost_warden" else 0.0,
			"chain": 2 if def.id == "stormcaller" else 0, "speed": 16.0})
	return true
