"""CR_BogMother — boss "Mãe do Pântano": an old swamp witch, hunched, green warty skin, long hooked
nose, stringy grey hair, tall crooked purple hat with a brown band and buckle, ragged olive robe with
dark spots, purple bead necklace, and a gnarled staff curling into a spiral. Ref: portraits/bog_mother.png.
Biped (hunched, robe). H 1.4.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_BogMother"
ATAQUE_QUADRO = 10
PALETA = {"Skin": "8AAE3A", "SkinDark": "62862A", "Hair": "A8A8A0", "Hat": "6A3A9A", "HatDark": "4A2470",
          "Band": "6B4426", "Buckle": ("D8A030", 0.4, 0.5), "Robe": "6A6A2E", "RobeDark": "4A4A1E", "Bead": "9A4AC8",
          "Wood": "6B4A2A", "Eye": "F2E26A", "Pupil": "1A1408", "Mouth": "3A1A1A", "Tooth": "E8DCB0"}

P = BP.params(hunch=0.12, head_c=(0, -0.16, 0.9), head_r=(0.13, 0.12, 0.14), neck0_z=0.76, neck1_z=0.8,
              chest_z=0.66, waist_z=0.52, pelvis_z=0.42, shoulder_z=0.72, shoulder_x=0.15, elbow_out=0.08, elbow_z=0.56,
              wrist_x=0.27, wrist_z=0.48, wrist_y=-0.12, hand_bottom=0.4, hand_size=0.1,
              hip_x=0.08, hip_z=0.38, knee_x=0.1, knee_y=-0.04, knee_z=0.2, ankle_x=0.11, ankle_z=0.07, foot_len=0.18,
              r_pelvis=(0.15, 0.11), r_waist=(0.13, 0.1), r_chest=(0.16, 0.12), r_neck0=(0.06, 0.055), r_neck1=(0.055, 0.05),
              r_shoulder=0.05, r_elbow=0.04, r_wrist=0.034, r_hip=0.065, r_knee=0.05, r_ankle=0.042)


def head(hc, hr):
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, c.z + 0.02, 0.05, size=(0.034, 0.016, 0.026), slant=-10, pupils=0.014)
    K.along("Nose", "Skin", "DEF-head", c + Vector((0, -0.11, 0.0)), c + Vector((0, -0.22, -0.05)), 0.035, 0.012, segments=10)
    K.sphere("NoseTip", "SkinDark", "DEF-head", c + Vector((0, -0.225, -0.06)), (0.018, 0.018, 0.018), u=8, v=5)
    K.sphere("Wart", "SkinDark", "DEF-head", c + Vector((0.04, -0.17, -0.02)), (0.012, 0.012, 0.012), u=6, v=4)
    K.sphere("Chin", "Skin", "DEF-head", c + Vector((0, -0.08, -0.12)), (0.06, 0.05, 0.045), u=10, v=6)
    K.sphere("Mouth", "Mouth", "DEF-head", c + Vector((0, -0.12, -0.075)), (0.05, 0.012, 0.012), u=10, v=4)
    K.along("Tooth", "Tooth", "DEF-head", c + Vector((0.02, -0.127, -0.07)), c + Vector((0.021, -0.13, -0.095)), 0.01, 0.003, segments=4)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.box("Brow" + sd, "SkinDark", "DEF-head", (s * 0.05, c.y - 0.11, c.z + 0.065), (0.06, 0.02, 0.016),
              rotation=(0, math.radians(-18) * s, 0), bevel=0.005)
        for k, (dx, ln) in enumerate(((0.0, 0.34), (0.04, 0.3), (-0.03, 0.26))):
            K.lock("Hair%d%s" % (k, sd), "Hair", "DEF-head", c + Vector((s * (0.11 + dx * 0.3), 0.03 + dx, 0.03)),
                   (s * 0.25, 0.25 + dx * 3, -1), ln, 0.05, thick=0.35, rings=7, seg=7)
    K.lock("HairBack", "Hair", "DEF-head", c + Vector((0, 0.1, 0.03)), (0, 0.4, -1), 0.36, 0.09, thick=0.35, rings=7, seg=7)
    # tall crooked hat
    brim = c + Vector((0, 0.01, 0.07))
    K.cone("Brim", "Hat", "DEF-head", brim, 0.27, 0.25, 0.025, segments=24, rotation=(math.radians(-6), 0, 0))
    K.cone("Crown", "Hat", "DEF-head", brim + Vector((0, 0.02, 0.1)), 0.15, 0.1, 0.18, segments=18)
    K.band("HatBand", "Band", "DEF-head", brim + Vector((0, 0.0, 0.045)), 0.148, 0.148, 0.045)
    K.box("HatBuckle", "Buckle", "DEF-head", brim + Vector((0, -0.152, 0.045)), (0.05, 0.012, 0.04), bevel=0.005)
    pts = [brim + Vector((0, 0.03, 0.19))]
    for k, dd in enumerate(((0.0, 0.03, 0.1), (0.02, 0.06, 0.08), (0.03, 0.09, 0.04), (0.02, 0.08, -0.03))):
        pts.append(pts[-1] + Vector(dd))
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("HatTip%d" % k, "Hat" if k < 3 else "HatDark", "DEF-head", a, b, 0.1 - 0.024 * k, 0.078 - 0.022 * k, segments=12)


def robes(J):
    BP.robe("Robe", top_z=0.54, hem_z=0.02, top_r=0.14, hem_r=0.27, trim_role="RobeDark", ragged=0.05)
    K.sphere("Shawl", "RobeDark", "DEF-chest", (0, -0.03, 0.7), (0.19, 0.15, 0.07), u=16, v=8)
    for i, (x, y, z) in enumerate(((0.12, -0.2, 0.3), (-0.15, -0.18, 0.2), (0.05, -0.22, 0.12), (-0.08, -0.15, 0.4), (0.18, -0.08, 0.1))):
        K.sphere("Spot%d" % i, "RobeDark", "AUTO", (x, y, z), (0.03, 0.012, 0.03), u=8, v=4)
    for i in range(9):
        a = math.radians(-70 + 17.5 * i)
        p = Vector((math.sin(a) * 0.1, -math.cos(a) * 0.1 - 0.06, 0.73 - 0.035 * math.cos(a)))
        K.sphere("Bead%d" % i, "Bead", "DEF-chest", p, (0.016, 0.016, 0.016), u=8, v=5)
    for s, sd in ((1, "L"), (-1, "R")):
        K.along("Sleeve." + sd, "Robe", "DEF-forearm." + sd, J["el" + sd], J["wr" + sd], 0.045, 0.075, 0.0, 0.95, segments=12)
    hx, hy, hz = J["wrR"]
    base, top = Vector((hx - 0.01, hy - 0.04, 0.03)), Vector((hx - 0.02, hy - 0.05, 1.05))
    pts = [base + (top - base) * (i / 6) + Vector((0.015 * math.sin(i * 1.7), 0.01 * math.cos(i * 2.3), 0)) for i in range(7)]
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Staff%d" % i, "Wood", "DEF-hand.R", a, b, 0.02, 0.018, segments=8)
    spiral = []
    for k in range(10):   # the staff top curls into a spiral
        a = math.radians(40 * k)
        r = 0.09 - 0.007 * k
        spiral.append(top + Vector((-math.sin(a) * r * 0.9 + 0.0, 0, (1 - math.cos(a)) * r * 0.9)))
    for k, (a, b) in enumerate(zip(spiral, spiral[1:])):
        K.along("Curl%d" % k, "Wood", "DEF-hand.R", a, b, 0.018 - 0.001 * k, 0.017 - 0.001 * k, segments=8)


def pecas():
    J = BP.body("Body", P, role="Robe")
    BP.hands("", J, P, role="Skin", style="mitt3", size=0.85)
    BP.feet("", J, P, role="RobeDark", style="shoe", size=1.0)
    head(P["head_c"], P["head_r"])
    robes(J)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=14, arm_out=6)
    BP.run(arm, lean=18, stride=24, arm_swing=14, hold_right=True)
    BP.attack(arm, "hammer")
    BP.cast(arm, "summon")
    BP.die(arm)
