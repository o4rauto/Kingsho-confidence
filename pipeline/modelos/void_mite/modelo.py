"""CR_VoidMite — "Ácaro do Vazio": a round lilac tick with a spotted domed shell, a small face with two
big glossy eyes, curling antennae and six stubby legs. Ref: portraits/void_mite.png. Bug family. H 0.6.
"""
import math
from mathutils import Vector
import kit as K
import bug as BG

NOME = "CR_VoidMite"
ATAQUE_QUADRO = 8
PALETA = {"Shell": "9A6AE0", "Spot": "5A2A9A", "Under": "7A4AC0", "Face": "B48AF0", "Eye": "2A1048",
          "Glint": "FFFFFF", "Leg": "6A3AB0"}

SHELL_C = Vector((0, 0.04, 0.25))
LEGS = [((0.2, -0.12, 0.13), (0.27, -0.2, 0.0)), ((0.23, 0.02, 0.13), (0.3, 0.03, 0.0)), ((0.2, 0.17, 0.13), (0.27, 0.25, 0.0))]


def pecas():
    K.sphere("Shell", "Shell", "DEF-body", SHELL_C, (0.28, 0.31, 0.22), u=22, v=14)
    K.sphere("Belly", "Under", "DEF-body", SHELL_C + Vector((0, 0, -0.07)), (0.25, 0.28, 0.13), u=18, v=10)
    rad = (0.28, 0.31, 0.22)
    spots = [(0.0, 0.1, 0.95, 0.07), (0.5, -0.2, 0.75, 0.05), (-0.5, -0.15, 0.78, 0.055), (0.35, 0.45, 0.7, 0.06),
             (-0.4, 0.4, 0.72, 0.05), (0.8, 0.2, 0.45, 0.045), (-0.8, 0.1, 0.45, 0.05), (0.0, 0.7, 0.6, 0.055),
             (0.2, -0.45, 0.82, 0.04), (-0.2, 0.25, 0.92, 0.04)]
    for i, (x, y, z, r) in enumerate(spots):
        n = Vector((x, y, z)).normalized()
        p = SHELL_C + Vector((n.x * rad[0], n.y * rad[1], n.z * rad[2])) * 0.985
        ob = K.sphere("Spot%d" % i, "Spot", "DEF-body", p, (r, r, 0.012), u=10, v=4)
        ob.rotation_mode = "QUATERNION"
        ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(n)
    hc = Vector((0, -0.25, 0.19))
    K.sphere("Face", "Face", "DEF-head", hc, (0.18, 0.11, 0.13), u=16, v=10)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", hc + Vector((s * 0.072, -0.075, 0.02)), (0.064, 0.038, 0.075), u=12, v=8)
        K.sphere("Glint" + sd, "Glint", "DEF-head", hc + Vector((s * 0.072 + 0.02, -0.11, 0.055)), (0.016, 0.008, 0.018), u=6, v=4)
        pts = [hc + Vector((s * 0.05, 0.0, 0.1))]
        for k in range(1, 7):   # antenna: up and out, the tip curling forward and down
            a = math.radians(30 * k)
            pts.append(pts[0] + Vector((s * (0.025 * k + 0.01 * math.sin(a)), -0.035 * k + 0.02, 0.1 * math.sin(a) + 0.015 * k)))
        for k, (a, b) in enumerate(zip(pts, pts[1:])):
            K.along("Antenna%d%s" % (k, sd), "Leg", "DEF-head", a, b, 0.015, 0.012, segments=6)
    for i, (hip, foot) in enumerate(LEGS):
        for s, sd in ((1, "L"), (-1, "R")):
            a, b = Vector((s * hip[0], hip[1], hip[2])), Vector((s * foot[0], foot[1], foot[2]))
            K.along("Leg%d.%s" % (i, sd), "Leg", "DEF-leg%d.%s" % (i, sd), a, b, 0.048, 0.034, segments=8)
            K.sphere("Foot%d.%s" % (i, sd), "Leg", "DEF-leg%d.%s" % (i, sd), b + Vector((0, 0, 0.016)), (0.038, 0.04, 0.026), u=8, v=5)
    return BG.bones((0, 0.1, 0.1), (0, -0.05, 0.45), (0, -0.18, 0.2), (0, -0.36, 0.22), LEGS)


def animar(arm):
    BG.animate(arm, 3, stride=26, bob=0.03, flip_h=0.48)
