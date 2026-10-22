"""CH_Husk — Phase 3 forms: face (nose, eyes, brows, mouth, teeth, cheekbones), helmet bands and
spike collar, fingers and thumbs, toes, cloth wraps, belt buckle.
blender --background --python build/03_forms.py -- --master CH_Husk_master.blend
Constants and joint centres come from 02_blockout.py so both phases stay in step.
"""
import os, sys, math, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy, bmesh
from mathutils import Vector, Matrix, Euler
import _lib as L

_spec = importlib.util.spec_from_file_location("blockout", os.path.join(HERE, "02_blockout.py"))
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)

L.PHASE = "03_forms"
L.OWNER_TAG = "phase:" + L.PHASE

H = B.H
HEAD_C = Vector((0, -B.HUNCH - 0.05, B.CHIN_Z + 0.19))     # 02 head centre
HEAD_R = Vector((0.17, B.HEAD_DEPTH / 2, 0.20))            # 02 head radii


def face_y(x, z, inset=0.0):
    """Front surface of the head ellipsoid at (x, z), pushed in by inset."""
    k = 1 - (x / HEAD_R.x) ** 2 - ((z - HEAD_C.z) / HEAD_R.z) ** 2
    return HEAD_C.y - HEAD_R.y * math.sqrt(max(k, 0.0)) + inset


def along(name, a, b, radius, t0, t1, segments=12):
    """Cylinder wrapped around the limb segment a->b between fractions t0..t1 (wraps, bands)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    c = a + d * ((t0 + t1) / 2)
    ob = L.cylinder(name, radius, d.length * (t1 - t0), segments=segments, location=c)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    return ob


def face():
    # nose: long and pointed, hanging down-forward (ref)
    base = Vector((0, face_y(0, 0.745, 0.01), 0.745))
    tip = base + Vector((0, -0.075, -0.05))
    along("CH_Husk_Nose_LOD0", base, tip, 0.034, 0.0, 1.0, segments=10).data   # placeholder shape
    nose = bpy.data.objects["CH_Husk_Nose_LOD0"]
    bm = bmesh.new(); bm.from_mesh(nose.data)
    for v in bm.verts:                       # taper to a point toward the tip (+Z local)
        if v.co.z > 0:
            v.co.x *= 0.15; v.co.y *= 0.15
    bm.to_mesh(nose.data); bm.free()
    for s in (1, -1):
        side = ".L" if s > 0 else ".R"
        ex = s * 0.068
        e = L.sphere("CH_Husk_Eye%s_LOD0" % side, 1.0, u=12, v=6,
                     location=(ex, face_y(ex, B.EYE_Z, 0.012), B.EYE_Z), scale=(0.042, 0.02, 0.026))
        e.rotation_euler = (0, math.radians(-14) * s, math.radians(14) * s)     # angry slant, follows the face
        bx = s * 0.062
        br = L.box("CH_Husk_Brow%s_LOD0" % side, (0.10, 0.045, 0.03),
                   location=(bx, face_y(bx, B.EYE_Z + 0.04, 0.006), B.EYE_Z + 0.042))
        br.rotation_euler = (0, math.radians(-24) * s, math.radians(14) * s)
        L.sphere("CH_Husk_Cheek%s_LOD0" % side, 0.045, u=10, v=6,
                 location=(s * 0.105, face_y(s * 0.105, 0.715, 0.03), 0.715), scale=(1.0, 0.8, 0.9))
    mz = 0.555 * H                                                  # P4 mouth
    L.sphere("CH_Husk_Mouth_LOD0", 1.0, u=12, v=6, location=(0, -0.262, mz), scale=(0.075, 0.03, 0.03))
    for i, x in enumerate((-0.048, -0.024, 0.0, 0.024, 0.048)):
        top = i % 2 == 0
        L.box("CH_Husk_Tooth%d_LOD0" % i, (0.017, 0.012, 0.022),
              location=(x, -0.288, mz + (0.012 if top else -0.012)))


def helmet_details():
    rx, ry, rz = B.HELMET_W / 2 * 0.95 * 1.03, 0.205 * 1.03, (B.DOME_TOP - B.BRIM_Z) * 1.03
    c = Vector((0, -B.HUNCH - 0.02, B.BRIM_Z))
    for name, plane in (("FrontBack", "YZ"), ("SideSide", "XZ")):
        bm = bmesh.new()
        rows = []
        n = 16
        for i in range(n + 1):
            a = math.pi * i / n
            if plane == "YZ":
                p = Vector((0, -math.cos(a) * ry, math.sin(a) * rz))
                w = Vector((0.026, 0, 0))
            else:
                p = Vector((-math.cos(a) * rx, 0, math.sin(a) * rz))
                w = Vector((0, 0.026, 0))
            rows.append((bm.verts.new(p - w), bm.verts.new(p + w)))
        for (a0, b0), (a1, b1) in zip(rows, rows[1:]):
            bm.faces.new((a0, a1, b1, b0))
        ob = L.new_mesh_object("CH_Husk_HelmetBand%s_LOD0" % name, bm, "LOW", location=c)
        L.solidify(ob, 0.012, offset=1.0)
    L.cylinder("CH_Husk_SpikeCollar_LOD0", 0.05, 0.03, segments=12, location=(0, c.y, B.SPIKE_BASE - 0.005))


def hands_feet(joints):
    for side, s in (("L", 1), ("R", -1)):
        wx, wy, wz = joints["wr" + side]
        hc = Vector((wx + s * 0.01, wy - 0.01, B.HAND_BOTTOM + B.HAND_SIZE * 0.45))
        for i, dx in enumerate((-0.03, 0.0, 0.03)):
            top = hc + Vector((dx, -0.03, -0.035))
            tip = top + Vector((dx * 0.3, -0.025, -0.06))          # fingers curl forward
            along("CH_Husk_Finger%d.%s_LOD0" % (i, side), top, tip, 0.017, 0.0, 1.0, segments=8)
            L.sphere("CH_Husk_FingerTip%d.%s_LOD0" % (i, side), 0.017, u=6, v=4, location=tip)
        th0 = hc + Vector((-s * 0.045, -0.03, 0.0))
        th1 = th0 + Vector((-s * 0.02, -0.04, -0.035))
        along("CH_Husk_Thumb.%s_LOD0" % side, th0, th1, 0.016, 0.0, 1.0, segments=8)
        ax, ay, az = joints["an" + side]
        foot_c = Vector((ax + s * 0.01, ay - B.FOOT_LEN * 0.32, 0.045))
        rot = Matrix.Rotation(math.radians(18) * s, 3, "Z")
        for i, dx in enumerate((-0.035, 0.0, 0.035)):
            p = foot_c + rot @ Vector((dx, -B.FOOT_LEN / 2 - 0.005, -0.02))
            L.sphere("CH_Husk_Toe%d.%s_LOD0" % (i, side), 0.024, u=8, v=5, location=p, scale=(1, 1.2, 0.8))
        # cloth wraps: forearm just above the hand, shin just above the ankle (ref P11)
        along("CH_Husk_WrapArm.%s_LOD0" % side, joints["wr" + side], joints["el" + side], 0.044, 0.05, 0.45, segments=10)
        along("CH_Husk_WrapAnkle.%s_LOD0" % side, joints["an" + side], joints["kn" + side], 0.043, 0.0, 0.4, segments=10)


def belt_buckle():
    front_y = -(B.BELT_W / 2 * 1.08) * 0.78
    L.box("CH_Husk_Buckle_LOD0", (0.055, 0.014, 0.04), location=(0, front_y - 0.006, B.BELT_Z))


def build(scene, args):
    joints, _ = B.joint_table()
    face()
    helmet_details()
    hands_feet(joints)
    belt_buckle()
    L.log("form objects:", len([o for o in bpy.data.objects if o.get("owner") == L.OWNER_TAG]))


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--master", required=True)
    a = p.parse_args(L.argv_after_dashes())
    scene = L.open_master(a.master)
    L.clear_owned()
    build(scene, a)
    L.save_master(a.master)
    L.log("saved", a.master)
