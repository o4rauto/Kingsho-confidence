"""Bug family (mites, beetles, scorpions, spiders): a body on short legs. Bones:
DEF-root -> DEF-body -> DEF-head, DEF-leg<i>.L/R (one bone each, hip -> foot), plus any extra bones the
character adds (tail, claws). Clips: idle (breathe), run (tripod gait), attack (rear up and bite), die (flip).
Legs are given for the left side (+X) and mirrored.
"""
import math
from mathutils import Vector
import kit as K


def bones(body_a, body_b, head_a, head_b, legs, extra=()):
    B = [("DEF-root", (0, 0, 0), (0, 0.15, 0), None),
         ("DEF-body", body_a, body_b, "DEF-root"),
         ("DEF-head", head_a, head_b, "DEF-body")]
    for i, (hip, foot) in enumerate(legs):
        for s, sd in ((1, "L"), (-1, "R")):
            B.append(("DEF-leg%d.%s" % (i, sd), (s * hip[0], hip[1], hip[2]), (s * foot[0], foot[1], foot[2]), "DEF-body"))
    return B + list(extra)


def _legs(n, sweep, lift):
    """sweep/lift(i, side_index) -> degrees forward / up for leg i."""
    pose = {}
    for i in range(n):
        for j, (sd, sg) in enumerate((("L", 1), ("R", -1))):
            # left leg (+X): -Z swings it forward, -Y lifts it; the right leg mirrors both
            pose["DEF-leg%d.%s" % (i, sd)] = [("Z", -sg * sweep(i, j)), ("Y", -sg * lift(i, j))]
    return pose


def animate(arm, n_legs, stride=24, bob=0.02, flip_h=0.4, extra=None):
    """extra(clip, t) -> pose dict for the character's own bones (t: 0..1 through the clip).
    flip_h: height of the back, so the flipped body lands on it instead of sinking."""
    def add(pose, name, t):
        if extra:
            pose.update(extra(name, t))
        return pose

    K.clip(arm, "idle", 36, True)
    for f in range(1, 38, 6):
        ph = 2 * math.pi * (f - 1) / 36
        pose = _legs(n_legs, lambda i, j: 3 * math.sin(ph + i), lambda i, j: 0)
        pose["DEF-body"] = {"rot": [("X", 2 * math.sin(ph))], "loc": (0, 0, 0.01 * math.sin(ph)),
                            "scale": (1 + 0.02 * math.sin(ph), 1, 1 + 0.02 * math.sin(ph))}
        pose["DEF-head"] = [("Z", 6 * math.sin(ph * 0.5)), ("X", -3 * math.sin(ph))]
        K.key(arm, f, add(pose, "idle", (f - 1) / 36))
    K.clip(arm, "run", 8, True)
    for f in range(1, 10):
        ph = 2 * math.pi * (f - 1) / 8
        g = lambda i, j: ph + ((i + j) % 2) * math.pi
        pose = _legs(n_legs, lambda i, j: stride * math.sin(g(i, j)), lambda i, j: 18 * max(0.0, math.cos(g(i, j))))
        pose["DEF-body"] = {"rot": [("X", 4), ("Y", 3 * math.sin(ph))], "loc": (0, 0, bob * abs(math.sin(ph)) + 0.01)}
        pose["DEF-head"] = [("X", -4)]
        K.key(arm, f, add(pose, "run", (f - 1) / 8))
    K.clip(arm, "attack", 14, False)
    for f, k, lunge in ((1, 0, 0), (5, 1, 0), (8, 0, 1), (14, 0, 0)):
        pose = _legs(n_legs, lambda i, j: 10 * (k - lunge) if i == 0 else 0, lambda i, j: 25 * k if i == 0 else 0)
        pose["DEF-body"] = {"rot": [("X", -18 * k + 14 * lunge)], "loc": (0, 0.04 * k - 0.1 * lunge, 0.03 * k)}
        pose["DEF-head"] = [("X", -20 * k + 25 * lunge)]
        K.key(arm, f, add(pose, "attack", (f - 1) / 14))
    K.clip(arm, "die", 24, False)
    for f, k in ((1, 0.0), (6, 0.4), (12, 1.0), (16, 0.95), (24, 1.0)):
        pose = _legs(n_legs, lambda i, j: 0, lambda i, j: 45 * k)
        pose["DEF-root"] = {"rot": [("Y", 180 * min(1, k * 1.1))], "loc": (0, 0, flip_h * min(1, k) + 0.15 * math.sin(math.pi * min(1, k)))}
        K.key(arm, f, add(pose, "die", (f - 1) / 24))
