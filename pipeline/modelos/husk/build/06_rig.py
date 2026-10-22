"""CH_Husk — Phase 6 articulation: delivery copy + deformation skeleton.
Copies every LOW mesh into EXPORT with modifiers applied, builds an 18-bone humanoid in RIG_DEF from
the 02 joint table, binds the body and loincloth with automatic weights, gives each rigid part 100 %
to its bone, and joins everything into one skinned mesh CH_Husk (one draw per material in Godot).
Run after 02, 03 and 05.
blender --background --python build/06_rig.py -- --master CH_Husk_master.blend
"""
import os, sys, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy
from mathutils import Vector
import _lib as L

_spec = importlib.util.spec_from_file_location("blockout", os.path.join(HERE, "02_blockout.py"))
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)

L.PHASE = "06_rig"
L.OWNER_TAG = "phase:" + L.PHASE

RIGID = [   # (name substring, bone) — first match wins; everything else is skinned automatically
    ("Hand.L", "DEF-hand.L"), ("Finger", None), ("Thumb.L", "DEF-hand.L"), ("Hand.R", "DEF-hand.R"),
    ("Thumb.R", "DEF-hand.R"), ("Foot.L", "DEF-foot.L"), ("Toe", None), ("Foot.R", "DEF-foot.R"),
    ("WrapArm.L", "DEF-forearm.L"), ("WrapArm.R", "DEF-forearm.R"),
    ("WrapAnkle.L", "DEF-shin.L"), ("WrapAnkle.R", "DEF-shin.R"),
    ("Belt", "DEF-pelvis"), ("Buckle", "DEF-pelvis"),
    ("Helmet", "DEF-head"), ("Spike", "DEF-head"), ("Ear", "DEF-head"), ("Head", "DEF-head"),
    ("Jaw", "DEF-head"), ("Nose", "DEF-head"), ("Eye", "DEF-head"), ("Brow", "DEF-head"),
    ("Cheek", "DEF-head"), ("Mouth", "DEF-head"), ("Tooth", "DEF-head"),
]
SKINNED = ("Body", "Loincloth")


def bone_table(j):
    hand_tip = lambda s: (j["wr" + s][0], j["wr" + s][1] - 0.01, B.HAND_BOTTOM)
    toe = lambda s: (j["an" + s][0], j["an" + s][1] - B.FOOT_LEN * 0.8, 0.03)
    head_top = (0, j["neck1"][1] - 0.01, B.DOME_TOP)
    bones = [
        ("DEF-root", (0, 0, 0), (0, 0.15, 0), None),
        ("DEF-pelvis", j["pelvis"], j["waist"], "DEF-root"),
        ("DEF-spine", j["waist"], j["chest"], "DEF-pelvis"),
        ("DEF-chest", j["chest"], j["neck0"], "DEF-spine"),
        ("DEF-neck", j["neck0"], j["neck1"], "DEF-chest"),
        ("DEF-head", j["neck1"], head_top, "DEF-neck"),
    ]
    for s in ("L", "R"):
        bones += [
            ("DEF-upper_arm." + s, j["sh" + s], j["el" + s], "DEF-chest"),
            ("DEF-forearm." + s, j["el" + s], j["wr" + s], "DEF-upper_arm." + s),
            ("DEF-hand." + s, j["wr" + s], hand_tip(s), "DEF-forearm." + s),
            ("DEF-thigh." + s, j["hip" + s], j["kn" + s], "DEF-pelvis"),
            ("DEF-shin." + s, j["kn" + s], j["an" + s], "DEF-thigh." + s),
            ("DEF-foot." + s, j["an" + s], toe(s), "DEF-shin." + s),
        ]
    return [(n, h, t, p, 0.0, True) for n, h, t, p in bones]


def delivery_copy(ob):
    me = ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh().copy()
    me.transform(ob.matrix_world)
    cp = bpy.data.objects.new(ob.name.replace("_LOD0", "") + "_X", me)
    L.col("EXPORT").objects.link(cp)
    return L.own(cp)


def rigid_bone(name):
    for key, bone in RIGID:
        if key in name:
            if bone is None:   # fingers / toes: side from the name
                side = ".L" if name.endswith(".L_X") else ".R"
                return ("DEF-hand" if key == "Finger" else "DEF-foot") + side
            return bone
    return None


def build():
    joints, _ = B.joint_table()
    arm = L.armature("CH_Husk_Rig", bone_table(joints))
    for o in [o for o in bpy.data.objects if o.get("owner") == L.OWNER_TAG and o.type == "ARMATURE"]:
        o.data.name = "CH_Husk_Rig"
    parts = [delivery_copy(o) for o in list(bpy.data.collections["LOW"].all_objects) if o.type == "MESH"]
    skinned = [p for p in parts if any(k in p.name for k in SKINNED)]
    for p in skinned:
        L.bind(p, arm)                                   # automatic (bone heat) weights
    for p in parts:
        if p in skinned:
            continue
        bone = rigid_bone(p.name)
        if bone is None:
            raise RuntimeError("no bone for " + p.name)
        vg = p.vertex_groups.new(name=bone)
        vg.add(list(range(len(p.data.vertices))), 1.0, "REPLACE")
    # join into one skinned mesh; the body keeps its Armature modifier
    body = next(p for p in skinned if "Body" in p.name)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body.name = "CH_Husk"
    body.data.name = "CH_Husk"
    body.parent = arm
    mod = next((m for m in body.modifiers if m.type == "ARMATURE"), None) or body.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    # weight hygiene: max 4 influences, normalised
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    unweighted = sum(1 for v in body.data.vertices if not v.groups)
    me = body.data
    me.calc_loop_triangles()
    L.log("joined mesh: %d verts, %d tris, %d unweighted, %d materials, bones %d" % (
        len(me.vertices), len(me.loop_triangles), unweighted, len(me.materials), len(arm.data.bones)))
    L.socket("SOCKET_hand.R", hand_socket(joints), parent=arm, parent_bone="DEF-hand.R")
    L.socket("SOCKET_head", (0, joints["neck1"][1], B.SPIKE_TIP), parent=arm, parent_bone="DEF-head")


def hand_socket(j):
    return (j["wrR"][0], j["wrR"][1] - 0.02, B.HAND_BOTTOM + B.HAND_SIZE * 0.3)


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--master", required=True)
    a = p.parse_args(L.argv_after_dashes())
    L.open_master(a.master)
    L.clear_owned()
    build()
    L.save_master(a.master)
    L.log("saved", a.master)
