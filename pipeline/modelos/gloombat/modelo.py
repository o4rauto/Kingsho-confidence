"""CR_Gloombat — "Morcego Sombrio": round purple furball bat, big ears, pink snout, little fangs,
big membrane wings. Ref: portraits/gloombat.png. Flyer family. Hovers ~0.6 m up.
"""
import math
from mathutils import Vector
import kit as K
import flyer as FY

NOME = "CR_Gloombat"
ATAQUE_QUADRO = 8
PALETA = {"Fur": "4E3A7A", "FurLight": "6A54A0", "Wing": "8E5AA8", "WingBone": "3E2E62", "Ear": "C68AB8",
          "Snout": "E88AA8", "Eye": "1E1424", "Shine": "FFFFFF", "Tooth": "F4F0E4"}

BZ = 0.62


def pecas():
    c = Vector((0, 0, BZ))
    K.sphere("Body", "Fur", "DEF-body", c, (0.2, 0.18, 0.22), u=18, v=12)
    K.sphere("Belly", "FurLight", "DEF-body", c + Vector((0, -0.06, -0.04)), (0.14, 0.12, 0.15), u=14, v=8)
    h = c + Vector((0, -0.04, 0.17))
    K.sphere("Head", "Fur", "DEF-head", h, (0.16, 0.14, 0.13), u=16, v=10)
    K.sphere("Snout", "Snout", "DEF-head", h + Vector((0, -0.13, -0.03)), (0.045, 0.03, 0.03), u=10, v=6)
    for s in (1, -1):
        K.sphere("Nostril%d" % (s > 0), "WingBone", "DEF-head", h + Vector((s * 0.015, -0.158, -0.025)), (0.008, 0.005, 0.008), u=6, v=4)
        K.sphere("Eye%d" % (s > 0), "Eye", "DEF-head", h + Vector((s * 0.06, -0.12, 0.03)), (0.025, 0.012, 0.03), u=8, v=6)
        K.sphere("Shine%d" % (s > 0), "Shine", "DEF-head", h + Vector((s * 0.065, -0.132, 0.045)), (0.008, 0.004, 0.008), u=6, v=4)
        K.along("Fang%d" % (s > 0), "Tooth", "DEF-head", h + Vector((s * 0.02, -0.125, -0.06)), h + Vector((s * 0.02, -0.128, -0.09)), 0.009, 0.002, segments=5)
        K.lock("Ear%d" % (s > 0), "Fur", "DEF-head", h + Vector((s * 0.08, 0.0, 0.08)), (s * 0.4, 0.05, 1), 0.17, 0.07, thick=0.25)
        K.lock("EarIn%d" % (s > 0), "Ear", "DEF-head", h + Vector((s * 0.08, -0.012, 0.08)), (s * 0.4, 0.05, 1), 0.13, 0.045, thick=0.2)
        # wings: inner membrane on wing_in, outer on wing_out, with bone struts
        root, mid, tip = Vector((s * 0.15, 0.03, BZ + 0.05)), Vector((s * 0.42, 0.04, BZ + 0.1)), Vector((s * 0.72, 0.05, BZ - 0.02))
        sd = "L" if s > 0 else "R"
        K.lock("WingIn" + sd, "Wing", "DEF-wing_in." + sd, root, (s, 0.05, 0.12), 0.32, 0.17, thick=0.12, curl=-0.05, power=0.5)
        K.lock("WingOut" + sd, "Wing", "DEF-wing_out." + sd, mid, (s, 0.05, -0.3), 0.34, 0.14, thick=0.12, curl=-0.04, power=0.6)
        K.along("Strut0" + sd, "WingBone", "DEF-wing_in." + sd, root, mid, 0.014, segments=6)
        K.along("Strut1" + sd, "WingBone", "DEF-wing_out." + sd, mid, tip, 0.011, 0.004, segments=6)
        K.sphere("Foot" + sd, "WingBone", "DEF-foot." + sd, (s * 0.05, 0.0, BZ - 0.24), (0.025, 0.03, 0.02), u=8, v=5)
    return FY.bones(BZ, BZ + 0.32, 0.15, 0.72, foot_z=BZ - 0.26)


def animar(arm):
    FY.animate(arm, hover=0.05)
