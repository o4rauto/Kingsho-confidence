"""CR_Scorpion — "Escorpião das Dunas" (no portrait: designed from game_data — runner, sand c98a3a, armour,
poison). A sand-orange scorpion with a segmented carapace, two big pincers, eight legs and a tail arching
over its back to a dark stinger dripping green venom. Bug family + claw and tail bones. H 0.7.
"""
import math
from mathutils import Vector
import kit as K
import bug as BG

NOME = "CR_Scorpion"
ATAQUE_QUADRO = 8
PALETA = {"Shell": "C98A3A", "ShellDark": "8E5A22", "Belly": "E2B070", "Sting": "3A2014", "Venom": "9BE24D",
          "Eye": "1A0E08", "Glint": "FFFFFF"}
BRILHO = ("Venom",)

LEGS = [((0.11, -0.1, 0.15), (0.3, -0.2, 0.0)), ((0.12, 0.0, 0.15), (0.33, -0.02, 0.0)),
        ((0.12, 0.1, 0.15), (0.32, 0.14, 0.0)), ((0.1, 0.19, 0.15), (0.28, 0.3, 0.0))]
TAIL = [Vector(p) for p in ((0, 0.28, 0.2), (0, 0.42, 0.3), (0, 0.48, 0.46), (0, 0.42, 0.62), (0, 0.3, 0.68))]
STING = Vector((0, 0.2, 0.6))


def pecas():
    for i, (y, r) in enumerate(((-0.08, (0.15, 0.13, 0.085)), (0.06, (0.145, 0.12, 0.08)), (0.18, (0.12, 0.1, 0.07)))):
        K.sphere("Seg%d" % i, "Shell", "DEF-body", (0, y, 0.19), r, u=16, v=10)
        K.sphere("Plate%d" % i, "ShellDark", "DEF-body", (0, y + 0.05, 0.255 - 0.006 * i), (r[0] * 0.75, 0.02, 0.02), u=10, v=4)
    K.sphere("Belly", "Belly", "DEF-body", (0, 0.04, 0.13), (0.13, 0.2, 0.05), u=14, v=8)
    hc = Vector((0, -0.2, 0.17))
    K.sphere("Head", "Shell", "DEF-head", hc, (0.1, 0.08, 0.065), u=14, v=8)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", hc + Vector((s * 0.035, -0.06, 0.035)), (0.022, 0.018, 0.022), u=8, v=6)
        K.sphere("Glint" + sd, "Glint", "DEF-head", hc + Vector((s * 0.035 + 0.006, -0.077, 0.045)), (0.006, 0.004, 0.006), u=6, v=4)
    for s, sd in ((1, "L"), (-1, "R")):
        bone = "DEF-claw." + sd
        a, b, c = Vector((s * 0.1, -0.2, 0.17)), Vector((s * 0.22, -0.3, 0.16)), Vector((s * 0.2, -0.42, 0.15))
        K.along("ClawArm0." + sd, "Shell", bone, a, b, 0.032, 0.03, segments=8)
        K.along("ClawArm1." + sd, "Shell", bone, b, c, 0.03, 0.035, segments=8)
        K.sphere("Pincer." + sd, "Shell", bone, c + Vector((0, -0.04, 0)), (0.06, 0.075, 0.045), u=12, v=8)
        K.along("FingerOut." + sd, "ShellDark", bone, c + Vector((s * 0.03, -0.09, 0)), c + Vector((s * 0.01, -0.19, 0)), 0.03, 0.004, segments=6)
        K.along("FingerIn." + sd, "ShellDark", bone, c + Vector((-s * 0.025, -0.09, 0)), c + Vector((-s * 0.01, -0.17, 0)), 0.024, 0.004, segments=6)
    for i, (hip, foot) in enumerate(LEGS):
        for s, sd in ((1, "L"), (-1, "R")):
            h, f = Vector((s * hip[0], hip[1], hip[2])), Vector((s * foot[0], foot[1], foot[2]))
            knee = h + (f - h) * 0.55 + Vector((0, 0, 0.12))
            bone = "DEF-leg%d.%s" % (i, sd)
            K.along("LegUp%d.%s" % (i, sd), "Shell", bone, h, knee, 0.022, 0.018, segments=6)
            K.along("LegLow%d.%s" % (i, sd), "ShellDark", bone, knee, f, 0.018, 0.006, segments=6)
    bones = ("DEF-tail1", "DEF-tail1", "DEF-tail2", "DEF-tail2")
    for i, (a, b) in enumerate(zip(TAIL, TAIL[1:])):
        K.sphere("TailSeg%d" % i, "Shell", bones[i], b, (0.06 - 0.006 * i,) * 3, u=12, v=8)
        K.along("TailLink%d" % i, "ShellDark", bones[i], a, b, 0.045 - 0.005 * i, segments=8)
    K.sphere("StingBulb", "Shell", "DEF-sting", TAIL[-1] + (STING - TAIL[-1]) * 0.3, (0.05, 0.05, 0.05), u=10, v=8)
    K.along("Sting", "Sting", "DEF-sting", TAIL[-1] + (STING - TAIL[-1]) * 0.4, STING, 0.03, 0.003, segments=8)
    K.sphere("VenomDrop", "Venom", "DEF-sting", STING + Vector((0, 0.0, -0.025)), (0.014, 0.014, 0.02), u=8, v=6)
    extra = [("DEF-claw.L", (0.1, -0.2, 0.17), (0.2, -0.5, 0.15), "DEF-body"),
             ("DEF-claw.R", (-0.1, -0.2, 0.17), (-0.2, -0.5, 0.15), "DEF-body"),
             ("DEF-tail1", tuple(TAIL[0]), tuple(TAIL[2]), "DEF-body"),
             ("DEF-tail2", tuple(TAIL[2]), tuple(TAIL[4]), "DEF-tail1"),
             ("DEF-sting", tuple(TAIL[4]), tuple(STING), "DEF-tail2")]
    return BG.bones((0, 0.2, 0.18), (0, -0.12, 0.2), (0, -0.14, 0.17), (0, -0.28, 0.17), LEGS, extra)


def _extra(name, t):
    w = math.sin(2 * math.pi * t)
    if name == "idle":
        return {"DEF-tail1": [("Y", 6 * w)], "DEF-tail2": [("X", 5 * w)],
                "DEF-claw.L": [("Z", 8 * w)], "DEF-claw.R": [("Z", -8 * w)]}
    if name == "run":
        return {"DEF-tail1": [("Y", 8 * w), ("X", -6)], "DEF-claw.L": [("Z", -10)], "DEF-claw.R": [("Z", 10)]}
    if name == "attack":
        k = 1.0 if 0.25 < t < 0.6 else 0.0
        wind = 1.0 if 0.1 < t <= 0.4 else 0.0
        return {"DEF-tail1": [("X", -12 * wind + 25 * k)], "DEF-tail2": [("X", -15 * wind + 35 * k)], "DEF-sting": [("X", 30 * k)],
                "DEF-claw.L": [("Z", 20 * wind)], "DEF-claw.R": [("Z", -20 * wind)]}
    return {"DEF-tail1": [("X", -30 * min(1, t * 2))], "DEF-claw.L": [("Y", -30 * t)], "DEF-claw.R": [("Y", 30 * t)]}


def animar(arm):
    BG.animate(arm, 4, stride=22, bob=0.015, flip_h=0.3, extra=_extra)
