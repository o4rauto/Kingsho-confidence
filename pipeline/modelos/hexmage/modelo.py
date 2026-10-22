"""CH_Hexmage — "Mago do Feitiço": goblin witch in a deep purple hood and robe, green skin, yellow eyes,
long nose, crooked wooden staff, pouch. Ref: portraits/hexmage.png. Biped. H 1.15.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Hexmage"
ATAQUE_QUADRO = 13
PALETA = {"Skin": "7AB83A", "SkinDark": "5A8A2A", "Robe": "8A3AB8", "RobeDark": "5E2486", "Leather": "6B4426",
          "Wood": "7A5434", "Eye": "F2D24A", "Pupil": "1A1408", "Mouth": "3A1A1A", "Gem": ("E04AF0", 0.3, 0.0)}
BRILHO = ("Gem",)

P = BP.hero(hunch=0.04, head_c=(0, -0.05, 0.74))


def pecas():
    J = BP.body("Body", P, role="Robe")
    BP.hands("", J, P, role="Skin", style="mitt3", size=0.7)
    BP.feet("", J, P, role="Leather", style="shoe", size=0.85)
    hc, hr = P["head_c"], P["head_r"]
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, 0.75, 0.06, size=(0.04, 0.018, 0.034), slant=-14, pupils=0.016)
    nose = K.along("Nose", "SkinDark", "DEF-head", (0, c.y - 0.13, 0.72), (0, c.y - 0.22, 0.67), 0.03, 0.006, segments=8)
    K.sphere("Mouth", "Mouth", "DEF-head", (0, c.y - 0.13, 0.65), (0.04, 0.01, 0.01), u=8, v=4)
    for s in (1, -1):
        K.leaf("Ear%d" % (s > 0), "Skin", "DEF-head", (s * 0.15, c.y + 0.0, 0.74), 0.14, 0.04, side=s, rotation=(0, math.radians(-12), math.radians(-25)))
    base = c + Vector((0, 0.01, -0.01))
    K.dome("Hood", "Robe", "DEF-head", base, (0.18, 0.17, 0.21), cut=-0.5, u=24, v=14, face_open=(0.3, 0.55))
    K.along("HoodTip", "Robe", "DEF-head", base + Vector((0, 0.05, 0.18)), base + Vector((0, 0.18, 0.28)), 0.06, 0.004, segments=8)
    BP.robe("Robe", top_z=0.42, hem_z=0.04, top_r=0.1, hem_r=0.19, trim_role="RobeDark", ragged=0.02)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.38), 0.105, 0.08, 0.03)
    K.sphere("Pouch", "Leather", "DEF-pelvis", (-0.08, -0.07, 0.34), (0.035, 0.025, 0.035), u=8, v=6)
    K.sphere("Brooch", "Gem", "DEF-chest", (0, -0.085, 0.52), (0.018, 0.01, 0.018), u=8, v=5)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Sleeve." + sd, "Robe", "DEF-forearm." + sd, J["el" + sd], J["wr" + sd], 0.035, 0.055, 0.0, 1.0, segments=12)
    hx, hy, hz = J["wrR"]
    base, top = Vector((hx - 0.01, hy - 0.04, 0.03)), Vector((hx - 0.02, hy - 0.05, 0.72))
    pts = [base + (top - base) * (i / 5) + Vector((0.012 * math.sin(i * 2.1), 0, 0)) for i in range(6)]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Staff%d" % i, "Wood", "DEF-hand.R", a, b, 0.016, 0.014, segments=8)
    K.along("StaffHook", "Wood", "DEF-hand.R", top, top + Vector((0.06, 0, 0.06)), 0.015, 0.01, segments=8)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=8, arm_out=6)
    BP.run(arm, lean=14, stride=28, arm_swing=20, hold_right=True)
    BP.attack(arm, "cast")
    BP.die(arm)
