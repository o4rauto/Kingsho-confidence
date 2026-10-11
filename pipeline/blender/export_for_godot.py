"""
Bundle a rigged character + its Mixamo animations into ONE .glb for the game.

<anim_dir> must contain Mixamo downloads named by the game's animation names:
    idle.fbx   (downloaded "With Skin" — this is the base mesh + skeleton)
    run.fbx attack.fbx hit.fbx die.fbx [cast.fbx fly.fbx ...]  ("Without Skin")
Each file becomes an animation with that name; the game matches them loosely
(see godot/scripts/game/model_rig.gd), so "Run" or "run_fast" also work.

Command line:
    blender --background --python export_for_godot.py -- <id> <anim_dir> <godot/assets/models>
Inside Blender / via Blender MCP:
    exec(open(".../export_for_godot.py").read()); export("warden", "/anims/warden", "/repo/godot/assets/models")
"""
import glob
import os
import sys

import bpy


def _import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, automatic_bone_orientation=True)
    return [o for o in bpy.data.objects if o not in before]


def export(char_id, anim_dir, models_dir):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    base_path = os.path.join(anim_dir, "idle.fbx")
    if not os.path.exists(base_path):
        raise RuntimeError("idle.fbx (With Skin) is required as the base")
    base = _import_fbx(base_path)
    arm = next(o for o in base if o.type == "ARMATURE")
    arm.name = char_id
    arm.animation_data_create()
    tracks = []
    for path in [base_path] + sorted(p for p in glob.glob(os.path.join(anim_dir, "*.fbx")) if not p.endswith("idle.fbx")):
        name = os.path.splitext(os.path.basename(path))[0]
        if path == base_path:
            action = arm.animation_data.action
        else:
            objs = _import_fbx(path)
            src = next((o for o in objs if o.type == "ARMATURE"), None)
            action = src.animation_data.action if src and src.animation_data else None
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
        if action is None:
            print(f"skip {name}: no action")
            continue
        action.name = name
        action.use_fake_user = True
        track = arm.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, int(action.frame_range[0]), action)
        tracks.append(name)
    arm.animation_data.action = None
    os.makedirs(models_dir, exist_ok=True)
    out = os.path.join(models_dir, f"{char_id}.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_animations=True,
                              export_animation_mode="NLA_TRACKS")
    print(f"EXPORTED {out} animations={tracks}")
    return out


if __name__ == "__main__" and "--" in sys.argv:
    a = sys.argv[sys.argv.index("--") + 1:]
    export(a[0], a[1], a[2])
