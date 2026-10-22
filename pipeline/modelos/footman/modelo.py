"""CH_Footman — militia troop (portrait troop_militia): blue-steel helmet, blue tunic, sword and round
wooden shield. H = 1.20 m. Back of helmet and shield strap inferred.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Footman"
MODELO = "footman"
ATAQUE_QUADRO = 8
PALETA = {
    "Skin": "EDB48C", "Tunic": "3A6AB0", "Steel": ("8AA3C8", 0.45, 0.4), "SteelDark": ("5D7598", 0.5, 0.4),
    "Leather": "6B4426", "Wood": "8A5A30", "Eye": "F4F4F4", "Pupil": "2F6FB5", "Brow": "5A3A1E",
    "Mouth": "8A3A2A", "Mail": ("9AA0A8", 0.55, 0.5), "Gold": ("D8A030", 0.45, 0.4),
}

P = BP.params(
    hunch=0.0, head_c=(0, -0.03, 0.765), head_r=(0.15, 0.14, 0.16),
    neck0_z=0.55, neck1_z=0.60, chest_z=0.47, waist_z=0.39, pelvis_z=0.33,
    shoulder_z=0.525, shoulder_x=0.11, elbow_out=0.045, elbow_z=0.41,
    wrist_x=0.185, wrist_z=0.31, wrist_y=-0.03, hand_bottom=0.24, hand_size=0.10,
    hip_x=0.065, hip_z=0.31, knee_x=0.075, knee_y=-0.02, knee_z=0.17, ankle_x=0.09, ankle_z=0.085,
    foot_len=0.15,
    r_pelvis=(0.1, 0.07), r_waist=(0.09, 0.065), r_chest=(0.115, 0.08), r_neck0=(0.045, 0.04),
    r_neck1=(0.04, 0.036), r_shoulder=0.042, r_elbow=0.032, r_wrist=0.033, r_hip=0.052, r_knee=0.042, r_ankle=0.036,
)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, 0.735, 0.06, size=(0.04, 0.018, 0.04), slant=-10, pupils=0.024)
    for s, sd in ((1, ".L"), (-1, ".R")):
        x = s * 0.06
        K.box("Brow" + sd, "Brow", "DEF-head", (x, K.ellipsoid_front_y(hc, hr, x, 0.78, 0.004), 0.78),
              (0.05, 0.014, 0.013), rotation=(0, math.radians(-18) * s, math.radians(16) * s))
    K.sphere("Nose", "Skin", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.70, 0.006), 0.70), (0.016, 0.012, 0.016), u=8, v=5)
    K.box("Mouth", "Mouth", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.655, 0.004), 0.655), (0.04, 0.008, 0.008))
    # helmet: dome, thick brim, nose guard, crest ridge (portrait: covers the ears, brim at the brows)
    base = c + Vector((0, 0.005, 0.03))
    K.dome("Helmet", "Steel", "DEF-head", base, (0.172, 0.165, 0.175))
    K.band("HelmetBrim", "SteelDark", "DEF-head", base + Vector((0, 0, 0.005)), 0.178, 0.17, 0.045, thickness=0.014)
    K.arc_strip("HelmetCrest", "SteelDark", "DEF-head", base, 0.18, 0.172, 0.182, 0.035)
    K.box("NoseGuard", "SteelDark", "DEF-head", (0, base.y - 0.178, base.z - 0.05), (0.028, 0.016, 0.11), bevel=0.006)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.box("CheekGuard" + sd, "Steel", "DEF-head", (s * 0.15, base.y - 0.04, base.z - 0.07), (0.03, 0.12, 0.13),
              rotation=(0, math.radians(-8) * s, math.radians(20) * s), bevel=0.01)


def gear(J):
    K.sphere("Chest", "Tunic", "DEF-chest", (0, -0.025, 0.465), (0.118, 0.085, 0.085), u=14, v=8)
    K.skirt("MailSkirt", "Mail", "AUTO", 0.37, 0.21, 0.098, 0.12, side_lift=0.04, thickness=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.37), 0.103, 0.078, 0.035)
    K.box("Buckle", "Gold", "DEF-pelvis", (0, -0.088, 0.37), (0.04, 0.012, 0.03), bevel=0.006)
    for s, sd in ((1, "L"), (-1, "R")):
        K.dome("Pauldron." + sd, "Steel", "DEF-upper_arm." + sd, Vector(J["sh" + sd]) + Vector((s * 0.012, 0, 0)), (0.06, 0.06, 0.05))
        K.along("Glove." + sd, "Leather", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.037, 0.035, 0.0, 0.4, segments=10)


def sword(J):
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.005, hy - 0.02, 0.285))
    tip = h + Vector((-0.05, -0.1, -0.28))
    d = (tip - h).normalized()
    K.along("Blade", "Steel", "DEF-hand.R", h + d * 0.04, tip, 0.024, 0.004, segments=4)
    side = d.cross(Vector((0, 0, 1))).normalized()
    K.along("Guard", "Gold", "DEF-hand.R", h + d * 0.035 - side * 0.05, h + d * 0.035 + side * 0.05, 0.012, segments=6)
    K.sphere("Pommel", "Gold", "DEF-hand.R", h - d * 0.05, (0.016, 0.016, 0.016), u=8, v=5)


def shield(J):
    hx, hy, hz = J["wrL"]
    c = Vector((hx + 0.035, hy - 0.06, 0.34))
    rot = (0, 0, math.radians(30))
    K.cone("Shield", "Wood", "DEF-forearm.L", c, 0.13, 0.13, 0.024, axis="Y", segments=20, rotation=rot)
    K.cone("ShieldRim", "SteelDark", "DEF-forearm.L", c + Vector((0, 0.002, 0)), 0.138, 0.138, 0.018, axis="Y", segments=20, rotation=rot)
    K.sphere("ShieldBoss", "Steel", "DEF-forearm.L", c + Vector((math.sin(math.radians(30)) * -0.0, -0.02, 0)) + Vector((-0.008, -0.004, 0)),
             (0.04, 0.03, 0.04), u=10, v=6, rotation=rot)


def pecas():
    J = BP.body("Body", P, role="Tunic")
    BP.hands("", J, P, role="Leather", style="fist", size=0.85)
    BP.feet("", J, P, role="Leather", style="boot", size=0.9)
    head(P["head_c"], P["head_r"])
    gear(J)
    sword(J)
    shield(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=5)
    BP.run(arm, lean=14, stride=38, arm_swing=26)
    BP.attack(arm, "sword")
    BP.die(arm)
