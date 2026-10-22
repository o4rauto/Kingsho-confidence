"""Bastion Rush — character kit for Blender (bpy, background-safe).

Generalised from the husk pilot (pipeline/modelos/husk/, built with the blender-image-to-3d skill).
A character module (pipeline/modelos/<id>/modelo.py) builds its parts with these helpers; each part
carries two custom props read by the rig step:
    ob["role"] -> palette key used for its material ("Skin", "Steel", ...)
    ob["bone"] -> deformation bone that owns it 100 %, or "AUTO" for automatic (bone heat) weights
Conventions: metres, Z up, the character faces -Y (= +Z in Godot), character's left (.L) = +X.
"""
import math
import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion


# ───────────────────────── scene and collections ─────────────────────────

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for name in ("LOW", "RIG_DEF", "EXPORT", "SOCKETS"):
        col(name)


def col(name):
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(c)
    return c


def _obj(name, bm, role, bone, location=(0, 0, 0), rotation=(0, 0, 0), smooth=True, scale=(1, 1, 1)):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.location = location
    ob.rotation_euler = rotation
    ob.scale = scale
    col("LOW").objects.link(ob)
    ob["role"] = role
    ob["bone"] = bone
    if smooth:
        shade_smooth(ob)
    return ob


def shade_smooth(ob, sharp_deg=48):
    for p in ob.data.polygons:
        p.use_smooth = True
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    for e in bm.edges:
        if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(sharp_deg):
            e.smooth = False
    bm.to_mesh(ob.data)
    bm.free()


# ───────────────────────── primitives ─────────────────────────

def sphere(name, role, bone, center, radii, u=14, v=8, rotation=(0, 0, 0)):
    """Ellipsoid with radii (rx, ry, rz)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=radii, verts=bm.verts)
    return _obj(name, bm, role, bone, center, rotation)


def box(name, role, bone, center, size, rotation=(0, 0, 0), bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES", profile=0.5)
    return _obj(name, bm, role, bone, center, rotation, smooth=bevel > 0)


def cone(name, role, bone, center, r0, r1, height, axis="Z", segments=12, rotation=(0, 0, 0), cap=True):
    """Frustum centred at center along axis (r0 at -h/2, r1 at +h/2)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap, cap_tris=False, segments=segments, radius1=r0, radius2=r1, depth=height)
    if axis == "X":
        bmesh.ops.rotate(bm, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "Y"), verts=bm.verts)
    elif axis == "Y":
        bmesh.ops.rotate(bm, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(-90), 3, "X"), verts=bm.verts)
    return _obj(name, bm, role, bone, center, rotation)


def along(name, role, bone, a, b, r0, r1=None, t0=0.0, t1=1.0, segments=10, cap=True):
    """Frustum along the segment a->b between fractions t0..t1 (limbs, poles, wraps, horns)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    c = a + d * ((t0 + t1) / 2)
    ob = cone(name, role, bone, c, r0, r0 if r1 is None else r1, max(d.length * (t1 - t0), 1e-4), segments=segments, cap=cap)
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    return ob


def plate(name, role, bone, center, outline, thickness=0.02, rotation=(0, 0, 0), bulge=0.0):
    """Flat piece facing -Y, extruded from a convex 2D outline [(x, z), ...]: kite shields, blades, banners,
    fins. bulge pushes the front centre forward (a domed shield face)."""
    bm = bmesh.new()
    cx = sum(x for x, _ in outline) / len(outline)
    cz = sum(z for _, z in outline) / len(outline)
    front = [bm.verts.new((x, -thickness / 2, z)) for x, z in outline]
    back = [bm.verts.new((x, thickness / 2, z)) for x, z in outline]
    mid = bm.verts.new((cx, -thickness / 2 - bulge, cz))
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[j], front[i], mid))
        bm.faces.new((front[i], front[j], back[j], back[i]))
    bm.faces.new(back)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _obj(name, bm, role, bone, center, rotation)


def capsule(name, role, bone, a, b, r, segments=10):
    """Rounded limb: tube a->b with ball ends, one object."""
    a, b = Vector(a), Vector(b)
    bm = bmesh.new()
    d = b - a
    q = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4()
    ring_n, rings = segments, []
    hemi = 3
    profile = []
    for i in range(hemi, 0, -1):
        ang = math.pi / 2 * i / hemi
        profile.append((-math.sin(ang) * r, math.cos(ang) * r))
    profile.append((0.0, r))
    profile.append((d.length, r))
    for i in range(1, hemi + 1):
        ang = math.pi / 2 * i / hemi
        profile.append((d.length + math.sin(ang) * r, math.cos(ang) * r))
    for z, rr in profile:
        ring = []
        for k in range(ring_n):
            t = 2 * math.pi * k / ring_n
            ring.append(bm.verts.new(q @ Vector((math.cos(t) * max(rr, 1e-4), math.sin(t) * max(rr, 1e-4), z))))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(ring_n):
            bm.faces.new((r0[k], r0[(k + 1) % ring_n], r1[(k + 1) % ring_n], r1[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _obj(name, bm, role, bone, a)


def leaf(name, role, bone, root, length, width, thick=0.28, curl=0.03, side=1, rotation=(0, 0, 0),
         rings=9, seg=10, power=0.9):
    """Pointed leaf along +X (mirrored to -X when side < 0): ears, wings, flames, leaves, blades."""
    bm = bmesh.new()
    rs = []
    for i in range(rings):
        u = i / (rings - 1)
        w = width * (1 - u) ** power + 0.003
        ring = []
        for k in range(seg):
            a = 2 * math.pi * k / seg
            ring.append(bm.verts.new((u * length, math.sin(a) * w * thick, math.cos(a) * w + u * u * curl)))
        rs.append(ring)
    for r0, r1 in zip(rs, rs[1:]):
        for k in range(seg):
            bm.faces.new((r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]))
    bm.faces.new(list(reversed(rs[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if side < 0:
        bmesh.ops.scale(bm, vec=(-1, 1, 1), verts=bm.verts)
        bmesh.ops.reverse_faces(bm, faces=bm.faces)
    rot = (rotation[0], rotation[1] * side, rotation[2] * side)
    return _obj(name, bm, role, bone, root, rot)


def lock(name, role, bone, root, direction, length, width, thick=0.35, curl=0.04, power=0.8):
    """A leaf pointed along an arbitrary direction (hair locks, flames, feathers, fins, leaves).
    The flat side faces the camera when direction is mostly vertical; curl bends the tip 'up'."""
    ob = leaf(name, role, bone, (0, 0, 0), length, width, thick=thick, curl=curl, power=power)
    d = Vector(direction).normalized()
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = Vector((1, 0, 0)).rotation_difference(d)
    ob.location = Vector(root)
    return ob


def dome(name, role, bone, base_center, radii, cut=-0.05, u=20, v=10, face_open=None):
    """Upper part of an ellipsoid sitting on base_center (helmets, caps, shells, hoods).
    face_open=(y, z) removes the front window y < -y, z < z (unit-sphere units) for hoods and cowls."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    gone = [x for x in bm.verts if x.co.z < cut or (face_open and x.co.y < -face_open[0] and x.co.z < face_open[1])]
    bmesh.ops.delete(bm, geom=gone, context="VERTS")
    bmesh.ops.scale(bm, vec=radii, verts=bm.verts)
    return _obj(name, bm, role, bone, base_center)


def band(name, role, bone, center, rx, ry, height, thickness=0.012, segments=20, z_tilt=0.0):
    """Closed elliptical strip (belts, helmet brims, collars, bracelets)."""
    bm = bmesh.new()
    top, bot = [], []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        x, y = math.cos(a) * rx, math.sin(a) * ry
        top.append(bm.verts.new((x, y, height / 2 + y * z_tilt)))
        bot.append(bm.verts.new((x, y, -height / 2 + y * z_tilt)))
    for i in range(segments):
        j = (i + 1) % segments
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    ob = _obj(name, bm, role, bone, center)
    solidify(ob, thickness, offset=1.0)
    return ob


def arc_strip(name, role, bone, center, rx, ry, rz, width, plane="YZ", n=16, thickness=0.012):
    """Half-ellipse strip over a dome (helmet bands, hood seams, ribs)."""
    bm = bmesh.new()
    rows = []
    for i in range(n + 1):
        a = math.pi * i / n
        if plane == "YZ":
            p, w = Vector((0, -math.cos(a) * ry, math.sin(a) * rz)), Vector((width / 2, 0, 0))
        else:
            p, w = Vector((-math.cos(a) * rx, 0, math.sin(a) * rz)), Vector((0, width / 2, 0))
        rows.append((bm.verts.new(p - w), bm.verts.new(p + w)))
    for (a0, b0), (a1, b1) in zip(rows, rows[1:]):
        bm.faces.new((a0, a1, b1, b0))
    ob = _obj(name, bm, role, bone, center)
    solidify(ob, thickness, offset=1.0)
    return ob


def skirt(name, role, bone, top_z, bot_z, top_r, bot_r, depth=0.78, ragged=0.0, side_lift=0.0,
          segments=16, thickness=0.012, center=(0, 0, 0), arc=None):
    """Open tube from top ring to bottom ring: skirts, robes, loincloths, capes (with ragged hem).
    arc=(a0, a1) in degrees keeps only part of the ring (0 = +X, 90 = back/+Y): capes, aprons."""
    bm = bmesh.new()
    top, bot = [], []
    cx, cy = center[0], center[1]
    n = segments + (1 if arc else 0)
    for i in range(n):
        a = (math.radians(arc[0] + (arc[1] - arc[0]) * i / segments) if arc else 2 * math.pi * i / segments)
        side = abs(math.cos(a))
        hem = bot_z + side_lift * side ** 2 - (ragged if i % 2 else 0.0)
        top.append(bm.verts.new((cx + math.cos(a) * top_r, cy + math.sin(a) * top_r * depth, top_z)))
        bot.append(bm.verts.new((cx + math.cos(a) * bot_r, cy + math.sin(a) * bot_r * depth, hem)))
    for i in range(segments if not arc else n - 1):
        j = (i + 1) % n
        bm.faces.new((top[i], top[j], bot[j], bot[i]))
    ob = _obj(name, bm, role, bone)
    solidify(ob, thickness)
    return ob


def lathe(name, role, bone, center, profile_rz, segments=16):
    """Spin a (radius, z) profile around Z: pots, crowns, staffs' heads, collars, cones with bulges."""
    bm = bmesh.new()
    rings = []
    for r, z in profile_rz:
        ring = []
        for k in range(segments):
            a = 2 * math.pi * k / segments
            ring.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, z)))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(segments):
            bm.faces.new((r0[k], r0[(k + 1) % segments], r1[(k + 1) % segments], r1[k]))
    if profile_rz[0][0] > 1e-4:
        bm.faces.new(list(reversed(rings[0])))
    if profile_rz[-1][0] > 1e-4:
        bm.faces.new(rings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _obj(name, bm, role, bone, center)


def skin_body(name, role, chains, radii, subdiv=1):
    """Skin-modifier mass from joint chains; radii maps rounded joint position -> (rx, ry). AUTO weights."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    seen, order = {}, []
    for pts in chains:
        prev = None
        for p in pts:
            key = tuple(round(c, 5) for c in p)
            v = seen.get(key)
            if v is None:
                v = bm.verts.new(p)
                seen[key] = v
                order.append((v, radii[key]))
            if prev is not None and prev is not v and not bm.edges.get((prev, v)):
                bm.edges.new((prev, v))
            prev = v
    bm.verts.index_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    col("LOW").objects.link(ob)
    m = ob.modifiers.new("Skin", "SKIN")
    m.use_smooth_shade = True
    layer = me.skin_vertices[0].data
    for i, (v, r) in enumerate(order):
        layer[i].radius = r
        layer[i].use_root = (i == 0)
    s = ob.modifiers.new("Subdivision", "SUBSURF")
    s.levels = s.render_levels = subdiv
    ob["role"] = role
    ob["bone"] = "AUTO"
    return ob


def solidify(ob, thickness, offset=-1.0):
    m = ob.modifiers.new("Solidify", "SOLIDIFY")
    m.thickness = thickness
    m.offset = offset
    m.use_rim = True
    return m


def taper_tip(ob, axis_index=2, keep=0.15):
    """Pull the + end of a primitive to a point (noses, spikes, claws) in its local frame."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    for v in bm.verts:
        if v.co[axis_index] > 0:
            for i in range(3):
                if i != axis_index:
                    v.co[i] *= keep
    bm.to_mesh(ob.data)
    bm.free()
    return ob


def mirrored(fn):
    """Call fn(s, side) for the character's left (s=+1, '.L') and right (s=-1, '.R')."""
    return [fn(s, ".L" if s > 0 else ".R") for s in (1, -1)]


# ───────────────────────── face kit ─────────────────────────

def ellipsoid_front_y(center, radii, x, z, inset=0.0):
    k = 1 - (x / radii[0]) ** 2 - ((z - center[2]) / radii[2]) ** 2
    return center[1] - radii[1] * math.sqrt(max(k, 0.0)) + inset


def eyes(prefix, head_c, head_r, z, dx, size=(0.04, 0.02, 0.026), role="Eye", bone="DEF-head", slant=-14,
         pupils=None, pupil_role="Pupil", inset=0.012):
    out = []
    for s, side in ((1, ".L"), (-1, ".R")):
        x = s * dx
        y = ellipsoid_front_y(head_c, head_r, x, z, inset)
        e = sphere(prefix + "Eye" + side, role, bone, (x, y, z), size, u=12, v=6,
                   rotation=(0, math.radians(slant) * s, math.radians(14) * s))
        out.append(e)
        if pupils:
            sphere(prefix + "Pupil" + side, pupil_role, bone, (x * 0.97, y - size[1] * 0.75, z - size[2] * 0.05),
                   (pupils, pupils * 0.5, pupils), u=8, v=5)
    return out


# ───────────────────────── materials ─────────────────────────

def _lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple([x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c] + [1.0])


def paint(prefix, palette, glow=()):
    """palette: role -> hex (or (hex, roughness, metallic)). Roles in glow get a soft emission."""
    mats = {}
    for role, spec in palette.items():
        hx, rough, metal = (spec, 0.85, 0.0) if isinstance(spec, str) else spec
        m = bpy.data.materials.get(prefix + role) or bpy.data.materials.new(prefix + role)
        bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = _lin(hx)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if role in glow:
            bsdf.inputs["Emission Color"].default_value = _lin(hx)
            bsdf.inputs["Emission Strength"].default_value = 0.6
        mats[role] = m
    missing = set()
    for ob in col("LOW").all_objects:
        if ob.type != "MESH":
            continue
        role = ob.get("role", "Skin")
        if role not in mats:
            missing.add(role)
            continue
        ob.data.materials.clear()
        ob.data.materials.append(mats[role])
    if missing:
        raise RuntimeError("palette has no colour for roles: %s" % sorted(missing))


# ───────────────────────── rig ─────────────────────────

def armature(name, bones):
    """bones = [(name, head, tail, parent_or_None), ...] — all deforming."""
    arm = bpy.data.armatures.new(name)
    ob = bpy.data.objects.new(name, arm)
    col("RIG_DEF").objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    for bname, head, tail, parent in bones:
        eb = arm.edit_bones.new(bname)
        eb.head, eb.tail = Vector(head), Vector(tail)
        eb.use_deform = True
        if parent:
            eb.parent = arm.edit_bones[parent]
            eb.use_connect = (Vector(head) - arm.edit_bones[parent].tail).length < 1e-5
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def _bind_auto(mesh_ob, arm_ob):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    mesh_ob.select_set(True)
    arm_ob.select_set(True)
    bpy.context.view_layer.objects.active = arm_ob
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def rig_and_join(name, arm):
    """Delivery copies (modifiers applied) -> weights (AUTO or 100 % to ob['bone']) -> one skinned mesh."""
    dg = bpy.context.evaluated_depsgraph_get()
    bone_names = {b.name for b in arm.data.bones}
    parts = []
    for ob in list(col("LOW").all_objects):
        if ob.type != "MESH":
            continue
        me = ob.evaluated_get(dg).to_mesh().copy()
        me.transform(ob.matrix_world)
        cp = bpy.data.objects.new(ob.name + "_X", me)
        col("EXPORT").objects.link(cp)
        cp["bone"] = ob.get("bone", "AUTO")
        parts.append(cp)
    autos = [p for p in parts if p["bone"] == "AUTO"]
    for p in parts:
        if p["bone"] == "AUTO":
            continue
        if p["bone"] not in bone_names:
            raise RuntimeError("part %s wants missing bone %s" % (p.name, p["bone"]))
        vg = p.vertex_groups.new(name=p["bone"])
        vg.add(list(range(len(p.data.vertices))), 1.0, "REPLACE")
    for p in autos:
        _bind_auto(p, arm)
    base = autos[0] if autos else parts[0]
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()
    base.name = name
    base.data.name = name
    base.parent = arm
    base.matrix_parent_inverse = arm.matrix_world.inverted()
    mod = next((m for m in base.modifiers if m.type == "ARMATURE"), None) or base.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    unweighted = sum(1 for v in base.data.vertices if not v.groups)
    if unweighted:
        # bone heat can miss isolated islands: give them to the nearest bone head
        heads = [(b.name, b.head_local) for b in arm.data.bones]
        groups = {n: (base.vertex_groups.get(n) or base.vertex_groups.new(name=n)) for n, _ in heads}
        for v in base.data.vertices:
            if not v.groups:
                n = min(heads, key=lambda h: (h[1] - v.co).length)[0]
                groups[n].add([v.index], 1.0, "REPLACE")
    return base, unweighted


# ───────────────────────── animation ─────────────────────────

def world_rot(pb, axis, deg):
    m = pb.bone.matrix_local.to_3x3()
    return (m.inverted() @ Matrix.Rotation(math.radians(deg), 3, axis) @ m).to_quaternion()


def key(arm, frame, pose):
    """pose: {bone: [(axis, deg), ...] | {"rot": [...], "loc": (x, y, z), "scale": s}} — world-axis terms."""
    for pb in arm.pose.bones:
        spec = pose.get(pb.name, [])
        rots = spec.get("rot", []) if isinstance(spec, dict) else spec
        q = Quaternion()
        for axis, deg in rots:
            q = world_rot(pb, axis, deg) @ q
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        # location and scale are keyed on every bone at every key (neutral when not given), so a value
        # set mid-clip never sticks to the following keys
        loc = spec.get("loc") if isinstance(spec, dict) else None
        pb.location = pb.bone.matrix_local.to_3x3().inverted() @ Vector(loc or (0, 0, 0))
        pb.keyframe_insert("location", frame=frame)
        s = spec.get("scale", 1.0) if isinstance(spec, dict) else 1.0
        pb.scale = (s, s, s) if isinstance(s, (int, float)) else s
        pb.keyframe_insert("scale", frame=frame)


CLIPS = {}


def clip(arm, name, frames, loop):
    old = bpy.data.actions.get(name)
    if old:
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    arm.animation_data_create()
    arm.animation_data.action = act
    CLIPS[name] = (frames, loop)
    return act


def finish_clips(arm):
    for name, (frames, loop) in CLIPS.items():
        act = bpy.data.actions[name]
        act.frame_range = (1, frames + 1 if loop else frames)
        act.use_frame_range = True
        act.use_cyclic = loop
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)


# ───────────────────────── export and stats ─────────────────────────

def export_glb(path, arm, mesh):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    arm.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_animations=True, export_animation_mode="ACTIONS",
                              export_def_bones=True, export_skins=True, export_morph=False,
                              export_texcoords=True, export_normals=True, export_materials="EXPORT",
                              export_extras=False, export_cameras=False, export_lights=False,
                              export_rest_position_armature=True)


def stats(mesh, arm):
    me = mesh.data
    me.calc_loop_triangles()
    zs = [(mesh.matrix_world @ v.co).z for v in me.vertices]
    return {"tris": len(me.loop_triangles), "verts": len(me.vertices), "bones": len(arm.data.bones),
            "materials": len(me.materials), "height": round(max(zs) - min(zs), 3),
            "clips": {k: v[0] for k, v in CLIPS.items()}}
