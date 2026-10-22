"""CH_FrostWarden — "Guardiã do Gelo": ice-elf queen, long white-blue hair, crystal crown, pale skin,
blue gown with icy hem, glowing ice orb in the left hand. Ref: portraits/frost_warden.png. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_FrostWarden"
ATAQUE_QUADRO = 13
PALETA = {"Skin": "F2DCD8", "Hair": "DCEBF8", "HairShade": "A8C8E8", "Gown": "6AAEE8", "GownLight": "BCE2FA",
          "Ice": ("9AE0FF", 0.2, 0.0), "Eye": "F4F8FF", "Pupil": "2E88D8", "Brow": "B8D0E8", "Mouth": "C07A86",
          "Orb": ("7FD4FF", 0.2, 0.0), "Shine": "FFFFFF"}
BRILHO = ("Ice", "Orb")

P = BP.hero(r_chest=(0.1, 0.07))


def head(hc, hr):
    c = Vector(hc)
    BP.chibi_face(hc, hr, 0.738, eye_dx=0.064, eye_size=(0.046, 0.02, 0.054), pupil=0.03, slant=0,
                  brow_role="Brow", brow_tilt=0, shine_role="Shine", ears="elf")
    K.sphere("HairCap", "Hair", "DEF-head", c + Vector((0, 0.015, 0.045)), (0.16, 0.15, 0.152), u=16, v=10)
    K.sphere("HairBack", "HairShade", "DEF-head", c + Vector((0, 0.07, -0.1)), (0.16, 0.1, 0.22), u=14, v=10)
    for s in (1, -1):
        for j in range(3):
            K.lock("Lock%d%d" % (s > 0, j), "Hair" if j % 2 else "HairShade", "DEF-head",
                   c + Vector((s * (0.11 + 0.025 * j), 0.02 + 0.03 * j, -0.03)), (s * 0.12, 0.15, -1), 0.3 + 0.03 * j, 0.05, thick=0.5)
    K.lock("Fringe0", "Hair", "DEF-head", c + Vector((-0.03, -0.12, 0.12)), (-0.6, -0.6, -0.6), 0.1, 0.06, thick=0.4)
    K.lock("Fringe1", "Hair", "DEF-head", c + Vector((0.03, -0.12, 0.12)), (0.6, -0.6, -0.6), 0.1, 0.06, thick=0.4)
    # crystal crown: a ring of ice spikes, tallest at the front
    for i in range(7):
        a = math.radians(-60 + 120 * i / 6)
        root = c + Vector((math.sin(a) * 0.12, -math.cos(a) * 0.11, 0.12))
        h = 0.14 - 0.035 * abs(i - 3)
        K.along("Crown%d" % i, "Ice", "DEF-head", root, root + Vector((math.sin(a) * 0.02, -0.01, h)), 0.025, 0.003, segments=6)
    K.sphere("CrownGem", "Ice", "DEF-head", (0, c.y - 0.15, c.z + 0.1), (0.016, 0.01, 0.022), u=6, v=4)


def gown(J):
    K.sphere("Bodice", "Gown", "DEF-chest", (0, -0.02, 0.46), (0.105, 0.078, 0.09), u=14, v=8)
    BP.robe("Gown", top_z=0.40, hem_z=0.03, top_r=0.095, hem_r=0.21)
    for i in range(10):   # icy jagged hem
        a = 2 * math.pi * i / 10
        p = Vector((math.cos(a) * 0.205, math.sin(a) * 0.17, 0.06))
        K.along("HemIce%d" % i, "GownLight", "DEF-pelvis", p + Vector((0, 0, 0.06)), p + Vector((0, 0, -0.02)), 0.03, 0.004, segments=6)
    K.sphere("Collar", "GownLight", "DEF-chest", (0, 0.0, 0.54), (0.1, 0.08, 0.035), u=12, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Sleeve." + sd, "GownLight", "DEF-forearm." + sd, J["el" + sd], J["wr" + sd], 0.032, 0.05, 0.0, 1.0, segments=12)


def orb(J):
    hx, hy, hz = J["wrL"]
    c = Vector((hx + 0.04, hy - 0.06, 0.29))
    K.sphere("Orb", "Orb", "DEF-hand.L", c, (0.055, 0.055, 0.055), u=14, v=10)
    for i in range(3):
        a = 2 * math.pi * i / 3
        K.sphere("OrbSpark%d" % i, "Ice", "DEF-hand.L", c + Vector((math.cos(a) * 0.08, 0, math.sin(a) * 0.08)), (0.012, 0.012, 0.02), u=4, v=3)


def pecas():
    J = BP.body("Body", P, role="Gown")
    BP.hands("", J, P, role="Skin", style="fist", size=0.75)
    BP.feet("", J, P, role="Gown", style="shoe", size=0.8)
    head(P["head_c"], P["head_r"])
    gown(J)
    orb(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=4)
    BP.run(arm, lean=10, stride=28, arm_swing=20)
    BP.attack(arm, "cast")
    BP.die(arm)
