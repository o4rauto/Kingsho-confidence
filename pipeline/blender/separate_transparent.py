"""
Fix transparent parts (glasses, lenses, crystals, gems) — video step where the
AI texture had no transparency and looked wrongly shaded.

Splits the active mesh by material, then every material whose name matches a
keyword (or listed in KEYWORDS) becomes alpha-blended glass.

Inside Blender / via Blender MCP (select the object first):
    exec(open(".../separate_transparent.py").read()); make_transparent(["lens", "glass"])
Command line:
    blender model.blend --background --python separate_transparent.py -- lens glass crystal
"""
import sys

import bpy

KEYWORDS = ["glass", "lens", "lente", "vidro", "crystal", "cristal", "gem"]


def make_transparent(keywords=None, alpha=0.35):
    keywords = [k.lower() for k in (keywords or KEYWORDS)]
    obj = bpy.context.view_layer.objects.active
    if obj is None or obj.type != "MESH":
        raise RuntimeError("Select the mesh first")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="MATERIAL")
    bpy.ops.object.mode_set(mode="OBJECT")
    changed = []
    for o in bpy.context.selected_objects:
        for slot in o.material_slots:
            m = slot.material
            if m is None or not any(k in m.name.lower() for k in keywords):
                continue
            m.blend_method = "BLEND"
            if hasattr(m, "surface_render_method"):
                m.surface_render_method = "BLENDED"
            bsdf = m.node_tree.nodes.get("Principled BSDF") if m.use_nodes else None
            if bsdf:
                bsdf.inputs["Alpha"].default_value = alpha
                bsdf.inputs["Roughness"].default_value = 0.05
            changed.append(m.name)
    print(f"TRANSPARENT {changed}")
    return changed


if __name__ == "__main__" and "--" in sys.argv:
    make_transparent(sys.argv[sys.argv.index("--") + 1:] or None)
