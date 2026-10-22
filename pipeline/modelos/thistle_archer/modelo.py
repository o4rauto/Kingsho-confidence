"""CH_ThistleArcher — "Arqueira do Cardo": hooded elf-ish ranger girl, green hood and cloak, brown hair,
green tunic, leather bracers and boots, longbow. Ref: portraits/thistle_archer.png. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_ThistleArcher"
ATAQUE_QUADRO = 9
PALETA = {"Skin": "EDB48C", "Hood": "3E8A3A", "HoodDark": "2C6A2C", "Tunic": "5E9A3E", "Leather": "7A4A26",
          "LeatherDark": "4E2E18", "Hair": "7A4A2A", "Eye": "F4F4F4", "Pupil": "2E8A5A", "Brow": "5A341C",
          "Mouth": "A04A3A", "Wood": "6E4424", "String": "F2EBD8", "Feather": "E8E2D2"}

P = BP.hero(r_chest=(0.1, 0.07))


def head(hc, hr):
    c = Vector(hc)
    BP.chibi_face(hc, hr, 0.738, eye_dx=0.064, eye_size=(0.046, 0.02, 0.052), pupil=0.03, slant=-4,
                  brow_role="Brow", brow_tilt=8, shine_role="String", ears=None)
    K.sphere("HairCap", "Hair", "DEF-head", c + Vector((0, 0.015, 0.045)), (0.158, 0.148, 0.15), u=16, v=10)
    for i, (x, d) in enumerate(((-0.08, (-0.5, -0.6, -0.7)), (0.0, (0.1, -0.6, -0.8)), (0.08, (0.5, -0.6, -0.7)))):
        K.lock("Fringe%d" % i, "Hair", "DEF-head", c + Vector((x, -0.12, 0.11)), d, 0.08, 0.045, thick=0.4)
    for s in (1, -1):   # long locks over the shoulders
        K.lock("Lock%d" % (s > 0), "Hair", "DEF-head", c + Vector((s * 0.12, -0.02, -0.04)), (s * 0.2, 0.0, -1), 0.2, 0.05, thick=0.5)
    base = c + Vector((0, 0.018, 0.005))
    K.dome("Hood", "Hood", "DEF-head", base, (0.18, 0.172, 0.205), cut=-0.45, u=24, v=14, face_open=(0.28, 0.6))
    K.along("HoodTip", "Hood", "DEF-head", base + Vector((0, 0.05, 0.18)), base + Vector((0, 0.15, 0.24)), 0.055, 0.004, segments=8)


def gear(J):
    K.sphere("Tunic", "Tunic", "DEF-chest", (0, -0.02, 0.46), (0.108, 0.08, 0.09), u=14, v=8)
    K.skirt("TunicSkirt", "Tunic", "AUTO", 0.37, 0.24, 0.093, 0.11, side_lift=0.03, thickness=0.01)
    K.skirt("Cloak", "Hood", "DEF-chest", 0.56, 0.18, 0.11, 0.18, arc=(10, 170), thickness=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.37), 0.098, 0.074, 0.03)
    K.along("Strap", "Leather", "DEF-chest", (0.09, -0.065, 0.53), (-0.1, -0.075, 0.38), 0.011, segments=6)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Bracer." + sd, "Leather", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.034, 0.032, 0.05, 0.55, segments=10)
        K.along("Legging." + sd, "HoodDark", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.05, 0.043, 0.15, 1.0, segments=10)
    a, b = Vector((0.07, 0.1, 0.36)), Vector((-0.08, 0.1, 0.58))
    K.along("Quiver", "Leather", "DEF-chest", a, b, 0.04, 0.045, segments=12)
    d = (b - a).normalized()
    for i, off in enumerate((Vector((0.01, 0, 0)), Vector((-0.02, 0.015, 0)), Vector((0.0, -0.02, 0.01)))):
        s0, s1 = b + off, b + off + d * 0.1
        K.along("Arrow%d" % i, "Wood", "DEF-chest", s0, s1, 0.006, segments=6)
        K.leaf("Fletch%d" % i, "HoodDark" if i % 2 else "Feather", "DEF-chest", s1 - d * 0.02, 0.05, 0.02,
               rotation=(0, math.radians(-60), math.radians(160)))


def bow(J):
    hx, hy, hz = J["wrL"]
    g = Vector((hx + 0.02, hy - 0.02, 0.29))
    pts = [g + Vector((0.075 * (1 - t * t), 0, t * 0.34)) for t in [i / 8 * 2 - 1 for i in range(9)]]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Bow%d" % i, "Wood", "DEF-hand.L", a, b, 0.015 if 2 < i < 6 else 0.011, segments=8)
    K.along("BowGrip", "LeatherDark", "DEF-hand.L", pts[3], pts[5], 0.019, segments=8)
    K.along("BowString", "String", "DEF-hand.L", pts[0], pts[-1], 0.003, segments=4)


def pecas():
    J = BP.body("Body", P, role="Tunic")
    BP.hands("", J, P, role="Leather", style="fist", size=0.8)
    BP.feet("", J, P, role="LeatherDark", style="boot", size=0.9)
    head(P["head_c"], P["head_r"])
    gear(J)
    bow(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=4)
    BP.run(arm, lean=14, stride=38, arm_swing=26)
    BP.attack(arm, "shoot")
    BP.cast(arm, "summon")
    BP.die(arm)
