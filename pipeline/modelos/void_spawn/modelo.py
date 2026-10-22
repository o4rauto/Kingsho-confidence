"""CR_VoidSpawn — "Cria do Vazio": a glossy purple octopus with one huge eye and six curling tentacles.
Ref: portraits/void_spawn.png. Own rig: body + two bones per tentacle (skinned, bone-heat weights). H 0.9.
"""
import math
from mathutils import Vector
import kit as K

NOME = "CR_VoidSpawn"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "6A2AB0", "SkinDark": "4A1A84", "Shine": "A070E0", "Eye": "F6F0FA", "Iris": "C048B8",
          "Pupil": "22102E", "Glint": "FFFFFF", "Cup": "C89AF0"}

N = 6
HEAD_C = Vector((0, 0, 0.56))


def _angle(k):
    return math.radians(30 + 60 * k)   # 0 = front (-Y)


def _ray(k, r, z):
    a = _angle(k)
    return Vector((math.sin(a) * r, -math.cos(a) * r, z))


def _chain(k):
    return [_ray(k, 0.12, 0.36), _ray(k, 0.28, 0.2), _ray(k, 0.42, 0.07), _ray(k, 0.55, 0.06), _ray(k, 0.6, 0.15)]


def pecas():
    K.sphere("Head", "Skin", "DEF-body", HEAD_C, (0.27, 0.25, 0.3), u=22, v=14)
    K.sphere("Shine", "Shine", "DEF-body", HEAD_C + Vector((0.09, -0.08, 0.2)), (0.07, 0.05, 0.05), u=10, v=6)
    K.sphere("Lid", "SkinDark", "DEF-body", HEAD_C + Vector((0, -0.17, 0.02)), (0.16, 0.1, 0.15), u=16, v=10)
    K.sphere("Eye", "Eye", "DEF-body", HEAD_C + Vector((0, -0.2, 0.0)), (0.14, 0.09, 0.13), u=18, v=12)
    K.sphere("Iris", "Iris", "DEF-body", HEAD_C + Vector((0, -0.275, 0.0)), (0.075, 0.03, 0.075), u=14, v=8)
    K.sphere("Pupil", "Pupil", "DEF-body", HEAD_C + Vector((0, -0.298, 0.0)), (0.036, 0.014, 0.042), u=10, v=6)
    K.sphere("Glint", "Glint", "DEF-body", HEAD_C + Vector((0.03, -0.304, 0.035)), (0.016, 0.006, 0.016), u=6, v=4)
    core = (0, 0, 0.42)
    chains, radii = [], {tuple(round(c, 5) for c in core): (0.17, 0.17)}
    for k in range(N):
        pts = _chain(k)
        chains.append([core] + [tuple(p) for p in pts])
        for p, r in zip(pts, (0.1, 0.088, 0.068, 0.046, 0.026)):
            radii[tuple(round(c, 5) for c in p)] = (r, r)
    K.skin_body("Tentacles", "Skin", chains, radii)
    for k in range(N):   # a few suckers under the front tentacles
        if k in (0, 5, 1, 4):
            pts = _chain(k)
            for j, t in enumerate((0.35, 0.7)):
                p = pts[2] + (pts[3] - pts[2]) * t + Vector((0, 0, -0.035))
                K.sphere("Cup%d%d" % (k, j), "Cup", "DEF-t%d.1" % k, p, (0.018, 0.018, 0.01), u=8, v=4)
    B = [("DEF-root", (0, 0, 0), (0, 0.15, 0), None), ("DEF-body", (0, 0, 0.36), (0, 0, 0.86), "DEF-root")]
    for k in range(N):
        p = _chain(k)
        B += [("DEF-t%d.0" % k, p[0], p[2], "DEF-body"), ("DEF-t%d.1" % k, p[2], p[4], "DEF-t%d.0" % k)]
    return B


def _tangent(k):
    a = _angle(k)
    return Vector((math.cos(a), math.sin(a), 0))   # rotating about it by +deg pushes the tentacle down


def _tentacles(lift0, lift1):
    """lift0/lift1(k) -> degrees up for the inner/outer bone of tentacle k."""
    pose = {}
    for k in range(N):
        t = _tangent(k)
        pose["DEF-t%d.0" % k] = [(t, -lift0(k))]
        pose["DEF-t%d.1" % k] = [(t, -lift1(k))]
    return pose


def animar(arm):
    K.clip(arm, "idle", 36, True)
    for f in range(1, 38, 4):
        ph = 2 * math.pi * (f - 1) / 36
        pose = _tentacles(lambda k: 10 * math.sin(ph + k * 1.1), lambda k: 18 * math.sin(ph + k * 1.1 - 0.9))
        pose["DEF-body"] = {"rot": [("Y", 3 * math.sin(ph))], "loc": (0, 0, 0.02 * math.sin(ph)),
                            "scale": (1 - 0.02 * math.sin(ph), 1 - 0.02 * math.sin(ph), 1 + 0.03 * math.sin(ph))}
        K.key(arm, f, pose)
    K.clip(arm, "run", 16, True)
    for f in range(1, 18, 2):
        ph = 2 * math.pi * (f - 1) / 16
        pose = _tentacles(lambda k: 18 * math.sin(ph + (k % 2) * math.pi), lambda k: 26 * math.sin(ph + (k % 2) * math.pi - 0.8))
        pose["DEF-body"] = {"rot": [("X", 14)], "loc": (0, 0, 0.03 + 0.03 * abs(math.sin(ph)))}
        K.key(arm, f, pose)
    K.clip(arm, "attack", 14, False)
    front = (0, 5)
    for f, body, l0, l1 in ((1, {}, 0, 0),
                            (5, {"rot": [("X", -16)], "loc": (0, 0.06, 0.02), "scale": (1.08, 1.08, 0.92)}, 35, 45),
                            (8, {"rot": [("X", 24)], "loc": (0, -0.16, -0.02), "scale": (0.94, 0.94, 1.1)}, -20, -10),
                            (14, {}, 0, 0)):
        pose = _tentacles(lambda k: l0 if k in front else l0 * 0.3, lambda k: l1 if k in front else l1 * 0.3)
        pose["DEF-body"] = body
        K.key(arm, f, pose)
    K.clip(arm, "die", 24, False)
    for f, k in ((1, 0.0), (6, 0.3), (16, 0.9), (24, 1.0)):
        pose = _tentacles(lambda i: -14 * k, lambda i: -10 * k)
        pose["DEF-body"] = {"rot": [("Y", 25 * k)], "loc": (0, 0, -0.2 * k), "scale": (1 + 0.25 * k, 1 + 0.25 * k, 1 - 0.65 * k)}
        K.key(arm, f, pose)
