"""CR_Sapling — "Muda em Chamas": a stubby tree whose autumn crown is on fire, carved glowing face,
branch arms, root legs. Ref: portraits/sapling.png. Biped (roots as legs). H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_Sapling"
ATAQUE_QUADRO = 7
PALETA = {"Bark": "7A4A26", "BarkDark": "54301A", "Leaf": "E8782A", "LeafDark": "C8501E", "Flame": "FF9A2A",
          "FlameLight": "FFD24A", "Glow": "FFC23A"}
BRILHO = ("Flame", "FlameLight", "Glow")

P = BP.params(hunch=0.0, head_c=(0, -0.02, 0.72), head_r=(0.16, 0.14, 0.16), neck0_z=0.66, neck1_z=0.76,
              chest_z=0.5, waist_z=0.38, pelvis_z=0.28, shoulder_z=0.55, shoulder_x=0.13, elbow_out=0.08, elbow_z=0.46,
              wrist_x=0.27, wrist_z=0.38, wrist_y=-0.04, hand_bottom=0.3, hand_size=0.08, hip_x=0.08, hip_z=0.22,
              knee_x=0.12, knee_y=-0.02, knee_z=0.12, ankle_x=0.16, ankle_z=0.05, foot_len=0.16,
              r_pelvis=(0.17, 0.14), r_waist=(0.15, 0.13), r_chest=(0.15, 0.13), r_neck0=(0.14, 0.12), r_neck1=(0.13, 0.11),
              r_shoulder=0.04, r_elbow=0.03, r_wrist=0.025, r_hip=0.06, r_knee=0.05, r_ankle=0.045)


def pecas():
    J = BP.body("Trunk", P, role="Bark")
    K.lathe("TrunkBase", "BarkDark", "DEF-pelvis", (0, 0, 0.18), [(0.22, 0.0), (0.18, 0.05), (0.15, 0.14), (0.0, 0.14)])
    c = Vector(P["head_c"])
    for s in (1, -1):   # carved glowing eyes and grin on the trunk
        K.sphere("Eye%d" % (s > 0), "Glow", "DEF-head", (s * 0.06, -0.14, 0.62), (0.04, 0.012, 0.022), u=8, v=4,
                 rotation=(0, math.radians(-18) * s, 0))
    K.sphere("Mouth", "Glow", "DEF-head", (0, -0.15, 0.5), (0.07, 0.012, 0.03), u=10, v=5)
    K.sphere("BrowRidge", "BarkDark", "DEF-head", (0, -0.13, 0.66), (0.12, 0.03, 0.025), u=10, v=5)
    for i, (p, r, role) in enumerate((((0, 0.0, 0.86), (0.26, 0.21, 0.14), "Leaf"), ((-0.19, 0.02, 0.8), (0.15, 0.14, 0.11), "LeafDark"),
                                      ((0.19, 0.02, 0.8), (0.15, 0.14, 0.11), "LeafDark"), ((0, 0.1, 0.94), (0.17, 0.14, 0.1), "Leaf"))):
        K.sphere("Crown%d" % i, role, "DEF-head", p, r, u=10, v=7)
    for i, (d, ln, w) in enumerate((((0, 0.1, 1), 0.26, 0.09), ((-0.6, 0.2, 0.8), 0.22, 0.08), ((0.6, 0.2, 0.8), 0.22, 0.08),
                                    ((-0.3, 0.6, 0.8), 0.18, 0.07), ((0.3, 0.6, 0.8), 0.18, 0.07), ((0, -0.4, 0.9), 0.16, 0.06))):
        K.lock("Fire%d" % i, "FlameLight" if i % 2 else "Flame", "DEF-head", Vector((0, 0.02, 0.92)) + Vector(d) * 0.1, d, ln, w, thick=0.5)
    for s, sd in ((1, "L"), (-1, "R")):   # twig fingers
        wr = Vector(J["wr" + sd])
        for k, d in enumerate(((s * 0.6, -0.3, -0.3), (s * 0.7, -0.1, 0.1), (s * 0.4, -0.5, 0.0))):
            K.along("Twig%d.%s" % (k, sd), "BarkDark", "DEF-hand." + sd, wr, wr + Vector(d) * 0.1, 0.012, 0.003, segments=6)
        an = Vector(J["an" + sd])
        for k, d in enumerate(((s * 0.3, -1, -0.2), (s * 1, -0.3, -0.2), (0, 0.6, -0.2))):
            K.along("Root%d.%s" % (k, sd), "BarkDark", "DEF-foot." + sd, an, an + Vector(d) * 0.1, 0.03, 0.006, segments=6)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=14)
    BP.run(arm, lean=8, stride=24, arm_swing=26)
    BP.attack(arm, "swipe2")
    BP.die(arm)
