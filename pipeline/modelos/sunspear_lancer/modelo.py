"""CH_SunspearLancer — "Lanceiro do Sol": golden spartan, crested Corinthian helmet (red crest), golden
armour, long spear, round golden shield with a sun emblem. Ref: portraits/sunspear_lancer.png. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_SunspearLancer"
ATAQUE_QUADRO = 8
PALETA = {"Skin": "D99A6A", "Gold": ("E8B030", 0.4, 0.45), "GoldDark": ("B8821E", 0.45, 0.4), "Crest": "D8381E",
          "Eye": "F4F0E8", "Pupil": "6A3A1A", "Brow": "4A2A14", "Mouth": "8A3A2A", "Leather": "6B4426",
          "Wood": "7A4A26", "Steel": ("C8CED6", 0.4, 0.5), "Sun": ("F8D040", 0.35, 0.3)}

P = BP.hero(r_chest=(0.115, 0.08), r_shoulder=0.042)


def helmet(hc, hr):
    c = Vector(hc)
    BP.chibi_face(hc, hr, 0.735, eye_dx=0.058, eye_size=(0.034, 0.016, 0.03), pupil=0.02, slant=-12,
                  brow_role="Brow", brow_tilt=20, chin=True)
    K.dome("Helm", "Gold", "DEF-head", c + Vector((0, 0.01, -0.02)), (0.168, 0.16, 0.2), cut=-0.5, u=24, v=14, face_open=(0.4, 0.42))
    for s in (1, -1):
        K.box("Cheek%d" % (s > 0), "Gold", "DEF-head", (s * 0.11, c.y - 0.1, 0.68), (0.05, 0.06, 0.14),
              rotation=(0, 0, math.radians(30) * s), bevel=0.012)
    K.box("NoseGuard", "GoldDark", "DEF-head", (0, c.y - 0.16, 0.76), (0.025, 0.02, 0.08), bevel=0.006)
    for i in range(9):   # crest: a fan of red locks front to back
        t = i / 8
        root = c + Vector((0, -0.08 + 0.2 * t, 0.17 - 0.02 * abs(t - 0.5)))
        K.lock("Crest%d" % i, "Crest", "DEF-head", root, (0, -0.4 + 1.1 * t, 1), 0.16 + 0.05 * math.sin(t * math.pi), 0.05,
               thick=0.35, curl=0.03)


def armour(J):
    K.sphere("Cuirass", "Gold", "DEF-chest", (0, -0.03, 0.465), (0.12, 0.088, 0.09), u=16, v=10)
    K.sphere("Abs", "GoldDark", "DEF-spine", (0, -0.06, 0.4), (0.08, 0.04, 0.04), u=10, v=6)
    K.skirt("Pteruges", "GoldDark", "AUTO", 0.37, 0.24, 0.1, 0.12, ragged=0.025, side_lift=0.02, thickness=0.012)
    K.band("Belt", "Leather", "DEF-pelvis", (0, 0, 0.37), 0.104, 0.078, 0.03)
    for s, sd in ((1, "L"), (-1, "R")):
        sh = Vector(J["sh" + sd])
        K.dome("Pauldron." + sd, "Gold", "DEF-upper_arm." + sd, sh + Vector((s * 0.015, 0, 0)), (0.064, 0.064, 0.05))
        K.along("Bracer." + sd, "Gold", "DEF-forearm." + sd, J["wr" + sd], J["el" + sd], 0.036, 0.034, 0.0, 0.6, segments=10)
        K.along("Greave." + sd, "Gold", "DEF-shin." + sd, J["an" + sd], J["kn" + sd], 0.045, 0.047, 0.0, 0.9, segments=10)


def spear(J):
    hx, hy, hz = J["wrR"]
    base, top = Vector((hx - 0.01, hy - 0.04, 0.02)), Vector((hx - 0.01, hy - 0.04, 0.95))
    K.along("Shaft", "Wood", "DEF-hand.R", base, top, 0.012, segments=8)
    K.along("SpearHead", "Steel", "DEF-hand.R", top, top + Vector((0, 0, 0.14)), 0.03, 0.002, segments=4)
    K.band("SpearCollar", "Gold", "DEF-hand.R", top, 0.016, 0.016, 0.02)


def shield(J):
    hx, hy, hz = J["wrL"]
    c = Vector((hx + 0.04, hy - 0.07, 0.35))
    rot = (0, 0, math.radians(28))
    K.cone("Shield", "Gold", "DEF-forearm.L", c, 0.14, 0.14, 0.03, axis="Y", segments=24, rotation=rot)
    K.sphere("SunBoss", "Sun", "DEF-forearm.L", c + Vector((-0.008, -0.018, 0)), (0.05, 0.02, 0.05), u=12, v=6, rotation=rot)
    for i in range(8):
        a = 2 * math.pi * i / 8
        p = c + Vector((math.cos(a) * 0.085 * math.cos(math.radians(28)), -0.02 - math.cos(a) * 0.085 * math.sin(math.radians(28)), math.sin(a) * 0.085))
        K.sphere("Ray%d" % i, "GoldDark", "DEF-forearm.L", p, (0.018, 0.01, 0.018), u=4, v=3)


def pecas():
    J = BP.body("Body", P, role="Leather")
    BP.hands("", J, P, role="Skin", style="fist", size=0.85)
    BP.feet("", J, P, role="Gold", style="boot", size=0.9)
    helmet(P["head_c"], P["head_r"])
    armour(J)
    spear(J)
    shield(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=5)
    BP.run(arm, lean=12, stride=34, arm_swing=22, hold_right=True)
    BP.attack(arm, "spear")
    BP.cast(arm, "throw")
    BP.die(arm)
