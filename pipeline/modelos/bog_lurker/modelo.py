"""CR_BogLurker — "Espreitador do Brejo": a hulking swamp crocodile on two legs, long toothy snout,
mossy back, dripping weeds, heavy tail. Ref: portraits/bog_lurker.png. Biped (hunched, short arms). H 1.1.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_BogLurker"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "4E6A3A", "SkinDark": "34502A", "Belly": "8A9A5A", "Moss": "6A8A2A", "Tooth": "EFE6CF",
          "Eye": "F2D24A", "Pupil": "1A1408", "Mouth": "5A1A1A"}

P = BP.params(hunch=0.1, head_c=(0, -0.24, 0.72), head_r=(0.12, 0.14, 0.1), neck0_z=0.66, neck1_z=0.7,
              chest_z=0.56, waist_z=0.44, pelvis_z=0.34, shoulder_z=0.6, shoulder_x=0.2, elbow_out=0.06, elbow_z=0.48,
              wrist_x=0.29, wrist_z=0.38, wrist_y=-0.1, hand_bottom=0.28, hand_size=0.1,
              hip_x=0.12, hip_z=0.3, knee_x=0.17, knee_y=-0.06, knee_z=0.16, ankle_x=0.2, ankle_z=0.06, foot_len=0.2,
              r_pelvis=(0.2, 0.17), r_waist=(0.22, 0.18), r_chest=(0.22, 0.17), r_neck0=(0.14, 0.12), r_neck1=(0.11, 0.1),
              r_shoulder=0.07, r_elbow=0.055, r_wrist=0.05, r_hip=0.09, r_knee=0.075, r_ankle=0.06)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="mitt3", size=1.0)
    BP.feet("", J, P, role="Skin", style="toes3", size=1.2)
    K.sphere("Belly", "Belly", "DEF-spine", (0, -0.12, 0.47), (0.17, 0.08, 0.16), u=14, v=8)
    c = Vector(P["head_c"])
    K.sphere("Skull", "Skin", "DEF-head", c, (0.12, 0.12, 0.09), u=14, v=10)
    K.along("UpperJaw", "Skin", "DEF-head", c + Vector((0, -0.05, -0.0)), c + Vector((0, -0.3, -0.02)), 0.075, 0.045, segments=10)
    K.along("LowerJaw", "SkinDark", "DEF-head", c + Vector((0, -0.04, -0.06)), c + Vector((0, -0.28, -0.07)), 0.06, 0.04, segments=10)
    K.sphere("MouthLine", "Mouth", "DEF-head", c + Vector((0, -0.17, -0.045)), (0.06, 0.12, 0.012), u=10, v=4)
    for i in range(6):
        y = -0.1 - 0.035 * i
        for s in (1, -1):
            K.along("Tooth%d%d" % (i, s > 0), "Tooth", "DEF-head", c + Vector((s * 0.055, y, -0.04)), c + Vector((s * 0.058, y, -0.075)), 0.01, 0.002, segments=5)
    for s in (1, -1):
        K.sphere("Eye%d" % (s > 0), "Eye", "DEF-head", c + Vector((s * 0.06, -0.06, 0.07)), (0.03, 0.025, 0.025), u=8, v=6)
        K.sphere("Pupil%d" % (s > 0), "Pupil", "DEF-head", c + Vector((s * 0.062, -0.082, 0.075)), (0.006, 0.008, 0.018), u=6, v=4)
    for i, (p, r) in enumerate((((0, 0.08, 0.66), (0.18, 0.1, 0.06)), ((0.12, 0.06, 0.55), (0.1, 0.1, 0.05)), ((-0.12, 0.08, 0.5), (0.1, 0.1, 0.05)))):
        K.sphere("Moss%d" % i, "Moss", "DEF-chest", p, r, u=10, v=6)
    for i, x in enumerate((-0.15, -0.05, 0.08, 0.17)):
        K.lock("Drip%d" % i, "Moss", "DEF-chest", (x, -0.1, 0.62), (0.05, -0.1, -1), 0.12 + 0.04 * (i % 2), 0.03, thick=0.4)
    t0, t1, t2 = Vector((0, 0.15, 0.3)), Vector((0, 0.4, 0.15)), Vector((0, 0.62, 0.06))
    K.along("Tail0", "Skin", "DEF-pelvis", t0, t1, 0.12, 0.08, segments=10)
    K.along("Tail1", "Skin", "DEF-pelvis", t1, t2, 0.08, 0.02, segments=10)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=10, arm_out=10)
    BP.run(arm, lean=16, stride=26, arm_swing=22)
    BP.attack(arm, "bite")
    BP.die(arm)
