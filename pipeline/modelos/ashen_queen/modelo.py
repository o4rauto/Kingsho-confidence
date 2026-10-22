"""CH_AshenQueen — "A Rainha das Cinzas": fire queen, burning hair, dark-red spiked crown, glowing amber
eyes, long crimson gown with a flame collar, staff topped with a living flame. Ref: portraits/ashen_queen.png. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_AshenQueen"
ATAQUE_QUADRO = 11
PALETA = {"Skin": "F2C09A", "Gown": "B8261E", "GownDark": "7E1612", "Fire": "FF7A1A", "FireLight": "FFC23A",
          "Crown": ("8E1E14", 0.5, 0.3), "Eye": "FFD26A", "Pupil": "A8360E", "Brow": "8E2A10", "Mouth": "B03A2A",
          "Wood": "5A2E1A", "Shine": "FFFFFF"}
BRILHO = ("Fire", "FireLight", "Eye")

P = BP.hero(r_chest=(0.098, 0.07))


def head(hc, hr):
    c = Vector(hc)
    BP.chibi_face(hc, hr, 0.735, eye_dx=0.064, eye_size=(0.046, 0.02, 0.046), pupil=0.026, slant=-14,
                  brow_role="Brow", brow_tilt=20, shine_role="Shine", ears="elf")
    K.sphere("HairCap", "Fire", "DEF-head", c + Vector((0, 0.015, 0.045)), (0.16, 0.15, 0.152), u=16, v=10)
    flames = [((0, 0.2, 1), 0.3, 0.1), ((-0.5, 0.3, 0.85), 0.28, 0.09), ((0.5, 0.3, 0.85), 0.28, 0.09),
              ((-0.85, 0.4, 0.4), 0.22, 0.08), ((0.85, 0.4, 0.4), 0.22, 0.08), ((0, 0.9, 0.45), 0.25, 0.09),
              ((-0.3, 0.9, 0.0), 0.2, 0.08), ((0.3, 0.9, 0.0), 0.2, 0.08)]
    for i, (d, ln, w) in enumerate(flames):
        d = Vector(d).normalized()
        K.lock("Flame%d" % i, "FireLight" if i % 3 == 0 else "Fire", "DEF-head",
               c + Vector((d.x * 0.1, 0.02 + d.y * 0.08, 0.06 + d.z * 0.1)), d, ln, w, thick=0.5, curl=0.05)
    for i in range(5):   # crown spikes
        a = math.radians(-50 + 25 * i)
        root = c + Vector((math.sin(a) * 0.125, -math.cos(a) * 0.115, 0.12))
        K.along("Crown%d" % i, "Crown", "DEF-head", root, root + Vector((0, -0.01, 0.1 - 0.02 * abs(i - 2))), 0.026, 0.003, segments=6)
    K.band("CrownBand", "Crown", "DEF-head", c + Vector((0, 0.0, 0.12)), 0.135, 0.125, 0.03)


def gown(J):
    K.sphere("Bodice", "Gown", "DEF-chest", (0, -0.02, 0.46), (0.1, 0.076, 0.09), u=14, v=8)
    BP.robe("Gown", top_z=0.40, hem_z=0.03, top_r=0.095, hem_r=0.21, trim_role="GownDark")
    for s in (1, -1):   # flame collar on the shoulders
        for j in range(2):
            K.lock("Collar%d%d" % (s > 0, j), "Fire", "DEF-chest", (s * 0.08, 0.02, 0.54), (s * 0.5, 0.3 + 0.3 * j, 0.8), 0.1, 0.04, thick=0.5)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Sleeve." + sd, "GownDark", "DEF-forearm." + sd, J["el" + sd], J["wr" + sd], 0.03, 0.045, 0.0, 1.0, segments=12)


def staff(J):
    hx, hy, hz = J["wrL"]
    base, top = Vector((hx + 0.01, hy - 0.05, 0.03)), Vector((hx + 0.01, hy - 0.05, 0.78))
    BP.staff("DEF-hand.L", base, top, role="Wood", r=0.014)
    K.lathe("StaffCup", "Crown", "DEF-hand.L", top, [(0.012, 0.0), (0.04, 0.03), (0.035, 0.05)])
    for i, (d, ln) in enumerate((((0, 0, 1), 0.16), ((0.4, 0, 0.9), 0.11), ((-0.4, 0, 0.9), 0.11), ((0, 0.4, 0.9), 0.1))):
        K.lock("StaffFlame%d" % i, "FireLight" if i == 0 else "Fire", "DEF-hand.L", top + Vector((0, 0, 0.04)), d, ln, 0.04, thick=0.6)


def pecas():
    J = BP.body("Body", P, role="Gown")
    BP.hands("", J, P, role="Skin", style="fist", size=0.75)
    BP.feet("", J, P, role="GownDark", style="shoe", size=0.8)
    head(P["head_c"], P["head_r"])
    gown(J)
    staff(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=4)
    BP.run(arm, lean=10, stride=28, arm_swing=20)
    BP.attack(arm, "throw")
    BP.cast(arm, "cast")
    BP.die(arm)
