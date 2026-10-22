"""CH_Husk — Phase 8 animation: idle, run (in place), attack (claw swipe), die. 24 fps.
Names match what the game looks for (model_rig._match_anim): idle, run, attack, die.
Rotations are authored about world axes in the rest pose (front = -Y): a negative angle about X
swings a hanging limb forward, a positive one leans the spine forward.
Run after 06.
blender --background --python build/08_anim.py -- --master CH_Husk_master.blend
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Matrix, Vector, Quaternion
import _lib as L

L.PHASE = "08_anim"
FPS = 24
CLIPS = {}   # name -> (frames, loop)


def world_rot(pb, axis, deg):
    """Local quaternion that turns pose bone pb by deg about a world axis (in its rest frame)."""
    m = pb.bone.matrix_local.to_3x3()
    rw = Matrix.Rotation(math.radians(deg), 3, axis)
    return (m.inverted() @ rw @ m).to_quaternion()


def key(arm, frame, pose):
    """pose = {bone: [(axis, deg), ...] or {'rot': [...], 'loc': (x, y, z)}} keyed at frame."""
    for pb in arm.pose.bones:
        spec = pose.get(pb.name, [])
        rots = spec.get("rot", []) if isinstance(spec, dict) else spec
        q = Quaternion()
        for axis, deg in rots:
            q = world_rot(pb, axis, deg) @ q
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        loc = spec.get("loc") if isinstance(spec, dict) else None
        if pb.name == "DEF-root" or loc is not None:
            pb.location = pb.bone.matrix_local.to_3x3().inverted() @ Vector(loc or (0, 0, 0))
            pb.keyframe_insert("location", frame=frame)


def new_clip(arm, name, frames, loop):
    old = bpy.data.actions.get(name)
    if old:
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    arm.animation_data_create()
    arm.animation_data.action = act
    CLIPS[name] = (frames, loop)
    return act


def idle(arm):
    new_clip(arm, "idle", 48, True)
    for f, k in ((1, 0.0), (25, 1.0), (49, 0.0)):
        key(arm, f, {
            "DEF-root": {"rot": [], "loc": (0, 0, -0.008 * k)},
            "DEF-spine": [("X", 6 + 3 * k)],                       # hunched, breathing
            "DEF-head": [("X", -4 - 3 * k), ("Z", 4 * k)],
            "DEF-upper_arm.L": [("Y", -6 - 2 * k), ("X", -4 * k)],
            "DEF-upper_arm.R": [("Y", 6 + 2 * k), ("X", 4 * k)],
            "DEF-forearm.L": [("X", -10 - 4 * k)], "DEF-forearm.R": [("X", -10 - 4 * k)],
            "DEF-thigh.L": [("X", -8)], "DEF-thigh.R": [("X", -8)],
            "DEF-shin.L": [("X", 14 + 3 * k)], "DEF-shin.R": [("X", 14 + 3 * k)],
        })


def run(arm):
    new_clip(arm, "run", 16, True)
    for f in range(1, 18, 2):
        ph = 2 * math.pi * (f - 1) / 16
        sw, up = math.sin(ph), abs(math.cos(ph))
        key(arm, f, {
            "DEF-root": {"rot": [], "loc": (0, 0, 0.03 * up - 0.02)},
            "DEF-spine": [("X", 18)],                              # leans into the scurry
            "DEF-head": [("X", -14), ("Z", 5 * sw)],
            "DEF-thigh.L": [("X", -40 * sw - 5)], "DEF-thigh.R": [("X", 40 * sw - 5)],
            "DEF-shin.L": [("X", 30 + 30 * max(0, sw))], "DEF-shin.R": [("X", 30 + 30 * max(0, -sw))],
            "DEF-foot.L": [("X", -10 * sw)], "DEF-foot.R": [("X", 10 * sw)],
            "DEF-upper_arm.L": [("X", 35 * sw), ("Y", -10)], "DEF-upper_arm.R": [("X", -35 * sw), ("Y", 10)],
            "DEF-forearm.L": [("X", -35)], "DEF-forearm.R": [("X", -35)],
        })


def attack(arm):
    new_clip(arm, "attack", 14, False)
    rest = {"DEF-spine": [("X", 8)], "DEF-head": [("X", -6)], "DEF-thigh.L": [("X", -8)],
            "DEF-thigh.R": [("X", -8)], "DEF-shin.L": [("X", 14)], "DEF-shin.R": [("X", 14)],
            "DEF-upper_arm.R": [("Y", 6)], "DEF-upper_arm.L": [("Y", -6)]}
    windup = {   # claw raised OUT to the side (the helmet is wider than the shoulders)
        "DEF-root": {"rot": [], "loc": (0, 0.02, 0)},
        "DEF-spine": [("X", 4), ("Z", -22)], "DEF-head": [("X", -10), ("Z", 10)],
        "DEF-upper_arm.R": [("Y", 115), ("X", -25)], "DEF-forearm.R": [("X", -55)],
        "DEF-upper_arm.L": [("Y", -25), ("X", 15)],
        "DEF-thigh.L": [("X", -4)], "DEF-thigh.R": [("X", -12)], "DEF-shin.L": [("X", 12)], "DEF-shin.R": [("X", 20)],
    }
    strike = {   # swipe down and across the front, lunging
        "DEF-root": {"rot": [], "loc": (0, -0.06, -0.01)},
        "DEF-spine": [("X", 24), ("Z", 18)], "DEF-head": [("X", -12), ("Z", -8)],
        "DEF-upper_arm.R": [("Y", 30), ("X", -60), ("Z", -25)], "DEF-forearm.R": [("X", -10)],
        "DEF-hand.R": [("X", -30)],
        "DEF-upper_arm.L": [("Y", -15), ("X", 25)],
        "DEF-thigh.L": [("X", -30)], "DEF-thigh.R": [("X", 8)], "DEF-shin.L": [("X", 30)], "DEF-shin.R": [("X", 10)],
    }
    for f, pose in ((1, rest), (5, windup), (8, strike), (14, rest)):
        key(arm, f, pose)


def die(arm):
    new_clip(arm, "die", 28, False)
    poses = {1: 0.0, 6: 0.15, 18: 1.0, 22: 0.93, 28: 1.0}
    for f, k in poses.items():
        key(arm, f, {
            "DEF-root": {"rot": [("X", -88 * k)], "loc": (0, 0.02 * k, 0.07 * k)},   # topples backward
            "DEF-spine": [("X", 10 - 20 * k)],
            "DEF-head": [("X", -25 * k), ("Z", 20 * k)],
            "DEF-upper_arm.L": [("Y", -60 * k), ("X", -30 * k)], "DEF-upper_arm.R": [("Y", 60 * k), ("X", -30 * k)],
            "DEF-forearm.L": [("X", -30 * k)], "DEF-forearm.R": [("X", -30 * k)],
            "DEF-thigh.L": [("X", -50 * k)], "DEF-thigh.R": [("X", -30 * k)],
            "DEF-shin.L": [("X", 40 * k)], "DEF-shin.R": [("X", 60 * k)],
        })


def build():
    arm = bpy.data.objects["CH_Husk_Rig"]
    bpy.context.scene.render.fps = FPS
    for fn in (idle, run, attack, die):
        fn(arm)
    for name, (frames, loop) in CLIPS.items():
        act = bpy.data.actions[name]
        act.frame_range = (1, frames + 1 if loop else frames)
        act.use_frame_range = True
        act.use_cyclic = loop
    # rest pose stays the default; no action left assigned so the exporter sees every clip
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_quaternion = Quaternion(); pb.location = (0, 0, 0)
    L.log("clips:", {k: v for k, v in CLIPS.items()})


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--master", required=True)
    a = p.parse_args(L.argv_after_dashes())
    L.open_master(a.master)
    build()
    L.save_master(a.master)
