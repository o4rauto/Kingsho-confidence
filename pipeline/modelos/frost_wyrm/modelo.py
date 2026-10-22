"""CR_FrostWyrm — boss "Serpe Gélida": an ice-blue dragon with a long raised neck, back-swept horns, a
toothy snout, ice-crystal spines down the back, pale belly scales, bat wings of frosted membrane and a
long tail ending in a crystal fin. Ref: portraits/frost_wyrm.png. Quad family + one bone per wing. H 1.3.
"""
import math
from mathutils import Vector, Euler
import kit as K
import quad as Q

NOME = "CR_FrostWyrm"
ATAQUE_QUADRO = 8
PALETA = {"Scale": "6AB8E0", "ScaleDark": "3A88B8", "Belly": "C4EAF8", "Wing": "A8DCF4", "WingBone": "4A98C8",
          "Crystal": "E2F8FF", "Horn": "EAF6FF", "Eye": "B8F4FF", "Tooth": "FFFFFF", "Mouth": "1A2A4A"}
BRILHO = ("Eye", "Crystal")

P = Q.params(body_z=0.44, pelvis_y=0.26, chest_y=-0.16, neck=(0, -0.4, 0.9), head=(0, -0.5, 1.02),
             tail=((0, 0.58, 0.36), (0, 0.92, 0.2)), leg_x=0.15, f_elbow=(-0.2, 0.2), f_paw=(-0.24, 0.035),
             b_hock=(0.38, 0.2), b_paw=(0.32, 0.035),
             r_pelvis=(0.19, 0.2), r_chest=(0.21, 0.22), r_neck=(0.09, 0.09), r_leg_up=0.095, r_leg_low=0.07,
             r_paw=0.075, r_tail0=(0.11, 0.11), r_tail1=(0.065, 0.065))

WING = [(x * 1.5, z * 1.5) for x, z in ((0.0, -0.02), (0.06, 0.14), (0.16, 0.3), (0.3, 0.44), (0.45, 0.52), (0.56, 0.5),
                                         (0.5, 0.38), (0.47, 0.26), (0.38, 0.2), (0.3, 0.1), (0.18, 0.05), (0.08, -0.02))]
WING_ROT = math.radians(-40)


def _wing_root(s):
    return Vector((s * 0.1, -0.12, 0.66))


def _wing_m(s):
    return Euler((WING_ROT, 0, s * math.radians(15))).to_matrix()


def head():
    hd = Vector(P["head"])
    K.sphere("Skull", "Scale", "DEF-head", hd, (0.12, 0.14, 0.11), u=16, v=10)
    K.along("Snout", "Scale", "DEF-head", hd + Vector((0, -0.06, 0.0)), hd + Vector((0, -0.28, -0.03)), 0.09, 0.06, segments=12)
    K.sphere("NoseTip", "Scale", "DEF-head", hd + Vector((0, -0.28, -0.03)), (0.062, 0.05, 0.05), u=12, v=8)
    K.along("Jaw", "ScaleDark", "DEF-head", hd + Vector((0, -0.04, -0.06)), hd + Vector((0, -0.26, -0.08)), 0.07, 0.04, segments=10)
    K.sphere("MouthLine", "Mouth", "DEF-head", hd + Vector((0, -0.16, -0.045)), (0.05, 0.08, 0.012), u=10, v=4)
    for i in range(4):
        y = -0.1 - 0.035 * i
        for s in (1, -1):
            K.along("Tooth%d%d" % (i, s > 0), "Tooth", "DEF-head", hd + Vector((s * 0.045, y, -0.035)),
                    hd + Vector((s * 0.047, y, -0.07)), 0.011, 0.002, segments=5)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", hd + Vector((s * 0.065, -0.07, 0.04)), (0.026, 0.03, 0.02), u=8, v=6,
                 rotation=(0, 0, math.radians(-20) * s))
        K.sphere("Brow" + sd, "ScaleDark", "DEF-head", hd + Vector((s * 0.06, -0.06, 0.07)), (0.04, 0.05, 0.02), u=8, v=5)
        K.sphere("Nostril" + sd, "Mouth", "DEF-head", hd + Vector((s * 0.025, -0.32, 0.0)), (0.01, 0.01, 0.008), u=6, v=4)
        pts = [hd + Vector((s * 0.06, 0.02, 0.06))]
        for k in range(1, 5):   # horns sweep back and curl up at the tip
            pts.append(pts[0] + Vector((s * 0.03 * k, 0.08 * k, 0.015 * k + 0.006 * k * k)))
        for k, (a, b) in enumerate(zip(pts, pts[1:])):
            K.along("Horn%d%s" % (k, sd), "Horn", "DEF-head", a, b, 0.04 - 0.008 * k, 0.033 - 0.008 * k, segments=8)
        K.lock("Fin" + sd, "Crystal", "DEF-head", hd + Vector((s * 0.09, 0.0, 0.0)), (s * 1, 0.6, 0.1), 0.1, 0.05, thick=0.3)


def spines(J):
    chain = [(Vector(P["neck"]), "DEF-neck"), (Vector(J["chest"]) + Vector((0, 0, 0.17)), "DEF-chest"),
             (Vector(J["pelvis"]) + Vector((0, -0.06, 0.18)), "DEF-pelvis"), (Vector(J["pelvis"]) + Vector((0, 0.12, 0.17)), "DEF-pelvis"),
             (Vector(J["tail0"]) + Vector((0, 0, 0.09)), "DEF-tail1"), (Vector(J["tail1"]) + Vector((0, 0, 0.05)), "DEF-tail2")]
    for i, (p, bone) in enumerate(chain):
        K.lock("Spine%d" % i, "Crystal", bone, p + Vector((0, 0.02, 0.0)), (0, 0.5, 1), 0.14 - 0.012 * i, 0.06, thick=0.35, curl=0.0)
    n0, n1 = Vector(J["chest"]), Vector(P["neck"])
    for i in range(3):   # neck spines between chest and head
        p = n0 + (n1 - n0) * (0.3 + 0.25 * i) + Vector((0, 0.06, 0.04))
        K.lock("NeckSpine%d" % i, "Crystal", "DEF-chest" if i == 0 else "DEF-neck", p, (0, 0.7, 0.8), 0.1, 0.045, thick=0.35, curl=0.0)
        K.sphere("NeckBelly%d" % i, "Belly", "DEF-chest" if i == 0 else "DEF-neck", n0 + (n1 - n0) * (0.25 + 0.25 * i) + Vector((0, -0.06, -0.01)),
                 (0.07, 0.04, 0.06), u=10, v=6)
    K.sphere("Belly", "Belly", "DEF-chest", Vector(J["chest"]) + Vector((0, -0.05, -0.08)), (0.15, 0.16, 0.12), u=14, v=8)
    t1 = Vector(J["tail1"])
    tip = t1 + Vector((0.12, 0.26, -0.1))
    K.along("TailTip", "Scale", "DEF-tail2", t1, tip, 0.065, 0.025, segments=10)
    K.lock("TailFin", "Crystal", "DEF-tail2", tip, (0, 0.6, 0.6), 0.16, 0.09, thick=0.3, curl=0.0)


def wings():
    for s, sd in ((1, "L"), (-1, "R")):
        root, m = _wing_root(s), _wing_m(s)
        outline = [(s * x, z) for x, z in WING]
        if s < 0:
            outline.reverse()
        K.plate("Wing." + sd, "Wing", "DEF-wing." + sd, root, outline, thickness=0.014,
                rotation=(WING_ROT, 0, s * math.radians(15)))
        for k in (3, 4, 6, 8):
            x, z = WING[k]
            K.along("WingBone%d.%s" % (k, sd), "WingBone", "DEF-wing." + sd, root, root + m @ Vector((s * x, -0.012, z)),
                    0.022 if k == 4 else 0.014, 0.006, segments=6)
        K.sphere("WingJoint." + sd, "WingBone", "DEF-wing." + sd, root, (0.05, 0.05, 0.05), u=10, v=6)


def pecas():
    J = Q.body("Body", P, "Scale")
    head()
    spines(J)
    wings()
    for s, sd in ((1, "L"), (-1, "R")):
        for fb in ("f", "b"):
            paw = Vector(J[fb + "p" + sd])
            for k, dx in enumerate((-0.035, 0.0, 0.035)):
                K.along("Claw%s%d.%s" % (fb, k, sd), "Horn", "DEF-leg_%s_paw.%s" % (fb, sd), paw + Vector((dx, -0.04, -0.01)),
                        paw + Vector((dx * 1.3, -0.1, -0.025)), 0.016, 0.003, segments=5)
    B = Q.bones(J, P)
    for s, sd in ((1, "L"), (-1, "R")):
        root = _wing_root(s)
        B.append(("DEF-wing." + sd, tuple(root), tuple(root + _wing_m(s) @ Vector((s * 0.68, 0, 0.75))), "DEF-chest"))
    return B


def _wings(name, t):
    if name == "idle":
        a = 12 * math.sin(2 * math.pi * t)
    elif name == "run":
        a = 28 * math.sin(2 * math.pi * t)
    elif name == "attack":
        a = -35 if 0.2 < t < 0.5 else (20 if t >= 0.5 and t < 0.9 else 0)
    else:
        a = 45 * min(1.0, t * 2)
    return {"DEF-wing.L": [("Y", a)], "DEF-wing.R": [("Y", -a)]}


def animar(arm):
    Q.animate(arm, stride=26, extra=_wings)
