"""CH_Sentry — "Sentinela Oca": hollow suit of blue plate, cyan plume, closed visor with a glowing
cyan slit, spiked pauldrons, wooden crossbow held at the hip. Ref: portraits/sentry.png. Biped. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_Sentry"
ATAQUE_QUADRO = 7
PALETA = {"Steel": ("6F8FBF", 0.4, 0.5), "SteelLight": ("A6C0E0", 0.35, 0.5), "SteelDark": ("45597E", 0.45, 0.5),
          "Plume": "5CC8EE", "PlumeLight": "A8E8FF", "Visor": "141824", "Eye": "6FF0FF",
          "Wood": "8A5A30", "Leather": "5A3A20", "String": "E8E2D2"}
BRILHO = ("Eye",)

P = BP.hero(head_c=(0, -0.03, 0.745), head_r=(0.13, 0.125, 0.15), wrist_x=0.15, wrist_y=-0.1, wrist_z=0.37,
            elbow_z=0.42, hand_bottom=0.29, elbow_out=0.06, r_chest=(0.112, 0.078), r_hip=0.052, r_knee=0.044)


def helmet(hc, hr):
    c = Vector(hc)
    K.sphere("Helm", "Steel", "DEF-head", c, (hr[0] + 0.01, hr[1] + 0.012, hr[2]), u=18, v=12)
    K.box("Visor", "Visor", "DEF-head", (0, c.y - hr[1] - 0.004, c.z - 0.01), (0.19, 0.03, 0.04), bevel=0.008)
    K.box("Slit", "Eye", "DEF-head", (0, c.y - hr[1] - 0.02, c.z - 0.008), (0.15, 0.008, 0.014), bevel=0.003)
    K.sphere("Bevor", "SteelLight", "DEF-head", (0, c.y - hr[1] + 0.03, c.z - 0.085), (0.105, 0.07, 0.065), u=14, v=8)
    K.box("VisorRidge", "SteelLight", "DEF-head", (0, c.y - hr[1] - 0.01, c.z + 0.05), (0.02, 0.03, 0.08), bevel=0.008)
    K.arc_strip("HelmRidge", "SteelLight", "DEF-head", c, hr[0], hr[1] + 0.014, hr[2] + 0.012, 0.03)
    plume = [((0, 0.45, 0.9), 0.22, 0.08), ((0, 0.85, 0.5), 0.28, 0.095), ((0.3, 0.85, 0.4), 0.22, 0.08),
             ((-0.3, 0.85, 0.4), 0.22, 0.08), ((0, 0.95, -0.15), 0.26, 0.09), ((0.15, 0.6, 0.75), 0.2, 0.07)]
    for i, (d, ln, w) in enumerate(plume):
        K.lock("Plume%d" % i, "PlumeLight" if i % 3 == 1 else "Plume", "DEF-head", c + Vector((0, 0.06, hr[2] - 0.03)),
               d, ln, w, thick=0.55, curl=0.06)


def armour(J):
    K.sphere("Breastplate", "Steel", "DEF-chest", (0, -0.03, 0.465), (0.12, 0.088, 0.09), u=16, v=10)
    K.sphere("Gorget", "SteelDark", "DEF-neck", (0, -0.02, 0.56), (0.07, 0.06, 0.03), u=12, v=6)
    K.skirt("Faulds", "Steel", "AUTO", 0.38, 0.25, 0.1, 0.125, side_lift=0.02, thickness=0.014)
    K.skirt("Tasset", "SteelDark", "DEF-pelvis", 0.37, 0.21, 0.1, 0.11, arc=(240, 300), thickness=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.375), 0.104, 0.078, 0.03)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Steel", "DEF-upper_arm." + sd, sh + Vector((s * 0.015, 0, 0)), (0.066, 0.066, 0.055))
        K.band("PauldronTrim." + sd, "SteelLight", "DEF-upper_arm." + sd, sh + Vector((s * 0.015, 0, 0.002)), 0.066, 0.066, 0.012)
        K.along("Spike." + sd, "SteelLight", "DEF-upper_arm." + sd, sh + Vector((s * 0.03, 0, 0.04)),
                sh + Vector((s * 0.07, 0.0, 0.13)), 0.024, 0.003, segments=6)
        K.along("Vambrace." + sd, "Steel", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.037, 0.035, 0.0, 0.7, segments=10)
        K.along("Greave." + sd, "Steel", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.045, 0.047, 0.0, 0.85, segments=10)
        K.sphere("Knee." + sd, "SteelLight", "DEF-shin." + sd, Vector(J["kn" + sd]) + Vector((0, -0.03, 0)), (0.042, 0.033, 0.038), u=10, v=6)
        K.along("Cuisse." + sd, "Steel", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.054, 0.049, 0.2, 0.8, segments=10)


def crossbow(J):
    """Held level at the hip, pointing forward; rigid on the right hand (the left hand steadies it)."""
    hx, hy, hz = J["wrR"]
    butt = Vector((hx + 0.02, hy + 0.08, 0.36))
    front = Vector((0.05, -0.38, 0.38))
    d = (front - butt).normalized()
    K.along("Stock", "Wood", "DEF-hand.R", butt, front, 0.024, 0.016, segments=8)
    K.box("Grip", "Leather", "DEF-hand.R", butt + d * 0.11 + Vector((0, 0, -0.03)), (0.03, 0.03, 0.06), bevel=0.006)
    side = d.cross(Vector((0, 0, 1))).normalized()
    pf = butt + d * 0.36
    pts = [pf + side * (t * 0.18) - d * (t * t * 0.07) for t in (-1, -0.6, -0.25, 0.25, 0.6, 1)]
    pts.insert(3, pf + d * 0.008)
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Prod%d" % i, "SteelLight", "DEF-hand.R", a, b, 0.012, segments=6)
    nut = butt + d * 0.2
    for i, tip in enumerate((pts[0], pts[-1])):
        K.along("String%d" % i, "String", "DEF-hand.R", tip, nut, 0.0035, segments=4)
    K.along("Bolt", "Wood", "DEF-hand.R", nut + Vector((0, 0, 0.02)), front + d * 0.05 + Vector((0, 0, 0.02)), 0.006, segments=5)
    K.along("BoltTip", "SteelLight", "DEF-hand.R", front + d * 0.05 + Vector((0, 0, 0.02)), front + d * 0.11 + Vector((0, 0, 0.02)),
            0.014, 0.001, segments=4)


def pecas():
    J = BP.body("Body", P, role="SteelDark")
    BP.hands("", J, P, role="SteelDark", style="fist", size=0.85)
    BP.feet("", J, P, role="Steel", style="boot", size=0.95)
    helmet(P["head_c"], P["head_r"])
    armour(J)
    crossbow(J)
    return BP.bones(J, P)


def crossbow_shot(arm):
    """The ranged clip: aim, fire (the stock kicks the shoulders back), recover."""
    rest = {"DEF-spine": [("X", 6)], "DEF-head": [("X", -4)]}
    rest.update(BP._legs_rest())
    aim = {"DEF-spine": [("X", 12), ("Z", -6)], "DEF-head": [("X", -12), ("Z", 4)],
           "DEF-upper_arm.R": [("X", -14)], "DEF-upper_arm.L": [("X", -14)]}
    aim.update(BP._legs_rest())
    fire = {"DEF-root": {"rot": [], "loc": (0, 0.035, 0)}, "DEF-spine": [("X", -10), ("Z", -4)], "DEF-head": [("X", 6)],
            "DEF-upper_arm.R": [("X", -34)], "DEF-upper_arm.L": [("X", -30)], "DEF-forearm.R": [("X", -8)],
            "DEF-thigh.L": [("X", -12)], "DEF-shin.L": [("X", 14)]}
    K.clip(arm, "cast", 16, False)
    for f, pose in ((1, rest), (6, aim), (9, fire), (16, rest)):
        K.key(arm, f, pose)


def animar(arm):
    BP.idle(arm, lean=3, arm_out=2)
    BP.run(arm, lean=14, stride=36, arm_swing=6)
    BP.attack(arm, "punch")   # blocked in melee: a jab with the stock
    crossbow_shot(arm)
    BP.die(arm)
