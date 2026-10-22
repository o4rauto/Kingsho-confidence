"""Quadruped family (wolves, beasts, lizards): body along Y (head at -Y), 4 legs, tail.
Bones: DEF-root, DEF-pelvis, DEF-chest, DEF-neck, DEF-head, DEF-tail1, DEF-tail2,
DEF-leg_f_up/low/paw.L/R (front), DEF-leg_b_up/low/paw.L/R (back).
Clips: idle (breath, tail wag), run (gallop), attack (bite lunge), die (rolls onto its side).
"""
import math
from mathutils import Vector
import kit as K

DEFAULTS = dict(
    body_z=0.42, pelvis_y=0.18, chest_y=-0.14, neck=(0, -0.26, 0.55), head=(0, -0.36, 0.6),
    tail=((0, 0.34, 0.5), (0, 0.5, 0.58)), leg_x=0.08, f_elbow=(-0.13, 0.22), f_paw=(-0.15, 0.03),
    b_hock=(0.22, 0.18), b_paw=(0.2, 0.03),
    r_pelvis=(0.1, 0.11), r_chest=(0.12, 0.13), r_neck=(0.07, 0.07), r_leg_up=0.045, r_leg_low=0.032, r_paw=0.034,
    r_tail0=(0.05, 0.05), r_tail1=(0.03, 0.03),
)


def params(**over):
    P = dict(DEFAULTS)
    P.update(over)
    return P


def joints(P):
    z = P["body_z"]
    J = {"pelvis": (0, P["pelvis_y"], z), "chest": (0, P["chest_y"], z + 0.02), "neck": P["neck"],
         "tail0": P["tail"][0], "tail1": P["tail"][1]}
    for s, sd in ((1, "L"), (-1, "R")):
        x = s * P["leg_x"]
        J["fs" + sd] = (x, P["chest_y"], z - 0.04)
        J["fe" + sd] = (x * 1.05, P["f_elbow"][0], P["f_elbow"][1])
        J["fp" + sd] = (x * 1.1, P["f_paw"][0], P["f_paw"][1])
        J["bs" + sd] = (x, P["pelvis_y"], z - 0.04)
        J["bh" + sd] = (x * 1.05, P["b_hock"][0], P["b_hock"][1])
        J["bp" + sd] = (x * 1.1, P["b_paw"][0], P["b_paw"][1])
    return J


def body(name, P, role):
    J = joints(P)
    R = {"pelvis": P["r_pelvis"], "chest": P["r_chest"], "neck": P["r_neck"], "tail0": P["r_tail0"], "tail1": P["r_tail1"]}
    for sd in ("L", "R"):
        R.update({"fs" + sd: (P["r_leg_up"],) * 2, "fe" + sd: (P["r_leg_low"],) * 2, "fp" + sd: (P["r_paw"],) * 2,
                  "bs" + sd: (P["r_leg_up"] * 1.15,) * 2, "bh" + sd: (P["r_leg_low"],) * 2, "bp" + sd: (P["r_paw"],) * 2})
    chains = [[J["tail1"], J["tail0"], J["pelvis"], J["chest"], J["neck"]]]
    for sd in ("L", "R"):
        chains.append([J["chest"], J["fs" + sd], J["fe" + sd], J["fp" + sd]])
        chains.append([J["pelvis"], J["bs" + sd], J["bh" + sd], J["bp" + sd]])
    K.skin_body(name, role, chains, {tuple(round(c, 5) for c in J[k]): R[k] for k in J})
    return J


def bones(J, P):
    hd = Vector(P["head"])
    B = [("DEF-root", (0, 0, 0), (0, 0.15, 0), None),
         ("DEF-pelvis", J["pelvis"], J["chest"], "DEF-root"),
         ("DEF-chest", J["chest"], J["neck"], "DEF-pelvis"),
         ("DEF-neck", J["neck"], tuple(hd), "DEF-chest"),
         ("DEF-head", tuple(hd), tuple(hd + Vector((0, -0.12, 0.02))), "DEF-neck"),
         ("DEF-tail1", J["pelvis"], J["tail0"], "DEF-pelvis"),
         ("DEF-tail2", J["tail0"], J["tail1"], "DEF-tail1")]
    for sd in ("L", "R"):
        B += [("DEF-leg_f_up." + sd, J["fs" + sd], J["fe" + sd], "DEF-chest"),
              ("DEF-leg_f_low." + sd, J["fe" + sd], J["fp" + sd], "DEF-leg_f_up." + sd),
              ("DEF-leg_f_paw." + sd, J["fp" + sd], tuple(Vector(J["fp" + sd]) + Vector((0, -0.06, -0.02))), "DEF-leg_f_low." + sd),
              ("DEF-leg_b_up." + sd, J["bs" + sd], J["bh" + sd], "DEF-pelvis"),
              ("DEF-leg_b_low." + sd, J["bh" + sd], J["bp" + sd], "DEF-leg_b_up." + sd),
              ("DEF-leg_b_paw." + sd, J["bp" + sd], tuple(Vector(J["bp" + sd]) + Vector((0, -0.06, -0.02))), "DEF-leg_b_low." + sd)]
    return B


def animate(arm, stride=32, extra=None):
    """extra(clip, t) -> pose dict for the character's own bones (wings, jaw...), t: 0..1 through the clip."""
    def key(name, n, f, pose):
        if extra:
            pose = dict(pose)
            pose.update(extra(name, (f - 1) / n))
        K.key(arm, f, pose)

    K.clip(arm, "idle", 40, True)
    for f, k in ((1, 0.0), (11, 1.0), (21, 0.0), (31, -1.0), (41, 0.0)):
        key("idle", 40, f, {"DEF-root": {"rot": [], "loc": (0, 0, -0.006 * abs(k))}, "DEF-chest": [("X", -2 * abs(k))],
                       "DEF-head": [("X", 4 * k), ("Z", 5 * k)], "DEF-tail1": [("Z", 20 * k), ("X", -10)],
                       "DEF-tail2": [("Z", 15 * k)]})
    K.clip(arm, "run", 12, True)
    for f in range(1, 14, 2):
        ph = 2 * math.pi * (f - 1) / 12
        sw, c = math.sin(ph), math.cos(ph)
        key("run", 12, f, {"DEF-root": {"rot": [], "loc": (0, 0, 0.035 * abs(c))},
                       "DEF-pelvis": [("X", 6 * sw)], "DEF-chest": [("X", -5 * sw)], "DEF-head": [("X", -4 * sw)],
                       "DEF-leg_f_up.L": [("X", stride * sw)], "DEF-leg_f_up.R": [("X", stride * math.sin(ph + 0.6))],
                       "DEF-leg_b_up.L": [("X", -stride * sw)], "DEF-leg_b_up.R": [("X", -stride * math.sin(ph + 0.6))],
                       "DEF-leg_f_low.L": [("X", -25 * max(0, -sw))], "DEF-leg_f_low.R": [("X", -25 * max(0, -math.sin(ph + 0.6)))],
                       "DEF-leg_b_low.L": [("X", 25 * max(0, sw))], "DEF-leg_b_low.R": [("X", 25 * max(0, math.sin(ph + 0.6)))],
                       "DEF-tail1": [("X", -20 + 10 * sw)]})
    K.clip(arm, "attack", 14, False)
    for f, pose in ((1, {}),
                    (5, {"DEF-root": {"rot": [], "loc": (0, 0.06, -0.02)}, "DEF-chest": [("X", -8)], "DEF-head": [("X", -20)],
                         "DEF-leg_b_up.L": [("X", 15)], "DEF-leg_b_up.R": [("X", 15)]}),
                    (8, {"DEF-root": {"rot": [], "loc": (0, -0.16, 0.03)}, "DEF-chest": [("X", 10)], "DEF-head": [("X", 25)],
                         "DEF-leg_f_up.L": [("X", -40)], "DEF-leg_f_up.R": [("X", -35)],
                         "DEF-leg_b_up.L": [("X", 30)], "DEF-leg_b_up.R": [("X", 30)]}),
                    (14, {})):
        key("attack", 14, f, pose)
    K.clip(arm, "cast", 16, False)   # roar / croak: rear up, head high, then thrust it forward
    for f, pose in ((1, {}),
                    (6, {"DEF-root": {"rot": [], "loc": (0, 0.03, 0.03)}, "DEF-chest": [("X", -18)], "DEF-head": [("X", -30)],
                         "DEF-leg_f_up.L": [("X", -25)], "DEF-leg_f_up.R": [("X", -25)]}),
                    (10, {"DEF-root": {"rot": [], "loc": (0, -0.04, 0)}, "DEF-chest": [("X", 6)], "DEF-head": [("X", 22)],
                          "DEF-tail1": [("X", -25)]}),
                    (16, {})):
        key("cast", 16, f, pose)
    K.clip(arm, "die", 24, False)
    for f, k in ((1, 0.0), (6, 0.2), (14, 1.0), (18, 0.92), (24, 1.0)):
        key("die", 24, f, {"DEF-root": {"rot": [("Y", 88 * k)], "loc": (0.0, 0, 0.06 * k)},
                       "DEF-head": [("X", 15 * k)], "DEF-tail1": [("X", 20 * k)],
                       "DEF-leg_f_up.L": [("X", -20 * k)], "DEF-leg_b_up.L": [("X", 20 * k)]})
