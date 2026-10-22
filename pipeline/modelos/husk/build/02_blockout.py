"""CH_Husk — Phase 2 blockout: primary masses and the silhouette parts (helmet, ears, hands, feet).
blender --background --python build/02_blockout.py -- --master CH_Husk_master.blend
All constants in metres, H = 1.20 m (brief); fractions of H come from ref/concept.png.
Front = -Y, character's left (.L) = +X.
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
import _lib as L

L.PHASE = "02_blockout"
L.OWNER_TAG = "phase:" + L.PHASE

H = 1.20

# --- measured (brief PROPORTIONS) ---
SPIKE_TIP = 1.00 * H          # P1
SPIKE_BASE = 0.89 * H         # P1
DOME_TOP = 0.885 * H          # P2
BRIM_Z = 0.72 * H             # P2
CHIN_Z = 0.50 * H             # P3
EYE_Z = 0.635 * H             # P4
EAR_Z0, EAR_Z1 = 0.70 * H, 0.78 * H   # P5
EAR_SPAN = 0.567 * H          # P5
HELMET_W = 0.37 * H           # P6
SHOULDER_Z = 0.47 * H         # P7
SHOULDER_W = 0.245 * H        # P7
BELT_Z = 0.34 * H             # P8
BELT_W = 0.205 * H            # P8
CROTCH_Z = 0.25 * H           # P9
CLOTH_HEM = 0.19 * H          # P9
KNEE_Z = 0.14 * H             # P10
ANKLE_Z = 0.06 * H            # P10
FOOT_LEN = 0.16 * H           # P10
HAND_BOTTOM = 0.18 * H        # P11
HAND_SIZE = 0.11 * H          # P11
FEET_APART = 0.23 * H         # P12
HAND_SPAN_X = 0.245           # ref: hands band ~0.88 of the ear span (120 px of 127) -> wrists at +-0.245
CHEST_W = 0.22 * H            # P13
LIMB_R = 0.035 * H            # P13

# --- inferred (no side view) ---
HUNCH = 0.035                 # inferred: chest/head pushed forward (-Y), crouched posture
HEAD_DEPTH = 0.32             # inferred: skull front-to-back


def skin(name, chains, radii_xy, collection="LOW", subdiv=1):
    """Skin-modifier body with per-joint elliptical radii (rx across, ry front-back)."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vert_by_pos, order = {}, []
    for pts in chains:
        prev = None
        for p in pts:
            key = tuple(round(c, 5) for c in p)
            v = vert_by_pos.get(key)
            if v is None:
                v = bm.verts.new(p)
                vert_by_pos[key] = v
                order.append((v, radii_xy[key] if key in radii_xy else radii_xy[p]))
            if prev is not None and prev is not v and not bm.edges.get((prev, v)):
                bm.edges.new((prev, v))
            prev = v
    bm.verts.index_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    L.col(collection).objects.link(ob)
    m = ob.modifiers.new("Skin", "SKIN")
    m.use_smooth_shade = True
    layer = me.skin_vertices[0].data
    for i, (v, r) in enumerate(order):
        layer[i].radius = r
        layer[i].use_root = (i == 0)
    s = ob.modifiers.new("Subdivision", "SUBSURF")
    s.levels = subdiv
    s.render_levels = subdiv
    return L.own(ob)


def joint_table():
    """Joint centres (x, y, z) and skin radii (rx, ry) shared by later phases."""
    sx = SHOULDER_W / 2 - 0.02
    joints = {
        "pelvis": (0, 0.0, CROTCH_Z + 0.05),
        "waist": (0, -0.005, BELT_Z + 0.02),
        "chest": (0, -HUNCH * 0.6, SHOULDER_Z - 0.045),
        "neck0": (0, -HUNCH, SHOULDER_Z + 0.02),
        "neck1": (0, -HUNCH - 0.02, CHIN_Z + 0.04),
    }
    r = {
        "pelvis": (BELT_W / 2 * 0.95, 0.075),
        "waist": (BELT_W / 2 * 0.85, 0.065),
        "chest": (CHEST_W / 2 * 1.05, 0.08),
        "neck0": (0.065, 0.055),       # ref: no visible neck, chin sits on the chest
        "neck1": (0.06, 0.05),
    }
    arms, legs = [], []
    for s in (1, -1):
        sh = (s * sx, -HUNCH * 0.6, SHOULDER_Z - 0.01)
        el = (s * (sx + 0.075), 0.0, SHOULDER_Z - 0.14)            # elbow out (ref arms hang wide)
        wr = (s * HAND_SPAN_X, -0.02, HAND_BOTTOM + HAND_SIZE * 0.85)   # wrist inside the big hand
        hip = (s * 0.07, 0.0, CROTCH_Z + 0.05)
        kn = (s * 0.115, -0.06, KNEE_Z + 0.005)                     # bent knee, inferred depth
        an = (s * (FEET_APART / 2 + 0.02), 0.0, ANKLE_Z + 0.02)
        for k, p in (("sh", sh), ("el", el), ("wr", wr), ("hip", hip), ("kn", kn), ("an", an)):
            joints[k + ("L" if s > 0 else "R")] = p
        r.update({"sh" + ("L" if s > 0 else "R"): (0.048, 0.048),
                  "el" + ("L" if s > 0 else "R"): (LIMB_R * 0.75, LIMB_R * 0.75),
                  "wr" + ("L" if s > 0 else "R"): (0.038, 0.038),      # forearm with wraps ~15 px
                  "hip" + ("L" if s > 0 else "R"): (0.06, 0.06),
                  "kn" + ("L" if s > 0 else "R"): (0.048, 0.048),      # ref leg ~20 px wide
                  "an" + ("L" if s > 0 else "R"): (0.036, 0.036)})
    return joints, r


def body():
    joints, r = joint_table()
    J = lambda k: joints[k]
    chains = [[J("pelvis"), J("waist"), J("chest"), J("neck0"), J("neck1")],
              [J("chest"), J("shL"), J("elL"), J("wrL")], [J("chest"), J("shR"), J("elR"), J("wrR")],
              [J("pelvis"), J("hipL"), J("knL"), J("anL")], [J("pelvis"), J("hipR"), J("knR"), J("anR")]]
    radii = {tuple(round(c, 5) for c in joints[k]): r[k] for k in joints}
    ob = skin("CH_Husk_Body_LOD0", chains, radii)
    return ob, joints


def head(joints):
    cz = CHIN_Z + 0.19
    h = L.sphere("CH_Husk_Head_LOD0", 1.0, u=20, v=12, location=(0, -HUNCH - 0.05, cz),
                 scale=(0.17, HEAD_DEPTH / 2, 0.20))
    # jaw / muzzle mass pushing the lower face forward (ref: mouth at P4 0.555 H)
    L.sphere("CH_Husk_Jaw_LOD0", 1.0, u=14, v=8, location=(0, -HUNCH - 0.14, CHIN_Z + 0.07),
             scale=(0.13, 0.085, 0.075))

    return h


def helmet():
    # dome: upper half of an ellipsoid sitting on the brim
    rx, ry = HELMET_W / 2 * 0.95, 0.205
    rz = DOME_TOP - BRIM_Z
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=12, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.05], context="VERTS")
    bmesh.ops.scale(bm, vec=(rx, ry, rz), verts=bm.verts)
    L.new_mesh_object("CH_Husk_HelmetDome_LOD0", bm, "LOW", location=(0, -HUNCH - 0.02, BRIM_Z))
    # brim ring
    L.cylinder("CH_Husk_HelmetBrim_LOD0", rx + 0.01, 0.045, segments=24,
               location=(0, -HUNCH - 0.02, BRIM_Z + 0.01)).scale = (1.0, (ry + 0.01) / (rx + 0.01), 1.0)
    # cheek/neck guards: curved plates hugging the face from the cheek round to the nape (ref P6)
    for s in (1, -1):
        bm = bmesh.new()
        cols = []
        for i in range(9):
            th = math.radians(58 + (125 - 58) * i / 8)   # cheek round to behind the ear, not a full bucket
            x, y = s * math.sin(th) * (rx - 0.005), -math.cos(th) * (ry - 0.005)
            cols.append((bm.verts.new((x, y, 0.0)), bm.verts.new((x * 0.93, y * 0.93, -(BRIM_Z - CHIN_Z - 0.01)))))
        for (a0, b0), (a1, b1) in zip(cols, cols[1:]):
            bm.faces.new((a0, a1, b1, b0) if s > 0 else (a0, b0, b1, a1))
        g = L.new_mesh_object("CH_Husk_HelmetGuard%s_LOD0" % (".L" if s > 0 else ".R"), bm, "LOW",
                              location=(0, -HUNCH - 0.02, BRIM_Z + 0.01))
        L.solidify(g, 0.018)
    L.cylinder("CH_Husk_HelmetSpike_LOD0", 0.04, SPIKE_TIP - SPIKE_BASE + 0.02, segments=12,
               radius_top=0.003, location=(0, -HUNCH - 0.02, (SPIKE_TIP + SPIKE_BASE - 0.02) / 2))


def ears():
    length = EAR_SPAN / 2 - 0.13
    for s in (1, -1):
        bm = bmesh.new()
        rings = []
        for i in range(9):
            u = i / 8
            w = 0.085 * (1 - u) ** 0.9 + 0.003          # leaf half-height along the ear
            ring = []
            for k in range(10):
                a = 2 * math.pi * k / 10
                ring.append(bm.verts.new((u * length, math.sin(a) * w * 0.28, math.cos(a) * w + u * u * 0.03)))
            rings.append(ring)
        for r0, r1 in zip(rings, rings[1:]):
            for k in range(10):
                bm.faces.new((r0[k], r0[(k + 1) % 10], r1[(k + 1) % 10], r1[k]))
        bm.faces.new(list(reversed(rings[0])))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        if s < 0:
            bmesh.ops.scale(bm, vec=(-1, 1, 1), verts=bm.verts)
            bmesh.ops.reverse_faces(bm, faces=bm.faces)
        ob = L.new_mesh_object("CH_Husk_Ear%s_LOD0" % (".L" if s > 0 else ".R"), bm, "LOW",
                               location=(s * 0.14, -HUNCH - 0.03, EAR_Z0 - 0.02))
        ob.rotation_euler = (0, math.radians(-22) * s, math.radians(-12) * s)   # tip up and slightly back


def hands(joints):
    for side, s in (("L", 1), ("R", -1)):
        wx, wy, wz = joints["wr" + side]
        c = (wx + s * 0.01, wy - 0.01, HAND_BOTTOM + HAND_SIZE * 0.45)
        L.sphere("CH_Husk_Hand.%s_LOD0" % side, 1.0, u=12, v=8, location=c,
                 scale=(0.055, 0.05, HAND_SIZE * 0.5))


def feet(joints):
    for side, s in (("L", 1), ("R", -1)):
        ax, ay, az = joints["an" + side]
        ob = L.sphere("CH_Husk_Foot.%s_LOD0" % side, 1.0, u=12, v=8,
                      location=(ax + s * 0.01, ay - FOOT_LEN * 0.32, 0.045), scale=(0.062, FOOT_LEN / 2 + 0.01, 0.05))
        ob.rotation_euler.z = math.radians(18) * s    # toes splay outward


def loincloth():
    bm = bmesh.new()
    seg = 16
    top_r, bot_r = BELT_W / 2 * 1.05, BELT_W / 2 * 1.25
    top, bot = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        side = abs(math.cos(a))                              # 1 at the hips' sides
        hem = CLOTH_HEM + 0.07 * side ** 2 - (0.025 if i % 2 else 0.0)   # ragged, shorter at the sides
        top.append(bm.verts.new((math.cos(a) * top_r, math.sin(a) * top_r * 0.75, BELT_Z)))
        bot.append(bm.verts.new((math.cos(a) * bot_r, math.sin(a) * bot_r * 0.8, hem)))
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((top[i], top[j], bot[j], bot[i]))
    ob = L.new_mesh_object("CH_Husk_Loincloth_LOD0", bm, "LOW")
    L.solidify(ob, 0.012)
    L.cylinder("CH_Husk_Belt_LOD0", BELT_W / 2 * 1.08, 0.035, segments=20,
               location=(0, 0, BELT_Z)).scale = (1, 0.78, 1)


def build(scene, args):
    ob, joints = body()
    head(joints)
    helmet()
    ears()
    hands(joints)
    feet(joints)
    loincloth()
    L.log("blockout objects:", len([o for o in bpy.data.objects if o.get("owner") == L.OWNER_TAG]))


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
