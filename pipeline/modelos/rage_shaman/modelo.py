"""CH_RageShaman — "Xamã da Fúria" (no portrait: designed from game_data — caster, red b0202a, rage aura,
heals). A hunched orc shaman wearing a horned ram skull, red war paint, ragged red cloak, bone necklace,
and a totem staff topped with a burning red gem in a cage of bones and hanging feathers. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_RageShaman"
ATAQUE_QUADRO = 13
PALETA = {"Skin": "7E9048", "SkinDark": "5C6C34", "Robe": "B0202A", "RobeDark": "781419", "Bone": "EFE6CF",
          "Horn": "C8B48C", "Socket": "201014", "Eye": "FF4A2A", "Tusk": "F4ECD8", "Mouth": "3A1410",
          "Paint": "E8E0D0", "Wood": "6B4426", "Fur": "6A5040", "Leather": "5A3A20", "Gem": ("FF3A2A", 0.3, 0.0),
          "Feather": "D8402E"}
BRILHO = ("Eye", "Gem")

P = BP.hero(hunch=0.06, head_c=(0, -0.08, 0.72), head_r=(0.14, 0.13, 0.14), neck0_z=0.55, neck1_z=0.6,
            chest_z=0.47, waist_z=0.38, pelvis_z=0.31, shoulder_z=0.52, shoulder_x=0.125, elbow_z=0.4,
            wrist_x=0.2, wrist_z=0.31, wrist_y=-0.07, hand_bottom=0.23, hand_size=0.1,
            r_chest=(0.13, 0.095), r_waist=(0.11, 0.085), r_pelvis=(0.11, 0.08), r_shoulder=0.046, r_elbow=0.036,
            r_wrist=0.034, r_hip=0.054, r_knee=0.044, r_ankle=0.038)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.sphere("Jaw", "SkinDark", "DEF-head", c + Vector((0, -0.07, -0.08)), (0.1, 0.07, 0.05), u=12, v=8)
    K.sphere("Mouth", "Mouth", "DEF-head", c + Vector((0, -0.13, -0.075)), (0.05, 0.012, 0.014), u=8, v=4)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.along("Tusk" + sd, "Tusk", "DEF-head", c + Vector((s * 0.045, -0.12, -0.09)), c + Vector((s * 0.06, -0.15, -0.02)),
                0.016, 0.003, segments=6)
        K.leaf("Ear" + sd, "Skin", "DEF-head", c + Vector((s * 0.15, 0.01, -0.03)), 0.12, 0.045, side=s,
               rotation=(0, math.radians(-10), math.radians(-30)))
    # red hood, and a ram skull worn as a mask over the brow, eyes glowing in the sockets
    K.dome("Hood", "Robe", "DEF-head", c + Vector((0, 0.012, -0.02)), (0.165, 0.16, 0.17), cut=-0.45, u=22, v=12,
           face_open=(0.35, 0.45))
    K.sphere("Skull", "Bone", "DEF-head", c + Vector((0, -0.1, 0.07)), (0.105, 0.075, 0.08), u=16, v=10)
    K.sphere("Snout", "Bone", "DEF-head", c + Vector((0, -0.165, 0.03)), (0.05, 0.045, 0.04), u=10, v=6)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Socket" + sd, "Socket", "DEF-head", c + Vector((s * 0.045, -0.16, 0.075)), (0.03, 0.02, 0.026), u=8, v=6)
        K.sphere("Eye" + sd, "Eye", "DEF-head", c + Vector((s * 0.045, -0.174, 0.074)), (0.015, 0.008, 0.012), u=8, v=4)
        pts = []
        for i in range(9):   # curled horn: out, back, down and forward around the ear
            a = math.radians(-20 + 42 * i)
            r = 0.1 - 0.006 * i
            pts.append(c + Vector((s * (0.11 + 0.012 * i), -0.02 + math.sin(a) * r * 0.85, 0.1 + math.cos(a) * r - 0.1)))
        for i, (a, b) in enumerate(zip(pts, pts[1:])):
            K.along("Horn%d%s" % (i, sd), "Horn", "DEF-head", a, b, 0.048 - 0.0045 * i, 0.044 - 0.0045 * i, segments=8)


def gear(J):
    K.skirt("Cloak", "Robe", "DEF-chest", 0.56, 0.1, 0.12, 0.2, arc=(15, 165), ragged=0.05, thickness=0.012)
    K.sphere("FurMantle", "Fur", "DEF-chest", (0, 0.0, 0.54), (0.15, 0.115, 0.045), u=14, v=8)
    K.skirt("Loin", "Robe", "AUTO", 0.37, 0.17, 0.105, 0.14, ragged=0.04, side_lift=0.05, thickness=0.012)
    K.skirt("LoinTrim", "RobeDark", "AUTO", 0.37, 0.3, 0.108, 0.12, thickness=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.37), 0.11, 0.084, 0.03)
    for i in range(7):   # bone necklace
        a = math.radians(-60 + 20 * i)
        p = Vector((math.sin(a) * 0.11, -math.cos(a) * 0.1 - 0.01, 0.5 - 0.03 * math.cos(a)))
        K.along("Fang%d" % i, "Bone", "DEF-chest", p, p + Vector((0, -0.01, -0.045)), 0.012, 0.003, segments=5)
    for s, sd in ((1, "L"), (-1, "R")):   # war paint stripes
        el, wr = Vector(J["el" + sd]), Vector(J["wr" + sd])
        for k in range(2):
            K.band("Paint%d.%s" % (k, sd), "Paint", "DEF-forearm." + sd, el + (wr - el) * (0.35 + 0.25 * k), 0.038, 0.038, 0.012)
        K.box("ChestPaint." + sd, "Robe", "DEF-chest", (s * 0.05, -0.12, 0.45), (0.022, 0.01, 0.07),
              rotation=(0, math.radians(18) * s, 0))


def totem(J):
    hx, hy, hz = J["wrR"]
    base, top = Vector((hx - 0.01, hy - 0.04, 0.03)), Vector((hx - 0.02, hy - 0.05, 0.86))
    pts = [base + (top - base) * (i / 5) + Vector((0.01 * math.sin(i * 1.9), 0, 0)) for i in range(6)]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Staff%d" % i, "Wood", "DEF-hand.R", a, b, 0.017, 0.015, segments=8)
    g = top + Vector((0, 0, 0.06))
    K.sphere("Gem", "Gem", "DEF-hand.R", g, (0.045, 0.045, 0.055), u=12, v=8)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        root = top + Vector((math.cos(a) * 0.03, math.sin(a) * 0.03, -0.01))
        K.along("Cage%d" % k, "Bone", "DEF-hand.R", root, g + Vector((math.cos(a) * 0.05, math.sin(a) * 0.05, 0.08)),
                0.01, 0.003, segments=5)
    K.band("Binding", "Leather", "DEF-hand.R", top - Vector((0, 0, 0.04)), 0.024, 0.024, 0.04)
    for k, dx in enumerate((-0.03, 0.0, 0.03)):
        K.along("Cord%d" % k, "Leather", "DEF-hand.R", top - Vector((0, 0, 0.05)), top + Vector((dx, -0.01, -0.14)), 0.003, segments=4)
        K.lock("Feather%d" % k, "Feather" if k != 1 else "Bone", "DEF-hand.R", top + Vector((dx, -0.01, -0.14)), (dx * 3, -0.1, -1),
               0.09, 0.03, thick=0.25)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="mitt3", size=0.85)
    BP.feet("", J, P, role="Skin", style="toes3", size=0.9)
    head(P["head_c"], P["head_r"])
    gear(J)
    totem(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=10, arm_out=8)
    BP.run(arm, lean=16, stride=30, arm_swing=22, hold_right=True)
    BP.attack(arm, "cast")
    BP.die(arm)
