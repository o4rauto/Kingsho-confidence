"""CR_MagmaSlime — "Gosma de Magma" (no portrait: designed from game_data — brute, molten ff5a1a, splits
into fire imps, burns on touch). A squat glowing blob of lava wearing a cracked crust of dark rock plates
on its back, lava drips down its sides, bubbles on top, glowing eyes and a wide molten grin. Floaty. H 0.6.
"""
import math
from mathutils import Vector
import kit as K
import floaty as FL
import rocha as RC

NOME = "CR_MagmaSlime"
ATAQUE_QUADRO = 8
PALETA = {"Lava": "FF5A1A", "LavaLight": "FFB43A", "Rock": "3A2A26", "RockDark": "241A18", "Eye": "FFE87A",
          "Pupil": "2A1008", "Mouth": "5A1408"}
BRILHO = ("Lava", "LavaLight", "Eye")

C = Vector((0, 0, 0.27))


def pecas():
    K.sphere("Blob", "Lava", "DEF-body", C, (0.34, 0.31, 0.26), u=22, v=14)
    K.sphere("Base", "Lava", "DEF-body", C + Vector((0, 0, -0.15)), (0.38, 0.35, 0.12), u=22, v=10)
    RC.shell("Crust", "DEF-top", C + Vector((0, 0.03, 0.0)), (0.34, 0.31, 0.26), 26, 0.13, seed=7, min_z=0.15,
             skip=lambda u: u.y < -0.45 and u.z < 0.75)
    for i, (x, y) in enumerate(((0.1, -0.05), (-0.14, 0.04), (0.02, 0.12))):
        K.sphere("Bubble%d" % i, "LavaLight", "DEF-top", C + Vector((x, y, 0.25)), (0.035, 0.035, 0.035), u=8, v=6)
    for k in range(7):
        a = math.radians(30 + 50 * k)
        root = C + Vector((math.cos(a) * 0.3, math.sin(a) * 0.27, -0.02))
        K.lock("Drip%d" % k, "LavaLight" if k % 2 else "Lava", "DEF-body", root, (math.cos(a) * 0.2, math.sin(a) * 0.2, -1),
               0.12, 0.05, thick=0.6, rings=6, seg=7)
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Socket" + sd, "RockDark", "DEF-body", C + Vector((s * 0.1, -0.25, 0.08)), (0.065, 0.04, 0.055), u=10, v=6)
        K.sphere("Eye" + sd, "Eye", "DEF-body", C + Vector((s * 0.1, -0.28, 0.08)), (0.045, 0.02, 0.04), u=10, v=6,
                 rotation=(0, math.radians(-15) * s, 0))
        K.sphere("Pupil" + sd, "Pupil", "DEF-body", C + Vector((s * 0.095, -0.298, 0.075)), (0.016, 0.006, 0.024), u=6, v=4)
    pts = []
    for i in range(9):
        t = i / 8 * 2 - 1
        pts.append(C + Vector((t * 0.17, -0.3 + 0.04 * t * t, -0.07 + 0.05 * t * t)))
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Grin%d" % i, "Mouth", "DEF-body", a, b, 0.024, segments=6)
    return FL.bones(0.05, 0.3, 0.55)


def animar(arm):
    FL.animate(arm, bob=0.03, sway=6)
