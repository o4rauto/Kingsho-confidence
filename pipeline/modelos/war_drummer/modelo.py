"""CH_WarDrummer — "Tamboreiro da Debandada" (no portrait: designed from game_data — caster, colour c8642a).
A stocky horde goblin with war paint, a feather headband, bone necklace and a big orange war drum on the
belly, beating it with two bone sticks. Same chibi goblin family as the husk. H 1.15.
"""
import math
from mathutils import Vector
import kit as K
import biped as BP

NOME = "CH_WarDrummer"
ATAQUE_QUADRO = 11
PALETA = {"Skin": "7A9A3A", "SkinDark": "5A7A28", "Drum": "C8642A", "DrumHead": "EADBB8", "Leather": "5A3A20",
          "Bone": "EFE6CF", "Paint": "D83A2A", "Feather": "E8E2D2", "FeatherTip": "C8642A", "Eye": "F2E2A0",
          "Pupil": "2A1A0A", "Mouth": "4A1410", "Cloth": "7A5A30"}

P = BP.hero(hunch=0.04, head_c=(0, -0.07, 0.72), head_r=(0.15, 0.14, 0.15), neck0_z=0.53, neck1_z=0.58,
            chest_z=0.46, waist_z=0.38, pelvis_z=0.31, shoulder_z=0.51, shoulder_x=0.12, elbow_z=0.4,
            wrist_x=0.2, wrist_z=0.33, wrist_y=-0.09, hand_bottom=0.26, hand_size=0.09,
            r_chest=(0.12, 0.09), r_waist=(0.11, 0.09), r_pelvis=(0.11, 0.08), r_shoulder=0.042, r_elbow=0.032,
            r_wrist=0.032, r_hip=0.052, r_knee=0.042, r_ankle=0.036)


def pecas():
    J = BP.body("Body", P, role="Skin")
    BP.hands("", J, P, role="Skin", style="fist", size=0.85)
    BP.feet("", J, P, role="Skin", style="toes3", size=0.85)
    hc, hr = P["head_c"], P["head_r"]
    c = Vector(hc)
    K.sphere("Head", "Skin", "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, 0.73, 0.058, size=(0.038, 0.016, 0.026), slant=-18, pupils=0.014)
    K.sphere("Nose", "SkinDark", "DEF-head", (0, c.y - 0.16, 0.69), (0.03, 0.035, 0.03), u=10, v=6)
    K.sphere("Mouth", "Mouth", "DEF-head", (0, c.y - 0.135, 0.64), (0.055, 0.015, 0.015), u=10, v=5)
    for s in (1, -1):
        K.leaf("Ear%d" % (s > 0), "Skin", "DEF-head", (s * 0.14, c.y, 0.74), 0.15, 0.05, side=s, rotation=(0, math.radians(-15), math.radians(-12)))
        K.box("Paint%d" % (s > 0), "Paint", "DEF-head", (s * 0.08, K.ellipsoid_front_y(hc, hr, s * 0.08, 0.69, 0.003), 0.69),
              (0.05, 0.008, 0.012), rotation=(0, math.radians(25) * s, math.radians(15) * s))
    K.band("Headband", "Leather", "DEF-head", c + Vector((0, 0, 0.07)), 0.152, 0.142, 0.03)
    for i, (x, tilt) in enumerate(((0.06, 15), (0.1, 30))):
        K.lock("Feather%d" % i, "Feather", "DEF-head", c + Vector((x, 0.06, 0.08)), (0.3, 0.3, 1), 0.18, 0.035, thick=0.2)
    K.skirt("Loincloth", "Cloth", "AUTO", 0.36, 0.2, 0.1, 0.12, ragged=0.02, side_lift=0.05)
    for i in range(7):   # bone necklace
        a = math.radians(200 + 20 * i)
        K.sphere("Tooth%d" % i, "Bone", "DEF-chest", (math.cos(a) * 0.085, -0.03 + math.sin(a) * 0.075, 0.5), (0.012, 0.01, 0.022), u=6, v=4)
    # the war drum on the belly, on a strap
    dc = Vector((0, -0.14, 0.36))
    K.cone("Drum", "Drum", "DEF-pelvis", dc, 0.12, 0.12, 0.13, axis="Z", segments=18, rotation=(math.radians(70), 0, 0))
    K.cone("DrumHead", "DrumHead", "DEF-pelvis", dc + Vector((0, -0.062, 0.022)), 0.112, 0.112, 0.01, axis="Z", segments=18, rotation=(math.radians(70), 0, 0))
    K.along("DrumStrap", "Leather", "DEF-chest", (0.1, -0.06, 0.52), (-0.1, -0.12, 0.4), 0.012, segments=6)
    for s, sd in ((1, "L"), (-1, "R")):
        wr = Vector(J["wr" + sd])
        K.along("Stick." + sd, "Bone", "DEF-hand." + sd, wr + Vector((0, -0.02, -0.04)), wr + Vector((-s * 0.04, -0.12, -0.02)), 0.01, 0.008, segments=6)
        K.sphere("StickKnob." + sd, "Bone", "DEF-hand." + sd, wr + Vector((-s * 0.04, -0.125, -0.02)), (0.018, 0.018, 0.018), u=6, v=4)
    return BP.bones(J, P)


def animar(arm):
    BP.idle(arm, lean=6, arm_out=8)
    BP.run(arm, lean=14, stride=32, arm_swing=22)
    BP.attack(arm, "slam")
    BP.die(arm)
