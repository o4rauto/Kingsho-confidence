"""CH_Runestone — "Pedra Rúnica": a golem of separate floating blue-grey stones with glowing blue runes,
glowing eyes, floating shards around. Ref: portraits/runestone.png. Biped skeleton, every stone rigid to
its bone (gaps between stones are part of the design). H 1.3.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Runestone"
ATAQUE_QUADRO = 11
PALETA = {"Stone": ("7E8EA2", 0.9, 0.0), "StoneDark": ("5E6C80", 0.9, 0.0), "Rune": "5AC8FF", "Eye": "9AE8FF"}
BRILHO = ("Rune", "Eye")

P = BP.params(
    hunch=0.03, head_c=(0, -0.06, 0.98), head_r=(0.14, 0.13, 0.13),
    neck0_z=0.80, neck1_z=0.86, chest_z=0.68, waist_z=0.52, pelvis_z=0.42,
    shoulder_z=0.76, shoulder_x=0.22, elbow_out=0.06, elbow_z=0.56, wrist_x=0.32, wrist_z=0.40, wrist_y=-0.04,
    hand_bottom=0.24, hand_size=0.15, hip_x=0.1, hip_z=0.4, knee_x=0.13, knee_y=-0.03, knee_z=0.22,
    ankle_x=0.15, ankle_z=0.09, foot_len=0.2,
)


def rune(name, bone, at, axis_rot, w=0.07, h=0.02):
    K.box(name, "Rune", bone, at, (w, 0.01, h), rotation=axis_rot)


def stone(name, bone, center, size, rot=(0, 0, 0), role="Stone"):
    return K.box(name, role, bone, center, size, rotation=rot, bevel=min(size) * 0.22)


def pecas():
    J, _ = BP.joints(P)
    hc = Vector(P["head_c"])
    stone("Head", "DEF-head", hc, (0.24, 0.22, 0.2))
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", hc + Vector((s * 0.055, -0.115, 0.01)), (0.028, 0.012, 0.016), u=8, v=4)
    rune("RuneHead", "DEF-head", hc + Vector((0, -0.113, 0.07)), (0, 0, 0), 0.03, 0.04)
    stone("Chest", "DEF-chest", (0, -0.02, 0.68), (0.36, 0.24, 0.24), rot=(math.radians(-6), 0, 0))
    for i, (x, z, r) in enumerate(((-0.08, 0.7, 30), (0.06, 0.66, -40), (0.0, 0.62, 80))):
        rune("RuneChest%d" % i, "DEF-chest", (x, -0.142, z), (0, math.radians(r), 0), 0.06, 0.016)
    stone("Belly", "DEF-spine", (0, -0.01, 0.52), (0.26, 0.2, 0.12), role="StoneDark")
    stone("Hips", "DEF-pelvis", (0, 0, 0.42), (0.3, 0.2, 0.1))
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = Vector(J["sh" + sd]), Vector(J["el" + sd]), Vector(J["wr" + sd])
        stone("Shoulder." + sd, "DEF-upper_arm." + sd, sh + Vector((s * 0.03, 0, 0.02)), (0.15, 0.15, 0.13), rot=(0, 0, math.radians(10) * s))
        stone("UpperArm." + sd, "DEF-upper_arm." + sd, (sh + el) / 2 + Vector((s * 0.02, 0, -0.02)), (0.1, 0.1, 0.11), role="StoneDark")
        stone("Forearm." + sd, "DEF-forearm." + sd, (el + wr) / 2, (0.12, 0.12, 0.14))
        rune("RuneArm." + sd, "DEF-forearm." + sd, (el + wr) / 2 + Vector((0, -0.062, 0)), (0, math.radians(60), 0), 0.05, 0.015)
        stone("Fist." + sd, "DEF-hand." + sd, wr + Vector((s * 0.01, -0.02, -0.1)), (0.15, 0.13, 0.14))
        hp, kn, an = Vector(J["hip" + sd]), Vector(J["kn" + sd]), Vector(J["an" + sd])
        stone("Thigh." + sd, "DEF-thigh." + sd, (hp + kn) / 2, (0.12, 0.12, 0.13), role="StoneDark")
        stone("Shin." + sd, "DEF-shin." + sd, (kn + an) / 2 + Vector((0, 0, 0.01)), (0.13, 0.13, 0.12))
        stone("Foot." + sd, "DEF-foot." + sd, an + Vector((0, -0.05, -0.04)), (0.13, 0.18, 0.09))
    # floating shards around the body
    for i, (p, sz, b) in enumerate((((0.38, 0.0, 1.0), 0.07, "DEF-chest"), ((-0.4, 0.02, 0.95), 0.08, "DEF-chest"),
                                    ((0.27, 0.05, 1.15), 0.05, "DEF-head"), ((-0.3, 0.1, 0.55), 0.06, "DEF-spine"),
                                    ((0.42, 0.05, 0.5), 0.05, "DEF-spine"), ((-0.15, 0.1, 1.2), 0.06, "DEF-head"))):
        stone("Shard%d" % i, b, p, (sz, sz * 0.8, sz * 1.2), rot=(0.4 * i, 0.3, 0.7 * i))
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=4, arm_out=10)
    BP.run(arm, lean=10, stride=26, arm_swing=22)
    BP.attack(arm, "throw")
    BP.cast(arm, "slam")
    BP.die(arm)
