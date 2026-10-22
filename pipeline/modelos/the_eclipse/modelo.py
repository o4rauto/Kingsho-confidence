"""CR_TheEclipse — boss "O Eclipse": a dark-crowned knight in near-black indigo plate, a tall spiked crown
set with purple gems over a closed helm whose visor burns with purple eyes, spiked pauldrons with gems,
a long dark-purple cape, belt with a gem buckle, and a long sword held low. Ref: portraits/the_eclipse.png.
Biped. H 1.4.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_TheEclipse"
ATAQUE_QUADRO = 10
PALETA = {"Plate": ("3A3450", 0.4, 0.55), "PlateLight": ("5A5278", 0.38, 0.55), "PlateDark": ("18141F", 0.45, 0.5),
          "Gem": "C84AF0", "Eye": "E070FF", "Cape": "3A1A50", "CapeIn": "5A2A78", "Leather": "4A3226",
          "Blade": ("A8A4C8", 0.3, 0.7), "Visor": "0A0810"}
BRILHO = ("Gem", "Eye")

P = BP.params(hunch=0.02, head_c=(0, -0.04, 1.0), head_r=(0.15, 0.145, 0.16), neck0_z=0.78, neck1_z=0.83,
              chest_z=0.66, waist_z=0.55, pelvis_z=0.47, shoulder_z=0.74, shoulder_x=0.16, elbow_out=0.07, elbow_z=0.58,
              wrist_x=0.27, wrist_z=0.45, wrist_y=-0.04, hand_bottom=0.36, hand_size=0.11,
              hip_x=0.085, hip_z=0.44, knee_x=0.1, knee_y=-0.03, knee_z=0.24, ankle_x=0.12, ankle_z=0.1, foot_len=0.19,
              r_pelvis=(0.13, 0.09), r_waist=(0.12, 0.085), r_chest=(0.16, 0.11), r_neck0=(0.06, 0.055), r_neck1=(0.055, 0.05),
              r_shoulder=0.058, r_elbow=0.045, r_wrist=0.042, r_hip=0.068, r_knee=0.058, r_ankle=0.05)


def helm(hc, hr):
    c = Vector(hc)
    K.sphere("Helm", "Plate", "DEF-head", c, (hr[0] + 0.01, hr[1] + 0.012, hr[2]), u=18, v=12)
    K.box("Visor", "Visor", "DEF-head", (0, c.y - hr[1] - 0.004, c.z - 0.01), (0.22, 0.03, 0.06), bevel=0.01)
    K.box("VisorRidge", "PlateLight", "DEF-head", (0, c.y - hr[1] - 0.012, c.z - 0.02), (0.025, 0.03, 0.16), bevel=0.008)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", (s * 0.055, c.y - hr[1] - 0.022, c.z - 0.005), (0.035, 0.01, 0.016), u=8, v=4,
                 rotation=(0, math.radians(-14) * s, 0))
    base = c + Vector((0, 0.0, hr[2] - 0.05))
    K.band("CrownBand", "PlateDark", "DEF-head", base, hr[0] + 0.012, hr[1] + 0.012, 0.06, thickness=0.016)
    for k in range(7):
        a = math.radians(-90 + 30 * k)
        root = base + Vector((math.sin(a) * (hr[0] + 0.01), -math.cos(a) * (hr[1] + 0.01), 0.02))
        h = 0.2 if k == 3 else (0.15 if k in (2, 4) else 0.11)
        K.along("Spike%d" % k, "PlateDark", "DEF-head", root, root + Vector((math.sin(a) * 0.02, -math.cos(a) * 0.02, h)),
                0.035, 0.004, segments=6)
        if k in (2, 3, 4):
            K.sphere("CrownGem%d" % k, "Gem", "DEF-head", root + Vector((math.sin(a) * 0.01, -math.cos(a) * 0.01 - 0.008, 0.04)),
                     (0.018, 0.01, 0.026), u=8, v=5)


def armour(J):
    K.sphere("Breastplate", "Plate", "DEF-chest", (0, -0.035, 0.66), (0.165, 0.115, 0.12), u=16, v=10)
    K.sphere("ChestGem", "Gem", "DEF-chest", (0, -0.15, 0.68), (0.025, 0.012, 0.03), u=8, v=6)
    K.skirt("Cape", "Cape", "DEF-chest", 0.74, 0.04, 0.14, 0.3, arc=(10, 170), ragged=0.05, thickness=0.014)
    K.skirt("Faulds", "Plate", "AUTO", 0.52, 0.34, 0.13, 0.155, side_lift=0.03, thickness=0.014)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.52), 0.132, 0.095, 0.035)
    K.sphere("BeltGem", "Gem", "DEF-pelvis", (0, -0.1, 0.52), (0.022, 0.012, 0.022), u=8, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Plate", "DEF-upper_arm." + sd, sh + Vector((s * 0.02, 0, 0.0)), (0.09, 0.088, 0.075))
        K.band("PauldronRim." + sd, "PlateLight", "DEF-upper_arm." + sd, sh + Vector((s * 0.02, 0, 0.0)), 0.091, 0.089, 0.015)
        for k in range(2):
            K.along("PSpike%d.%s" % (k, sd), "PlateDark", "DEF-upper_arm." + sd, sh + Vector((s * 0.05, 0.02 - 0.04 * k, 0.05)),
                    sh + Vector((s * 0.12, 0.03 - 0.05 * k, 0.17 - 0.03 * k)), 0.03, 0.003, segments=6)
        K.sphere("PGem." + sd, "Gem", "DEF-upper_arm." + sd, sh + Vector((s * 0.06, -0.07, 0.03)), (0.018, 0.012, 0.018), u=8, v=5)
        K.along("Vambrace." + sd, "Plate", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.048, 0.045, 0.0, 0.75, segments=10)
        K.along("Greave." + sd, "Plate", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.058, 0.062, 0.0, 0.85, segments=10)
        K.sphere("Knee." + sd, "PlateLight", "DEF-shin." + sd, Vector(J["kn" + sd]) + Vector((0, -0.04, 0)), (0.05, 0.04, 0.046), u=10, v=6)
        K.along("Cuisse." + sd, "Plate", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.07, 0.063, 0.25, 0.8, segments=10)


def sword(J):
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.005, hy - 0.03, P["hand_bottom"] + 0.05))
    tip = h + Vector((-0.12, -0.2, -0.36))
    d = (tip - h).normalized()
    K.along("Blade", "Blade", "DEF-hand.R", h + d * 0.05, tip, 0.03, 0.004, segments=4)
    side = d.cross(Vector((0, 0, 1))).normalized()
    K.along("Guard", "PlateDark", "DEF-hand.R", h + d * 0.045 - side * 0.07, h + d * 0.045 + side * 0.07, 0.016, segments=6)
    K.sphere("GuardGem", "Gem", "DEF-hand.R", h + d * 0.045, (0.02, 0.02, 0.02), u=8, v=5)
    K.sphere("Pommel", "PlateDark", "DEF-hand.R", h - d * 0.06, (0.02, 0.02, 0.02), u=8, v=5)


def pecas():
    J = BP.body("Body", P, role="PlateDark")
    BP.hands("", J, P, role="Plate", style="fist", size=1.0)
    BP.feet("", J, P, role="Plate", style="boot", size=1.1)
    helm(P["head_c"], P["head_r"])
    armour(J)
    sword(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=6)
    BP.run(arm, lean=12, stride=28, arm_swing=18)
    BP.attack(arm, "cleave")
    BP.cast(arm, "summon")
    BP.die(arm)
