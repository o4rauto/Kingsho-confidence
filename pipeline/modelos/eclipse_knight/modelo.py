"""CH_EclipseKnight — "Cavaleiro do Eclipse" (no portrait: designed from game_data — brute, indigo 2a2440,
armour, absorb shield, ward aura, breaks walls). A heavy knight of the fallen sun temple: dark indigo plate
with gold trim, a horned helm crowned by gold sun rays, a big round shield bearing the eclipse (a black disc
ringed by a glowing gold corona) and a flanged war hammer. Biped. H 1.25.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_EclipseKnight"
ATAQUE_QUADRO = 10
PALETA = {"Plate": ("2E2850", 0.4, 0.55), "PlateLight": ("4A4278", 0.4, 0.55), "Gold": ("E8B84A", 0.35, 0.6),
          "Corona": "FFD86A", "Void": "0E0A18", "Eye": "FFD86A", "Leather": "4A3226", "Steel": ("9AA0B4", 0.35, 0.6)}
BRILHO = ("Corona", "Eye")

P = BP.hero(hunch=0.02, head_c=(0, -0.03, 0.76), head_r=(0.14, 0.135, 0.15),
            shoulder_x=0.13, wrist_x=0.21, r_chest=(0.135, 0.095), r_waist=(0.105, 0.075), r_pelvis=(0.11, 0.08),
            r_shoulder=0.05, r_elbow=0.038, r_wrist=0.036, r_hip=0.06, r_knee=0.05, r_ankle=0.044)


def helm(hc, hr):
    c = Vector(hc)
    K.sphere("Helm", "Plate", "DEF-head", c, (hr[0] + 0.012, hr[1] + 0.012, hr[2]), u=18, v=12)
    K.box("Visor", "Void", "DEF-head", (0, c.y - hr[1] - 0.004, c.z - 0.005), (0.2, 0.03, 0.05), bevel=0.008)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", (s * 0.045, c.y - hr[1] - 0.02, c.z - 0.003), (0.022, 0.008, 0.012), u=8, v=4)
        pts = [c + Vector((s * 0.12, 0.0, 0.05))]
        for k in range(1, 4):
            pts.append(pts[0] + Vector((s * 0.05 * k, -0.01 * k, 0.03 * k + 0.012 * k * k)))
        for k, (a, b) in enumerate(zip(pts, pts[1:])):
            K.along("Horn%d%s" % (k, sd), "Gold", "DEF-head", a, b, 0.028 - 0.007 * k, 0.022 - 0.007 * k, segments=8)
    K.arc_strip("Ridge", "Gold", "DEF-head", c, hr[0], hr[1] + 0.014, hr[2] + 0.012, 0.03)
    K.box("Bevor", "PlateLight", "DEF-head", (0, c.y - hr[1] + 0.01, c.z - 0.08), (0.16, 0.05, 0.06), bevel=0.015)
    for k in range(5):   # sun-ray crest
        a = math.radians(-50 + 25 * k)
        root = c + Vector((math.sin(a) * 0.04, 0.02, hr[2] - 0.01))
        K.lock("Ray%d" % k, "Corona" if k % 2 == 0 else "Gold", "DEF-head", root, (math.sin(a), 0.15, math.cos(a)),
               0.12 if k == 2 else 0.09, 0.035, thick=0.4, curl=0.0, power=1.2, rings=6, seg=6)


def armour(J):
    K.sphere("Breastplate", "Plate", "DEF-chest", (0, -0.035, 0.465), (0.14, 0.1, 0.1), u=16, v=10)
    K.sphere("Sun", "Gold", "DEF-chest", (0, -0.13, 0.47), (0.04, 0.012, 0.04), u=12, v=6)
    K.skirt("Faulds", "Plate", "AUTO", 0.38, 0.24, 0.112, 0.135, side_lift=0.02, thickness=0.014)
    K.skirt("Tabard", "Gold", "DEF-pelvis", 0.37, 0.18, 0.105, 0.115, arc=(245, 295), thickness=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.375), 0.115, 0.086, 0.035)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Plate", "DEF-upper_arm." + sd, sh + Vector((s * 0.018, 0, 0)), (0.082, 0.08, 0.068))
        K.band("PauldronTrim." + sd, "Gold", "DEF-upper_arm." + sd, sh + Vector((s * 0.018, 0, 0.0)), 0.083, 0.081, 0.015)
        K.along("Vambrace." + sd, "Plate", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.043, 0.04, 0.0, 0.75, segments=10)
        K.along("Greave." + sd, "Plate", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.052, 0.054, 0.0, 0.85, segments=10)
        K.sphere("Knee." + sd, "Gold", "DEF-shin." + sd, Vector(J["kn" + sd]) + Vector((0, -0.035, 0)), (0.045, 0.035, 0.042), u=10, v=6)
        K.along("Cuisse." + sd, "PlateLight", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.062, 0.056, 0.25, 0.8, segments=10)


def hammer(J):
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.005, hy - 0.025, 0.28))
    end = h + Vector((-0.04, -0.1, -0.22))
    d = (end - h).normalized()
    K.along("Haft", "Leather", "DEF-hand.R", h - d * 0.05, end, 0.016, segments=8)
    side = d.cross(Vector((1, 0, 0))).normalized()
    K.box("HammerHead", "Steel", "DEF-hand.R", end + d * 0.04, (0.16, 0.08, 0.08), bevel=0.012)
    for k in range(4):
        a = math.radians(90 * k)
        K.box("Flange%d" % k, "Gold", "DEF-hand.R", end + d * 0.04 + Vector((0, math.cos(a) * 0.045, math.sin(a) * 0.045)),
              (0.1, 0.02 if k % 2 == 0 else 0.03, 0.03 if k % 2 == 0 else 0.02), bevel=0.004)


def shield(J):
    hx, hy, hz = J["wrL"]
    c = Vector((hx + 0.05, hy - 0.07, 0.38))
    rot = (math.radians(90), 0, math.radians(26))
    K.cone("Shield", "Plate", "DEF-forearm.L", c, 0.17, 0.17, 0.03, segments=24, rotation=rot)
    K.cone("Rim", "Gold", "DEF-forearm.L", c + Vector((0, 0.004, 0)), 0.182, 0.182, 0.024, segments=24, rotation=rot)
    face = Vector((math.sin(rot[2]), -math.cos(rot[2]), 0))
    K.cone("Corona", "Corona", "DEF-forearm.L", c + face * 0.017, 0.11, 0.11, 0.006, segments=24, rotation=rot)
    K.cone("Eclipse", "Void", "DEF-forearm.L", c + face * 0.022, 0.085, 0.085, 0.008, segments=24, rotation=rot)
    for k in range(8):
        a = math.radians(45 * k)
        side = Vector((math.cos(rot[2]), math.sin(rot[2]), 0))
        p = c + face * 0.017 + side * math.cos(a) * 0.13 + Vector((0, 0, math.sin(a) * 0.13))
        q = c + face * 0.017 + side * math.cos(a) * 0.16 + Vector((0, 0, math.sin(a) * 0.16))
        K.along("Ray%d" % k, "Corona", "DEF-forearm.L", p, q, 0.012, 0.002, segments=4)


def pecas():
    J = BP.body("Body", P, role="Void")
    BP.hands("", J, P, role="Plate", style="fist", size=0.95)
    BP.feet("", J, P, role="Plate", style="boot", size=1.05)
    helm(P["head_c"], P["head_r"])
    armour(J)
    hammer(J)
    shield(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=6)
    BP.run(arm, lean=12, stride=30, arm_swing=20)
    BP.attack(arm, "hammer")
    BP.die(arm)
