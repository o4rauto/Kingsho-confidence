"""Biped family: joints from proportions, body, hands, feet, 18-bone skeleton and stock clips.
P keys (metres; any can be overridden by the character): see DEFAULTS. Front = -Y, left = +X.
"""
import math
from mathutils import Vector
import kit as K

DEFAULTS = dict(
    H=1.2, hunch=0.03,
    head_c=(0, -0.06, 0.80), head_r=(0.17, 0.16, 0.20),
    neck0_z=0.585, neck1_z=0.64,
    chest_z=0.52, waist_z=0.43, pelvis_z=0.35,
    shoulder_z=0.555, shoulder_x=0.13, elbow_out=0.075, elbow_z=0.425,
    wrist_x=0.245, wrist_z=0.33, wrist_y=-0.02,
    hand_bottom=0.216, hand_size=0.13,
    hip_x=0.07, hip_z=0.35, knee_x=0.115, knee_y=-0.06, knee_z=0.173, ankle_x=0.158, ankle_z=0.092,
    foot_len=0.19,
    r_pelvis=(0.117, 0.075), r_waist=(0.105, 0.065), r_chest=(0.138, 0.08),
    r_neck0=(0.065, 0.055), r_neck1=(0.06, 0.05), r_shoulder=0.048, r_elbow=0.032, r_wrist=0.038,
    r_hip=0.06, r_knee=0.048, r_ankle=0.036,
    arms=True, legs=True,
)


def params(**over):
    P = dict(DEFAULTS)
    P.update(over)
    return P


def joints(P):
    h = P["hunch"]
    J = {
        "pelvis": (0, 0.0, P["pelvis_z"]),
        "waist": (0, -0.005, P["waist_z"]),
        "chest": (0, -h * 0.6, P["chest_z"]),
        "neck0": (0, -h, P["neck0_z"]),
        "neck1": (0, -h - 0.02, P["neck1_z"]),
    }
    R = {"pelvis": P["r_pelvis"], "waist": P["r_waist"], "chest": P["r_chest"],
         "neck0": P["r_neck0"], "neck1": P["r_neck1"]}
    for s, sd in ((1, "L"), (-1, "R")):
        if P["arms"]:
            J["sh" + sd] = (s * P["shoulder_x"], -h * 0.6, P["shoulder_z"])
            J["el" + sd] = (s * (P["shoulder_x"] + P["elbow_out"]), 0.0, P["elbow_z"])
            J["wr" + sd] = (s * P["wrist_x"], P["wrist_y"], P["wrist_z"])
            R.update({"sh" + sd: (P["r_shoulder"],) * 2, "el" + sd: (P["r_elbow"],) * 2, "wr" + sd: (P["r_wrist"],) * 2})
        if P["legs"]:
            J["hip" + sd] = (s * P["hip_x"], 0.0, P["hip_z"])
            J["kn" + sd] = (s * P["knee_x"], P["knee_y"], P["knee_z"])
            J["an" + sd] = (s * P["ankle_x"], 0.0, P["ankle_z"])
            R.update({"hip" + sd: (P["r_hip"],) * 2, "kn" + sd: (P["r_knee"],) * 2, "an" + sd: (P["r_ankle"],) * 2})
    return J, R


def body(name, P, role="Skin"):
    J, R = joints(P)
    chains = [[J["pelvis"], J["waist"], J["chest"], J["neck0"], J["neck1"]]]
    for sd in ("L", "R"):
        if P["arms"]:
            chains.append([J["chest"], J["sh" + sd], J["el" + sd], J["wr" + sd]])
        if P["legs"]:
            chains.append([J["pelvis"], J["hip" + sd], J["kn" + sd], J["an" + sd]])
    radii = {tuple(round(c, 5) for c in J[k]): R[k] for k in J}
    K.skin_body(name, role, chains, radii)
    return J


def hands(prefix, J, P, role="Skin", style="mitt3", size=1.0):
    """mitt3: palm + 3 fingers + thumb (monsters, bare hands) · fist: ball (gloves, holding weapons)."""
    out = {}
    for s, sd in ((1, "L"), (-1, "R")):
        wx, wy, wz = J["wr" + sd]
        hc = Vector((wx + s * 0.01, wy - 0.01, P["hand_bottom"] + P["hand_size"] * 0.45))
        bone = "DEF-hand." + sd
        if style == "fist":
            K.sphere(prefix + "Hand." + sd, role, bone, hc, (0.05 * size, 0.05 * size, 0.055 * size), u=12, v=8)
        else:
            K.sphere(prefix + "Hand." + sd, role, bone, hc, (0.055 * size, 0.05 * size, P["hand_size"] * 0.5 * size), u=12, v=8)
            for i, dx in enumerate((-0.03, 0.0, 0.03)):
                top = hc + Vector((dx * size, -0.03 * size, -0.035 * size))
                tip = top + Vector((dx * 0.3, -0.025, -0.06)) * size
                K.capsule(prefix + "Finger%d.%s" % (i, sd), role, bone, top, tip, 0.017 * size, segments=8)
            th0 = hc + Vector((-s * 0.045, -0.03, 0.0)) * size
            K.capsule(prefix + "Thumb." + sd, role, bone, th0, th0 + Vector((-s * 0.02, -0.04, -0.035)) * size, 0.016 * size, segments=8)
        out[sd] = hc
    return out


def feet(prefix, J, P, role="Skin", style="toes3", splay=18, size=1.0, toe_role=None):
    """toes3: long bare foot with 3 toes · boot: rounded boot · shoe: small round shoe."""
    out = {}
    for s, sd in ((1, "L"), (-1, "R")):
        ax, ay, az = J["an" + sd]
        fl = P["foot_len"] * size
        c = Vector((ax + s * 0.01, ay - fl * 0.32, 0.045 * size))
        rot = (0, 0, math.radians(splay) * s)
        bone = "DEF-foot." + sd
        if style == "boot":
            K.sphere(prefix + "Foot." + sd, role, bone, c + Vector((0, 0, 0.005)), (0.06 * size, fl / 2, 0.05 * size), u=12, v=8, rotation=rot)
            K.cone(prefix + "BootTop." + sd, role, bone, (ax, ay, az + 0.03), 0.05 * size, 0.055 * size, 0.08, segments=12)
        elif style == "shoe":
            K.sphere(prefix + "Foot." + sd, role, bone, c, (0.05 * size, fl * 0.42, 0.04 * size), u=12, v=8, rotation=rot)
        else:
            K.sphere(prefix + "Foot." + sd, role, bone, c, (0.062 * size, fl / 2 + 0.01, 0.05 * size), u=12, v=8, rotation=rot)
            from mathutils import Matrix
            m = Matrix.Rotation(math.radians(splay) * s, 3, "Z")
            for i, dx in enumerate((-0.035, 0.0, 0.035)):
                p = c + m @ (Vector((dx, -fl / 2 - 0.005, -0.02)) * size)
                K.sphere(prefix + "Toe%d.%s" % (i, sd), toe_role or role, bone, p, (0.024 * size, 0.029 * size, 0.019 * size), u=8, v=5)
        out[sd] = c
    return out


def bones(J, P):
    hc, hr = P["head_c"], P["head_r"]
    head_top = (0, J["neck1"][1] - 0.01, hc[2] + hr[2])
    B = [("DEF-root", (0, 0, 0), (0, 0.15, 0), None),
         ("DEF-pelvis", J["pelvis"], J["waist"], "DEF-root"),
         ("DEF-spine", J["waist"], J["chest"], "DEF-pelvis"),
         ("DEF-chest", J["chest"], J["neck0"], "DEF-spine"),
         ("DEF-neck", J["neck0"], J["neck1"], "DEF-chest"),
         ("DEF-head", J["neck1"], head_top, "DEF-neck")]
    for sd in ("L", "R"):
        if P["arms"]:
            tip = (J["wr" + sd][0], J["wr" + sd][1] - 0.01, P["hand_bottom"])
            B += [("DEF-upper_arm." + sd, J["sh" + sd], J["el" + sd], "DEF-chest"),
                  ("DEF-forearm." + sd, J["el" + sd], J["wr" + sd], "DEF-upper_arm." + sd),
                  ("DEF-hand." + sd, J["wr" + sd], tip, "DEF-forearm." + sd)]
        if P["legs"]:
            toe = (J["an" + sd][0], J["an" + sd][1] - P["foot_len"] * 0.8, 0.03)
            B += [("DEF-thigh." + sd, J["hip" + sd], J["kn" + sd], "DEF-pelvis"),
                  ("DEF-shin." + sd, J["kn" + sd], J["an" + sd], "DEF-thigh." + sd),
                  ("DEF-foot." + sd, J["an" + sd], toe, "DEF-shin." + sd)]
    return B


# ───────────────────────── stock clips (24 fps) ─────────────────────────

def _legs_rest():
    return {"DEF-thigh.L": [("X", -8)], "DEF-thigh.R": [("X", -8)],
            "DEF-shin.L": [("X", 14)], "DEF-shin.R": [("X", 14)]}


def idle(arm, lean=6, arm_out=6):
    K.clip(arm, "idle", 48, True)
    for f, k in ((1, 0.0), (25, 1.0), (49, 0.0)):
        pose = {"DEF-root": {"rot": [], "loc": (0, 0, -0.008 * k)},
                "DEF-spine": [("X", lean + 3 * k)],
                "DEF-head": [("X", -lean * 0.6 - 3 * k), ("Z", 4 * k)],
                "DEF-upper_arm.L": [("Y", -arm_out - 2 * k), ("X", -4 * k)],
                "DEF-upper_arm.R": [("Y", arm_out + 2 * k), ("X", 4 * k)],
                "DEF-forearm.L": [("X", -10 - 4 * k)], "DEF-forearm.R": [("X", -10 - 4 * k)]}
        pose.update(_legs_rest())
        K.key(arm, f, pose)


def run(arm, lean=18, stride=40, arm_swing=35, frames=16, hold_right=False):
    K.clip(arm, "run", frames, True)
    for f in range(1, frames + 2, 2):
        ph = 2 * math.pi * (f - 1) / frames
        sw, up = math.sin(ph), abs(math.cos(ph))
        pose = {"DEF-root": {"rot": [], "loc": (0, 0, 0.03 * up - 0.02)},
                "DEF-spine": [("X", lean)], "DEF-head": [("X", -lean * 0.75), ("Z", 5 * sw)],
                "DEF-thigh.L": [("X", -stride * sw - 5)], "DEF-thigh.R": [("X", stride * sw - 5)],
                "DEF-shin.L": [("X", 30 + 30 * max(0, sw))], "DEF-shin.R": [("X", 30 + 30 * max(0, -sw))],
                "DEF-foot.L": [("X", -10 * sw)], "DEF-foot.R": [("X", 10 * sw)],
                "DEF-upper_arm.L": [("X", arm_swing * sw), ("Y", -10)],
                "DEF-upper_arm.R": [("X", -arm_swing * sw * (0.3 if hold_right else 1)), ("Y", 10)],
                "DEF-forearm.L": [("X", -35)], "DEF-forearm.R": [("X", -35 if not hold_right else -60)]}
        K.key(arm, f, pose)


def attack(arm, style="claw"):
    """claw: one-arm swipe · sword: side-overhead swing, right hand · slam: two-hand overhead smash ·
    shoot: bow draw and release · cast: both arms gather and thrust · spear: forward thrust."""
    rest = {"DEF-spine": [("X", 8)], "DEF-head": [("X", -6)],
            "DEF-upper_arm.R": [("Y", 6)], "DEF-upper_arm.L": [("Y", -6)]}
    rest.update(_legs_rest())
    if style in ("claw", "sword"):
        n = 14
        a = {"DEF-root": {"rot": [], "loc": (0, 0.02, 0)},
             "DEF-spine": [("X", 4), ("Z", -22)], "DEF-head": [("X", -10), ("Z", 10)],
             "DEF-upper_arm.R": [("Y", 115), ("X", -25)], "DEF-forearm.R": [("X", -55)],
             "DEF-upper_arm.L": [("Y", -25), ("X", 15)],
             "DEF-thigh.L": [("X", -4)], "DEF-thigh.R": [("X", -12)], "DEF-shin.L": [("X", 12)], "DEF-shin.R": [("X", 20)]}
        b = {"DEF-root": {"rot": [], "loc": (0, -0.06, -0.01)},
             "DEF-spine": [("X", 24), ("Z", 18)], "DEF-head": [("X", -12), ("Z", -8)],
             "DEF-upper_arm.R": [("Y", 30), ("X", -60), ("Z", -25)], "DEF-forearm.R": [("X", -10)],
             "DEF-hand.R": [("X", -30)], "DEF-upper_arm.L": [("Y", -15), ("X", 25)],
             "DEF-thigh.L": [("X", -30)], "DEF-thigh.R": [("X", 8)], "DEF-shin.L": [("X", 30)], "DEF-shin.R": [("X", 10)]}
        keys = ((1, rest), (5, a), (8, b), (n, rest))
    elif style == "slam":
        n = 18
        a = {"DEF-root": {"rot": [], "loc": (0, 0.03, 0.01)}, "DEF-spine": [("X", -12)], "DEF-head": [("X", 8)],
             "DEF-upper_arm.L": [("X", -160), ("Y", -10)], "DEF-upper_arm.R": [("X", -160), ("Y", 10)],
             "DEF-forearm.L": [("X", -30)], "DEF-forearm.R": [("X", -30)]}
        b = {"DEF-root": {"rot": [], "loc": (0, -0.05, -0.04)}, "DEF-spine": [("X", 32)], "DEF-head": [("X", -20)],
             "DEF-upper_arm.L": [("X", -40), ("Y", -10)], "DEF-upper_arm.R": [("X", -40), ("Y", 10)],
             "DEF-forearm.L": [("X", -5)], "DEF-forearm.R": [("X", -5)],
             "DEF-thigh.L": [("X", -30)], "DEF-thigh.R": [("X", -30)], "DEF-shin.L": [("X", 40)], "DEF-shin.R": [("X", 40)]}
        keys = ((1, rest), (8, a), (11, b), (n, rest))
    elif style == "shoot":
        n = 16
        a = {"DEF-spine": [("Z", 20), ("X", 4)], "DEF-head": [("Z", -16)],
             "DEF-upper_arm.L": [("X", -85), ("Y", -10)], "DEF-forearm.L": [("X", -5)],
             "DEF-upper_arm.R": [("X", -80), ("Y", 25)], "DEF-forearm.R": [("Z", -100)]}
        b = {"DEF-spine": [("Z", 22), ("X", 2)], "DEF-head": [("Z", -16)],
             "DEF-upper_arm.L": [("X", -88), ("Y", -10)], "DEF-forearm.L": [("X", -5)],
             "DEF-upper_arm.R": [("X", -70), ("Y", 55)], "DEF-forearm.R": [("Z", -20)]}
        keys = ((1, rest), (7, a), (9, b), (n, rest))
    elif style == "cast":
        n = 20
        a = {"DEF-spine": [("X", -10)], "DEF-head": [("X", 10)],
             "DEF-upper_arm.L": [("X", -150), ("Y", -25)], "DEF-upper_arm.R": [("X", -150), ("Y", 25)],
             "DEF-forearm.L": [("X", -20)], "DEF-forearm.R": [("X", -20)]}
        b = {"DEF-root": {"rot": [], "loc": (0, -0.04, 0)}, "DEF-spine": [("X", 18)], "DEF-head": [("X", -10)],
             "DEF-upper_arm.L": [("X", -80), ("Y", -10)], "DEF-upper_arm.R": [("X", -80), ("Y", 10)],
             "DEF-forearm.L": [("X", -5)], "DEF-forearm.R": [("X", -5)]}
        keys = ((1, rest), (9, a), (13, b), (n, rest))
    else:   # spear
        n = 14
        a = {"DEF-root": {"rot": [], "loc": (0, 0.04, 0)}, "DEF-spine": [("X", 0), ("Z", -15)],
             "DEF-upper_arm.R": [("X", -40), ("Y", 30)], "DEF-forearm.R": [("X", -70)]}
        b = {"DEF-root": {"rot": [], "loc": (0, -0.1, -0.01)}, "DEF-spine": [("X", 20), ("Z", 10)],
             "DEF-upper_arm.R": [("X", -85), ("Y", 10)], "DEF-forearm.R": [("X", -5)],
             "DEF-thigh.L": [("X", -35)], "DEF-thigh.R": [("X", 10)], "DEF-shin.L": [("X", 35)]}
        keys = ((1, rest), (5, a), (8, b), (n, rest))
    K.clip(arm, "attack", n, False)
    for f, pose in keys:
        K.key(arm, f, pose)


def die(arm):
    K.clip(arm, "die", 28, False)
    for f, k in ((1, 0.0), (6, 0.15), (18, 1.0), (22, 0.93), (28, 1.0)):
        K.key(arm, f, {
            "DEF-root": {"rot": [("X", -88 * k)], "loc": (0, 0.02 * k, 0.07 * k)},
            "DEF-spine": [("X", 10 - 20 * k)], "DEF-head": [("X", -25 * k), ("Z", 20 * k)],
            "DEF-upper_arm.L": [("Y", -60 * k), ("X", -30 * k)], "DEF-upper_arm.R": [("Y", 60 * k), ("X", -30 * k)],
            "DEF-forearm.L": [("X", -30 * k)], "DEF-forearm.R": [("X", -30 * k)],
            "DEF-thigh.L": [("X", -50 * k)], "DEF-thigh.R": [("X", -30 * k)],
            "DEF-shin.L": [("X", 40 * k)], "DEF-shin.R": [("X", 60 * k)]})


def animate(arm, attack_style="claw", lean=6, run_lean=18, hold_right=False):
    idle(arm, lean=lean)
    run(arm, lean=run_lean, hold_right=hold_right)
    attack(arm, attack_style)
    die(arm)


# ───────────────────────── shared looks ─────────────────────────

def chibi_face(hc, hr, eye_z, eye_dx=0.064, eye_size=(0.046, 0.02, 0.054), pupil=0.028, slant=-6,
               brow_role=None, brow_tilt=12, mouth_role="Mouth", mouth_w=0.028, shine_role=None,
               chin=True, nose=True, ears=None, skin="Skin", eye_role="Eye", pupil_role="Pupil"):
    """Big-eyed chibi face on the head ellipsoid. ears: None | 'elf' | 'round'."""
    c = Vector(hc)
    K.sphere("Head", skin, "DEF-head", c, hr, u=18, v=12)
    K.eyes("", hc, hr, eye_z, eye_dx, size=eye_size, slant=slant, pupils=pupil, role=eye_role, pupil_role=pupil_role)
    if shine_role:
        for s, sd in ((1, ".L"), (-1, ".R")):
            x = s * (eye_dx + 0.006)
            z = eye_z + eye_size[2] * 0.35
            K.sphere("Shine" + sd, shine_role, "DEF-head", (x, K.ellipsoid_front_y(hc, hr, x, z, -0.012), z),
                     (0.011, 0.006, 0.011), u=8, v=4)
    if brow_role:
        bz = eye_z + eye_size[2] * 1.05
        for s, sd in ((1, ".L"), (-1, ".R")):
            x = s * eye_dx
            K.box("Brow" + sd, brow_role, "DEF-head", (x, K.ellipsoid_front_y(hc, hr, x, bz, 0.004), bz),
                  (0.05, 0.013, 0.012), rotation=(0, math.radians(-brow_tilt) * s, math.radians(16) * s))
    mz = eye_z - eye_size[2] - 0.035
    if nose:
        nz = (eye_z + mz) / 2 - 0.005
        K.sphere("Nose", skin, "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, nz, 0.005), nz), (0.013, 0.01, 0.013), u=8, v=5)
    if mouth_role:
        K.sphere("Mouth", mouth_role, "DEF-head", (0, K.ellipsoid_front_y(hc, hr, 0, mz, 0.007), mz), (mouth_w, 0.006, 0.007), u=8, v=4)
    if chin:
        K.sphere("Chin", skin, "DEF-head", (0, c.y - 0.04, c.z - hr[2] * 0.78), (hr[0] * 0.46, hr[1] * 0.43, hr[2] * 0.27), u=12, v=8)
    if ears:
        for s, sd in ((1, ".L"), (-1, ".R")):
            if ears == "elf":
                K.leaf("Ear" + sd, skin, "DEF-head", (s * (hr[0] - 0.01), c.y + 0.01, eye_z), 0.09, 0.03, side=s,
                       rotation=(0, math.radians(-30), math.radians(-20)))
            else:
                K.sphere("Ear" + sd, skin, "DEF-head", (s * hr[0], c.y + 0.01, eye_z - 0.01), (0.02, 0.03, 0.035), u=8, v=6)


def robe(role, top_z=0.40, hem_z=0.03, top_r=0.10, hem_r=0.2, trim_role=None, ragged=0.0, front_open=False):
    """Long skirt to the floor (casters, queens). Skinned to the legs so it sways with the stride."""
    arc = (110, 430) if front_open else None
    K.skirt("Robe", role, "AUTO", top_z, hem_z, top_r, hem_r, depth=0.85, ragged=ragged, segments=20, thickness=0.012, arc=arc)
    if trim_role:
        K.band("RobeHem", trim_role, "DEF-pelvis", (0, 0, hem_z + 0.012), hem_r + 0.004, (hem_r + 0.004) * 0.85, 0.025, segments=20)


def staff(bone, base, top, role="Wood", r=0.014):
    K.along("Staff", role, bone, base, top, r, r * 0.9, segments=8)


HERO = dict(   # the warden's chibi proportions (H 1.2): heroes start from these and tweak
    hunch=0.01, head_c=(0, -0.035, 0.775), head_r=(0.15, 0.14, 0.17),
    neck0_z=0.55, neck1_z=0.60, chest_z=0.47, waist_z=0.39, pelvis_z=0.33,
    shoulder_z=0.525, shoulder_x=0.105, elbow_out=0.05, elbow_z=0.41,
    wrist_x=0.19, wrist_z=0.31, wrist_y=-0.03, hand_bottom=0.235, hand_size=0.10,
    hip_x=0.06, hip_z=0.31, knee_x=0.075, knee_y=-0.025, knee_z=0.17, ankle_x=0.09, ankle_z=0.085,
    foot_len=0.15,
    r_pelvis=(0.095, 0.068), r_waist=(0.082, 0.058), r_chest=(0.105, 0.072), r_neck0=(0.045, 0.04),
    r_neck1=(0.04, 0.036), r_shoulder=0.038, r_elbow=0.029, r_wrist=0.03, r_hip=0.05, r_knee=0.04, r_ankle=0.034,
)


def hero(**over):
    d = dict(HERO)
    d.update(over)
    return params(**d)
