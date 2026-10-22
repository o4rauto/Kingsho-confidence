"""CH_Warden — Kael, the hero: chibi elf archer, flame hair, golden armour, golden recurve bow.
Reference: godot/assets/art/portraits/warden.png (sheet pipeline/referencias/personagens_3_herois_tropas.jpg).
H = 1.20 m; fractions of H measured on the portrait (342x453 px). Back of hair and quiver inferred.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Warden"
ATAQUE_QUADRO = 9
PALETA = {
    "Skin": "EDB48C", "Leather": "6B3A22", "Gold": ("E0A82E", 0.45, 0.35), "GoldDark": ("B07A1C", 0.5, 0.3),
    "Tabard": "B3302A", "HairA": "E4501C", "HairB": "F59A25", "Eye": "F2B23A", "Pupil": "3A1A0A",
    "Mouth": "8A3A2A", "Gem": ("D8262A", 0.3, 0.0), "String": "F2EBD8", "Wood": "7A4A26", "Feather": "E8E2D2",
}
BRILHO = ("Gem",)

P = BP.params(
    hunch=0.01, head_c=(0, -0.035, 0.775), head_r=(0.15, 0.14, 0.17),
    neck0_z=0.55, neck1_z=0.60, chest_z=0.47, waist_z=0.39, pelvis_z=0.33,
    shoulder_z=0.525, shoulder_x=0.105, elbow_out=0.05, elbow_z=0.41,
    wrist_x=0.19, wrist_z=0.31, wrist_y=-0.03, hand_bottom=0.235, hand_size=0.10,
    hip_x=0.06, hip_z=0.31, knee_x=0.075, knee_y=-0.025, knee_z=0.17, ankle_x=0.09, ankle_z=0.085,
    foot_len=0.15,
    r_pelvis=(0.095, 0.068), r_waist=(0.082, 0.058), r_chest=(0.105, 0.072), r_neck0=(0.045, 0.04),
    r_neck1=(0.04, 0.036), r_shoulder=0.038, r_elbow=0.029, r_wrist=0.03, r_hip=0.05, r_knee=0.04, r_ankle=0.034,
)


def hair(hc):
    c = Vector(hc)
    cap_c = c + Vector((0, 0.012, 0.045))
    K.sphere("HairCap", "HairA", "DEF-head", cap_c, (0.163, 0.152, 0.165), u=18, v=12)
    K.sphere("HairBack", "HairA", "DEF-head", c + Vector((0, 0.07, -0.06)), (0.17, 0.12, 0.19), u=16, v=10)
    # flowing flame locks (portrait: mass up and out to both sides, falling to the shoulders on the right)
    locks = [((0, 0.3, 1), 0.27, 0.095), ((-0.6, 0.35, 0.8), 0.28, 0.095), ((0.55, 0.35, 0.85), 0.25, 0.09),
             ((-0.92, 0.4, 0.25), 0.27, 0.085), ((0.9, 0.4, 0.3), 0.23, 0.08), ((-0.8, 0.5, -0.38), 0.3, 0.09),
             ((0.8, 0.5, -0.3), 0.22, 0.075), ((0, 0.9, 0.45), 0.25, 0.09), ((-0.35, 0.95, -0.12), 0.24, 0.085),
             ((0.35, 0.95, -0.05), 0.21, 0.085), ((-0.25, 0.4, 0.95), 0.2, 0.07), ((0.3, 0.45, 0.9), 0.19, 0.07)]
    for i, (d, ln, w) in enumerate(locks):
        d = Vector(d).normalized()
        root = cap_c + Vector((d.x * 0.12, d.y * 0.1, d.z * 0.11))
        K.lock("HairLock%d" % i, "HairB" if i % 3 == 2 else "HairA", "DEF-head", root, d, ln, w, thick=0.4, curl=0.04)
    for i, (d, ln) in enumerate((((-0.7, -0.45, -0.55), 0.12), ((0.65, -0.45, -0.55), 0.11), ((0.05, -0.6, -0.8), 0.1))):
        root = c + Vector((d[0] * 0.04, -0.12, 0.125))
        K.lock("Bang%d" % i, "HairA", "DEF-head", root, d, ln, 0.05, thick=0.4, curl=0.02)


def face(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, 0.735, 0.066, size=(0.05, 0.022, 0.06), slant=-6, pupils=0.03)
    for s, sd in ((1, ".L"), (-1, ".R")):     # white catch-light, chibi style
        x = s * 0.072
        K.sphere("Shine" + sd, "String", "DEF-head", (x, K.ellipsoid_front_y(hc, hr, x, 0.755, -0.012), 0.755),
                 (0.011, 0.006, 0.011), u=8, v=4)
    K.sphere("Chin", "Skin", "DEF-head", (0, c.y - 0.04, 0.635), (0.07, 0.06, 0.045), u=12, v=8)
    for s, sd in ((1, ".L"), (-1, ".R")):
        x = s * 0.065
        K.box("Brow" + sd, "HairA", "DEF-head", (x, K.ellipsoid_front_y(hc, hr, x, 0.80, 0.004), 0.80),
              (0.055, 0.014, 0.012), rotation=(0, math.radians(-12) * s, math.radians(16) * s))
        K.leaf("Ear" + sd, "Skin", "DEF-head", (s * 0.14, c.y + 0.01, 0.75), 0.09, 0.03, side=s,
               rotation=(0, math.radians(-30), math.radians(-20)))
    K.sphere("Mouth", "Mouth", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.665, 0.008), 0.665), (0.018, 0.006, 0.006), u=8, v=4)
    K.sphere("Nose", "Skin", "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, 0.70, 0.004), 0.70), (0.012, 0.01, 0.012), u=8, v=5)
    # tiara with a red gem (portrait 0.70 H)
    K.band("Tiara", "Gold", "DEF-head", (0, c.y + 0.005, 0.84), hr[0] + 0.006, hr[1] + 0.006, 0.03, z_tilt=0.12)
    K.sphere("TiaraGem", "Gem", "DEF-head", (0, c.y - hr[1] - 0.012, 0.83), (0.017, 0.01, 0.024), u=10, v=6)


def armour(J):
    K.sphere("ChestPlate", "Gold", "DEF-chest", (0, -0.03, 0.465), (0.112, 0.08, 0.085), u=16, v=10)
    K.sphere("ChestRidge", "GoldDark", "DEF-chest", (0, -0.1, 0.46), (0.012, 0.01, 0.06), u=8, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Gold", "DEF-upper_arm." + sd, sh + Vector((s * 0.015, 0, 0.0)), (0.062, 0.062, 0.05))
        K.along("Bracer." + sd, "Gold", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.036, 0.034, 0.05, 0.55, segments=10)
        K.along("Greave." + sd, "Gold", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.043, 0.046, 0.05, 0.8, segments=10)
        K.sphere("KneeCap." + sd, "Gold", "DEF-shin." + sd, Vector(J["kn" + sd]) + Vector((0, -0.03, 0)), (0.04, 0.03, 0.035), u=10, v=6)
        K.box("Tasset." + sd, "Gold", "DEF-thigh." + sd, (s * 0.085, -0.02, 0.29), (0.07, 0.07, 0.07),
              rotation=(0, math.radians(14) * s, 0), bevel=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.35), 0.098, 0.074, 0.035)
    K.sphere("Buckle", "Gold", "DEF-pelvis", (0, -0.082, 0.35), (0.025, 0.012, 0.022), u=10, v=6)
    K.skirt("Tabard", "Tabard", "AUTO", 0.34, 0.20, 0.092, 0.11, ragged=0.0, side_lift=0.09, thickness=0.01)


def bow(J):
    hx, hy, hz = J["wrL"]
    g = Vector((hx + 0.02, hy - 0.02, 0.28))
    pts = []
    for i in range(9):            # recurve in the XZ plane, bulging outward (+X), tips flick back
        t = (i / 8) * 2 - 1
        x = 0.07 * (1 - t * t) - 0.025 * abs(t) ** 6
        pts.append(g + Vector((x, 0, t * 0.30)))
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Bow%d" % i, "Gold", "DEF-hand.L", a, b, 0.015 if 2 < i < 6 else 0.012, segments=8)
    K.along("BowGrip", "Leather", "DEF-hand.L", pts[3], pts[5], 0.019, segments=8)
    K.along("BowString", "String", "DEF-hand.L", pts[0], pts[-1], 0.003, segments=4)


def quiver():
    a, b = Vector((0.07, 0.11, 0.36)), Vector((-0.08, 0.11, 0.60))
    K.along("Quiver", "Leather", "DEF-chest", a, b, 0.045, 0.05, segments=12)
    K.band("QuiverRim", "Gold", "DEF-chest", b, 0.052, 0.052, 0.02)
    d = (b - a).normalized()
    for i, off in enumerate((Vector((0.01, 0, 0)), Vector((-0.02, 0.015, 0)), Vector((0.0, -0.02, 0.01)))):
        s0 = b + off
        s1 = s0 + d * 0.12
        K.along("Arrow%d" % i, "Wood", "DEF-chest", s0, s1, 0.006, segments=6)
        K.leaf("Fletch%d" % i, "Tabard" if i % 2 else "Feather", "DEF-chest", s1 - d * 0.02, 0.06, 0.02,
               rotation=(0, math.radians(-60), math.radians(160)))
    K.along("Strap", "Leather", "DEF-chest", (0.09, -0.065, 0.53), (-0.1, -0.075, 0.38), 0.012, segments=6)


def pecas():
    J = BP.body("Body", P, role="Leather")
    BP.hands("", J, P, role="Leather", style="fist", size=0.85)
    BP.feet("", J, P, role="Gold", style="boot", size=0.9)
    face(P["head_c"], P["head_r"])
    hair(P["head_c"])
    armour(J)
    bow(J)
    quiver()
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=4)
    BP.run(arm, lean=14, stride=38, arm_swing=28)
    BP.attack(arm, "shoot")
    BP.die(arm)
