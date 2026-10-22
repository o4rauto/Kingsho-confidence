"""CR_DrownedKing — boss "O Rei Afogado": undead sea king, gold crown, long grey hair and beard, teal
skin, dark tattered cape with a fur collar, rusty armour scraps, trident. Ref: portraits/drowned_king.png. H 1.3.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_DrownedKing"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "6FA89A", "SkinDark": "4E7E72", "Hair": "A8A8A0", "Cape": "2A3E52", "Fur": "B8B0A0",
          "Gold": ("D8A030", 0.4, 0.45), "Rust": ("6A5A4A", 0.7, 0.3), "Steel": ("8AA0A8", 0.45, 0.45),
          "Cloth": "5A4A36", "Eye": "F2E8A0", "Mouth": "2A1A1E"}
BRILHO = ("Eye",)

P = BP.hero(hunch=0.05, head_c=(0, -0.08, 0.86), head_r=(0.13, 0.13, 0.15), neck0_z=0.66, neck1_z=0.71,
            chest_z=0.57, waist_z=0.47, pelvis_z=0.39, shoulder_z=0.63, shoulder_x=0.13, elbow_z=0.49,
            wrist_x=0.22, wrist_z=0.37, hand_bottom=0.28, hand_size=0.11, hip_z=0.37, knee_z=0.2, ankle_z=0.09,
            r_chest=(0.12, 0.085), r_waist=(0.095, 0.07), r_pelvis=(0.105, 0.075), r_shoulder=0.042, r_elbow=0.032,
            r_wrist=0.034, r_hip=0.052, r_knee=0.042, r_ankle=0.036, foot_len=0.17)


def pecas():
    J = BP.body("Body", P, role="Cloth")
    BP.hands("", J, P, role="Skin", style="mitt3", size=0.9)
    BP.feet("", J, P, role="Skin", style="toes3", size=0.95)
    c = Vector(P["head_c"])
    K.sphere("Head", "Skin", "DEF-head", c, P["head_r"], u=18, v=12)
    for s in (1, -1):
        K.sphere("Socket%d" % (s > 0), "SkinDark", "DEF-head", (s * 0.05, c.y - 0.115, 0.88), (0.035, 0.02, 0.03), u=10, v=6)
        K.sphere("Eye%d" % (s > 0), "Eye", "DEF-head", (s * 0.05, c.y - 0.128, 0.88), (0.02, 0.01, 0.016), u=8, v=5)
        K.lock("HairSide%d" % (s > 0), "Hair", "DEF-head", c + Vector((s * 0.11, 0.02, 0.0)), (s * 0.2, 0.2, -1), 0.24, 0.06, thick=0.4)
    K.lock("Beard", "Hair", "DEF-head", c + Vector((0, -0.08, -0.1)), (0, -0.2, -1), 0.22, 0.09, thick=0.4)
    K.sphere("Mouth", "Mouth", "DEF-head", (0, c.y - 0.13, 0.8), (0.04, 0.01, 0.015), u=8, v=4)
    for i in range(5):   # crown
        a = math.radians(-60 + 30 * i)
        root = c + Vector((math.sin(a) * 0.1, -math.cos(a) * 0.098, 0.11))
        K.along("CrownSpike%d" % i, "Gold", "DEF-head", root, root + Vector((0, 0, 0.08 - 0.015 * abs(i - 2))), 0.025, 0.006, segments=6)
    K.band("Crown", "Gold", "DEF-head", c + Vector((0, 0, 0.1)), 0.104, 0.1, 0.045)
    K.skirt("Cape", "Cape", "DEF-chest", 0.66, 0.08, 0.13, 0.22, arc=(10, 170), ragged=0.04, thickness=0.012)
    K.sphere("FurCollar", "Fur", "DEF-chest", (0, 0.01, 0.65), (0.15, 0.11, 0.05), u=14, v=8)
    K.sphere("Breastplate", "Rust", "DEF-chest", (0, -0.03, 0.57), (0.12, 0.085, 0.08), u=14, v=8)
    K.skirt("Rags", "Cloth", "AUTO", 0.44, 0.2, 0.105, 0.14, ragged=0.04, side_lift=0.04)
    K.band("Belt", "Rust", "DEF-pelvis", (0, 0, 0.43), 0.11, 0.08, 0.035)
    hx, hy, hz = J["wrR"]
    base, top = Vector((hx - 0.01, hy - 0.05, 0.03)), Vector((hx - 0.01, hy - 0.05, 1.0))
    K.along("TridentShaft", "Rust", "DEF-hand.R", base, top, 0.013, segments=8)
    K.along("TridentBar", "Steel", "DEF-hand.R", top + Vector((-0.06, 0, 0)), top + Vector((0.06, 0, 0)), 0.012, segments=6)
    for x in (-0.06, 0.0, 0.06):
        K.along("Prong%d" % int(x * 100), "Steel", "DEF-hand.R", top + Vector((x, 0, 0)), top + Vector((x, 0, 0.14 if x == 0 else 0.11)), 0.014, 0.002, segments=4)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=8, arm_out=6)
    BP.run(arm, lean=14, stride=26, arm_swing=18, hold_right=True)
    BP.attack(arm, "spear")
    BP.die(arm)
