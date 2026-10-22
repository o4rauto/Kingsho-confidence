"""CH_Knight — "Cavaleiro Oco": hollow heavy knight in dark iron, tall bucket great-helm with a cross
visor, round pauldrons, spiked mace and kite shield with a boss. Ref: portraits/knight.png. Biped. H 1.25.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Knight"
ATAQUE_QUADRO = 8
PALETA = {"Steel": ("5C6274", 0.45, 0.5), "SteelLight": ("8890A4", 0.4, 0.5), "SteelDark": ("383C4A", 0.5, 0.5),
          "Visor": "0E0E14", "Mail": ("6A6E78", 0.55, 0.5), "Leather": "7A4A26", "Wood": "6B4426",
          "Buckle": ("B0B4BC", 0.35, 0.6)}

P = BP.hero(hunch=0.02, head_c=(0, -0.02, 0.72), head_r=(0.14, 0.13, 0.15),
            neck0_z=0.56, neck1_z=0.6, chest_z=0.47, waist_z=0.39, pelvis_z=0.33,
            shoulder_z=0.53, shoulder_x=0.13, elbow_out=0.05, elbow_z=0.41, wrist_x=0.21, wrist_z=0.31,
            hip_x=0.07, hip_z=0.31, knee_x=0.085, knee_z=0.17, ankle_x=0.1,
            r_chest=(0.135, 0.095), r_waist=(0.105, 0.075), r_pelvis=(0.11, 0.08), r_shoulder=0.05, r_elbow=0.038,
            r_wrist=0.036, r_hip=0.06, r_knee=0.05, r_ankle=0.044)


def helm(hc):
    c = Vector(hc)
    K.sphere("HeadVoid", "Visor", "DEF-head", c, (0.12, 0.11, 0.13), u=12, v=8)
    K.cone("GreatHelm", "Steel", "DEF-head", c + Vector((0, 0, 0.015)), 0.165, 0.158, 0.27, segments=20)
    K.dome("HelmTop", "Steel", "DEF-head", c + Vector((0, 0, 0.15)), (0.158, 0.158, 0.05), cut=0.0, u=20, v=6)
    K.arc_strip("HelmRidge", "SteelLight", "DEF-head", c + Vector((0, 0, 0.05)), 0.16, 0.16, 0.15, 0.04)
    fy = c.y - 0.162
    K.box("CrossV", "SteelLight", "DEF-head", (0, fy - 0.006, c.z - 0.02), (0.06, 0.02, 0.24), bevel=0.006)
    K.box("CrossH", "SteelLight", "DEF-head", (0, fy - 0.006, c.z + 0.035), (0.24, 0.02, 0.07), bevel=0.006)
    K.box("Slit", "Visor", "DEF-head", (0, fy - 0.022, c.z + 0.035), (0.2, 0.01, 0.024), bevel=0.003)
    K.box("SlitV", "Visor", "DEF-head", (0, fy - 0.022, c.z - 0.03), (0.022, 0.01, 0.1), bevel=0.003)
    for i in range(3):
        for j in range(2):
            K.sphere("Breath%d%d" % (i, j), "Visor", "DEF-head", (0.065 + 0.025 * j, fy + 0.008, c.z - 0.04 - 0.025 * i),
                     (0.008, 0.006, 0.008), u=6, v=4)
    K.band("HelmRim", "SteelDark", "DEF-head", c + Vector((0, 0, -0.115)), 0.168, 0.162, 0.03, thickness=0.012)


def armour(J):
    K.sphere("Breastplate", "Steel", "DEF-chest", (0, -0.035, 0.465), (0.14, 0.1, 0.1), u=16, v=10)
    K.sphere("Gorget", "SteelDark", "DEF-neck", (0, -0.02, 0.575), (0.1, 0.09, 0.04), u=14, v=6)
    K.box("Plackart", "SteelLight", "DEF-chest", (0, -0.125, 0.45), (0.1, 0.02, 0.07), bevel=0.012)
    K.skirt("MailSkirt", "Mail", "AUTO", 0.37, 0.2, 0.11, 0.13, side_lift=0.03, thickness=0.012)
    K.skirt("Faulds", "Steel", "AUTO", 0.38, 0.29, 0.112, 0.128, thickness=0.014)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.37), 0.118, 0.088, 0.035)
    K.box("Buckle", "Buckle", "DEF-pelvis", (0, -0.1, 0.37), (0.05, 0.014, 0.036), bevel=0.006)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Steel", "DEF-upper_arm." + sd, sh + Vector((s * 0.018, 0, 0)), (0.08, 0.08, 0.066))
        K.band("PauldronRim." + sd, "SteelDark", "DEF-upper_arm." + sd, sh + Vector((s * 0.018, 0, -0.002)), 0.082, 0.082, 0.016)
        K.sphere("Rivet." + sd, "SteelLight", "DEF-upper_arm." + sd, sh + Vector((s * 0.07, -0.02, 0.03)), (0.014, 0.014, 0.014), u=6, v=4)
        K.along("Vambrace." + sd, "Steel", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.042, 0.04, 0.0, 0.75, segments=10)
        K.sphere("Elbow." + sd, "SteelLight", "DEF-forearm." + sd, J["el" + sd], (0.04, 0.04, 0.04), u=10, v=6)
        K.along("Greave." + sd, "Steel", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.052, 0.054, 0.0, 0.85, segments=10)
        K.sphere("Knee." + sd, "SteelLight", "DEF-shin." + sd, Vector(J["kn" + sd]) + Vector((0, -0.035, 0)), (0.05, 0.038, 0.045), u=10, v=6)
        K.along("Cuisse." + sd, "Steel", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.062, 0.056, 0.25, 0.8, segments=10)


def mace(J):
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.005, hy - 0.025, 0.28))
    end = h + Vector((-0.06, -0.12, -0.24))
    d = (end - h).normalized()
    K.along("Haft", "Wood", "DEF-hand.R", h - d * 0.06, end, 0.016, segments=8)
    K.band("HaftRing", "SteelDark", "DEF-hand.R", end - d * 0.02, 0.022, 0.022, 0.02)
    ball = end + d * 0.06
    K.sphere("MaceBall", "SteelDark", "DEF-hand.R", ball, (0.065, 0.065, 0.065), u=14, v=10)
    dirs = [Vector((1, 0, 0)), Vector((-1, 0, 0)), Vector((0, 1, 0)), Vector((0, -1, 0)), Vector((0, 0, -1)),
            Vector((0.7, 0.7, 0.4)), Vector((-0.7, 0.7, 0.4)), Vector((0.7, -0.7, 0.4)), Vector((-0.7, -0.7, 0.4)),
            Vector((0.7, 0.7, -0.5)), Vector((-0.7, -0.7, -0.5))]
    for i, v in enumerate(dirs):
        v = v.normalized()
        K.along("MaceSpike%d" % i, "SteelLight", "DEF-hand.R", ball + v * 0.05, ball + v * 0.1, 0.02, 0.002, segments=5)


KITE = [(-0.125, 0.12), (-0.08, 0.15), (0.0, 0.16), (0.08, 0.15), (0.125, 0.12), (0.12, 0.0), (0.09, -0.1),
        (0.045, -0.17), (0.0, -0.21), (-0.045, -0.17), (-0.09, -0.1), (-0.12, 0.0)]


def shield(J):
    hx, hy, hz = J["wrL"]
    c = Vector((hx + 0.05, hy - 0.07, 0.4))
    rot = (0, 0, math.radians(26))
    K.plate("Shield", "Steel", "DEF-forearm.L", c, KITE, thickness=0.03, rotation=rot, bulge=0.03)
    K.plate("ShieldRim", "SteelDark", "DEF-forearm.L", c + Vector((0, 0.008, 0)), [(x * 1.1, z * 1.08) for x, z in KITE],
            thickness=0.026, rotation=rot)
    face = Vector((-math.sin(rot[2]), -math.cos(rot[2]), 0))
    K.sphere("ShieldBoss", "SteelLight", "DEF-forearm.L", c + face * 0.045 + Vector((0, 0, 0.01)), (0.042, 0.03, 0.042),
             u=12, v=8, rotation=rot)


def pecas():
    J = BP.body("Body", P, role="SteelDark")
    BP.hands("", J, P, role="SteelDark", style="fist", size=0.95)
    BP.feet("", J, P, role="Steel", style="boot", size=1.05)
    helm(P["head_c"])
    armour(J)
    mace(J)
    shield(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=6)
    BP.run(arm, lean=12, stride=32, arm_swing=22)
    BP.attack(arm, "sword")
    BP.die(arm)
