"""CR_IceWisp — "Fagulha de Gelo" (no portrait: designed from game_data — flyer, pale ice bdf2ff, saboteur).
A floating frost spirit: a glowing pale-blue orb crowned with straight ice-crystal shards instead of flames,
a curling frosty tail, round dark eyes and a small grin, three shards orbiting the crown. Floaty family. H 0.95.
"""
import math
from mathutils import Vector
import kit as K
import floaty as FL

NOME = "CR_IceWisp"
ATAQUE_QUADRO = 8
PALETA = {"Ice": "BDF2FF", "IceDeep": "6CC8EE", "Shard": "8AD8F4", "ShardLight": "EAFBFF", "Core": "FFFFFF",
          "Eye": "16325A", "Glint": "FFFFFF", "Mouth": "1E4A7A"}
BRILHO = ("Ice", "ShardLight", "Core")

BODY_C = Vector((0, 0, 0.5))


def pecas():
    K.sphere("Body", "Ice", "DEF-body", BODY_C, (0.22, 0.2, 0.21), u=20, v=12)
    K.sphere("Frost", "IceDeep", "DEF-body", BODY_C + Vector((0, 0.04, 0.05)), (0.2, 0.18, 0.18), u=16, v=10)
    K.sphere("Core", "Core", "DEF-body", BODY_C + Vector((0, -0.12, -0.03)), (0.12, 0.08, 0.1), u=12, v=8)
    shards = [((0, 0.1, 1), 0.32, 0.1, "ShardLight"), ((-0.55, 0.15, 0.85), 0.26, 0.085, "Shard"),
              ((0.55, 0.15, 0.85), 0.26, 0.085, "Shard"), ((-0.85, 0.25, 0.4), 0.18, 0.07, "ShardLight"),
              ((0.85, 0.25, 0.4), 0.18, 0.07, "ShardLight"), ((0, 0.8, 0.6), 0.22, 0.08, "Shard"),
              ((-0.3, -0.25, 0.92), 0.17, 0.06, "Shard"), ((0.3, -0.25, 0.92), 0.17, 0.06, "Shard")]
    for i, (d, ln, w, role) in enumerate(shards):
        d = Vector(d).normalized()
        root = BODY_C + Vector((d.x * 0.12, d.y * 0.08, 0.1 + d.z * 0.06))
        K.lock("Shard%d" % i, role, "DEF-top", root, d, ln, w, thick=0.7, curl=0.0, power=1.4)
    pts = [BODY_C + Vector((0, 0.06, -0.12))]
    for k in range(1, 6):   # frosty tail curling under and back
        a = math.radians(26 * k)
        pts.append(pts[0] + Vector((0.03 * math.sin(a * 2), 0.07 * k, -0.07 * k + 0.008 * k * k)))
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Tail%d" % k, "Ice" if k < 3 else "IceDeep", "DEF-body", a, b, 0.11 - 0.02 * k, 0.09 - 0.02 * k, segments=12)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-body", BODY_C + Vector((s * 0.075, -0.18, 0.04)), (0.045, 0.025, 0.055), u=10, v=6)
        K.sphere("Glint" + sd, "Glint", "DEF-body", BODY_C + Vector((s * 0.075 + 0.015, -0.2, 0.065)), (0.013, 0.006, 0.013), u=6, v=4)
    K.sphere("Mouth", "Mouth", "DEF-body", BODY_C + Vector((0, -0.195, -0.04)), (0.035, 0.012, 0.014), u=8, v=4)
    for k in range(3):   # orbiting shards
        a = math.radians(120 * k + 30)
        p = BODY_C + Vector((math.cos(a) * 0.32, math.sin(a) * 0.3, 0.22))
        K.lock("Orbit%d" % k, "ShardLight", "DEF-top", p, (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), 0.1, 0.045, thick=0.7,
               curl=0.0, power=1.4)
    return FL.bones(0.3, 0.6, 1.0)


def animar(arm):
    FL.animate(arm, bob=0.06, sway=8)
