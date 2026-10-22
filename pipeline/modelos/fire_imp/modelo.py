"""CR_FireImp — "Diabrete de Fogo" (no portrait: designed from game_data — runner, yellow-orange ffb03a,
burns on touch; born from a magma slime). Not a devil like the ember imp: a living fireball on stubby
charcoal limbs, a crest of yellow flame, big dark eyes and a wide grin, glowing embers for hands and
feet. Biped, small. H 0.9.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CR_FireImp"
ATAQUE_QUADRO = 8
PALETA = {"Fire": "FF9A2A", "FireLight": "FFD24A", "FireDeep": "FF6A1A", "Coal": "2E2424", "Ember": "FF7A2A",
          "Eye": "2A1408", "Glint": "FFFFFF", "Mouth": "5A1A08"}
BRILHO = ("Fire", "FireLight", "FireDeep", "Ember")

P = BP.hero(hunch=0.0, head_c=(0, -0.02, 0.56), head_r=(0.2, 0.18, 0.2), neck0_z=0.42, neck1_z=0.46,
            chest_z=0.38, waist_z=0.32, pelvis_z=0.27, shoulder_z=0.42, shoulder_x=0.12, elbow_out=0.05, elbow_z=0.33,
            wrist_x=0.21, wrist_z=0.26, wrist_y=-0.04, hand_bottom=0.19, hand_size=0.08,
            hip_x=0.06, hip_z=0.25, knee_x=0.075, knee_z=0.14, ankle_x=0.085, ankle_z=0.07, foot_len=0.13,
            r_chest=(0.09, 0.07), r_waist=(0.07, 0.055), r_pelvis=(0.075, 0.055), r_shoulder=0.032, r_elbow=0.026,
            r_wrist=0.024, r_hip=0.038, r_knee=0.032, r_ankle=0.028)


def pecas():
    J = BP.body("Body", P, role="Coal")
    BP.hands("", J, P, role="Ember", style="fist", size=0.7)
    BP.feet("", J, P, role="Ember", style="shoe", size=0.85)
    c = Vector(P["head_c"])
    K.sphere("Ball", "Fire", "DEF-head", c, P["head_r"], u=20, v=14)
    K.sphere("Core", "FireLight", "DEF-head", c + Vector((0, -0.1, -0.04)), (0.13, 0.08, 0.12), u=14, v=8)
    flames = [((0, 0.2, 1), 0.3, 0.12, "FireLight"), ((-0.5, 0.3, 0.8), 0.24, 0.1, "Fire"), ((0.5, 0.3, 0.8), 0.24, 0.1, "Fire"),
              ((0, 0.8, 0.6), 0.26, 0.1, "FireDeep"), ((-0.8, 0.4, 0.3), 0.18, 0.08, "FireDeep"), ((0.8, 0.4, 0.3), 0.18, 0.08, "FireDeep")]
    for i, (d, ln, w, role) in enumerate(flames):
        d = Vector(d).normalized()
        K.lock("Flame%d" % i, role, "DEF-head", c + Vector((d.x * 0.12, d.y * 0.08, 0.1)), d, ln, w, thick=0.55, curl=0.05, rings=7, seg=8)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", c + Vector((s * 0.07, -0.16, 0.03)), (0.04, 0.02, 0.05), u=10, v=6,
                 rotation=(0, math.radians(-12) * s, 0))
        K.box("Brow" + sd, "Coal", "DEF-head", c + Vector((s * 0.07, -0.17, 0.095)), (0.07, 0.02, 0.018),
              rotation=(0, math.radians(-22) * s, 0), bevel=0.006)
        K.sphere("Glint" + sd, "Glint", "DEF-head", c + Vector((s * 0.07 + 0.012, -0.178, 0.055)), (0.012, 0.005, 0.012), u=6, v=4)
    pts = []
    for i in range(7):
        t = i / 6 * 2 - 1
        pts.append(c + Vector((t * 0.09, -0.175 + 0.03 * t * t, -0.07 + 0.04 * t * t)))
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Grin%d" % i, "Mouth", "DEF-head", a, b, 0.016, segments=6)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=4, arm_out=16)
    BP.run(arm, lean=16, stride=40, arm_swing=36)
    BP.attack(arm, "pounce")
    BP.die(arm)
