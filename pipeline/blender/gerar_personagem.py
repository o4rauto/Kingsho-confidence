#!/usr/bin/env python3
"""
Bastion Rush — gerador de personagem 3D no Blender (sem IA, sem custo).

Monta um chibi estilo Clash Royale / Archero (cabeça grande, corpo pequeno,
olhos grandes), cria o esqueleto, assa as animações (idle / run / attack / die)
e exporta `<id>.glb`. O jogo carrega sozinho de `godot/assets/models/<id>.glb`
e casa as animações pelo nome (ver `scripts/game/model_rig.gd`).

Uso:
  blender --background --python pipeline/blender/gerar_personagem.py -- \
      --id husk --cor 7ab648 --pele 9ad36a --altura 1.0 --tipo runner \
      --saida godot/assets/models

Tipos: runner | brute | caster | flyer | boss | hero
"""
import bpy
import bmesh
import math
import sys
import os
from mathutils import Vector

# ───────────────────────── utilidades ─────────────────────────


def limpar_cena():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for bloco in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
        for item in list(bloco):
            bloco.remove(item)


def hex_para_rgb(h):
    h = h.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    # sRGB -> linear (o Blender trabalha em linear)
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b), 1.0)


def material(nome, cor_hex):
    m = bpy.data.materials.get(nome)
    if m is None:
        m = bpy.data.materials.new(nome)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = hex_para_rgb(cor_hex)
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = 0.75
    if "Specular" in bsdf.inputs:
        bsdf.inputs["Specular"].default_value = 0.15
    return m


def suavizar(obj, niveis=1):
    """Shading suave + subdivisão leve = aparência de brinquedo."""
    for p in obj.data.polygons:
        p.use_smooth = True
    if niveis:
        mod = obj.modifiers.new("Subdiv", 'SUBSURF')
        mod.levels = niveis
        mod.render_levels = niveis


def esfera(nome, raio, local, escala=(1, 1, 1), mat=None, seg=20, anel=12):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=raio, location=local,
                                         segments=seg, ring_count=anel)
    o = bpy.context.active_object
    o.name = nome
    o.scale = escala
    if mat:
        o.data.materials.append(mat)
    return o


def capsula(nome, raio, comprimento, local, mat=None):
    """Cilindro com as pontas arredondadas (membro)."""
    bpy.ops.mesh.primitive_cylinder_add(radius=raio, depth=comprimento,
                                        location=local, vertices=14)
    corpo = bpy.context.active_object
    corpo.name = nome
    if mat:
        corpo.data.materials.append(mat)
    for dz in (comprimento / 2.0, -comprimento / 2.0):
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=raio, location=(local[0], local[1], local[2] + dz),
            segments=14, ring_count=8)
        tampa = bpy.context.active_object
        if mat:
            tampa.data.materials.append(mat)
        tampa.select_set(True)
        corpo.select_set(True)
        bpy.context.view_layer.objects.active = corpo
        bpy.ops.object.join()
    return corpo


def juntar(objs, nome):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = nome
    return o


# ───────────────────────── o corpo ─────────────────────────

# proporções por tipo: (escala_cabeca, largura_corpo, altura_pernas, gordura)
PERFIS = {
    "runner": (1.00, 1.00, 1.00, 1.00),
    "brute":  (0.92, 1.45, 0.80, 1.35),
    "caster": (1.05, 0.95, 1.05, 0.95),
    "flyer":  (1.10, 0.85, 0.55, 0.90),
    "boss":   (0.95, 1.60, 0.90, 1.50),
    "hero":   (1.00, 1.05, 1.05, 1.00),
}


def construir(cid, cor, pele, tipo):
    kc, lc, hp, gordo = PERFIS.get(tipo, PERFIS["runner"])
    mat_roupa = material("roupa_" + cid, cor)
    mat_pele = material("pele_" + cid, pele)
    mat_olho = material("olho_" + cid, "ffffff")
    mat_pupila = material("pupila_" + cid, "1b1410")

    partes = []
    # pernas
    z_perna = 0.16 * hp
    for lado in (-1, 1):
        partes.append(capsula("perna", 0.085 * lc, 0.26 * hp,
                              (0.10 * lc * lado, 0, z_perna), mat_roupa))
        # pé
        partes.append(esfera("pe", 0.095 * lc, (0.10 * lc * lado, -0.03, 0.045),
                             (1.2, 1.5, 0.7), mat_roupa))
    # tronco
    z_corpo = 0.30 * hp + 0.15
    partes.append(esfera("corpo", 0.21, (0, 0, z_corpo),
                         (1.05 * lc * gordo, 0.95 * lc * gordo, 1.15), mat_roupa))
    # braços — encostados no tronco (raio X do corpo = 0.21 * lc * gordo)
    z_ombro = z_corpo + 0.10
    x_ombro = 0.195 * lc * gordo
    for lado in (-1, 1):
        partes.append(capsula("braco", 0.068 * lc, 0.26,
                              (x_ombro * lado, 0, z_ombro - 0.11), mat_pele))
        partes.append(esfera("mao", 0.080 * lc,
                             (x_ombro * lado, 0, z_ombro - 0.25),
                             (1, 1, 0.9), mat_pele))
    # cabeça (grande — a marca do chibi)
    z_cabeca = z_corpo + 0.20 + 0.26 * kc
    r_cabeca = 0.30 * kc
    partes.append(esfera("cabeca", r_cabeca, (0, 0, z_cabeca),
                         (1.0, 0.95, 0.98), mat_pele, seg=28, anel=18))
    corpo = juntar(partes, "corpo_" + cid)
    suavizar(corpo, 0)

    # olhos grandes (o que faz "ler" como personagem).
    # Ficam ENCRAVADOS na cabeça: (ox/rx)^2 + (oy/ry)^2 bem abaixo de 1,
    # senão a esfera do olho escapa da curva e parece solta.
    # A profundidade é calculada: na altura dos olhos a cabeça tem frente em
    # y = -ry*sqrt(1-(ox/rx)^2). Centramos o olho de modo que ele avance ~0.02
    # além dessa frente — salta à vista, mas a parte de trás continua dentro.
    olhos = []
    rx, ry = r_cabeca * 1.0, r_cabeca * 0.95
    r_olho = 0.095 * kc
    for lado in (-1, 1):
        ox = 0.40 * rx * lado
        oy = -0.79 * ry
        olhos.append(esfera("olho", r_olho, (ox, oy, z_cabeca + 0.03 * kc),
                            (1.0, 0.70, 1.20), mat_olho, seg=16, anel=10))
        olhos.append(esfera("pupila", 0.052 * kc,
                            (ox, oy - 0.045 * kc, z_cabeca + 0.022 * kc),
                            (1.0, 0.75, 1.10), mat_pupila, seg=14, anel=8))
    olhos_obj = juntar(olhos, "olhos_" + cid)
    suavizar(olhos_obj, 0)

    malha = juntar([corpo, olhos_obj], "malha_" + cid)
    return malha, z_cabeca, z_corpo, z_ombro, hp, lc, gordo


# ───────────────────────── esqueleto ─────────────────────────

def criar_esqueleto(cid, z_cabeca, z_corpo, z_ombro, hp, lc, gordo):
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = "esqueleto_" + cid
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    eb.remove(eb[0])  # tira o osso padrão

    def osso(nome, cabeca, cauda, pai=None):
        b = eb.new(nome)
        b.head = Vector(cabeca)
        b.tail = Vector(cauda)
        if pai:
            b.parent = eb[pai]
            b.use_connect = False
        return b

    z_quadril = 0.30 * hp
    osso("root", (0, 0, 0), (0, 0, 0.08))
    osso("hips", (0, 0, z_quadril), (0, 0, z_corpo), "root")
    osso("spine", (0, 0, z_corpo), (0, 0, z_ombro + 0.04), "hips")
    osso("head", (0, 0, z_ombro + 0.04), (0, 0, z_cabeca + 0.30), "spine")
    for lado, suf in ((-1, "_l"), (1, "_r")):
        osso("arm" + suf, (0.195 * lc * gordo * lado, 0, z_ombro),
             (0.195 * lc * gordo * lado, 0, z_ombro - 0.30), "spine")
        osso("leg" + suf, (0.10 * lc * lado, 0, z_quadril),
             (0.10 * lc * lado, 0, 0.0), "hips")
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm


def vincular(malha, arm):
    bpy.ops.object.select_all(action='DESELECT')
    malha.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')


# ───────────────────────── animações ─────────────────────────

def nova_acao(arm, nome):
    if arm.animation_data is None:
        arm.animation_data_create()
    act = bpy.data.actions.new(nome)
    arm.animation_data.action = act
    return act


def key(arm, osso, quadro, rot=None, loc=None):
    pb = arm.pose.bones.get(osso)
    if pb is None:
        return
    pb.rotation_mode = 'XYZ'
    if rot is not None:
        pb.rotation_euler = [math.radians(a) for a in rot]
        pb.keyframe_insert("rotation_euler", frame=quadro)
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert("location", frame=quadro)


def guardar(arm, act):
    """Empurra a ação pra uma faixa NLA — assim o glTF exporta todas."""
    trilha = arm.animation_data.nla_tracks.new()
    trilha.name = act.name
    trilha.strips.new(act.name, int(act.frame_range[0]), act)
    arm.animation_data.action = None


def animar(arm):
    # ---- idle: respiração ----
    a = nova_acao(arm, "idle")
    for q, s in ((1, 0), (15, 1), (30, 0)):
        key(arm, "spine", q, rot=(-2 * s, 0, 0))
        key(arm, "head", q, rot=(2 * s, 0, 0))
        key(arm, "hips", q, loc=(0, 0, 0.012 * s))
        key(arm, "arm_l", q, rot=(0, 0, 4 * s))
        key(arm, "arm_r", q, rot=(0, 0, -4 * s))
    a.use_fake_user = True
    guardar(arm, a)

    # ---- run: pernas e braços alternados ----
    a = nova_acao(arm, "run")
    ciclo = [(1, 35), (8, 0), (15, -35), (22, 0), (29, 35)]
    for q, ang in ciclo:
        key(arm, "leg_l", q, rot=(ang, 0, 0))
        key(arm, "leg_r", q, rot=(-ang, 0, 0))
        key(arm, "arm_l", q, rot=(-ang * 0.8, 0, 6))
        key(arm, "arm_r", q, rot=(ang * 0.8, 0, -6))
        key(arm, "spine", q, rot=(6, 0, 0))
    for q, alt in ((1, 0.0), (8, 0.045), (15, 0.0), (22, 0.045), (29, 0.0)):
        key(arm, "hips", q, loc=(0, 0, alt))
    a.use_fake_user = True
    guardar(arm, a)

    # ---- attack: recua e golpeia ----
    a = nova_acao(arm, "attack")
    key(arm, "arm_r", 1, rot=(0, 0, -6))
    key(arm, "arm_r", 7, rot=(70, 0, -10))     # prepara
    key(arm, "arm_r", 13, rot=(-95, 0, 0))     # golpe
    key(arm, "arm_r", 24, rot=(0, 0, -6))      # volta
    key(arm, "spine", 1, rot=(0, 0, 0))
    key(arm, "spine", 7, rot=(-8, 0, 0))
    key(arm, "spine", 13, rot=(14, 0, 0))
    key(arm, "spine", 24, rot=(0, 0, 0))
    key(arm, "hips", 13, loc=(0, -0.05, 0))
    key(arm, "hips", 24, loc=(0, 0, 0))
    a.use_fake_user = True
    guardar(arm, a)

    # ---- die: tomba pra trás ----
    a = nova_acao(arm, "die")
    key(arm, "root", 1, rot=(0, 0, 0), loc=(0, 0, 0))
    key(arm, "root", 10, rot=(-25, 0, 0), loc=(0, 0, 0.02))
    key(arm, "root", 28, rot=(-88, 0, 0), loc=(0, 0.12, 0))
    key(arm, "spine", 1, rot=(0, 0, 0))
    key(arm, "spine", 10, rot=(-12, 0, 0))
    key(arm, "spine", 28, rot=(16, 0, 0))
    key(arm, "head", 28, rot=(20, 0, 0))
    key(arm, "arm_l", 28, rot=(-40, 0, 25))
    key(arm, "arm_r", 28, rot=(-40, 0, -25))
    a.use_fake_user = True
    guardar(arm, a)


# ───────────────────────── principal ─────────────────────────

def argumentos():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    d = {}
    i = 0
    while i < len(argv):
        if argv[i].startswith("--"):
            d[argv[i][2:]] = argv[i + 1] if i + 1 < len(argv) else ""
            i += 2
        else:
            i += 1
    return d


def main():
    a = argumentos()
    cid = a.get("id", "teste")
    cor = a.get("cor", "7ab648")
    pele = a.get("pele", cor)
    tipo = a.get("tipo", "runner")
    altura = float(a.get("altura", "1.0"))
    saida = a.get("saida", "godot/assets/models")

    limpar_cena()
    malha, zc, zb, zo, hp, lc, gordo = construir(cid, cor, pele, tipo)
    arm = criar_esqueleto(cid, zc, zb, zo, hp, lc, gordo)
    vincular(malha, arm)
    animar(arm)

    # escala final (o jogo também normaliza, mas já sai no tamanho certo)
    arm.scale = (altura, altura, altura)
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    malha.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    os.makedirs(saida, exist_ok=True)
    destino = os.path.join(saida, cid + ".glb")
    bpy.ops.export_scene.gltf(
        filepath=destino,
        export_format='GLB',
        export_animations=True,
        export_apply=True,
        use_selection=False,
    )
    print("GERADO:", destino, os.path.getsize(destino), "bytes")
    print("ANIMACOES:", [t.name for t in arm.animation_data.nla_tracks])


main()
