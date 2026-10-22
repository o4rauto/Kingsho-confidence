"""CH_Drowned — "Soldado Afogado": teal zombie soldier, sunken glowing eyes, seaweed hair, rusty pauldron,
tattered cloth, spear and a round wooden shield. Ref: portraits/drowned.png. Biped. H 1.15.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Drowned"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "6FA89A", "SkinDark": "4E7E72", "Weed": "4E8A3A", "Cloth": "7A6A4A", "Rust": ("7A6A5A", 0.7, 0.3),
          "Wood": "7A5434", "Steel": ("8A929A", 0.5, 0.4), "Eye": "F2E8A0", "Mouth": "2A1A1E", "Tooth": "EFE6CF"}
BRILHO = ("Eye",)

P = BP.hero(hunch=0.05, head_c=(0, -0.08, 0.74), head_r=(0.13, 0.13, 0.15), neck0_z=0.54, neck1_z=0.59,
            r_chest=(0.1, 0.07), r_waist=(0.075, 0.055), r_shoulder=0.034, r_elbow=0.027, r_wrist=0.028,
            r_hip=0.045, r_knee=0.036, r_ankle=0.03)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="fist", size=0.8)
    BP.feet("", J, P, role="Skin", style="toes3", size=0.85)
    hc, hr = P["head_c"], P["head_r"]
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    for s in (1, -1):
        K.sphere("Socket%d" % (s > 0), "SkinDark", "DEF-head", (s * 0.05, c.y - 0.115, 0.76), (0.035, 0.02, 0.03), u=10, v=6)
        K.sphere("Eye%d" % (s > 0), "Eye", "DEF-head", (s * 0.05, c.y - 0.128, 0.76), (0.022, 0.01, 0.018), u=8, v=5)
    K.sphere("Jaw", "Skin", "DEF-head", c + Vector((0, -0.06, -0.1)), (0.09, 0.08, 0.05), u=12, v=8)
    K.sphere("Mouth", "Mouth", "DEF-head", (0, c.y - 0.135, 0.65), (0.05, 0.012, 0.025), u=10, v=5)
    for i, x in enumerate((-0.03, -0.01, 0.01, 0.03)):
        K.box("Tooth%d" % i, "Tooth", "DEF-head", (x, c.y - 0.145, 0.66 - 0.01 * (i % 2)), (0.014, 0.008, 0.016))
    for i, (d, ln) in enumerate((((0, 0.3, 1), 0.12), ((-0.6, 0.3, 0.5), 0.14), ((0.6, 0.4, 0.4), 0.13), ((0.2, 0.8, -0.3), 0.16))):
        K.lock("Weed%d" % i, "Weed", "DEF-head", c + Vector((0, 0.02, 0.12)), d, ln, 0.04, thick=0.4, curl=-0.03)
    K.skirt("Rags", "Cloth", "AUTO", 0.37, 0.2, 0.09, 0.12, ragged=0.04, side_lift=0.05)
    K.band("Belt", "Wood", "DEF-pelvis", (0, 0, 0.37), 0.095, 0.072, 0.03)
    K.dome("Pauldron", "Rust", "DEF-upper_arm.L", Vector(J["shL"]) + Vector((0.015, 0, 0)), (0.065, 0.065, 0.05))
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.005, hy - 0.03, 0.29))
    K.along("Spear", "Wood", "DEF-hand.R", h + Vector((0.08, 0.2, -0.2)), h + Vector((-0.12, -0.32, 0.25)), 0.011, segments=6)
    K.along("SpearTip", "Steel", "DEF-hand.R", h + Vector((-0.12, -0.32, 0.25)), h + Vector((-0.15, -0.39, 0.31)), 0.025, 0.002, segments=4)
    lx, ly, lz = J["wrL"]
    sc = Vector((lx + 0.035, ly - 0.06, 0.34))
    K.cone("Shield", "Wood", "DEF-forearm.L", sc, 0.12, 0.12, 0.022, axis="Y", segments=18, rotation=(0, 0, math.radians(30)))
    K.cone("ShieldRim", "Rust", "DEF-forearm.L", sc + Vector((0, 0.002, 0)), 0.127, 0.127, 0.016, axis="Y", segments=18, rotation=(0, 0, math.radians(30)))
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=10, arm_out=6)
    BP.run(arm, lean=18, stride=30, arm_swing=22, hold_right=True)
    BP.attack(arm, "spear")
    BP.die(arm)
