"""CR_EmberImp — "Diabrete de Brasa": small red-orange devil, flame hair, horns, pointed ears, grin,
long tail ending in a flame. Ref: portraits/ember_imp.png. Biped, small. H 1.0.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_EmberImp"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "E8541E", "SkinDark": "B8361A", "Flame": "FF8A1A", "FlameLight": "FFC83A", "Horn": "5A2A14",
          "Eye": "FFE07A", "Pupil": "8A1A0A", "Mouth": "6A140A", "Tooth": "F4EEDC"}
BRILHO = ("Flame", "FlameLight", "Eye")

P = BP.hero(hunch=0.03, head_c=(0, -0.05, 0.72), head_r=(0.15, 0.135, 0.15), neck0_z=0.52, neck1_z=0.57,
            chest_z=0.45, waist_z=0.37, pelvis_z=0.31, shoulder_z=0.5, shoulder_x=0.09, elbow_z=0.39,
            wrist_x=0.17, wrist_z=0.29, hand_bottom=0.2, hand_size=0.09, hip_z=0.29, knee_z=0.16, ankle_z=0.075,
            r_chest=(0.09, 0.07), r_waist=(0.07, 0.055), r_pelvis=(0.08, 0.06), r_shoulder=0.032, r_elbow=0.025,
            r_wrist=0.026, r_hip=0.042, r_knee=0.034, r_ankle=0.028)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="mitt3", size=0.8)
    BP.feet("", J, P, role="Skin", style="toes3", size=0.8)
    hc, hr = P["head_c"], P["head_r"]
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, 0.72, 0.058, size=(0.042, 0.018, 0.03), slant=-20, pupils=0.016)
    K.sphere("Grin", "Mouth", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.64, 0.01), 0.64), (0.06, 0.012, 0.016), u=10, v=5)
    for s in (1, -1):
        K.along("Fang%d" % (s > 0), "Tooth", "DEF-head", (s * 0.025, c.y - 0.13, 0.65), (s * 0.025, c.y - 0.13, 0.62), 0.008, 0.002, segments=5)
        K.leaf("Ear%d" % (s > 0), "Skin", "DEF-head", (s * 0.13, c.y, 0.73), 0.1, 0.04, side=s, rotation=(0, math.radians(-25), math.radians(-15)))
        K.along("Horn%d" % (s > 0), "Horn", "DEF-head", c + Vector((s * 0.07, -0.03, 0.12)), c + Vector((s * 0.11, 0.0, 0.22)), 0.025, 0.004, segments=8)
    for i, (d, ln) in enumerate((((0, 0.2, 1), 0.22), ((-0.5, 0.3, 0.8), 0.18), ((0.5, 0.3, 0.8), 0.18), ((0, 0.8, 0.6), 0.18))):
        K.lock("Hair%d" % i, "FlameLight" if i == 0 else "Flame", "DEF-head", c + Vector((0, 0.02, 0.1)), d, ln, 0.07, thick=0.5, curl=0.05)
    pts = [Vector((0, 0.06, 0.32)), Vector((0, 0.18, 0.26)), Vector((0.06, 0.28, 0.32)), Vector((0.1, 0.3, 0.45))]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Tail%d" % i, "Skin", "DEF-pelvis", a, b, 0.022 - 0.004 * i, 0.018 - 0.004 * i, segments=8)
    K.lock("TailFlame", "Flame", "DEF-pelvis", pts[-1], (0.2, 0.1, 1), 0.14, 0.05, thick=0.6)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=6, arm_out=10)
    BP.run(arm, lean=18, stride=40, arm_swing=34)
    BP.attack(arm, "claw")
    BP.die(arm)
