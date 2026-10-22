"""CH_PyreKnight — "Cavaleiro da Pira": silver plate knight, orange plume, closed visor with glowing
eyes, flaming sword, golden kite shield with a flame emblem. Ref: portraits/pyre_knight.png. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_PyreKnight"
ATAQUE_QUADRO = 8
PALETA = {"Steel": ("C9CFD8", 0.4, 0.5), "SteelDark": ("8A929E", 0.45, 0.5), "Mail": ("7A808A", 0.5, 0.5),
          "Plume": "F07A1E", "PlumeLight": "F8B23A", "Gold": ("E3A72E", 0.4, 0.4), "Orange": "E8641C",
          "Visor": "1E1A22", "Eye": "FFB13A", "Fire": "FF8A1A", "FireCore": "FFE07A", "Leather": "6B4426"}
BRILHO = ("Eye", "Fire", "FireCore")

P = BP.hero(r_chest=(0.115, 0.08), r_shoulder=0.042, r_hip=0.054, r_knee=0.044)


def helmet(hc, hr):
    c = Vector(hc)
    K.sphere("Helm", "Steel", "DEF-head", c, (hr[0] + 0.01, hr[1] + 0.01, hr[2]), u=18, v=12)
    K.box("Visor", "Visor", "DEF-head", (0, c.y - hr[1] - 0.0, c.z - 0.005), (0.2, 0.03, 0.045), bevel=0.008)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", (s * 0.05, c.y - hr[1] - 0.016, c.z - 0.003), (0.022, 0.008, 0.012), u=8, v=4)
    for i, z in enumerate((-0.06, -0.09)):
        K.box("Grill%d" % i, "SteelDark", "DEF-head", (0, c.y - hr[1] + 0.01, c.z + z), (0.12, 0.02, 0.01), bevel=0.003)
    K.arc_strip("HelmRidge", "Gold", "DEF-head", c + Vector((0, 0, 0.0)), hr[0], hr[1] + 0.012, hr[2] + 0.012, 0.035)
    plume = [((0, 0.3, 1), 0.26, 0.1), ((0, 0.75, 0.65), 0.3, 0.11), ((0.35, 0.7, 0.55), 0.24, 0.09),
             ((-0.35, 0.7, 0.55), 0.24, 0.09), ((0, 0.98, 0.15), 0.28, 0.1), ((0.4, 0.9, 0.0), 0.22, 0.085),
             ((-0.4, 0.9, 0.0), 0.22, 0.085), ((0, 0.9, -0.4), 0.22, 0.09), ((0.2, 0.5, 0.85), 0.2, 0.08)]
    for i, (d, ln, w) in enumerate(plume):
        K.lock("Plume%d" % i, "PlumeLight" if i % 3 == 1 else "Plume", "DEF-head", c + Vector((0, 0.05, hr[2] - 0.03)),
               d, ln, w, thick=0.55, curl=0.06)


def armour(J):
    K.sphere("Breastplate", "Steel", "DEF-chest", (0, -0.03, 0.465), (0.122, 0.088, 0.09), u=16, v=10)
    K.sphere("Gorget", "SteelDark", "DEF-neck", (0, -0.02, 0.56), (0.07, 0.06, 0.03), u=12, v=6)
    K.skirt("Tabard", "Orange", "DEF-pelvis", 0.37, 0.2, 0.1, 0.11, arc=(235, 305), thickness=0.012)
    K.skirt("Faulds", "Steel", "AUTO", 0.38, 0.27, 0.1, 0.12, side_lift=0.02, thickness=0.014)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.375), 0.104, 0.078, 0.032)
    K.sphere("BeltGem", "Gold", "DEF-pelvis", (0, -0.087, 0.375), (0.022, 0.012, 0.02), u=10, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Steel", "DEF-upper_arm." + sd, sh + Vector((s * 0.015, 0, 0)), (0.068, 0.068, 0.055))
        K.band("PauldronTrim." + sd, "Gold", "DEF-upper_arm." + sd, sh + Vector((s * 0.015, 0, 0.002)), 0.068, 0.068, 0.012)
        K.along("Vambrace." + sd, "Steel", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.038, 0.036, 0.0, 0.7, segments=10)
        K.along("Greave." + sd, "Steel", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.046, 0.048, 0.0, 0.85, segments=10)
        K.sphere("Knee." + sd, "Steel", "DEF-shin." + sd, Vector(J["kn" + sd]) + Vector((0, -0.03, 0)), (0.045, 0.035, 0.04), u=10, v=6)
        K.along("Cuisse." + sd, "Steel", "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.055, 0.05, 0.2, 0.8, segments=10)


def sword(J):
    hx, hy, hz = J["wrR"]
    h = Vector((hx - 0.005, hy - 0.025, 0.285))
    tip = h + Vector((-0.07, -0.16, -0.27))
    d = (tip - h).normalized()
    K.along("Blade", "FireCore", "DEF-hand.R", h + d * 0.04, tip, 0.026, 0.004, segments=4)
    side = d.cross(Vector((0, 0, 1))).normalized()
    K.along("Guard", "Gold", "DEF-hand.R", h + d * 0.035 - side * 0.055, h + d * 0.035 + side * 0.055, 0.013, segments=6)
    for i in range(4):
        p = h + d * (0.1 + 0.06 * i)
        K.lock("SwordFire%d" % i, "Fire", "DEF-hand.R", p, (side.x * 0.3, 0.1, 1.0), 0.09 - 0.012 * i, 0.03, thick=0.5)


def shield(J):
    hx, hy, hz = J["wrL"]
    c = Vector((hx + 0.04, hy - 0.065, 0.36))
    rot = (0, 0, math.radians(28))
    K.sphere("Shield", "Gold", "DEF-forearm.L", c, (0.115, 0.022, 0.16), u=16, v=10, rotation=rot)
    K.sphere("ShieldRim", "Orange", "DEF-forearm.L", c + Vector((0, 0.006, 0)), (0.124, 0.018, 0.17), u=16, v=10, rotation=rot)
    em = c + Vector((-0.012, -0.02, -0.04))
    K.lock("Emblem", "Fire", "DEF-forearm.L", em, (0, -0.2, 1), 0.13, 0.05, thick=0.25, curl=0.02)


def pecas():
    J = BP.body("Body", P, role="Mail")
    BP.hands("", J, P, role="Steel", style="fist", size=0.9)
    BP.feet("", J, P, role="Steel", style="boot", size=0.95)
    helmet(P["head_c"], P["head_r"])
    armour(J)
    sword(J)
    shield(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=5)
    BP.run(arm, lean=12, stride=34, arm_swing=24)
    BP.attack(arm, "sword")
    BP.die(arm)
