"""Flyer family (bats, birds, winged critters): hovering body, head, two-part wings, dangling feet.
Bones: DEF-root (ground) -> DEF-body -> DEF-head; DEF-wing_in.L/R -> DEF-wing_out.L/R; DEF-foot.L/R.
Clips: idle (slow hover flap), run (= fly, fast flap), attack (dive bite), die (folds and drops).
"""
import math
import kit as K


def bones(body_z, head_z, wing_root_x, wing_span, foot_z=None):
    B = [("DEF-root", (0, 0, 0), (0, 0.15, 0), None),
         ("DEF-body", (0, 0.02, body_z - 0.12), (0, 0, body_z + 0.08), "DEF-root"),
         ("DEF-head", (0, 0, body_z + 0.08), (0, -0.02, head_z), "DEF-body")]
    for s, sd in ((1, "L"), (-1, "R")):
        mid = wing_root_x + (wing_span - wing_root_x) * 0.5
        B += [("DEF-wing_in." + sd, (s * wing_root_x, 0.02, body_z + 0.04), (s * mid, 0.03, body_z + 0.08), "DEF-body"),
              ("DEF-wing_out." + sd, (s * mid, 0.03, body_z + 0.08), (s * wing_span, 0.04, body_z + 0.02), "DEF-wing_in." + sd)]
        if foot_z is not None:
            B.append(("DEF-foot." + sd, (s * 0.05, 0.02, body_z - 0.12), (s * 0.05, 0.0, foot_z), "DEF-body"))
    return B


def _flap(k):
    return {"DEF-wing_in.L": [("Y", -35 * k)], "DEF-wing_in.R": [("Y", 35 * k)],
            "DEF-wing_out.L": [("Y", -25 * k)], "DEF-wing_out.R": [("Y", 25 * k)]}


def animate(arm, hover=0.04):
    for name, frames, amp in (("idle", 16, 1.0), ("run", 10, 1.0)):
        K.clip(arm, name, frames, True)
        q = frames // 4
        for f, k in ((1, 1.0), (1 + q, 0.0), (1 + 2 * q, -1.0), (1 + 3 * q, 0.0), (1 + frames, 1.0)):
            pose = {"DEF-body": {"rot": [("X", 14 if name == "run" else 4)], "loc": (0, 0, -hover * k)},
                    "DEF-head": [("X", -10 if name == "run" else -2)],
                    "DEF-foot.L": [("X", 15 * k)], "DEF-foot.R": [("X", 15 * k)]}
            pose.update(_flap(k * amp))
            K.key(arm, f, pose)
    K.clip(arm, "attack", 14, False)
    for f, pose in ((1, _flap(0.3)),
                    (5, dict(_flap(1.0), **{"DEF-body": {"rot": [("X", -15)], "loc": (0, 0.06, 0.08)}, "DEF-head": [("X", 12)]})),
                    (8, dict(_flap(-0.8), **{"DEF-body": {"rot": [("X", 35)], "loc": (0, -0.2, -0.1)}, "DEF-head": [("X", 25)]})),
                    (14, _flap(0.3))):
        K.key(arm, f, pose)
    K.clip(arm, "cast", 14, False)   # ranged spit: back off, rear the head, spit forward
    for f, pose in ((1, _flap(0.3)),
                    (6, dict(_flap(1.0), **{"DEF-body": {"rot": [("X", -20)], "loc": (0, 0.08, 0.06)}, "DEF-head": [("X", -25)]})),
                    (9, dict(_flap(-0.4), **{"DEF-body": {"rot": [("X", 12)], "loc": (0, 0.0, 0.02)}, "DEF-head": [("X", 35)]})),
                    (14, _flap(0.3))):
        K.key(arm, f, pose)
    K.clip(arm, "die", 22, False)
    for f, k in ((1, 0.0), (6, 0.3), (16, 1.0), (22, 1.0)):
        pose = {"DEF-root": {"rot": [("Y", 70 * k)], "loc": (0, 0, 0)},
                "DEF-body": {"rot": [("X", 50 * k)], "loc": (0, 0, -0.45 * k)}, "DEF-head": [("X", 20 * k)]}
        pose.update({"DEF-wing_in.L": [("Y", 60 * k)], "DEF-wing_in.R": [("Y", -60 * k)],
                     "DEF-wing_out.L": [("Y", 70 * k)], "DEF-wing_out.R": [("Y", -70 * k)]})
        K.key(arm, f, pose)
