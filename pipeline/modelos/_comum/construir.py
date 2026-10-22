"""Builds one or more characters end to end:
    blender -b --python pipeline/modelos/_comum/construir.py -- <id> [<id> ...]
For each id, pipeline/modelos/<id>/modelo.py must define:
    NOME     asset name (e.g. "CH_Warden")
    PALETA   role -> hex | (hex, roughness, metallic)
    pecas()  builds the LOW parts with kit/biped helpers and returns the bone table
    animar(arm)  keys the clips (idle, run, attack, die …) with kit/biped helpers
optional: MODELO (game id of the .glb, default <id>), BRILHO (roles that glow).
Writes pipeline/modelos/<id>/<id>_master.blend, godot/assets/models/<MODELO>.glb and stats.json.
"""
import os, sys, json, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
import bpy
import kit as K


def load(cid):
    path = os.path.join(ROOT, "pipeline", "modelos", cid, "modelo.py")
    spec = importlib.util.spec_from_file_location("modelo_" + cid, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def build(cid):
    K.CLIPS.clear()
    K.reset_scene()
    M = load(cid)
    bones = M.pecas()
    K.paint("M_%s_" % cid, M.PALETA, glow=getattr(M, "BRILHO", ()))
    arm = K.armature(M.NOME + "_Rig", bones)
    mesh, unweighted = K.rig_and_join(M.NOME, arm)
    bpy.context.scene.render.fps = 24
    M.animar(arm)
    K.finish_clips(arm)
    folder = os.path.join(ROOT, "pipeline", "modelos", cid)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(folder, cid + "_master.blend"))
    model_id = getattr(M, "MODELO", cid)
    out = os.path.join(ROOT, "godot", "assets", "models", model_id + ".glb")
    K.export_glb(out, arm, mesh)
    st = K.stats(mesh, arm)
    st.update({"id": cid, "glb": os.path.relpath(out, ROOT), "unweighted_fixed": unweighted,
               "attack_frame": getattr(M, "ATAQUE_QUADRO", 8)})
    with open(os.path.join(folder, "stats.json"), "w") as f:
        json.dump(st, f, indent=1)
    print("BUILT", json.dumps(st))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for cid in args:
        build(cid)
