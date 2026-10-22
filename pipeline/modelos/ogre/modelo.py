"""CR_Ogre — "Ogro da Fenda": a hulking red-brown ogre, bald head with angry brows, underbite with big
tusks, spiked leather shoulder pads, studded wristbands, round belly, ragged loincloth, huge fists.
Ref: portraits/ogre.png. Biped (hunched). H 1.1.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_Ogre"
ATAQUE_QUADRO = 11
PALETA = {"Skin": "B4583E", "SkinDark": "8A3E2A", "Belly": "C87A5A", "Leather": "4A3426", "Steel": ("B8BCC4", 0.35, 0.6),
          "Cloth": "7A5A3A", "Tusk": "F0E6CC", "Eye": "F2D24A", "Pupil": "1A1408", "Mouth": "3A1410"}

P = BP.params(hunch=0.1, head_c=(0, -0.2, 0.8), head_r=(0.13, 0.13, 0.13), neck0_z=0.7, neck1_z=0.74,
              chest_z=0.6, waist_z=0.46, pelvis_z=0.34, shoulder_z=0.66, shoulder_x=0.22, elbow_out=0.06, elbow_z=0.5,
              wrist_x=0.32, wrist_z=0.36, wrist_y=-0.1, hand_bottom=0.24, hand_size=0.13,
              hip_x=0.12, hip_z=0.3, knee_x=0.16, knee_y=-0.05, knee_z=0.16, ankle_x=0.18, ankle_z=0.06, foot_len=0.2,
              r_pelvis=(0.2, 0.16), r_waist=(0.23, 0.19), r_chest=(0.24, 0.18), r_neck0=(0.13, 0.11), r_neck1=(0.11, 0.1),
              r_shoulder=0.09, r_elbow=0.07, r_wrist=0.065, r_hip=0.09, r_knee=0.075, r_ankle=0.065)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.sphere("Jaw", "Skin", "DEF-head", c + Vector((0, -0.06, -0.08)), (0.12, 0.1, 0.07), u=14, v=8)
    K.sphere("Mouth", "Mouth", "DEF-head", c + Vector((0, -0.15, -0.065)), (0.06, 0.012, 0.014), u=10, v=4)
    K.sphere("Nose", "SkinDark", "DEF-head", c + Vector((0, -0.13, 0.0)), (0.035, 0.03, 0.03), u=10, v=6)
    K.eyes("", hc, hr, c.z + 0.035, 0.05, size=(0.032, 0.014, 0.022), slant=-20, pupils=0.012)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.box("Brow" + sd, "SkinDark", "DEF-head", (s * 0.05, c.y - 0.115, c.z + 0.07), (0.07, 0.03, 0.025),
              rotation=(0, math.radians(-22) * s, math.radians(12) * s), bevel=0.01)
        K.along("Tusk" + sd, "Tusk", "DEF-head", c + Vector((s * 0.06, -0.13, -0.08)), c + Vector((s * 0.075, -0.16, 0.0)),
                0.022, 0.004, segments=6)
        K.leaf("Ear" + sd, "Skin", "DEF-head", c + Vector((s * 0.12, 0.0, 0.01)), 0.07, 0.04, side=s,
               rotation=(0, math.radians(-10), math.radians(-20)))


def gear(J):
    K.sphere("Belly", "Belly", "DEF-spine", (0, -0.13, 0.45), (0.19, 0.1, 0.16), u=16, v=10)
    K.skirt("Loin", "Cloth", "AUTO", 0.36, 0.14, 0.19, 0.22, ragged=0.05, side_lift=0.04, thickness=0.014)
    K.band("Belt", "Leather", "DEF-pelvis", (0, -0.01, 0.36), 0.2, 0.17, 0.045)
    K.box("Buckle", "Steel", "DEF-pelvis", (0, -0.18, 0.36), (0.06, 0.016, 0.045), bevel=0.008)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pad." + sd, "Leather", "DEF-upper_arm." + sd, sh + Vector((s * 0.01, 0, 0.02)), (0.12, 0.12, 0.09))
        for k, (dx, dy) in enumerate(((0.02, -0.05), (0.07, 0.02), (0.0, 0.06))):
            root = sh + Vector((s * (0.04 + dx), dy, 0.08))
            K.along("PadSpike%d.%s" % (k, sd), "Steel", "DEF-upper_arm." + sd, root, root + Vector((s * 0.04, dy * 0.4, 0.09)),
                    0.022, 0.003, segments=6)
        el, wr = Vector(J["el" + sd]), Vector(J["wr" + sd])
        cuff = el + (wr - el) * 0.75
        K.band("Cuff." + sd, "Leather", "DEF-forearm." + sd, cuff, 0.072, 0.072, 0.06, thickness=0.016)
        for k in range(4):
            a = math.radians(90 * k + 45)
            K.sphere("Stud%d.%s" % (k, sd), "Steel", "DEF-forearm." + sd, cuff + Vector((math.cos(a) * 0.088, math.sin(a) * 0.088, 0)),
                     (0.014, 0.014, 0.014), u=6, v=4)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="fist", size=1.6)
    BP.feet("", J, P, role="Skin", style="toes3", size=1.2)
    head(P["head_c"], P["head_r"])
    gear(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=10, arm_out=12)
    BP.run(arm, lean=16, stride=26, arm_swing=24)
    BP.attack(arm, "slam")
    BP.die(arm)
