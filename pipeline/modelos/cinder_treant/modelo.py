"""CR_CinderTreant — boss "Ent de Cinzas": tall charred tree giant with glowing lava cracks, a blazing
crown of leaves, grinning glowing face, long branch arms with twig claws, root feet.
Ref: portraits/cinder_treant.png. Biped, tall. H 1.4.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_CinderTreant"
ATAQUE_QUADRO = 11
PALETA = {"Bark": "4A2E1C", "BarkDark": "2E1C12", "Lava": "FF8A1A", "LavaLight": "FFD24A", "Fire": "FF6A1A",
          "Leaf": "E8782A"}
BRILHO = ("Lava", "LavaLight", "Fire")

P = BP.params(hunch=0.05, head_c=(0, -0.08, 1.06), head_r=(0.13, 0.12, 0.14),
              neck0_z=0.9, neck1_z=0.96, chest_z=0.78, waist_z=0.6, pelvis_z=0.48,
              shoulder_z=0.86, shoulder_x=0.16, elbow_out=0.1, elbow_z=0.64, wrist_x=0.32, wrist_z=0.44, wrist_y=-0.06,
              hand_bottom=0.3, hand_size=0.12, hip_x=0.09, hip_z=0.46, knee_x=0.13, knee_y=-0.05, knee_z=0.25,
              ankle_x=0.16, ankle_z=0.08, foot_len=0.2,
              r_pelvis=(0.15, 0.12), r_waist=(0.14, 0.11), r_chest=(0.21, 0.15), r_neck0=(0.1, 0.09), r_neck1=(0.09, 0.08),
              r_shoulder=0.08, r_elbow=0.062, r_wrist=0.055, r_hip=0.085, r_knee=0.07, r_ankle=0.062)


def pecas():
    J = BP.body("Body", P, role="Bark")
    c = Vector(P["head_c"])
    K.sphere("Head", "Bark", "DEF-head", c, P["head_r"], u=14, v=10)
    for s in (1, -1):
        K.sphere("Eye%d" % (s > 0), "LavaLight", "DEF-head", c + Vector((s * 0.05, -0.11, 0.02)), (0.03, 0.01, 0.018), u=8, v=4,
                 rotation=(0, math.radians(-20) * s, 0))
    K.sphere("Grin", "Lava", "DEF-head", c + Vector((0, -0.11, -0.06)), (0.07, 0.012, 0.025), u=10, v=5)
    # lava cracks on the chest, arms and legs
    for i, (p, r, rot) in enumerate((((0.04, -0.12, 0.8), (0.012, 0.006, 0.08), 20), ((-0.05, -0.12, 0.72), (0.01, 0.006, 0.07), -30),
                                     ((0.0, -0.1, 0.6), (0.01, 0.006, 0.06), 10))):
        K.sphere("Crack%d" % i, "Lava", "DEF-chest" if i < 2 else "DEF-spine", p, r, u=6, v=4, rotation=(0, math.radians(rot), 0))
    for s, sd in ((1, "L"), (-1, "R")):
        el, wr = Vector(J["el" + sd]), Vector(J["wr" + sd])
        K.sphere("ArmCrack." + sd, "Lava", "DEF-forearm." + sd, (el + wr) / 2 + Vector((0, -0.04, 0)), (0.008, 0.005, 0.05), u=6, v=4)
        for k, d in enumerate(((s * 0.3, -0.5, -0.8), (s * 0.7, -0.3, -0.6), (s * 0.1, -0.7, -0.6))):
            K.along("Claw%d.%s" % (k, sd), "BarkDark", "DEF-hand." + sd, wr, wr + Vector(d) * 0.14, 0.018, 0.003, segments=6)
        an = Vector(J["an" + sd])
        for k, d in enumerate(((s * 0.3, -1, -0.15), (s * 1, -0.3, -0.15), (0, 0.7, -0.15))):
            K.along("Root%d.%s" % (k, sd), "BarkDark", "DEF-foot." + sd, an, an + Vector(d) * 0.13, 0.04, 0.008, segments=6)
        for k in range(2):   # branch horns
            K.along("Branch%d.%s" % (k, sd), "Bark", "DEF-head", c + Vector((s * 0.08, 0.02, 0.08)),
                    c + Vector((s * (0.2 + 0.08 * k), 0.04, 0.22 + 0.06 * k)), 0.022, 0.006, segments=6)
    flames = [((0, 0.1, 1), 0.34, 0.12), ((-0.6, 0.2, 0.8), 0.3, 0.11), ((0.6, 0.2, 0.8), 0.3, 0.11), ((-0.9, 0.2, 0.3), 0.24, 0.09),
              ((0.9, 0.2, 0.3), 0.24, 0.09), ((0, 0.8, 0.6), 0.26, 0.1), ((-0.35, -0.3, 0.9), 0.2, 0.08), ((0.35, -0.3, 0.9), 0.2, 0.08)]
    for i, (d, ln, w) in enumerate(flames):
        d = Vector(d).normalized()
        K.lock("Blaze%d" % i, "LavaLight" if i % 3 == 0 else "Fire", "DEF-head", c + Vector((d.x * 0.1, 0.02, 0.1 + d.z * 0.05)), d, ln, w,
               thick=0.5, curl=0.05)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=8, arm_out=14)
    BP.run(arm, lean=12, stride=26, arm_swing=26)
    BP.attack(arm, "slam")
    BP.die(arm)
