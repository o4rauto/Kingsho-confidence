"""Floating family (wisps, flames, slimes, ghosts): no legs. Bones:
DEF-root (ground) -> DEF-body (the mass, z0..z1) -> DEF-top (flame tip / head, z1..z2), optional DEF-arm.L/R.
Clips: idle (bob + pulse), run (lean + quick bob), attack (squash, lunge, stretch), die (shrink and sink).
"""
import kit as K


def bones(z0, z1, z2, arms=None):
    B = [("DEF-root", (0, 0, 0), (0, 0.15, 0), None),
         ("DEF-body", (0, 0, z0), (0, 0, z1), "DEF-root"),
         ("DEF-top", (0, 0, z1), (0, 0, z2), "DEF-body")]
    if arms:   # arms = (shoulder_x, shoulder_z, hand_x, hand_z)
        sx, sz, hx, hz = arms
        B += [("DEF-arm.L", (sx, 0, sz), (hx, -0.02, hz), "DEF-body"),
              ("DEF-arm.R", (-sx, 0, sz), (-hx, -0.02, hz), "DEF-body")]
    return B


def animate(arm, bob=0.05, sway=10):
    K.clip(arm, "idle", 36, True)
    for f, k in ((1, 0.0), (10, 1.0), (19, 0.0), (28, -1.0), (37, 0.0)):
        K.key(arm, f, {"DEF-body": {"rot": [("Y", 3 * k)], "loc": (0, 0, bob * k), "scale": (1 - 0.03 * k, 1 - 0.03 * k, 1 + 0.05 * k)},
                       "DEF-top": [("Y", -sway * k), ("X", 4 * k)],
                       "DEF-arm.L": [("Y", -15 - 10 * k)], "DEF-arm.R": [("Y", 15 + 10 * k)]})
    K.clip(arm, "run", 16, True)
    for f, k in ((1, 0.0), (5, 1.0), (9, 0.0), (13, -1.0), (17, 0.0)):
        K.key(arm, f, {"DEF-body": {"rot": [("X", 16)], "loc": (0, 0, bob * 0.6 * abs(k) + 0.02)},
                       "DEF-top": [("X", -22), ("Y", sway * 0.6 * k)],
                       "DEF-arm.L": [("X", 30), ("Y", -20)], "DEF-arm.R": [("X", 30), ("Y", 20)]})
    K.clip(arm, "attack", 14, False)
    for f, pose in ((1, {}),
                    (5, {"DEF-body": {"rot": [("X", -12)], "loc": (0, 0.06, -0.02), "scale": (1.12, 1.12, 0.85)},
                         "DEF-top": [("X", 15)], "DEF-arm.L": [("Y", -60)], "DEF-arm.R": [("Y", 60)]}),
                    (8, {"DEF-body": {"rot": [("X", 25)], "loc": (0, -0.18, 0.02), "scale": (0.9, 0.9, 1.2)},
                         "DEF-top": [("X", -30)], "DEF-arm.L": [("X", -80)], "DEF-arm.R": [("X", -80)]}),
                    (14, {})):
        K.key(arm, f, pose)
    K.clip(arm, "cast", 14, False)   # ranged puff / spell: recoil, swell, push forward without lunging
    for f, pose in ((1, {}),
                    (6, {"DEF-body": {"rot": [("X", -16)], "loc": (0, 0.06, 0.03), "scale": (1.12, 1.12, 1.0)},
                         "DEF-top": [("X", 18)], "DEF-arm.L": [("Y", -70)], "DEF-arm.R": [("Y", 70)]}),
                    (9, {"DEF-body": {"rot": [("X", 16)], "loc": (0, -0.05, 0.0), "scale": (0.9, 0.9, 1.08)},
                         "DEF-top": [("X", -14)], "DEF-arm.L": [("X", -95), ("Y", -10)], "DEF-arm.R": [("X", -95), ("Y", 10)]}),
                    (14, {})):
        K.key(arm, f, pose)
    K.clip(arm, "die", 24, False)
    for f, k in ((1, 0.0), (6, 0.25), (16, 0.85), (24, 1.0)):
        s = 1 - 0.85 * k
        K.key(arm, f, {"DEF-body": {"rot": [("Y", 90 * k)], "loc": (0, 0, -0.25 * k), "scale": (s, s, s * (1 - 0.3 * k))},
                       "DEF-top": [("X", 30 * k)]})
