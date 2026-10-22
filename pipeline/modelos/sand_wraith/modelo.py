"""CR_SandWraith — "Espectro de Areia" (no portrait: designed from game_data — flyer, sand e8c88a, spits).
A hooded desert spirit: a tattered sand-coloured cowl around a dark hollow face with two burning amber
eyes, linen wrappings, clawed bony hands, and a body that thins into a whirling sand tail. Floaty family
with arms. H 1.05.
"""
import math
from mathutils import Vector
import kit as K
import floaty as FL

NOME = "CR_SandWraith"
ATAQUE_QUADRO = 8
PALETA = {"Sand": "E8C88A", "SandDark": "B8945A", "Wrap": "F2E4C2", "Void": "2A1E14", "Eye": "FFB43A",
          "Bone": "D8C8A0", "Gold": ("D8A030", 0.4, 0.5)}
BRILHO = ("Eye",)

C = Vector((0, 0, 0.62))


def pecas():
    K.sphere("Chest", "Sand", "DEF-body", C, (0.16, 0.13, 0.16), u=18, v=12)
    pts = [C + Vector((0, 0.0, -0.08))]
    for k in range(1, 7):   # body thins and whirls into a sand tail
        a = math.radians(55 * k)
        pts.append(pts[0] + Vector((0.05 * math.sin(a), 0.03 * k, -0.075 * k)))
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Whirl%d" % k, "Sand" if k % 2 == 0 else "SandDark", "DEF-body", a, b, 0.14 - 0.02 * k, 0.12 - 0.02 * k, segments=12)
    for k in range(5):
        a = math.radians(72 * k)
        root = C + Vector((math.cos(a) * 0.12, math.sin(a) * 0.1, -0.1))
        K.lock("Rag%d" % k, "SandDark", "DEF-body", root, (math.cos(a) * 0.4, math.sin(a) * 0.4, -1), 0.22, 0.07, thick=0.25, rings=6, seg=7)
    hc = C + Vector((0, -0.03, 0.22))
    K.sphere("Face", "Void", "DEF-top", hc, (0.11, 0.1, 0.12), u=14, v=10)
    K.dome("Cowl", "Sand", "DEF-top", hc + Vector((0, 0.015, -0.04)), (0.15, 0.15, 0.19), cut=-0.6, u=22, v=12, face_open=(0.35, 0.65))
    K.along("CowlTip", "Sand", "DEF-top", hc + Vector((0, 0.06, 0.12)), hc + Vector((0, 0.2, 0.2)), 0.06, 0.004, segments=8)
    K.sphere("Brooch", "Gold", "DEF-top", hc + Vector((0, -0.13, -0.1)), (0.03, 0.015, 0.03), u=8, v=6)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-top", hc + Vector((s * 0.04, -0.1, 0.0)), (0.024, 0.01, 0.016), u=8, v=4,
                 rotation=(0, math.radians(-18) * s, 0))
    for s, sd in ((1, "L"), (-1, "R")):
        bone = "DEF-arm." + sd
        sh, hand = C + Vector((s * 0.14, 0, 0.08)), C + Vector((s * 0.3, -0.08, -0.06))
        K.along("Sleeve." + sd, "Sand", bone, sh, hand, 0.05, 0.075, 0.0, 0.85, segments=12)
        K.sphere("Hand." + sd, "Bone", bone, hand, (0.035, 0.035, 0.035), u=8, v=6)
        K.along("Cuff." + sd, "Wrap", bone, sh, hand, 0.074, 0.078, 0.62, 0.74, segments=12)
        for k, d in enumerate(((s * 0.3, -0.5, -0.8), (s * 0.7, -0.2, -0.7), (0, -0.7, -0.7))):
            K.along("Finger%d.%s" % (k, sd), "Bone", bone, hand, hand + Vector(d) * 0.1, 0.014, 0.003, segments=5)
    return FL.bones(0.25, 0.8, 1.05, arms=(0.14, 0.7, 0.32, 0.56))


def animar(arm):
    FL.animate(arm, bob=0.06, sway=8)
