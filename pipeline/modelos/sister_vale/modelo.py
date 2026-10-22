"""CH_SisterVale — "Irmã Vale": angelic healer, long blonde hair, gold circlet, white robe with a blue
panel and gold trims, golden wings, golden staff with a blue crystal. Ref: portraits/sister_vale.png. H 1.2.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_SisterVale"
ATAQUE_QUADRO = 13
PALETA = {"Skin": "F2C6A2", "Hair": "F2CB5A", "HairLight": "F8DE8A", "Robe": "F2F2F4", "Blue": "4A86C8",
          "Gold": ("E3B23A", 0.4, 0.4), "Wing": "F0C24A", "WingLight": "F8DC80", "Eye": "F4F4F4", "Pupil": "2E78C8",
          "Brow": "C89A3A", "Mouth": "C06A5A", "Crystal": ("8AD8FF", 0.2, 0.0), "Shine": "FFFFFF"}
BRILHO = ("Crystal",)

P = BP.hero(r_chest=(0.1, 0.07))


def head(hc, hr):
    c = Vector(hc)
    BP.chibi_face(hc, hr, 0.738, eye_dx=0.064, eye_size=(0.046, 0.02, 0.054), pupil=0.03, slant=0,
                  brow_role="Brow", brow_tilt=-4, shine_role="Shine")
    K.sphere("HairCap", "Hair", "DEF-head", c + Vector((0, 0.015, 0.045)), (0.16, 0.15, 0.152), u=16, v=10)
    K.sphere("HairBack", "Hair", "DEF-head", c + Vector((0, 0.07, -0.08)), (0.16, 0.1, 0.2), u=14, v=10)
    for s in (1, -1):
        for j in range(2):
            K.lock("Lock%d%d" % (s > 0, j), "HairLight" if j else "Hair", "DEF-head",
                   c + Vector((s * (0.12 + 0.02 * j), 0.0 + 0.04 * j, -0.02)), (s * 0.15, 0.1, -1), 0.24, 0.055, thick=0.5)
    for i, (x, d) in enumerate(((-0.07, (-0.6, -0.6, -0.6)), (0.07, (0.6, -0.6, -0.6)))):
        K.lock("Fringe%d" % i, "Hair", "DEF-head", c + Vector((x * 0.4, -0.12, 0.12)), d, 0.1, 0.055, thick=0.4)
    K.band("Circlet", "Gold", "DEF-head", c + Vector((0, 0.005, 0.07)), 0.157, 0.147, 0.022, z_tilt=0.12)
    K.sphere("CircletGem", "Crystal", "DEF-head", (0, c.y - 0.155, c.z + 0.06), (0.014, 0.008, 0.02), u=8, v=5)


def robe(J):
    K.sphere("Bodice", "Robe", "DEF-chest", (0, -0.02, 0.46), (0.105, 0.078, 0.09), u=14, v=8)
    BP.robe("Robe", top_z=0.40, hem_z=0.03, top_r=0.095, hem_r=0.19, trim_role="Gold")
    K.box("Panel", "Blue", "DEF-pelvis", (0, -0.12, 0.2), (0.07, 0.012, 0.32), rotation=(math.radians(-14), 0, 0))
    K.band("Belt", "Gold", "DEF-pelvis", (0, 0, 0.38), 0.098, 0.074, 0.03)
    K.sphere("Collar", "Blue", "DEF-chest", (0, -0.04, 0.53), (0.075, 0.05, 0.025), u=12, v=6)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Sleeve." + sd, "Robe", "DEF-forearm." + sd, J["el" + sd], J["wr" + sd], 0.035, 0.055, 0.0, 1.0, segments=12)
        K.band("Cuff." + sd, "Gold", "DEF-forearm." + sd, Vector(J["wr" + sd]) + Vector((0, 0, 0.01)), 0.056, 0.056, 0.015)


def wings():
    for s, sd in ((1, ".L"), (-1, ".R")):
        root = Vector((s * 0.05, 0.08, 0.5))
        feathers = [((s * 0.6, 0.35, 0.8), 0.34, 0.09), ((s * 0.8, 0.4, 0.45), 0.36, 0.085), ((s * 0.9, 0.45, 0.1), 0.32, 0.08),
                    ((s * 0.85, 0.45, -0.25), 0.26, 0.07), ((s * 0.45, 0.4, 0.95), 0.3, 0.08)]
        for i, (d, ln, w) in enumerate(feathers):
            K.lock("Wing%s%d" % (sd, i), "WingLight" if i % 2 else "Wing", "DEF-chest", root, d, ln, w, thick=0.3, curl=0.06)


def staff(J):
    hx, hy, hz = J["wrR"]
    base, top = Vector((hx - 0.01, hy - 0.04, 0.03)), Vector((hx - 0.01, hy - 0.04, 0.78))
    BP.staff("DEF-hand.R", base, top, role="Gold", r=0.013)
    K.lathe("StaffHead", "Gold", "DEF-hand.R", top, [(0.012, 0.0), (0.035, 0.02), (0.03, 0.05), (0.01, 0.07)])
    K.sphere("Crystal", "Crystal", "DEF-hand.R", top + Vector((0, 0, 0.07)), (0.026, 0.026, 0.05), u=6, v=4)


def pecas():
    J = BP.body("Body", P, role="Robe")
    BP.hands("", J, P, role="Skin", style="fist", size=0.75)
    BP.feet("", J, P, role="Gold", style="shoe", size=0.8)
    head(P["head_c"], P["head_r"])
    robe(J)
    wings()
    staff(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=2, arm_out=4)
    BP.run(arm, lean=10, stride=28, arm_swing=20, hold_right=True)
    BP.attack(arm, "cast")
    BP.die(arm)
