"""CR_Yeti — "Yeti" (no portrait: designed from game_data — brute, white e8f2ff, regen, berserk, slam).
A shaggy white mountain brute: blue-grey face, hands and feet, small ivory horns, angry yellow eyes, open
fanged mouth, fur clumps on shoulders, forearms and shins, long arms with huge mitts. Biped (hunched). H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_Yeti"
ATAQUE_QUADRO = 10
PALETA = {"Fur": "EEF4FA", "FurShade": "C6D6E6", "Skin": "7894B4", "SkinDark": "56708E", "Horn": "E8DCC0",
          "Eye": "F2E06A", "Pupil": "1A1408", "Mouth": "2A1A2A", "Fang": "FFFFFF", "Ice": "A8E0F8"}

P = BP.params(hunch=0.1, head_c=(0, -0.18, 0.84), head_r=(0.14, 0.13, 0.14), neck0_z=0.74, neck1_z=0.78,
              chest_z=0.63, waist_z=0.48, pelvis_z=0.36, shoulder_z=0.7, shoulder_x=0.22, elbow_out=0.07, elbow_z=0.5,
              wrist_x=0.32, wrist_z=0.32, wrist_y=-0.08, hand_bottom=0.18, hand_size=0.14,
              hip_x=0.11, hip_z=0.32, knee_x=0.15, knee_y=-0.05, knee_z=0.17, ankle_x=0.17, ankle_z=0.07, foot_len=0.22,
              r_pelvis=(0.19, 0.15), r_waist=(0.2, 0.16), r_chest=(0.24, 0.18), r_neck0=(0.13, 0.11), r_neck1=(0.11, 0.1),
              r_shoulder=0.085, r_elbow=0.068, r_wrist=0.06, r_hip=0.09, r_knee=0.075, r_ankle=0.065)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Fur", "DEF-head", c, hr, u=18, v=12)
    K.sphere("Face", "Skin", "DEF-head", c + Vector((0, -0.08, -0.02)), (0.105, 0.075, 0.095), u=16, v=10)
    K.sphere("Brow", "FurShade", "DEF-head", c + Vector((0, -0.11, 0.06)), (0.11, 0.045, 0.035), u=12, v=6)
    K.eyes("", hc, (hr[0], hr[1] + 0.035, hr[2]), c.z + 0.025, 0.045, size=(0.03, 0.014, 0.024), slant=-20, pupils=0.012)
    K.sphere("Nose", "SkinDark", "DEF-head", c + Vector((0, -0.16, 0.0)), (0.03, 0.022, 0.022), u=8, v=6)
    K.sphere("Mouth", "Mouth", "DEF-head", c + Vector((0, -0.145, -0.065)), (0.06, 0.02, 0.03), u=12, v=6)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.along("FangUp" + sd, "Fang", "DEF-head", c + Vector((s * 0.035, -0.155, -0.04)), c + Vector((s * 0.035, -0.16, -0.075)),
                0.012, 0.002, segments=5)
        K.along("FangLow" + sd, "Fang", "DEF-head", c + Vector((s * 0.05, -0.15, -0.09)), c + Vector((s * 0.052, -0.158, -0.06)),
                0.011, 0.002, segments=5)
        pts = [c + Vector((s * 0.09, -0.02, 0.1))]
        for k in range(1, 4):
            pts.append(pts[0] + Vector((s * 0.035 * k, 0.01 * k, 0.04 * k - 0.006 * k * k)))
        for k, (a, b) in enumerate(zip(pts, pts[1:])):
            K.along("Horn%d%s" % (k, sd), "Horn", "DEF-head", a, b, 0.026 - 0.007 * k, 0.02 - 0.006 * k, segments=8)
    for k, (d, ln) in enumerate((((0, 0.6, 0.8), 0.14), ((0.5, 0.6, 0.5), 0.12), ((-0.5, 0.6, 0.5), 0.12), ((0, 0.9, 0.0), 0.13))):
        K.lock("HeadTuft%d" % k, "Fur", "DEF-head", c + Vector((d[0] * 0.08, 0.04, 0.08)), d, ln, 0.07, thick=0.5, rings=6, seg=7)


def fur(J):
    K.sphere("ChestFur", "FurShade", "DEF-chest", (0, -0.13, 0.6), (0.17, 0.08, 0.12), u=14, v=8)
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = Vector(J["sh" + sd]), Vector(J["el" + sd]), Vector(J["wr" + sd])
        for k, d in enumerate(((s * 0.6, 0.1, 1), (s * 1, 0.2, 0.3), (s * 0.5, 0.8, 0.5), (s * 0.4, -0.6, 0.4))):
            K.lock("ShoulderFur%d.%s" % (k, sd), "Fur" if k % 2 == 0 else "FurShade", "DEF-upper_arm." + sd,
                   sh + Vector((s * 0.04, 0, 0.04)), d, 0.15, 0.08, thick=0.5, rings=6, seg=7)
        cuff = el + (wr - el) * 0.55
        for k in range(4):
            a = math.radians(90 * k + 20)
            d = Vector((math.cos(a), math.sin(a), -1.2))
            K.lock("ArmFur%d.%s" % (k, sd), "Fur", "DEF-forearm." + sd, cuff + Vector((math.cos(a) * 0.05, math.sin(a) * 0.05, 0)),
                   d, 0.11, 0.06, thick=0.5, rings=6, seg=7)
        kn, an = Vector(J["kn" + sd]), Vector(J["an" + sd])
        for k in range(4):
            a = math.radians(90 * k + 45)
            d = Vector((math.cos(a), math.sin(a), -1.5))
            K.lock("LegFur%d.%s" % (k, sd), "FurShade" if k % 2 else "Fur", "DEF-shin." + sd,
                   kn + (an - kn) * 0.35 + Vector((math.cos(a) * 0.06, math.sin(a) * 0.06, 0)), d, 0.12, 0.06, thick=0.5, rings=6, seg=7)
    for k, x in enumerate((-0.12, -0.04, 0.04, 0.12)):
        K.lock("HipFur%d" % k, "Fur", "DEF-pelvis", (x, -0.12, 0.34), (x, -0.4, -1), 0.13, 0.07, thick=0.5, rings=6, seg=7)
    K.lock("IceShard", "Ice", "DEF-chest", (0.12, 0.12, 0.72), (0.4, 0.5, 1), 0.12, 0.05, thick=0.6, curl=0.0)


def pecas():
    J = BP.body("Body", P, role="Fur")
    BP.hands("", J, P, role="Skin", style="mitt3", size=1.5)
    BP.feet("", J, P, role="Skin", style="toes3", size=1.3)
    head(P["head_c"], P["head_r"])
    fur(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=12, arm_out=12)
    BP.run(arm, lean=18, stride=28, arm_swing=26)
    BP.attack(arm, "stomp")
    BP.die(arm)
