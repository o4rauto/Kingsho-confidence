"""CH_BoulderGolem — "Golem de Pedra": huge mossy rock golem, small head sunk between the shoulders,
glowing green eyes, giant rock fists. Ref: portraits/boulder_golem.png. Biped, rocks rigid to bones. H 1.3.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_BoulderGolem"
ATAQUE_QUADRO = 11
PALETA = {"Rock": ("8C8C80", 0.95, 0.0), "RockDark": ("6A6A60", 0.95, 0.0), "Moss": "6AA03A", "MossLight": "8CC24E",
          "Eye": "9AF06A"}
BRILHO = ("Eye",)

P = BP.params(
    hunch=0.08, head_c=(0, -0.12, 0.92), head_r=(0.13, 0.12, 0.11),
    neck0_z=0.82, neck1_z=0.86, chest_z=0.70, waist_z=0.54, pelvis_z=0.44,
    shoulder_z=0.78, shoulder_x=0.24, elbow_out=0.07, elbow_z=0.55, wrist_x=0.36, wrist_z=0.38, wrist_y=-0.06,
    hand_bottom=0.16, hand_size=0.2, hip_x=0.12, hip_z=0.42, knee_x=0.15, knee_y=-0.04, knee_z=0.22,
    ankle_x=0.17, ankle_z=0.09, foot_len=0.22,
)


def rock(name, bone, c, r, role="Rock", rot=(0, 0, 0)):
    return K.sphere(name, role, bone, c, r, u=8, v=6, rotation=rot)   # low segments = faceted rock


def pecas():
    J, _ = BP.joints(P)
    hc = Vector(P["head_c"])
    rock("Head", "DEF-head", hc, (0.13, 0.12, 0.11))
    rock("Brow", "DEF-head", hc + Vector((0, -0.08, 0.04)), (0.12, 0.05, 0.04), role="RockDark")
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", hc + Vector((s * 0.05, -0.11, 0.0)), (0.025, 0.01, 0.014), u=8, v=4)
    rock("Jaw", "DEF-head", hc + Vector((0, -0.06, -0.08)), (0.11, 0.08, 0.05), role="RockDark")
    rock("Chest", "DEF-chest", (0, -0.03, 0.7), (0.3, 0.2, 0.2))
    rock("Belly", "DEF-spine", (0, -0.02, 0.54), (0.22, 0.16, 0.12), role="RockDark")
    rock("Hips", "DEF-pelvis", (0, 0, 0.44), (0.2, 0.15, 0.1))
    for i, (p, r) in enumerate((((0.0, 0.0, 0.88), (0.2, 0.12, 0.05)), ((0.22, 0.0, 0.84), (0.1, 0.1, 0.04)),
                                ((-0.22, 0.0, 0.84), (0.1, 0.1, 0.04)), ((0.0, -0.05, 1.0), (0.09, 0.08, 0.03)))):
        K.sphere("Moss%d" % i, "Moss" if i % 2 else "MossLight", "DEF-chest" if i < 3 else "DEF-head", p, r, u=10, v=5)
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = Vector(J["sh" + sd]), Vector(J["el" + sd]), Vector(J["wr" + sd])
        rock("Shoulder." + sd, "DEF-upper_arm." + sd, sh + Vector((s * 0.04, 0, 0.03)), (0.16, 0.15, 0.14))
        rock("UpperArm." + sd, "DEF-upper_arm." + sd, (sh + el) / 2 + Vector((s * 0.02, 0, 0)), (0.1, 0.1, 0.12), role="RockDark")
        rock("Forearm." + sd, "DEF-forearm." + sd, (el + wr) / 2, (0.13, 0.13, 0.13))
        rock("Fist." + sd, "DEF-hand." + sd, wr + Vector((s * 0.01, -0.03, -0.12)), (0.16, 0.15, 0.15))
        for k in range(3):
            rock("Knuckle%d.%s" % (k, sd), "DEF-hand." + sd, wr + Vector((s * 0.01 + (k - 1) * 0.07, -0.15, -0.14)), (0.05, 0.045, 0.05), role="RockDark")
        hp, kn, an = Vector(J["hip" + sd]), Vector(J["kn" + sd]), Vector(J["an" + sd])
        rock("Thigh." + sd, "DEF-thigh." + sd, (hp + kn) / 2, (0.12, 0.12, 0.13), role="RockDark")
        rock("Shin." + sd, "DEF-shin." + sd, (kn + an) / 2, (0.12, 0.12, 0.11))
        rock("Foot." + sd, "DEF-foot." + sd, an + Vector((0, -0.05, -0.04)), (0.13, 0.17, 0.07))
        K.sphere("MossArm." + sd, "Moss", "DEF-upper_arm." + sd, sh + Vector((s * 0.05, 0, 0.14)), (0.1, 0.09, 0.035), u=10, v=5)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=6, arm_out=12)
    BP.run(arm, lean=10, stride=24, arm_swing=20)
    BP.attack(arm, "slam")
    BP.die(arm)
