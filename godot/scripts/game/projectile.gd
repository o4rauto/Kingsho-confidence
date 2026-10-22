extends Node3D
const FX := preload("res://scripts/game/fx2d.gd")
## Bolts, arrows and hexes (drawn 2D sprites, see fx2d.gd). Light homing toward a locked target; player and
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
var true_dmg := false
var life := 2.5
var alive := true
var _hit: Array = []
var kind := "arrow"          # arrow | bolt | orb  (pointed ones turn with the flight)
var _spr: Sprite3D

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
	true_dmg = opts.get("true_dmg", false)
	var dir: Vector3 = opts.get("dir", Vector3.ZERO)
	if dir == Vector3.ZERO and tgt != null:
		dir = _aim(tgt) - from
	vel = dir.normalized() * speed
	var col: Color = opts.get("color", Color("ffbf5e"))
	kind = opts.get("kind", _guess_kind(src, opts))
	var big := 1.5 if crit else 1.0
	match kind:
		"orb":
			_spr = FX.sprite("orb", 0.55 * big, "billboard", col)
		"bolt":
			_spr = FX.sprite("bolt", 1.5 * big, "free")
		_:
			_spr = FX.sprite("arrow", 0.95 * big, "free")
	add_child(_spr)
	_face()

## Which drawing fits the shooter: magic and monster spit are orbs, the
## ballista throws a big bolt, everyone else shoots arrows.
func _guess_kind(src: String, opts: Dictionary) -> String:
	if src == "enemy" or opts.get("true_dmg", false) or opts.get("chain", 0) > 0:
		return "orb"
	if speed >= 24.0 and opts.get("pierce", 0) >= 2:
		return "bolt"
	return "arrow"

func _face() -> void:
	if kind == "orb" or _spr == null or not is_inside_tree(): return
	FX.orient(_spr, vel, battle.cam)

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
	_face()
	if source == "enemy":
		var t = target
		if t == null or not is_instance_valid(t) or not t.alive:
			return
		if position.distance_to(t.position + Vector3(0, 1, 0)) < 0.9:
			t.take_damage(damage)
			alive = false
		return
	for e in battle.enemies:
		if not e.alive or _hit.has(e):
			continue
		var ep: Vector3 = e.hit_point()
		if position.distance_to(ep) < e.radius + 0.35:
			_hit.append(e)
			battle.hit_enemy(e, damage, {"source": source, "crit": crit, "burn": burn, "slow": slow, "chain": chain, "true_dmg": true_dmg})
			if pierce > 0:
				pierce -= 1
			else:
				alive = false
				return
