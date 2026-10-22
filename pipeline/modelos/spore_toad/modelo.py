"""CR_SporeToad — "Sapo de Esporos" (no portrait: designed from game_data — caster, green 9be24d, heals,
haste aura). A fat warty toad squatting low, bulging yellow eyes on top of a wide flat head, pale throat
sac, and three red-capped mushrooms sprouting from its back that puff glowing spores. Quad family. H 0.6.
"""
import math
from mathutils import Vector
import kit as K
import quad as Q

NOME = "CR_SporeToad"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "7AB83A", "SkinDark": "4E8426", "Belly": "D8E8A0", "Cap": "C8402A", "Dot": "F4ECD8",
          "Stem": "EDE0C0", "Spore": "E8F070", "Eye": "F2D24A", "Pupil": "1A1408", "Mouth": "3A2A14"}
BRILHO = ("Spore",)

P = Q.params(body_z=0.24, pelvis_y=0.1, chest_y=-0.08, neck=(0, -0.17, 0.3), head=(0, -0.22, 0.32),
             tail=((0, 0.22, 0.2), (0, 0.26, 0.18)), leg_x=0.15, f_elbow=(-0.17, 0.12), f_paw=(-0.21, 0.025),
             b_hock=(0.24, 0.12), b_paw=(0.12, 0.025),
             r_pelvis=(0.12, 0.11), r_chest=(0.12, 0.11), r_neck=(0.09, 0.09), r_leg_up=0.07, r_leg_low=0.055,
             r_paw=0.055, r_tail0=(0.06, 0.06), r_tail1=(0.03, 0.03))


def pecas():
    J = Q.body("Body", P, "Skin")
    K.sphere("Belly", "Skin", "AUTO", (0, 0.02, 0.25), (0.22, 0.26, 0.17), u=22, v=14)
    hd = Vector(P["head"])
    K.sphere("Head", "Skin", "DEF-head", hd + Vector((0, -0.03, 0.0)), (0.17, 0.14, 0.1), u=18, v=10)
    K.sphere("Throat", "Belly", "DEF-head", hd + Vector((0, -0.07, -0.07)), (0.12, 0.09, 0.07), u=14, v=8)
    K.sphere("BellyPatch", "Belly", "DEF-chest", (0, -0.12, 0.17), (0.17, 0.12, 0.1), u=14, v=8)
    pts = []
    for i in range(9):
        t = i / 8 * 2 - 1
        pts.append(hd + Vector((t * 0.15, -0.15 + 0.06 * t * t, -0.02 + 0.015 * t * t)))
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Mouth%d" % i, "Mouth", "DEF-head", a, b, 0.012, segments=6)
    for s, sd in ((1, ".L"), (-1, ".R")):
        e = hd + Vector((s * 0.09, -0.05, 0.08))
        K.sphere("EyeBump" + sd, "Skin", "DEF-head", e, (0.06, 0.06, 0.055), u=12, v=8)
        K.sphere("Eye" + sd, "Eye", "DEF-head", e + Vector((0, -0.03, 0.01)), (0.045, 0.04, 0.042), u=12, v=8)
        K.sphere("Pupil" + sd, "Pupil", "DEF-head", e + Vector((0, -0.068, 0.012)), (0.03, 0.008, 0.012), u=8, v=4)
    for i, (x, y, z) in enumerate(((0.12, 0.05, 0.36), (-0.1, 0.12, 0.35), (0.05, -0.05, 0.4), (-0.14, -0.04, 0.3),
                                      (0.15, 0.16, 0.3), (0.0, 0.2, 0.36))):
        K.sphere("Wart%d" % i, "SkinDark", "DEF-pelvis" if y > 0.05 else "DEF-chest", (x, y, z), (0.025, 0.025, 0.018), u=8, v=5)
    for i, (x, y, h, r) in enumerate(((0.0, 0.08, 0.2, 0.11), (0.12, 0.14, 0.13, 0.075), (-0.11, 0.0, 0.15, 0.08))):
        base = Vector((x, y, 0.36))
        top = base + Vector((x * 0.3, 0.02, h))
        bone = "DEF-pelvis" if y > 0.05 else "DEF-chest"
        K.along("Stem%d" % i, "Stem", bone, base, top, r * 0.32, r * 0.26, segments=8)
        K.dome("Cap%d" % i, "Cap", bone, top - Vector((0, 0, 0.02)), (r, r, r * 0.7), cut=-0.15, u=16, v=8)
        for k in range(4):
            a = math.radians(90 * k + 30 * i)
            K.sphere("Dot%d%d" % (i, k), "Dot", bone, top + Vector((math.cos(a) * r * 0.6, math.sin(a) * r * 0.6, r * 0.42)),
                     (r * 0.16, r * 0.16, r * 0.08), u=6, v=4)
        K.sphere("Spore%d" % i, "Spore", bone, top + Vector((r * 0.5, -0.02, r * 0.95)), (0.022, 0.022, 0.022), u=6, v=4)
    for s, sd in ((1, "L"), (-1, "R")):
        for fb in ("f", "b"):
            paw = Vector(J[fb + "p" + sd])
            for k, dx in enumerate((-0.04, 0.0, 0.04)):
                K.sphere("Toe%s%d.%s" % (fb, k, sd), "Skin", "DEF-leg_%s_paw.%s" % (fb, sd), paw + Vector((dx * 1.2 + s * 0.02, -0.06, -0.012)),
                         (0.022, 0.035, 0.014), u=8, v=5)
    return Q.bones(J, P)


def animar(arm):
    Q.animate(arm, stride=18)
