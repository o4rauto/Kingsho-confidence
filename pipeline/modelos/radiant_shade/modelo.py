"""CR_RadiantShade — "Sombra Radiante" (no portrait: designed from game_data — flyer, pale gold fff0b0,
spits light). A luminous winged spirit from the sun temple: a glowing hooded figure of light with a dark
face and two bright eyes, a gold halo, wings of long light feathers, and a body fading into a wisp tail.
Flyer family. Hovers ~0.65 m up.
"""
import math
from mathutils import Vector, Euler
import kit as K
import flyer as FY

NOME = "CR_RadiantShade"
ATAQUE_QUADRO = 8
PALETA = {"Light": "FFF0B0", "LightDeep": "F2D27A", "Feather": "FFF6D2", "FeatherTip": "F2C85A", "Face": "2A2030",
          "Eye": "FFFFFF", "Halo": ("F2C24A", 0.3, 0.6)}
BRILHO = ("Light", "Feather", "Eye", "Halo")

BZ = 0.66


def pecas():
    c = Vector((0, 0, BZ))
    K.sphere("Body", "Light", "DEF-body", c, (0.15, 0.13, 0.17), u=18, v=12)
    pts = [c + Vector((0, 0.01, -0.1))]
    for k in range(1, 6):
        a = math.radians(50 * k)
        pts.append(pts[0] + Vector((0.035 * math.sin(a), 0.04 * k, -0.07 * k)))
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        K.along("Wisp%d" % k, "Light" if k < 2 else "LightDeep", "DEF-body", a, b, 0.12 - 0.022 * k, 0.1 - 0.02 * k, segments=12)
    h = c + Vector((0, -0.02, 0.2))
    K.sphere("Face", "Face", "DEF-head", h, (0.1, 0.09, 0.1), u=14, v=10)
    K.dome("Hood", "Light", "DEF-head", h + Vector((0, 0.012, -0.03)), (0.135, 0.13, 0.15), cut=-0.6, u=22, v=12, face_open=(0.35, 0.6))
    for s, sd in ((1, ".L"), (-1, ".R")):
        K.sphere("Eye" + sd, "Eye", "DEF-head", h + Vector((s * 0.035, -0.09, 0.0)), (0.02, 0.01, 0.024), u=8, v=5)
    K.band("Halo", "Halo", "DEF-head", h + Vector((0, 0.05, 0.2)), 0.12, 0.12, 0.016, thickness=0.02, z_tilt=math.radians(-20))
    for s in (1, -1):
        sd = "L" if s > 0 else "R"
        root, mid = Vector((s * 0.12, 0.04, BZ + 0.06)), Vector((s * 0.36, 0.06, BZ + 0.14))
        m = Euler((math.radians(-25), 0, 0)).to_matrix()
        inner = [(0.0, 0.06), (0.12, 0.12), (0.26, 0.1), (0.26, -0.06), (0.18, -0.16), (0.08, -0.12), (0.0, -0.06)]
        outer = [(0.0, 0.1), (0.14, 0.14), (0.3, 0.1), (0.36, 0.02), (0.28, -0.08), (0.2, -0.16), (0.1, -0.14), (0.0, -0.06)]
        for nm, bone, base, ol in (("WingIn", "DEF-wing_in.", root, inner), ("WingOut", "DEF-wing_out.", mid, outer)):
            pts = [(s * x, z) for x, z in ol]
            if s < 0:
                pts.reverse()
            K.plate(nm + sd, "Feather", bone + sd, base, pts, thickness=0.016, rotation=(math.radians(-25), 0, 0))
            for k in range(3):   # gold feather tips along the trailing edge
                x, z = ol[-2 - k] if nm == "WingIn" else ol[-2 - k]
                tip = base + m @ Vector((s * x, 0.0, z))
                K.lock("Tip%s%d%s" % (nm, k, sd), "FeatherTip", bone + sd, tip, (s * 0.3, 0.2, -1), 0.1, 0.04, thick=0.25,
                       curl=0.0, rings=5, seg=6)
        K.sphere("Hand" + sd, "Light", "DEF-body", c + Vector((s * 0.13, -0.08, -0.06)), (0.035, 0.035, 0.04), u=8, v=6)
    return FY.bones(BZ, BZ + 0.3, 0.12, 0.62)


def animar(arm):
    FY.animate(arm, hover=0.05)
