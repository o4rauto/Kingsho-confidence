"""CR_SandColossus — boss "Colosso de Areia": a muscular sandstone giant with a stern face, gold headband
with a turquoise gem, wide gold collar, gold arm cuffs, linen loincloth with a gold front panel, and a
segmented scorpion tail arching from its back over its head. Ref: portraits/sand_colossus.png. Biped. H 1.35.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_SandColossus"
ATAQUE_QUADRO = 7
PALETA = {"Stone": "D2A468", "StoneDark": "A87C44", "Gold": ("D8A030", 0.35, 0.6), "GoldDark": ("A8742A", 0.4, 0.55),
          "Gem": "3AC8C0", "Linen": "EADCB8", "Eye": "2A1A0A", "Mouth": "5A3A1E", "Sting": "5A3A1E"}

P = BP.params(hunch=0.05, head_c=(0, -0.09, 1.0), head_r=(0.11, 0.11, 0.12), neck0_z=0.9, neck1_z=0.94,
              chest_z=0.76, waist_z=0.6, pelvis_z=0.5, shoulder_z=0.86, shoulder_x=0.24, elbow_out=0.08, elbow_z=0.64,
              wrist_x=0.34, wrist_z=0.44, wrist_y=-0.08, hand_bottom=0.3, hand_size=0.14,
              hip_x=0.12, hip_z=0.47, knee_x=0.15, knee_y=-0.04, knee_z=0.25, ankle_x=0.17, ankle_z=0.09, foot_len=0.24,
              r_pelvis=(0.17, 0.12), r_waist=(0.15, 0.11), r_chest=(0.25, 0.17), r_neck0=(0.1, 0.09), r_neck1=(0.09, 0.08),
              r_shoulder=0.1, r_elbow=0.08, r_wrist=0.075, r_hip=0.095, r_knee=0.08, r_ankle=0.075)

TAIL = [Vector(p) for p in ((-0.04, 0.12, 0.55), (-0.1, 0.3, 0.66), (-0.2, 0.38, 0.86), (-0.3, 0.34, 1.06), (-0.34, 0.2, 1.2),
                          (-0.3, 0.04, 1.26))]


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Stone", "DEF-head", c, hr, u=16, v=10)
    K.sphere("Jaw", "Stone", "DEF-head", c + Vector((0, -0.04, -0.07)), (0.09, 0.08, 0.06), u=12, v=8)
    K.box("Brow", "StoneDark", "DEF-head", (0, c.y - 0.1, c.z + 0.03), (0.15, 0.03, 0.03), bevel=0.01)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", (s * 0.04, c.y - 0.105, c.z + 0.005), (0.016, 0.008, 0.012), u=6, v=4)
    K.sphere("Nose", "StoneDark", "DEF-head", (0, c.y - 0.115, c.z - 0.025), (0.022, 0.02, 0.025), u=8, v=5)
    K.box("Mouth", "Mouth", "DEF-head", (0, c.y - 0.115, c.z - 0.075), (0.05, 0.01, 0.01))
    K.band("Headband", "Gold", "DEF-head", c + Vector((0, 0, 0.06)), hr[0] + 0.005, hr[1] + 0.005, 0.04, z_tilt=math.radians(-8))
    K.sphere("HeadGem", "Gem", "DEF-head", (0, c.y - 0.115, c.z + 0.06), (0.022, 0.012, 0.026), u=8, v=6)


def gear(J):
    K.skirt("Collar", "Gold", "DEF-chest", 0.93, 0.82, 0.12, 0.25, thickness=0.02, center=(0, -0.01, 0))
    K.skirt("CollarTrim", "GoldDark", "DEF-chest", 0.86, 0.835, 0.21, 0.245, thickness=0.022, center=(0, -0.01, 0))
    for i, (x, z) in enumerate(((0.09, 0.72), (-0.09, 0.72), (0.0, 0.62))):
        K.sphere("Muscle%d" % i, "StoneDark", "DEF-chest" if z > 0.7 else "DEF-spine", (x, -0.15 if z > 0.7 else -0.13, z),
                 (0.1 if z > 0.7 else 0.09, 0.05, 0.07), u=12, v=8)
    K.skirt("Loin", "Linen", "AUTO", 0.5, 0.32, 0.17, 0.2, side_lift=0.05, thickness=0.014)
    K.band("Belt", "Gold", "DEF-pelvis", (0, 0, 0.5), 0.175, 0.13, 0.05)
    K.plate("Panel", "Gold", "DEF-pelvis", (0, -0.15, 0.4), [(-0.06, 0.08), (0.06, 0.08), (0.05, -0.12), (0.0, -0.17), (-0.05, -0.12)],
            thickness=0.016, rotation=(math.radians(8), 0, 0))
    K.sphere("PanelGem", "Gem", "DEF-pelvis", (0, -0.165, 0.43), (0.02, 0.01, 0.026), u=8, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        el, wr = Vector(J["el" + sd]), Vector(J["wr" + sd])
        K.along("Cuff." + sd, "Gold", "DEF-forearm." + sd, el + (wr - el) * 0.35, el + (wr - el) * 0.85, 0.09, 0.088, segments=14)
        K.band("CuffTrim." + sd, "GoldDark", "DEF-forearm." + sd, el + (wr - el) * 0.6, 0.094, 0.094, 0.02)
        K.band("ArmBand." + sd, "Gold", "DEF-upper_arm." + sd, Vector(J["sh" + sd]) + (el - Vector(J["sh" + sd])) * 0.5, 0.09, 0.09, 0.03)
        K.band("Anklet." + sd, "Gold", "DEF-shin." + sd, Vector(J["an" + sd]) + Vector((0, 0, 0.05)), 0.08, 0.08, 0.035)
    for i, (a, b) in enumerate(zip(TAIL, TAIL[1:])):
        bone = "DEF-spine" if i == 0 else "DEF-chest"
        K.sphere("TailSeg%d" % i, "Stone" if i % 2 else "StoneDark", bone, b, (0.09 - 0.009 * i,) * 3, u=12, v=8)
        K.along("TailLink%d" % i, "StoneDark", bone, a, b, 0.075 - 0.009 * i, segments=10)
    tip = TAIL[-1] + Vector((0.02, -0.1, -0.12))
    K.along("Sting", "Sting", "DEF-chest", TAIL[-1], tip, 0.05, 0.004, segments=8)


def pecas():
    J = BP.body("Body", P, role="Stone")
    BP.hands("", J, P, role="Stone", style="fist", size=1.8)
    BP.feet("", J, P, role="Stone", style="toes3", size=1.4)
    head(P["head_c"], P["head_r"])
    gear(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=6, arm_out=10)
    BP.run(arm, lean=10, stride=22, arm_swing=16)
    BP.attack(arm, "punch")
    BP.die(arm)
