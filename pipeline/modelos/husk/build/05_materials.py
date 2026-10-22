"""CH_Husk — Phase 5 materials: flat cartoon colours per role (brief MATERIALS). No baked maps:
the game applies toon shading and the ink outline (AssetLib.aplicar_toon).
Run after 02 and 03 (they recreate their objects without materials).
blender --background --python build/05_materials.py -- --master CH_Husk_master.blend
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import _lib as L

L.PHASE = "05_materials"


def srgb(h, a=1.0):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return (*lin, a)


MATS = {   # role: (hex, roughness, metallic)
    "Skin": ("A8302A", 0.85, 0.0),
    "Rust": ("7A4A2A", 0.8, 0.0),
    "Steel": ("8E8E8A", 0.5, 0.3),
    "Eye": ("F2E2A0", 0.4, 0.0),
    "Teeth": ("EFE6CF", 0.5, 0.0),
    "Mouth": ("4A1410", 0.9, 0.0),
    "Cloth": ("7A6A3F", 0.95, 0.0),
    "Leather": ("4A3020", 0.8, 0.0),
    "Wrap": ("C8B08C", 0.95, 0.0),
}

ROLE_BY_PART = [   # first match wins (substring of the object name)
    ("HelmetDome", "Rust"), ("HelmetBand", "Steel"), ("HelmetBrim", "Steel"), ("HelmetGuard", "Steel"),
    ("HelmetSpike", "Steel"), ("SpikeCollar", "Steel"), ("Buckle", "Steel"),
    ("Eye", "Eye"), ("Tooth", "Teeth"), ("Mouth", "Mouth"),
    ("Loincloth", "Cloth"), ("Belt", "Leather"), ("Wrap", "Wrap"),
    ("", "Skin"),
]


def build():
    mats = {}
    for role, (hx, rough, metal) in MATS.items():
        m = L.material("M_Husk_" + role, srgb(hx), rough, metal)
        if role == "Eye":   # a little glow so the eyes read on dark maps
            bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
            bsdf.inputs["Emission Color"].default_value = srgb(hx)
            bsdf.inputs["Emission Strength"].default_value = 0.25
        mats[role] = m
    n = 0
    for ob in bpy.data.collections["LOW"].all_objects:
        if ob.type != "MESH":
            continue
        role = next(r for key, r in ROLE_BY_PART if key in ob.name)
        L.assign(ob, mats[role])
        n += 1
    L.log("materials assigned to", n, "objects")


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--master", required=True)
    a = p.parse_args(L.argv_after_dashes())
    L.open_master(a.master)
    build()
    L.save_master(a.master)
