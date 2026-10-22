"""CR_MagmaTyrant — boss "Tirano de Magma": a hulking golem of black basalt split by glowing lava cracks,
boulder shoulders and forearms, small head sunk between the shoulders with burning eyes and a jagged
molten maw, flames bursting from shoulders and crown, huge rock fists. Ref: portraits/magma_tyrant.png. H 1.35.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP
import rocha as RC

NOME = "CR_MagmaTyrant"
ATAQUE_QUADRO = 11
PALETA = {"Lava": "FF7A1A", "LavaLight": "FFC23A", "Rock": "3A2E30", "RockDark": "2A2224", "Fire": "FF6A1A",
          "FireLight": "FFD24A", "Eye": "FFE87A"}
BRILHO = ("Lava", "LavaLight", "Fire", "FireLight", "Eye")

P = BP.params(hunch=0.08, head_c=(0, -0.14, 1.0), head_r=(0.13, 0.12, 0.12), neck0_z=0.9, neck1_z=0.94,
              chest_z=0.76, waist_z=0.6, pelvis_z=0.5, shoulder_z=0.86, shoulder_x=0.25, elbow_out=0.08, elbow_z=0.64,
              wrist_x=0.36, wrist_z=0.44, wrist_y=-0.08, hand_bottom=0.28, hand_size=0.15,
              hip_x=0.13, hip_z=0.47, knee_x=0.16, knee_y=-0.04, knee_z=0.25, ankle_x=0.18, ankle_z=0.09, foot_len=0.24,
              r_pelvis=(0.18, 0.13), r_waist=(0.17, 0.13), r_chest=(0.25, 0.18), r_neck0=(0.11, 0.1), r_neck1=(0.1, 0.09),
              r_shoulder=0.1, r_elbow=0.085, r_wrist=0.08, r_hip=0.1, r_knee=0.085, r_ankle=0.08)


def pecas():
    J = BP.body("Body", P, role="Rock")
    chest = ((0, -0.02, 0.78), (0.27, 0.2, 0.18))
    K.sphere("Chest", "Rock", "DEF-chest", *chest, u=20, v=12)
    RC.cracks("ChestCrack", "DEF-chest", *chest, 30, 0.07, seed=3, min_z=-0.5)
    K.box("ChestSeam", "LavaLight", "DEF-chest", (0, -0.215, 0.78), (0.014, 0.012, 0.2))
    belly = ((0, -0.04, 0.6), (0.18, 0.14, 0.11))
    K.sphere("Belly", "RockDark", "DEF-spine", *belly, u=16, v=10)
    RC.cracks("BellyCrack", "DEF-spine", *belly, 10, 0.05, seed=4, min_z=-0.5)
    RC.limb_cracks("HipCrack", "DEF-pelvis", (0, 0, 0.42), (0, 0, 0.56), 0.17, 6, 0.05, seed=5)
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = Vector(J["sh" + sd]), Vector(J["el" + sd]), Vector(J["wr" + sd])
        boulder = (sh + Vector((s * 0.04, 0, 0.04)), (0.15, 0.14, 0.13))
        K.sphere("Shoulder." + sd, "RockDark", "DEF-upper_arm." + sd, *boulder, u=14, v=10)
        RC.cracks("ShoulderCrack." + sd, "DEF-upper_arm." + sd, *boulder, 10, 0.06, seed=10 + s, min_z=-0.3)
        K.along("Forearm." + sd, "Rock", "DEF-forearm." + sd, el, wr, 0.1, 0.12, segments=14)
        RC.limb_cracks("ForearmCrack." + sd, "DEF-forearm." + sd, el, wr, 0.11, 7, 0.06, seed=14 + s)
        RC.limb_cracks("UpperArmCrack." + sd, "DEF-upper_arm." + sd, sh, el, 0.09, 4, 0.05, seed=12 + s)
        fist = (Vector((wr.x + s * 0.01, wr.y - 0.02, P["hand_bottom"] + 0.07)), (0.12, 0.12, 0.12))
        K.sphere("Fist." + sd, "Rock", "DEF-hand." + sd, *fist, u=14, v=10)
        RC.cracks("FistCrack." + sd, "DEF-hand." + sd, *fist, 8, 0.05, seed=16 + s, min_z=-1)
        hp, kn, an = J["hip" + sd], J["kn" + sd], J["an" + sd]
        RC.limb_cracks("ThighCrack." + sd, "DEF-thigh." + sd, hp, kn, 0.1, 5, 0.05, seed=18 + s)
        K.along("Shin." + sd, "Rock", "DEF-shin." + sd, an, kn, 0.1, 0.09, segments=12)
        RC.limb_cracks("ShinCrack." + sd, "DEF-shin." + sd, an, kn, 0.1, 5, 0.05, seed=20 + s)
        K.sphere("Foot." + sd, "RockDark", "DEF-foot." + sd, Vector(an) + Vector((s * 0.01, -0.07, -0.04)), (0.11, 0.15, 0.065), u=12, v=8)
        for k, d in enumerate(((s * 0.3, 0.2, 1), (s * 0.8, 0.1, 0.7), (s * 0.1, 0.6, 0.8))):
            K.lock("ShoulderFire%d.%s" % (k, sd), "FireLight" if k == 0 else "Fire", "DEF-upper_arm." + sd,
                   sh + Vector((s * 0.06, 0.02, 0.12)), d, 0.26 - 0.04 * k, 0.1, thick=0.5, rings=7, seg=8)
    c = Vector(P["head_c"])
    K.sphere("Head", "Rock", "DEF-head", c, P["head_r"], u=16, v=10)
    RC.cracks("HeadCrack", "DEF-head", c, P["head_r"], 6, 0.04, seed=30, min_z=0.2, skip=lambda u: u.y < -0.4)
    K.box("Brow", "RockDark", "DEF-head", c + Vector((0, -0.11, 0.04)), (0.18, 0.05, 0.04), rotation=(math.radians(10), 0, 0))
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", c + Vector((s * 0.05, -0.12, 0.0)), (0.03, 0.012, 0.018), u=8, v=4,
                 rotation=(0, math.radians(-18) * s, 0))
        K.along("Horn" + sd, "RockDark", "DEF-head", c + Vector((s * 0.09, 0.0, 0.06)), c + Vector((s * 0.15, 0.03, 0.15)),
                0.035, 0.006, segments=6)
    K.sphere("Maw", "LavaLight", "DEF-head", c + Vector((0, -0.11, -0.07)), (0.07, 0.03, 0.03), u=10, v=6)
    for i, x in enumerate((-0.045, -0.015, 0.015, 0.045)):
        K.along("Fang%d" % i, "RockDark", "DEF-head", c + Vector((x, -0.135, -0.05)), c + Vector((x, -0.14, -0.08)), 0.012, 0.002, segments=4)
    for k, d in enumerate(((0, 0.2, 1), (-0.6, 0.3, 0.7), (0.6, 0.3, 0.7), (0, 0.8, 0.5))):
        K.lock("CrownFire%d" % k, "FireLight" if k == 0 else "Fire", "DEF-head", c + Vector((d[0] * 0.08, 0.04, 0.1)), d,
               0.24 if k == 0 else 0.18, 0.09, thick=0.5, rings=7, seg=8)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=8, arm_out=12)
    BP.run(arm, lean=10, stride=22, arm_swing=16)
    BP.attack(arm, "slam")
    BP.die(arm)
