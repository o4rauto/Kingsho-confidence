"""CH_Bowman — archer troop (portrait troop_bowmen): green hood and cloak, brown leather, quiver,
wooden longbow. H = 1.20 m. Back of cloak and quiver inferred.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Bowman"
MODELO = "bowman"
ATAQUE_QUADRO = 9
PALETA = {
    "Skin": "EDB48C", "Leather": "8A5A30", "LeatherDark": "5E3A1E", "Hood": "3E8A3A", "HoodDark": "2E6A2C",
    "Pants": "4E6B2E", "Hair": "6B4426", "Eye": "F4F4F4", "Pupil": "2E8A4A", "Mouth": "8A3A2A",
    "Wood": "7A4A26", "String": "F2EBD8", "Feather": "E8E2D2", "Steel": ("A8B0B8", 0.5, 0.4),
}

P = BP.params(
    hunch=0.01, head_c=(0, -0.03, 0.765), head_r=(0.145, 0.135, 0.155),
    neck0_z=0.55, neck1_z=0.60, chest_z=0.47, waist_z=0.39, pelvis_z=0.33,
    shoulder_z=0.525, shoulder_x=0.105, elbow_out=0.045, elbow_z=0.41,
    wrist_x=0.18, wrist_z=0.31, wrist_y=-0.03, hand_bottom=0.24, hand_size=0.10,
    hip_x=0.06, hip_z=0.31, knee_x=0.075, knee_y=-0.03, knee_z=0.17, ankle_x=0.09, ankle_z=0.085,
    foot_len=0.15,
    r_pelvis=(0.095, 0.068), r_waist=(0.085, 0.06), r_chest=(0.108, 0.075), r_neck0=(0.045, 0.04),
    r_neck1=(0.04, 0.036), r_shoulder=0.038, r_elbow=0.03, r_wrist=0.031, r_hip=0.05, r_knee=0.04, r_ankle=0.034,
)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, 0.735, 0.058, size=(0.038, 0.018, 0.04), slant=4, pupils=0.024)
    K.sphere("Nose", "Skin", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.70, 0.006), 0.70), (0.015, 0.012, 0.015), u=8, v=5)
    K.sphere("Mouth", "Mouth", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.66, 0.006), 0.66), (0.03, 0.008, 0.012), u=10, v=5)
    K.sphere("Hair", "Hair", "DEF-head", c + Vector((0, 0.01, 0.045)), (0.152, 0.142, 0.13), u=16, v=10)
    for i, x in enumerate((-0.07, 0.0, 0.07)):
        K.lock("Fringe%d" % i, "Hair", "DEF-head", c + Vector((x, -0.12, 0.1)), (x * 3, -0.6, -0.7), 0.07, 0.04, thick=0.4)
    # hood: a bigger dome over the hair, open at the face, with a peak and a back drape
    base = c + Vector((0, 0.015, 0.0))
    K.dome("Hood", "Hood", "DEF-head", base, (0.175, 0.165, 0.2), cut=-0.35, u=24, v=14, face_open=(0.3, 0.62))
    K.along("HoodPeak", "Hood", "DEF-head", base + Vector((0, 0.06, 0.17)), base + Vector((0, 0.16, 0.2)), 0.05, 0.004, segments=8)
    K.sphere("Cap", "LeatherDark", "DEF-head", base + Vector((0, -0.06, 0.12)), (0.1, 0.07, 0.045), u=12, v=6)


def gear(J):
    K.sphere("Tunic", "Leather", "DEF-chest", (0, -0.02, 0.46), (0.112, 0.082, 0.09), u=14, v=8)
    K.skirt("TunicSkirt", "Leather", "AUTO", 0.37, 0.24, 0.095, 0.112, side_lift=0.03, thickness=0.01)
    K.skirt("Cloak", "Hood", "DEF-chest", 0.55, 0.23, 0.11, 0.17, arc=(20, 160), thickness=0.012)
    K.band("Belt", "LeatherDark", "DEF-pelvis", (0, 0, 0.37), 0.1, 0.075, 0.032)
    K.sphere("Pouch", "LeatherDark", "DEF-pelvis", (0.07, -0.07, 0.34), (0.03, 0.02, 0.03), u=8, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Pants." + sd, "Pants", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.052, 0.045, 0.1, 1.0, segments=10)
        K.along("Bracer." + sd, "LeatherDark", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.035, 0.033, 0.05, 0.5, segments=10)
    a, b = Vector((0.07, 0.1, 0.36)), Vector((-0.08, 0.1, 0.58))
    K.along("Quiver", "LeatherDark", "DEF-chest", a, b, 0.042, 0.047, segments=12)
    d = (b - a).normalized()
    for i, off in enumerate((Vector((0.01, 0, 0)), Vector((-0.02, 0.015, 0)), Vector((0.0, -0.02, 0.01)))):
        s0, s1 = b + off, b + off + d * 0.11
        K.along("Arrow%d" % i, "Wood", "DEF-chest", s0, s1, 0.006, segments=6)
        K.leaf("Fletch%d" % i, "Feather", "DEF-chest", s1 - d * 0.02, 0.055, 0.02, rotation=(0, math.radians(-60), math.radians(160)))


def bow(J):
    hx, hy, hz = J["wrL"]
    g = Vector((hx + 0.02, hy - 0.02, 0.29))
    pts = []
    for i in range(9):
        t = (i / 8) * 2 - 1
        pts.append(g + Vector((0.08 * (1 - t * t), 0, t * 0.36)))
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Bow%d" % i, "Wood", "DEF-hand.L", a, b, 0.016 if 2 < i < 6 else 0.012, segments=8)
    K.along("BowGrip", "LeatherDark", "DEF-hand.L", pts[3], pts[5], 0.02, segments=8)
    K.along("BowString", "String", "DEF-hand.L", pts[0], pts[-1], 0.003, segments=4)


def pecas():
    J = BP.body("Body", P, role="Leather")
    BP.hands("", J, P, role="LeatherDark", style="fist", size=0.82)
    BP.feet("", J, P, role="LeatherDark", style="boot", size=0.9)
    head(P["head_c"], P["head_r"])
    gear(J)
    bow(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=4)
    BP.run(arm, lean=14, stride=38, arm_swing=26)
    BP.attack(arm, "shoot")
    BP.die(arm)
