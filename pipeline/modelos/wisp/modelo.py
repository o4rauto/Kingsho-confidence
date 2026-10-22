"""CR_Wisp — "Fagulha da Fenda": a floating pink flame with an angry grin and loose embers.
Reference: portraits/wisp.png. Floating family (no legs). Height ~1.0 m to the flame tip.
"""
import math
from mathutils import Vector
import kit as K
import floaty as FL

NOME = "CR_Wisp"
PALETA = {"Flame": "EE6FC0", "FlameLight": "F8A8DC", "Core": "FBD0EC", "Eye": "FFF2FA", "Pupil": "B02A80",
          "Mouth": "8E1E66", "Ember": "F48CCF"}
BRILHO = ("Flame", "FlameLight", "Core", "Eye", "Ember")
ATAQUE_QUADRO = 8

BODY_C = Vector((0, 0, 0.40))


def pecas():
    K.sphere("Body", "Flame", "DEF-body", BODY_C, (0.30, 0.26, 0.28), u=20, v=12)
    K.sphere("Belly", "FlameLight", "DEF-body", BODY_C + Vector((0, -0.08, -0.04)), (0.22, 0.2, 0.2), u=16, v=10)
    # flame tongues rising from the crown (portrait: tall central tongue, curls to both sides)
    tongues = [((0.0, 0.1, 1.0), 0.48, 0.17, "Flame"), ((-0.55, 0.15, 0.85), 0.36, 0.13, "Flame"),
               ((0.55, 0.15, 0.85), 0.34, 0.13, "Flame"), ((-0.9, 0.2, 0.4), 0.24, 0.1, "FlameLight"),
               ((0.9, 0.2, 0.45), 0.24, 0.1, "FlameLight"), ((0.0, 0.8, 0.6), 0.3, 0.13, "Flame"),
               ((-0.3, -0.2, 0.95), 0.26, 0.09, "FlameLight"), ((0.32, -0.2, 0.95), 0.24, 0.09, "FlameLight")]
    for i, (d, ln, w, role) in enumerate(tongues):
        d = Vector(d).normalized()
        root = BODY_C + Vector((d.x * 0.18, d.y * 0.1, 0.12 + d.z * 0.1))
        K.lock("Tongue%d" % i, role, "DEF-top", root, d, ln, w, thick=0.55, curl=0.05, power=0.7)
    K.sphere("Core", "Core", "DEF-body", BODY_C + Vector((0, -0.16, 0.08)), (0.12, 0.06, 0.1), u=12, v=8)
    # angry face: slanted glowing eyes, wide grin
    for s, sd in ((1, ".L"), (-1, ".R")):
        e = K.sphere("Eye" + sd, "Eye", "DEF-body", BODY_C + Vector((s * 0.1, -0.235, 0.06)), (0.07, 0.025, 0.04),
                     u=12, v=6, rotation=(0, math.radians(-22) * s, math.radians(16) * s))
        K.sphere("Pupil" + sd, "Pupil", "DEF-body", BODY_C + Vector((s * 0.085, -0.258, 0.05)), (0.022, 0.01, 0.022), u=8, v=5)
    pts = []
    for i in range(9):
        t = i / 8 * 2 - 1
        pts.append(BODY_C + Vector((t * 0.15, -0.255 + 0.03 * t * t, -0.07 + 0.06 * t * t)))
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Grin%d" % i, "Mouth", "DEF-body", a, b, 0.018, segments=6)
    # loose embers (small diamonds) around the flame
    for i, p in enumerate(((0.42, 0.0, 0.62), (-0.44, 0.02, 0.58), (0.2, 0.05, 1.05), (-0.36, 0.0, 0.28))):
        K.sphere("Ember%d" % i, "Ember", "DEF-top" if p[2] > 0.6 else "DEF-body", p, (0.028, 0.02, 0.045), u=4, v=3)
    return FL.bones(0.15, 0.55, 1.0)


def animar(arm):
    FL.animate(arm, bob=0.05, sway=12)
