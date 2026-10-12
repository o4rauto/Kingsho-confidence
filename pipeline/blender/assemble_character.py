"""
Assemble a character from AI-generated 3D parts (Tripo exports) — video step
"juntar as partes no Blender", automated.

Expects GLBs in <parts_dir> named after the character id:
    <id>_legs.glb   <id>_torso.glb   <id>_head.glb   <id>_prop_<anything>.glb (optional, any count)
Stacks legs → torso → head by their bounding boxes (with a small overlap so the
seams sink into each other), centres everything, scales to the target height,
puts the origin at the feet and exports <out_dir>/<id>_assembled.glb.
Fine-tune seams afterwards with Sculpt ▸ Grab / proportional editing (the
"Liquify for 3D" step in the video), then rig it.

Command line:
    blender --background --python assemble_character.py -- <id> <parts_dir> <out_dir> [height_m=1.8] [--no-join]
Inside Blender / via Blender MCP:
    exec(open(".../assemble_character.py").read()); assemble("warden", "/path/parts", "/path/out")
"""
import glob
import os
import sys

import bpy
from mathutils import Vector

OVERLAP = 0.06  # fraction of the lower part's height the upper part sinks in


def _import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    if not meshes:
        raise RuntimeError(f"No mesh inside {path}")
    bpy.ops.object.select_all(action="DESELECT")
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.name = os.path.splitext(os.path.basename(path))[0]
    return obj


def _bounds(obj):
    pts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx


def _place_on(obj, base_top_z, base_height, cx=0.0, cy=0.0):
    mn, mx = _bounds(obj)
    centre = (mn + mx) / 2
    obj.location.x += cx - centre.x
    obj.location.y += cy - centre.y
    obj.location.z += (base_top_z - base_height * OVERLAP) - mn.z


def assemble(char_id, parts_dir, out_dir, height=1.8, join=True):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    def part(name):
        p = os.path.join(parts_dir, f"{char_id}_{name}.glb")
        return _import_glb(p) if os.path.exists(p) else None

    legs, torso, head = part("legs"), part("torso"), part("head")
    stack = [p for p in (legs, torso, head) if p]
    if not stack:
        raise RuntimeError(f"No parts found for {char_id} in {parts_dir}")
    # Bottom piece sits on the ground, centred.
    mn, mx = _bounds(stack[0])
    stack[0].location -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    for lower, upper in zip(stack, stack[1:]):
        bpy.context.view_layer.update()
        lmn, lmx = _bounds(lower)
        _place_on(upper, lmx.z, lmx.z - lmn.z)
    # Props (weapons, shields, launchers...) to the right of the torso.
    anchor = torso or stack[-1]
    for i, path in enumerate(sorted(glob.glob(os.path.join(parts_dir, f"{char_id}_prop_*.glb")))):
        prop = _import_glb(path)
        bpy.context.view_layer.update()
        amn, amx = _bounds(anchor)
        pmn, pmx = _bounds(prop)
        prop.location.x += (amx.x + 0.02) - pmn.x
        prop.location.z += ((amn.z + amx.z) / 2) - ((pmn.z + pmx.z) / 2) + i * 0.05
        stack.append(prop)
    # Scale the whole character to the target height, origin at the feet.
    bpy.context.view_layer.update()
    allmn = Vector((min(_bounds(o)[0].x for o in stack), min(_bounds(o)[0].y for o in stack), min(_bounds(o)[0].z for o in stack)))
    allmx = Vector((max(_bounds(o)[1].x for o in stack), max(_bounds(o)[1].y for o in stack), max(_bounds(o)[1].z for o in stack)))
    k = height / max(1e-6, allmx.z - allmn.z)
    for o in stack:
        o.location = (o.location - Vector(((allmn.x + allmx.x) / 2, (allmn.y + allmx.y) / 2, allmn.z))) * k
        o.scale *= k
    bpy.ops.object.select_all(action="DESELECT")
    for o in stack:
        o.select_set(True)
    bpy.context.view_layer.objects.active = stack[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if join and len(stack) > 1:
        bpy.ops.object.join()
    bpy.context.view_layer.objects.active.name = char_id
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, f"{char_id}_assembled.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=False)
    print(f"ASSEMBLED {out}")
    return out


if __name__ == "__main__" and "--" in sys.argv:
    args = sys.argv[sys.argv.index("--") + 1:]
    flags = [a for a in args if a.startswith("--")]
    pos = [a for a in args if not a.startswith("--")]
    assemble(pos[0], pos[1], pos[2], float(pos[3]) if len(pos) > 3 else 1.8, join="--no-join" not in flags)
