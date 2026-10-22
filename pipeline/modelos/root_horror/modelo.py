"""CR_RootHorror — "Horror de Raízes" (no portrait: designed from game_data — brute, dark green 3a5a1a,
regenerates, breaks walls). A hunched mass of twisted roots: vines spiral around every limb, moss on the
shoulders, thorns, a hollow knot of a face with two glowing yellow-green eyes and a ragged maw, twig
antlers, and long root claws that drag on the ground. Biped (hunched, long arms). H 1.2.
"""
import math
import random
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_RootHorror"
ATAQUE_QUADRO = 10
PALETA = {"Root": "4A3E22", "RootDark": "2E2614", "Vine": "3A5A1A", "Moss": "6A8A2A", "Hollow": "120E08",
          "Eye": "D8F04A", "Thorn": "C8B890"}
BRILHO = ("Eye",)

P = BP.params(hunch=0.14, head_c=(0, -0.22, 0.86), head_r=(0.13, 0.12, 0.13), neck0_z=0.74, neck1_z=0.8,
              chest_z=0.64, waist_z=0.48, pelvis_z=0.36, shoulder_z=0.72, shoulder_x=0.2, elbow_out=0.08, elbow_z=0.48,
              wrist_x=0.3, wrist_z=0.24, wrist_y=-0.12, hand_bottom=0.12, hand_size=0.12,
              hip_x=0.11, hip_z=0.32, knee_x=0.14, knee_y=-0.05, knee_z=0.17, ankle_x=0.16, ankle_z=0.07, foot_len=0.2,
              r_pelvis=(0.16, 0.13), r_waist=(0.15, 0.12), r_chest=(0.22, 0.17), r_neck0=(0.1, 0.09), r_neck1=(0.09, 0.08),
              r_shoulder=0.075, r_elbow=0.06, r_wrist=0.05, r_hip=0.08, r_knee=0.065, r_ankle=0.055)


def vines(prefix, bone, a, b, r, turns=1.5, n=10, seed=0, role="Vine"):
    """A vine wound around the segment a->b."""
    rnd = random.Random(seed)
    a, b = Vector(a), Vector(b)
    d = b - a
    side = d.normalized().orthogonal().normalized()
    up = d.normalized().cross(side)
    ph = rnd.uniform(0, 6.28)
    pts = []
    for i in range(n + 1):
        t = i / n
        ang = ph + turns * 2 * math.pi * t
        pts.append(a + d * t + (side * math.cos(ang) + up * math.sin(ang)) * r)
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        K.along("%s%d" % (prefix, i), role, bone, p, q, 0.016, segments=6)


def pecas():
    J = BP.body("Body", P, role="Root")
    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr = J["sh" + sd], J["el" + sd], J["wr" + sd]
        vines("VineUA." + sd, "DEF-upper_arm." + sd, sh, el, 0.07, seed=1 + s)
        vines("VineFA." + sd, "DEF-forearm." + sd, el, wr, 0.058, seed=3 + s)
        vines("VineTh." + sd, "DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], 0.075, turns=1.2, n=8, seed=5 + s)
        vines("VineSh." + sd, "DEF-shin." + sd, J["kn" + sd], J["an" + sd], 0.062, turns=1.2, n=8, seed=7 + s)
        K.sphere("Moss." + sd, "Moss", "DEF-upper_arm." + sd, Vector(sh) + Vector((s * 0.02, 0.0, 0.05)), (0.1, 0.09, 0.05), u=12, v=6)
        w = Vector(wr)
        for k, dd in enumerate(((s * 0.2, -0.5, -1), (s * 0.6, -0.2, -1), (-s * 0.1, -0.6, -0.9))):
            K.along("Claw%d.%s" % (k, sd), "RootDark", "DEF-hand." + sd, w, w + Vector(dd).normalized() * 0.2, 0.032, 0.004, segments=6)
        an = Vector(J["an" + sd])
        for k, dd in enumerate(((s * 0.3, -1, -0.2), (s * 1, -0.3, -0.2), (0, 0.8, -0.2))):
            K.along("RootFoot%d.%s" % (k, sd), "RootDark", "DEF-foot." + sd, an, an + Vector(dd) * 0.14, 0.04, 0.008, segments=6)
        for k in range(2):
            p = Vector(el) + (Vector(wr) - Vector(el)) * (0.3 + 0.35 * k) + Vector((s * 0.05, 0.02, 0))
            K.along("Thorn%d.%s" % (k, sd), "Thorn", "DEF-forearm." + sd, p, p + Vector((s * 0.06, 0.02, 0.03)), 0.014, 0.002, segments=5)
    vines("VineChest", "DEF-chest", (0, 0, 0.5), (0, -0.05, 0.78), 0.19, turns=1.0, n=12, seed=11)
    K.sphere("BackMoss", "Moss", "DEF-chest", (0, 0.1, 0.72), (0.18, 0.12, 0.07), u=14, v=8)
    for k, (x, z) in enumerate(((0.1, 0.78), (-0.12, 0.7), (0.0, 0.62))):
        K.along("BackThorn%d" % k, "Thorn", "DEF-chest", (x, 0.13, z), (x * 1.3, 0.24, z + 0.06), 0.02, 0.002, segments=5)
    c = Vector(P["head_c"])
    K.sphere("Head", "Root", "DEF-head", c, P["head_r"], u=16, v=10)
    K.sphere("Hollow", "Hollow", "DEF-head", c + Vector((0, -0.09, -0.01)), (0.09, 0.06, 0.09), u=12, v=8)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", c + Vector((s * 0.035, -0.135, 0.03)), (0.022, 0.01, 0.018), u=8, v=4,
                 rotation=(0, math.radians(-20) * s, 0))
        pts = [c + Vector((s * 0.07, 0.02, 0.09))]
        for k, dd in enumerate(((s * 0.06, 0.03, 0.08), (s * 0.04, 0.05, 0.07), (s * 0.05, 0.02, 0.05))):
            pts.append(pts[-1] + Vector(dd))
        for k, (a, b) in enumerate(zip(pts, pts[1:])):
            K.along("Antler%d%s" % (k, sd), "RootDark", "DEF-head", a, b, 0.022 - 0.005 * k, 0.017 - 0.005 * k, segments=6)
        K.along("AntlerTwig" + sd, "RootDark", "DEF-head", pts[1], pts[1] + Vector((s * -0.02, -0.04, 0.07)), 0.012, 0.003, segments=5)
    for k, x in enumerate((-0.04, 0.0, 0.04)):
        K.along("Fang%d" % k, "Thorn", "DEF-head", c + Vector((x, -0.13, -0.05)), c + Vector((x, -0.14, -0.085)), 0.012, 0.002, segments=4)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=14, arm_out=10)
    BP.run(arm, lean=18, stride=24, arm_swing=20)
    BP.attack(arm, "sweep")
    BP.die(arm)
