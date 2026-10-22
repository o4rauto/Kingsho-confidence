"""CH_Stormcaller — "Mago da Tempestade": old wizard, tall blue pointed hat with a gold moon, long white
beard and brows, blue robe with gold trims and brown belt, twisted staff crackling with lightning.
Ref: portraits/stormcaller.png. H 1.25.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Stormcaller"
ATAQUE_QUADRO = 9
PALETA = {"Skin": "EDB48C", "Robe": "3A6AC0", "RobeDark": "2A4E96", "Gold": ("E3B23A", 0.4, 0.4),
          "Beard": "F2F2F2", "Eye": "F4F8FF", "Pupil": "2E78D8", "Mouth": "8A3A2A", "Leather": "6B4426",
          "Wood": "6E5A4A", "Bolt": ("9AE8FF", 0.2, 0.0)}
BRILHO = ("Bolt",)

P = BP.hero(head_c=(0, -0.04, 0.77))


def head(hc, hr):
    c = Vector(hc)
    BP.chibi_face(hc, hr, 0.75, eye_dx=0.06, eye_size=(0.04, 0.018, 0.04), pupil=0.024, slant=-12,
                  brow_role="Beard", brow_tilt=22, mouth_role=None, chin=False, nose=False)
    K.sphere("Nose", "Skin", "DEF-head", (0, c.y - 0.15, 0.71), (0.03, 0.03, 0.028), u=10, v=6)
    K.sphere("Mustache", "Beard", "DEF-head", (0, c.y - 0.13, 0.685), (0.09, 0.04, 0.03), u=12, v=6)
    K.lock("Beard", "Beard", "DEF-head", (0, c.y - 0.1, 0.67), (0, -0.25, -1), 0.26, 0.11, thick=0.45, curl=0.0, power=0.7)
    for s in (1, -1):
        K.sphere("BeardSide%d" % (s > 0), "Beard", "DEF-head", (s * 0.1, c.y - 0.06, 0.66), (0.06, 0.06, 0.07), u=10, v=6)
        K.sphere("HairSide%d" % (s > 0), "Beard", "DEF-head", (s * 0.13, c.y + 0.03, 0.75), (0.05, 0.07, 0.06), u=10, v=6)
    # pointed hat: wide brim + tall cone bent back, gold moon
    base = c + Vector((0, 0.01, 0.1))
    K.cone("HatBrim", "Robe", "DEF-head", base, 0.25, 0.2, 0.025, segments=24)
    K.cone("HatCone", "Robe", "DEF-head", base + Vector((0, 0.03, 0.14)), 0.17, 0.08, 0.27, segments=20, rotation=(math.radians(-12), 0, 0))
    K.cone("HatTip", "Robe", "DEF-head", base + Vector((0, 0.1, 0.33)), 0.08, 0.005, 0.16, segments=12, rotation=(math.radians(-40), 0, 0))
    K.band("HatBand", "RobeDark", "DEF-head", base + Vector((0, 0.0, 0.035)), 0.17, 0.17, 0.035)
    K.sphere("Moon", "Gold", "DEF-head", base + Vector((0, -0.17, 0.06)), (0.03, 0.01, 0.03), u=10, v=6)


def robe(J):
    K.sphere("Chest", "Robe", "DEF-chest", (0, -0.02, 0.46), (0.11, 0.08, 0.09), u=14, v=8)
    BP.robe("Robe", top_z=0.40, hem_z=0.03, top_r=0.1, hem_r=0.2, trim_role="Gold")
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.38), 0.104, 0.08, 0.035)
    K.box("Buckle", "Gold", "DEF-pelvis", (0, -0.088, 0.38), (0.035, 0.012, 0.03), bevel=0.005)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Sleeve." + sd, "Robe", "DEF-forearm." + sd, J["el" + sd], J["wr" + sd], 0.036, 0.058, 0.0, 1.0, segments=12)
        K.band("Cuff." + sd, "Gold", "DEF-forearm." + sd, Vector(J["wr" + sd]) + Vector((0, 0, 0.012)), 0.058, 0.058, 0.014)


def staff(J):
    hx, hy, hz = J["wrL"]
    base, top = Vector((hx + 0.01, hy - 0.05, 0.03)), Vector((hx + 0.02, hy - 0.05, 0.82))
    pts = [base + (top - base) * (i / 6) + Vector((0.015 * math.sin(i * 1.7), 0.01 * math.cos(i * 1.3), 0)) for i in range(7)]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Staff%d" % i, "Wood", "DEF-hand.L", a, b, 0.016, 0.014, segments=8)
    K.sphere("StaffKnot", "Wood", "DEF-hand.L", top, (0.03, 0.03, 0.03), u=8, v=6)
    zig = [top + Vector((0.0, 0, 0.02)), top + Vector((0.05, 0, 0.09)), top + Vector((0.0, 0, 0.13)),
           top + Vector((0.06, 0, 0.2)), top + Vector((0.02, 0, 0.24))]
    for i, (a, b) in enumerate(zip(zig, zig[1:])):
        K.along("Bolt%d" % i, "Bolt", "DEF-hand.L", a, b, 0.012, 0.008, segments=6)
    zig2 = [top + Vector((-0.02, 0, 0.0)), top + Vector((-0.07, 0, 0.06)), top + Vector((-0.03, 0, 0.1)), top + Vector((-0.08, 0, 0.16))]
    for i, (a, b) in enumerate(zip(zig2, zig2[1:])):
        K.along("BoltB%d" % i, "Bolt", "DEF-hand.L", a, b, 0.008, 0.005, segments=6)


def pecas():
    J = BP.body("Body", P, role="Robe")
    BP.hands("", J, P, role="Skin", style="fist", size=0.8)
    BP.feet("", J, P, role="Leather", style="shoe", size=0.85)
    head(P["head_c"], P["head_r"])
    robe(J)
    staff(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=6, arm_out=4)
    BP.run(arm, lean=12, stride=26, arm_swing=18)
    BP.attack(arm, "point")
    BP.cast(arm, "cast")
    BP.die(arm)
