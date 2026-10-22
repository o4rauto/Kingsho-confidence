"""CR_WolfPack — "Matilha Oca": grey wolf with a white chest and muzzle, yellow eyes, bared teeth and
a red bandana. Ref: portraits/wolf_pack.png (also the troop_wolves card). Quadruped family. Body ~1.15 long.
"""
import math
from mathutils import Vector
import kit as K
import quad as Q

NOME = "CR_WolfPack"
ATAQUE_QUADRO = 8
PALETA = {"Fur": "8E96A6", "FurDark": "5E6676", "FurLight": "E8ECF2", "Eye": "F2D24A", "Pupil": "201A10",
          "Nose": "1E1E24", "Mouth": "5A1A1E", "Tooth": "F4F0E4", "Bandana": "C42A2A"}

P = Q.params(body_z=0.32, pelvis_y=0.18, chest_y=-0.12, neck=(0, -0.24, 0.44), head=(0, -0.33, 0.5),
             tail=((0, 0.34, 0.36), (0, 0.56, 0.34)), leg_x=0.08, f_elbow=(-0.13, 0.15), f_paw=(-0.15, 0.035),
             b_hock=(0.24, 0.14), b_paw=(0.19, 0.035),
             r_pelvis=(0.1, 0.11), r_chest=(0.12, 0.13), r_neck=(0.08, 0.075), r_leg_up=0.052, r_leg_low=0.038, r_paw=0.04,
             r_tail0=(0.07, 0.07), r_tail1=(0.06, 0.06))


def pecas():
    J = Q.body("Body", P, role="Fur")
    hd = Vector(P["head"])
    K.sphere("Skull", "Fur", "DEF-head", hd, (0.1, 0.1, 0.085), u=16, v=10)
    K.sphere("Cheeks", "FurLight", "DEF-head", hd + Vector((0, -0.05, -0.035)), (0.09, 0.06, 0.05), u=12, v=8)
    K.along("Snout", "FurLight", "DEF-head", hd + Vector((0, -0.06, -0.02)), hd + Vector((0, -0.18, -0.04)), 0.045, 0.03, segments=10)
    K.sphere("Nose", "Nose", "DEF-head", hd + Vector((0, -0.185, -0.025)), (0.022, 0.016, 0.016), u=8, v=5)
    K.sphere("Mouth", "Mouth", "DEF-head", hd + Vector((0, -0.13, -0.065)), (0.04, 0.05, 0.01), u=8, v=5)
    for s in (1, -1):
        K.along("Fang%d" % (s > 0), "Tooth", "DEF-head", hd + Vector((s * 0.022, -0.155, -0.055)), hd + Vector((s * 0.02, -0.158, -0.085)), 0.008, 0.002, segments=6)
        K.sphere("Eye%d" % (s > 0), "Eye", "DEF-head", hd + Vector((s * 0.045, -0.08, 0.025)), (0.02, 0.012, 0.014), u=8, v=5,
                 rotation=(0, math.radians(-15) * s, math.radians(20) * s))
        K.sphere("Pupil%d" % (s > 0), "Pupil", "DEF-head", hd + Vector((s * 0.043, -0.09, 0.024)), (0.008, 0.005, 0.009), u=6, v=4)
        K.lock("Ear%d" % (s > 0), "FurDark", "DEF-head", hd + Vector((s * 0.055, 0.02, 0.06)), (s * 0.3, 0.2, 1), 0.11, 0.045, thick=0.35)
    K.sphere("ChestFur", "FurLight", "DEF-chest", Vector(J["chest"]) + Vector((0, -0.08, -0.04)), (0.09, 0.06, 0.1), u=12, v=8)
    K.sphere("Back", "FurDark", "DEF-pelvis", Vector(J["pelvis"]) + Vector((0, -0.05, 0.07)), (0.08, 0.16, 0.04), u=12, v=8)
    K.lock("TailTuft", "Fur", "DEF-tail2", Vector(J["tail1"]), (0, 1.0, 0.15), 0.14, 0.06, thick=0.8, curl=0.02)
    K.sphere("TailTip", "FurLight", "DEF-tail2", Vector(J["tail1"]) + Vector((0, 0.1, 0.02)), (0.04, 0.05, 0.04), u=8, v=6)
    K.band("Bandana", "Bandana", "DEF-chest", Vector(J["neck"]) + Vector((0, 0.02, -0.04)), 0.085, 0.08, 0.05, z_tilt=-0.3)
    K.lock("BandanaKnot", "Bandana", "DEF-chest", Vector(J["neck"]) + Vector((0, -0.07, -0.08)), (0, -0.3, -1), 0.1, 0.05, thick=0.25)
    for sd in ("L", "R"):
        for k, b in (("fp", "DEF-leg_f_paw."), ("bp", "DEF-leg_b_paw.")):
            K.sphere("Paw%s.%s" % (k, sd), "FurLight", b + sd, Vector(J[k + sd]) + Vector((0, -0.025, -0.01)), (0.035, 0.05, 0.025), u=10, v=6)
    return Q.bones(J, P)


def animar(arm):
    Q.animate(arm, stride=34)
