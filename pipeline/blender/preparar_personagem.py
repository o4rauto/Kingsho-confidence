#!/usr/bin/env python3
"""
Bastion Rush — prepara um personagem 3D vindo de imagem→3D (Tripo / Hyper3D / Meshy).

O serviço de IA entrega a MALHA. Este script faz o resto, que é o trabalho de
3D de verdade: inspeciona, normaliza, otimiza, rigga e anima.

  1. Importa o GLB/FBX/OBJ cru.
  2. INSPECIONA: polígonos, dimensões, materiais, se já veio com esqueleto.
  3. NORMALIZA: gira pra olhar na direção certa, escala pra altura do jogo,
     origem no PÉ do personagem (senão ele afunda/flutua no chão), aplica tudo.
  4. OTIMIZA: decimate até o teto de polígonos (o jogo é mobile).
  5. RIGA: se não veio esqueleto, cria um humanoide proporcional à malha e
     faz peso automático.
  6. ANIMA: idle / run / attack / die em faixas NLA.
  7. Exporta `godot/assets/models/<id>.glb` e um render de prévia pra aprovação.

Uso:
  blender --background --python pipeline/blender/preparar_personagem.py -- \
      --entrada ~/Downloads/knight.glb --id knight --altura 1.8 --tipo hero \
      --girar 180 --maxfaces 6000 --previa /tmp/knight_previa.png

--girar  graus em Z pra ele ficar olhando pro +X (confira na prévia e ajuste).
--tipo   hero | runner | brute | caster | flyer | boss
"""
import bpy
import math
import sys
import os
from mathutils import Vector

ANIM_FPS = 24


# ───────────────────────── utilidades ─────────────────────────

def args():
    a = sys.argv
    a = a[a.index("--") + 1:] if "--" in a else []
    d, i = {}, 0
    while i < len(a):
        if a[i].startswith("--"):
            d[a[i][2:]] = a[i + 1] if i + 1 < len(a) and not a[i + 1].startswith("--") else "1"
            i += 2
        else:
            i += 1
    return d


def limpar():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for b in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions):
        for it in list(b):
            b.remove(it)


def importar(caminho):
    ext = os.path.splitext(caminho)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=caminho)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=caminho)
    elif ext == ".obj":
        bpy.ops.import_scene.obj(filepath=caminho)
    else:
        sys.exit("Formato não suportado: " + ext + " (use GLB, FBX ou OBJ)")


def malhas():
    return [o for o in bpy.data.objects if o.type == 'MESH']


def esqueleto_existente():
    a = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    return a[0] if a else None


def juntar_malhas(nome):
    ms = malhas()
    if not ms:
        sys.exit("ERRO: o arquivo não tem nenhuma malha.")
    bpy.ops.object.select_all(action='DESELECT')
    for m in ms:
        m.select_set(True)
    bpy.context.view_layer.objects.active = ms[0]
    if len(ms) > 1:
        bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = nome
    return o


def caixa(obj):
    """Caixa delimitadora em coordenadas de mundo."""
    cantos = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    mn = Vector((min(c.x for c in cantos), min(c.y for c in cantos), min(c.z for c in cantos)))
    mx = Vector((max(c.x for c in cantos), max(c.y for c in cantos), max(c.z for c in cantos)))
    return mn, mx


def aplicar(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


# ───────────────────── normalizar e otimizar ─────────────────────

def normalizar(obj, altura_alvo, girar_z):
    """Gira, escala pra altura do jogo e põe a origem no pé, centrada em XY."""
    # O arquivo importado costuma vir com escala/rotação próprias. Assa tudo na
    # malha ANTES de medir — senão a escala nova substitui a que já existia e o
    # personagem sai no tamanho errado.
    aplicar(obj)

    if girar_z:
        obj.rotation_euler[2] += math.radians(girar_z)
        aplicar(obj)

    mn, mx = caixa(obj)
    alt = max(1e-6, mx.z - mn.z)
    k = altura_alvo / alt
    obj.scale = (k, k, k)
    aplicar(obj)

    # origem no pé, centrado em XY (o jogo põe o personagem no chão pelo y=0)
    mn, mx = caixa(obj)
    obj.location -= Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, mn.z))
    aplicar(obj)
    return caixa(obj)


def otimizar(obj, max_faces):
    """Reduz polígonos até o teto — o jogo roda em celular fraco."""
    antes = len(obj.data.polygons)
    if max_faces and antes > max_faces:
        m = obj.modifiers.new("Decimate", 'DECIMATE')
        m.ratio = max_faces / float(antes)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=m.name)
    return antes, len(obj.data.polygons)


# ───────────────────────── esqueleto ─────────────────────────

# fração da altura onde cada junta fica (humanoide chibi/estilizado)
JUNTAS = {
    "hero":   dict(quadril=0.46, peito=0.66, pescoco=0.76, ombro=0.72, mao=0.46, perna_x=0.11, ombro_x=0.20),
    "runner": dict(quadril=0.46, peito=0.66, pescoco=0.76, ombro=0.72, mao=0.46, perna_x=0.11, ombro_x=0.20),
    "brute":  dict(quadril=0.44, peito=0.64, pescoco=0.76, ombro=0.70, mao=0.42, perna_x=0.15, ombro_x=0.28),
    "caster": dict(quadril=0.46, peito=0.66, pescoco=0.78, ombro=0.72, mao=0.48, perna_x=0.10, ombro_x=0.19),
    "flyer":  dict(quadril=0.50, peito=0.68, pescoco=0.80, ombro=0.74, mao=0.52, perna_x=0.10, ombro_x=0.22),
    "boss":   dict(quadril=0.44, peito=0.64, pescoco=0.76, ombro=0.70, mao=0.42, perna_x=0.16, ombro_x=0.30),
}


def criar_esqueleto(cid, tipo, alt, larg):
    j = JUNTAS.get(tipo, JUNTAS["runner"])
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = "rig_" + cid
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    eb.remove(eb[0])

    def osso(n, cab, cau, pai=None):
        b = eb.new(n)
        b.head, b.tail = Vector(cab), Vector(cau)
        if pai:
            b.parent = eb[pai]
            b.use_connect = False
        return b

    zq, zp, zn = alt * j["quadril"], alt * j["peito"], alt * j["pescoco"]
    zo, zm = alt * j["ombro"], alt * j["mao"]
    px, ox = larg * j["perna_x"], larg * j["ombro_x"]

    osso("root", (0, 0, 0), (0, 0, alt * 0.08))
    osso("hips", (0, 0, zq), (0, 0, zp), "root")
    osso("spine", (0, 0, zp), (0, 0, zn), "hips")
    osso("head", (0, 0, zn), (0, 0, alt), "spine")
    for lado, suf in ((-1, "_l"), (1, "_r")):
        osso("arm" + suf, (ox * lado, 0, zo), (ox * lado * 1.15, 0, zm), "spine")
        osso("leg" + suf, (px * lado, 0, zq), (px * lado, 0, 0.0), "hips")
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm


def pesar(malha, arm):
    bpy.ops.object.select_all(action='DESELECT')
    malha.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')


# ───────────────────────── animações ─────────────────────────

def _acao(arm, nome):
    if arm.animation_data is None:
        arm.animation_data_create()
    act = bpy.data.actions.new(nome)
    arm.animation_data.action = act
    return act


def _k(arm, osso, q, rot=None, loc=None):
    pb = arm.pose.bones.get(osso)
    if pb is None:
        return
    pb.rotation_mode = 'XYZ'
    if rot is not None:
        pb.rotation_euler = [math.radians(v) for v in rot]
        pb.keyframe_insert("rotation_euler", frame=q)
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert("location", frame=q)


def _guardar(arm, act):
    t = arm.animation_data.nla_tracks.new()
    t.name = act.name
    t.strips.new(act.name, int(act.frame_range[0]), act)
    arm.animation_data.action = None
    act.use_fake_user = True


def animar(arm, alt):
    d = alt * 0.04  # deslocamentos proporcionais ao tamanho do bicho

    # idle — respiração
    a = _acao(arm, "idle")
    for q, s in ((1, 0), (18, 1), (36, 0)):
        _k(arm, "spine", q, rot=(-2 * s, 0, 0))
        _k(arm, "head", q, rot=(2 * s, 0, 0))
        _k(arm, "hips", q, loc=(0, 0, d * 0.25 * s))
        _k(arm, "arm_l", q, rot=(0, 0, 4 * s))
        _k(arm, "arm_r", q, rot=(0, 0, -4 * s))
    _guardar(arm, a)

    # run — pernas e braços em oposição
    a = _acao(arm, "run")
    for q, ang in ((1, 32), (8, 0), (15, -32), (22, 0), (29, 32)):
        _k(arm, "leg_l", q, rot=(ang, 0, 0))
        _k(arm, "leg_r", q, rot=(-ang, 0, 0))
        _k(arm, "arm_l", q, rot=(-ang * 0.75, 0, 6))
        _k(arm, "arm_r", q, rot=(ang * 0.75, 0, -6))
        _k(arm, "spine", q, rot=(6, 0, 0))
    for q, h in ((1, 0.0), (8, d), (15, 0.0), (22, d), (29, 0.0)):
        _k(arm, "hips", q, loc=(0, 0, h))
    _guardar(arm, a)

    # attack — prepara e golpeia com o braço direito
    a = _acao(arm, "attack")
    _k(arm, "arm_r", 1, rot=(0, 0, -6))
    _k(arm, "arm_r", 8, rot=(65, 0, -12))
    _k(arm, "arm_r", 15, rot=(-90, 0, 0))
    _k(arm, "arm_r", 28, rot=(0, 0, -6))
    for q, r in ((1, 0), (8, -8), (15, 14), (28, 0)):
        _k(arm, "spine", q, rot=(r, 0, 0))
    _k(arm, "hips", 15, loc=(0, -d, 0))
    _k(arm, "hips", 28, loc=(0, 0, 0))
    _guardar(arm, a)

    # die — tomba pra trás
    a = _acao(arm, "die")
    _k(arm, "root", 1, rot=(0, 0, 0), loc=(0, 0, 0))
    _k(arm, "root", 12, rot=(-25, 0, 0), loc=(0, 0, d * 0.4))
    _k(arm, "root", 32, rot=(-88, 0, 0), loc=(0, d * 2.5, 0))
    _k(arm, "spine", 32, rot=(16, 0, 0))
    _k(arm, "head", 32, rot=(20, 0, 0))
    _k(arm, "arm_l", 32, rot=(-40, 0, 25))
    _k(arm, "arm_r", 32, rot=(-40, 0, -25))
    _guardar(arm, a)


# ───────────────────────── prévia ─────────────────────────

def render_previa(saida, alt):
    # Silencia as faixas NLA: senão as 4 animações se somam e a prévia sai
    # com o personagem torto. Isso não afeta o GLB, que já foi exportado.
    for o in bpy.data.objects:
        if o.type == 'ARMATURE' and o.animation_data:
            for t in o.animation_data.nla_tracks:
                t.mute = True
    w = bpy.data.worlds['World']
    w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.62, 0.78, 0.92, 1)
    bpy.ops.object.light_add(type='SUN', location=(3, -4, 6))
    bpy.context.active_object.data.energy = 3.5
    bpy.ops.object.camera_add(
        location=(alt * 1.6, -alt * 2.2, alt * 0.85),
        rotation=(math.radians(76), 0, math.radians(36)))
    cam = bpy.context.active_object
    cam.data.lens = 55
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'
    sc.display.shading.color_type = 'TEXTURE'
    sc.render.resolution_x, sc.render.resolution_y = 420, 520
    sc.render.filepath = saida
    bpy.ops.render.render(write_still=True)


# ───────────────────────── principal ─────────────────────────

def main():
    a = args()
    entrada = os.path.expanduser(a.get("entrada", ""))
    if not entrada or not os.path.exists(entrada):
        sys.exit("ERRO: passe --entrada <arquivo .glb/.fbx/.obj> existente")
    cid = a.get("id", os.path.splitext(os.path.basename(entrada))[0])
    tipo = a.get("tipo", "runner")
    altura = float(a.get("altura", "1.8"))
    girar = float(a.get("girar", "0"))
    maxf = int(a.get("maxfaces", "6000"))
    saida_dir = os.path.expanduser(a.get("saida", "godot/assets/models"))
    previa = a.get("previa", "")

    limpar()
    importar(entrada)

    arm_orig = esqueleto_existente()
    ja_rigado = arm_orig is not None
    n_anims = len(bpy.data.actions)

    malha = juntar_malhas("malha_" + cid)
    mats = [m.name for m in malha.data.materials if m]
    print("INSPECAO: faces=%d materiais=%s ja_rigado=%s animacoes=%d"
          % (len(malha.data.polygons), mats or "(nenhum)", ja_rigado, n_anims))

    if ja_rigado:
        # Já veio rigado do serviço: só normaliza e devolve, sem estragar o rig.
        print("AVISO: o arquivo JA tem esqueleto — mantendo o rig original.")
        mn, mx = caixa(malha)
        print("DIMENSOES originais: %.2f x %.2f x %.2f" % (mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    else:
        mn, mx = normalizar(malha, altura, girar)
        antes, depois = otimizar(malha, maxf)
        larg = max(mx.x - mn.x, mx.y - mn.y)
        print("NORMALIZADO: altura=%.2f largura=%.2f | faces %d -> %d"
              % (mx.z - mn.z, larg, antes, depois))
        arm = criar_esqueleto(cid, tipo, altura, larg)
        pesar(malha, arm)
        animar(arm, altura)
        print("RIG: ossos=%s" % [b.name for b in arm.data.bones])
        print("ANIMACOES: %s" % [t.name for t in arm.animation_data.nla_tracks])

    os.makedirs(saida_dir, exist_ok=True)
    destino = os.path.join(saida_dir, cid + ".glb")
    bpy.ops.export_scene.gltf(filepath=destino, export_format='GLB',
                              export_animations=True, export_apply=True)
    print("GERADO: %s (%d bytes)" % (destino, os.path.getsize(destino)))

    if previa:
        render_previa(previa, altura)
        print("PREVIA: %s" % previa)


main()
