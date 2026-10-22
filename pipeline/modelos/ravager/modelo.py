"""CH_Ravager — "Devastador": hulking red-brown brute, bald, bearded, tusks, spiked wooden club.
Reference: portraits/ravager.png. Biped, heavy build, hunched. H = 1.30 m.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Ravager"
ATAQUE_QUADRO = 10
PALETA = {"Skin": "A54A2E", "SkinDark": "7E3420", "Beard": "4A2A18", "Tusk": "EFE3C4", "Eye": "F4EED8",
          "Pupil": "2A140A", "Mouth": "4A1410", "Cloth": "6E5A3A", "Iron": ("5A5E66", 0.5, 0.5),
          "Wood": "7A5434", "Spike": ("9A9EA6", 0.45, 0.5)}

P = BP.params(
    hunch=0.06, head_c=(0, -0.13, 0.86), head_r=(0.13, 0.125, 0.14),
    neck0_z=0.68, neck1_z=0.74, chest_z=0.60, waist_z=0.47, pelvis_z=0.38,
    shoulder_z=0.665, shoulder_x=0.17, elbow_out=0.05, elbow_z=0.49,
    wrist_x=0.26, wrist_z=0.36, wrist_y=-0.05, hand_bottom=0.24, hand_size=0.13,
    hip_x=0.09, hip_z=0.36, knee_x=0.12, knee_y=-0.05, knee_z=0.19, ankle_x=0.14, ankle_z=0.09,
    foot_len=0.19,
    r_pelvis=(0.16, 0.11), r_waist=(0.15, 0.11), r_chest=(0.2, 0.13), r_neck0=(0.09, 0.08),
    r_neck1=(0.075, 0.07), r_shoulder=0.075, r_elbow=0.06, r_wrist=0.062, r_hip=0.08, r_knee=0.065, r_ankle=0.055,
)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.sphere("Brow", "SkinDark", "DEF-head", c + Vector((0, -0.1, 0.035)), (0.12, 0.045, 0.035), u=12, v=6)
    K.eyes("", hc, hr, 0.875, 0.05, size=(0.03, 0.014, 0.022), slant=-16, pupils=0.012)
    K.sphere("Nose", "SkinDark", "DEF-head", (0, c.y - 0.13, 0.85), (0.035, 0.03, 0.03), u=10, v=6)
    K.sphere("Jaw", "Skin", "DEF-head", c + Vector((0, -0.05, -0.085)), (0.12, 0.1, 0.075), u=14, v=8)
    K.sphere("Beard", "Beard", "DEF-head", c + Vector((0, -0.07, -0.13)), (0.11, 0.08, 0.08), u=12, v=8)
    K.sphere("Mouth", "Mouth", "DEF-head", c + Vector((0, -0.14, -0.07)), (0.05, 0.015, 0.015), u=10, v=5)
    for s, sd in ((1, ".L"), (-1, ".R")):
        base = c + Vector((s * 0.05, -0.135, -0.075))
        K.along("Tusk" + sd, "Tusk", "DEF-head", base, base + Vector((s * 0.01, -0.01, 0.06)), 0.016, 0.003, segments=8)
        K.leaf("Ear" + sd, "Skin", "DEF-head", c + Vector((s * 0.12, 0.0, 0.0)), 0.06, 0.03, side=s,
               rotation=(0, math.radians(-25), math.radians(-25)))


def gear(J):
    K.sphere("Pecs", "Skin", "DEF-chest", (0, -0.08, 0.6), (0.17, 0.08, 0.08), u=14, v=8)
    K.sphere("Belly", "Skin", "DEF-spine", (0, -0.07, 0.48), (0.14, 0.1, 0.09), u=14, v=8)
    K.skirt("Loincloth", "Cloth", "AUTO", 0.42, 0.24, 0.15, 0.18, ragged=0.03, side_lift=0.05, thickness=0.012)
    K.band("Belt", "Beard", "DEF-pelvis", (0, 0, 0.42), 0.155, 0.115, 0.04)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Wristband." + sd, "Iron", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.072, 0.07, 0.05, 0.4, segments=12)
        K.sphere("Shoulder." + sd, "Skin", "DEF-upper_arm." + sd, Vector(J["sh" + sd]) + Vector((s * 0.02, 0, 0.01)), (0.085, 0.08, 0.07), u=12, v=8)


def club(J):
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.01, hy - 0.03, 0.31))
    tip = h + Vector((-0.06, -0.16, -0.32))
    K.along("Club", "Wood", "DEF-hand.R", h + (h - tip).normalized() * 0.05, tip, 0.03, 0.06, segments=10)
    d = (tip - h).normalized()
    for i in range(6):
        a = 2 * math.pi * i / 6
        side = d.orthogonal().normalized()
        up = d.cross(side)
        p = h + d * (0.2 + 0.05 * (i % 2)) + (side * math.cos(a) + up * math.sin(a)) * 0.05
        K.along("ClubSpike%d" % i, "Spike", "DEF-hand.R", p, p + (side * math.cos(a) + up * math.sin(a)) * 0.05, 0.014, 0.002, segments=6)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="fist", size=1.25)
    BP.feet("", J, P, role="Skin", style="toes3", size=1.1)
    head(P["head_c"], P["head_r"])
    gear(J)
    club(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=8, arm_out=10)
    BP.run(arm, lean=16, stride=34, arm_swing=26, hold_right=True)
    BP.attack(arm, "hammer")
    BP.die(arm)
