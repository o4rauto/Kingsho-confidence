"""CR_RiftSovereign — boss "Soberano da Fenda": a tall robed void lord, black face with glowing slit eyes
inside a hood that bursts into purple flame, spiked collar and shoulders, bell sleeves, a glowing trim
down the robe, an orb of void fire in each open hand. Ref: portraits/rift_sovereign.png. Biped. H 1.4.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_RiftSovereign"
ATAQUE_QUADRO = 13
PALETA = {"Robe": "3A1A5A", "RobeDark": "24103A", "Trim": "C04AF0", "Flame": "A040F0", "FlameLight": "E080FF",
          "Face": "0E0614", "Eye": "FF8AF0", "Skin": "8A6AB0", "Orb": "7A2AD0", "OrbFlame": "C050FF"}
BRILHO = ("Trim", "Flame", "FlameLight", "Eye", "Orb", "OrbFlame")

P = BP.params(hunch=0.03, head_c=(0, -0.05, 1.08), head_r=(0.12, 0.12, 0.14), neck0_z=0.92, neck1_z=0.97,
              chest_z=0.8, waist_z=0.66, pelvis_z=0.56, shoulder_z=0.88, shoulder_x=0.17, elbow_out=0.1, elbow_z=0.72,
              wrist_x=0.34, wrist_z=0.62, wrist_y=-0.12, hand_bottom=0.55, hand_size=0.1,
              hip_x=0.08, hip_z=0.52, knee_x=0.1, knee_y=-0.03, knee_z=0.28, ankle_x=0.12, ankle_z=0.08, foot_len=0.17,
              r_pelvis=(0.14, 0.1), r_waist=(0.12, 0.09), r_chest=(0.17, 0.12), r_neck0=(0.06, 0.055), r_neck1=(0.055, 0.05),
              r_shoulder=0.055, r_elbow=0.042, r_wrist=0.036, r_hip=0.07, r_knee=0.055, r_ankle=0.045)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Face", "Face", "DEF-head", c, hr, u=16, v=10)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", c + Vector((s * 0.045, -0.11, 0.0)), (0.035, 0.01, 0.014), u=8, v=4,
                 rotation=(0, math.radians(-22) * s, 0))
    K.dome("Hood", "Robe", "DEF-head", c + Vector((0, 0.015, -0.03)), (0.16, 0.16, 0.19), cut=-0.5, u=22, v=12,
           face_open=(0.3, 0.6))
    K.along("HoodPeak", "Robe", "DEF-head", c + Vector((0, -0.06, 0.13)), c + Vector((0, -0.14, 0.1)), 0.05, 0.01, segments=8)
    flames = [((0, 0.2, 1), 0.36, 0.13), ((-0.6, 0.3, 0.75), 0.3, 0.11), ((0.6, 0.3, 0.75), 0.3, 0.11),
              ((-0.95, 0.2, 0.3), 0.24, 0.09), ((0.95, 0.2, 0.3), 0.24, 0.09), ((0, 0.85, 0.5), 0.3, 0.11),
              ((-0.4, 0.7, 0.6), 0.24, 0.09), ((0.4, 0.7, 0.6), 0.24, 0.09)]
    for i, (d, ln, w) in enumerate(flames):
        d = Vector(d).normalized()
        K.lock("Blaze%d" % i, "FlameLight" if i % 3 == 0 else "Flame", "DEF-head", c + Vector((d.x * 0.1, 0.03 + d.y * 0.05, 0.08)),
               d, ln, w, thick=0.5, curl=0.05)


def robes(J):
    BP.robe("Robe", top_z=0.66, hem_z=0.02, top_r=0.13, hem_r=0.3, trim_role="Trim", ragged=0.04)
    K.box("FrontTrim", "Trim", "DEF-chest", (0, -0.12, 0.8), (0.03, 0.012, 0.2), bevel=0.006)
    K.band("Sash", "Trim", "DEF-pelvis", (0, 0, 0.66), 0.125, 0.095, 0.03)
    for k, (x, z, d) in enumerate(((0.0, 0.93, (0, 0.2, 1)), (0.09, 0.92, (0.5, 0.2, 1)), (-0.09, 0.92, (-0.5, 0.2, 1)),
                                    (0.15, 0.9, (0.9, 0.3, 0.6)), (-0.15, 0.9, (-0.9, 0.3, 0.6)))):
        K.lock("Collar%d" % k, "RobeDark", "DEF-chest", (x, 0.04, z), d, 0.16, 0.07, thick=0.4)
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = Vector(J["sh" + sd]), Vector(J["el" + sd]), Vector(J["wr" + sd])
        K.dome("Mantle." + sd, "RobeDark", "DEF-upper_arm." + sd, sh + Vector((s * 0.02, 0, 0.01)), (0.08, 0.08, 0.06))
        for k in range(2):
            K.along("ShoulderSpike%d.%s" % (k, sd), "RobeDark", "DEF-upper_arm." + sd, sh + Vector((s * 0.05, 0.02 * k, 0.04)),
                    sh + Vector((s * (0.14 + 0.03 * k), 0.03 * k, 0.16 - 0.05 * k)), 0.03, 0.003, segments=6)
        K.along("Sleeve." + sd, "Robe", "DEF-forearm." + sd, el, wr, 0.05, 0.09, 0.0, 0.95, segments=14)
        K.band("Cuff." + sd, "Trim", "DEF-forearm." + sd, el + (wr - el) * 0.93, 0.09, 0.09, 0.02)
        hc = wr + Vector((s * 0.03, -0.05, 0.1))
        K.sphere("Orb." + sd, "Orb", "DEF-hand." + sd, hc, (0.08, 0.08, 0.08), u=14, v=10)
        for k, dd in enumerate(((0, 0, 1), (0.6, 0, 0.8), (-0.6, 0, 0.8), (0, 0.6, 0.8), (0, -0.6, 0.8))):
            dd = Vector(dd).normalized()
            K.lock("OrbFire%d.%s" % (k, sd), "OrbFlame", "DEF-hand." + sd, hc + dd * 0.05, dd, 0.16 if k == 0 else 0.11,
                   0.06 if k == 0 else 0.045, thick=0.5)


def pecas():
    J = BP.body("Body", P, role="Robe")
    BP.hands("", J, P, role="Skin", style="mitt3", size=0.9)
    BP.feet("", J, P, role="RobeDark", style="shoe", size=1.0)
    head(P["head_c"], P["head_r"])
    robes(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=14)
    BP.run(arm, lean=10, stride=20, arm_swing=10)
    BP.attack(arm, "cast")
    BP.cast(arm, "summon")
    BP.die(arm)
