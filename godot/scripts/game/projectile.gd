extends Node3D
class_name Projectile
## Bolts, arrows and hexes. Light homing toward a locked target; player and
## champion shots hit enemies (with pierce), enemy shots hit the Warden.

var battle
var target
var vel := Vector3.ZERO
var speed := 18.0
var damage := 10.0
var source := "warden"   # warden | champion | enemy
var pierce := 0
var crit := false
var burn := 0.0
var slow := 0.0
var chain := 0
var life := 2.5
var alive := true
var _hit: Array = []

func setup(b, from: Vector3, tgt, dmg: float, src: String, opts: Dictionary = {}) -> void:
	battle = b
	position = from
	target = tgt
	damage = dmg
	source = src
	speed = opts.get("speed", 18.0 if src != "enemy" else 9.0)
	pierce = opts.get("pierce", 0)
	crit = opts.get("crit", false)
	burn = opts.get("burn", 0.0)
	slow = opts.get("slow", 0.0)
	chain = opts.get("chain", 0)
	var dir: Vector3 = opts.get("dir", Vector3.ZERO)
	if dir == Vector3.ZERO and tgt != null:
		dir = _aim(tgt) - from
	vel = dir.normalized() * speed
	var mi := MeshInstance3D.new()
	mi.mesh = battle.proj_mesh
	var col: Color = opts.get("color", Color("ffbf5e"))
	mi.material_override = AssetLib.mat(col, 3.0)
	mi.scale = Vector3.ONE * (1.6 if crit else 1.0)
	add_child(mi)

func _aim(t) -> Vector3:
	return t.hit_point() if t.has_method("hit_point") else t.position + Vector3(0, 1.0, 0)

func step(dt: float) -> void:
	life -= dt
	if life <= 0.0:
		alive = false
		return
	if target != null and is_instance_valid(target) and target.alive:
		var want: Vector3 = (_aim(target) - position).normalized() * speed
		vel = vel.lerp(want, minf(1.0, 6.0 * dt))
	position += vel * dt
	if source == "enemy":
		var w = battle.warden
		if w.alive and position.distance_to(w.position + Vector3(0, 1, 0)) < 0.8:
			w.take_damage(damage)
			alive = false
		return
	for e in battle.enemies:
		if not e.alive or _hit.has(e):
			continue
		var ep: Vector3 = e.hit_point()
		if position.distance_to(ep) < e.radius + 0.35:
			_hit.append(e)
			battle.hit_enemy(e, damage, {"source": source, "crit": crit, "burn": burn, "slow": slow, "chain": chain})
			if pierce > 0:
				pierce -= 1
			else:
				alive = false
				return
