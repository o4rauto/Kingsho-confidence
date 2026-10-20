#!/usr/bin/env python3
"""
Bastion Rush — construtor de torres 3D (hard-surface, modelado por script).

Estilo: cartoon estilizado — volumes primários simples, silhueta legível de
longe, cores controladas, detalhe seletivo. Low-poly de propósito: o jogo é
mobile e a torre aparece em dezenas de cópias na tela.

Cada família tem 3 tiers com progressão visual legível (o jogador precisa VER
que evoluiu): tier 1 base simples, tier 2 ganha ameias e altura, tier 3 ganha
telhado e estandarte.

Uso:
  blender --background --python pipeline/blender/construir_torre.py -- \
      --familia archer --tier 1 --cor 4e9a4e --saida godot/assets/models \
      --previa /tmp/torre.png

Famílias: archer | barracks | mage | artillery | ballista | cauldron | tesla | goldmine
"""
import bpy
import bmesh
import math
import sys
import os
from mathutils import Vector

# altura final por tier, igual ao que o jogo espera (asset_lib.make_tower)
ALTURA = {1: 3.1, 2: 3.5, 3: 3.9}

PEDRA = "a9a093"
PEDRA_ESC = "70685c"
MADEIRA = "8a5a2f"
MADEIRA_ESC = "573520"
TELHA = "b2432f"
METAL = "9aa0ab"


# ───────────────────────── utilidades ─────────────────────────

def limpar():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for b in (bpy.data.meshes, bpy.data.materials, bpy.data.objects):
        for it in list(b):
            try:
                b.remove(it)
            except Exception:
                pass


def hex_rgb(h):
    h = h.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))

    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b), 1.0)


_mats = {}


def mat(nome, cor_hex, rough=0.85):
    if nome in _mats:
        return _mats[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = hex_rgb(cor_hex)
    if "Roughness" in b.inputs:
        b.inputs["Roughness"].default_value = rough
    if "Specular" in b.inputs:
        b.inputs["Specular"].default_value = 0.1
    _mats[nome] = m
    return m


def cil(nome, r1, r2, h, z, lados=12, material=None):
    """Cone truncado — o volume primário da torre."""
    bpy.ops.mesh.primitive_cone_add(vertices=lados, radius1=r1, radius2=r2,
                                    depth=h, location=(0, 0, z + h / 2.0))
    o = bpy.context.active_object
    o.name = nome
    if material:
        o.data.materials.append(material)
    return o


def caixa(nome, sx, sy, sz, loc, rot_z=0.0, material=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = nome
    o.scale = (sx, sy, sz)
    o.rotation_euler[2] = rot_z
    if material:
        o.data.materials.append(material)
    return o


def aplicar(o):
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def juntar(objs, nome):
    objs = [o for o in objs if o is not None]
    for o in objs:
        aplicar(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = nome
    return o


def bisel(o, largura=0.02, segmentos=1):
    """Bevel: dá o brilho na quina. Objeto nenhum do mundo real tem aresta
    infinitamente viva — sem isso a silhueta fica dura e sem leitura."""
    m = o.modifiers.new("Bevel", 'BEVEL')
    m.width = largura
    m.segments = segmentos
    m.limit_method = 'ANGLE'
    m.angle_limit = math.radians(40)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=m.name)


def anel_de_pecas(prefixo, n, raio, criar):
    """Distribui n peças em círculo (ameias, postes, vigas)."""
    out = []
    for i in range(n):
        a = (i / float(n)) * math.tau
        o = criar(i, a, Vector((math.cos(a) * raio, math.sin(a) * raio, 0)))
        if o:
            o.rotation_euler[2] = a
            out.append(o)
    return out


# ───────────────────── peças comuns ─────────────────────

def base_pedra(h, r_baixo, r_cima):
    """Tronco de pedra levemente cônico + friso na base (dá apoio visual)."""
    corpo = cil("base", r_baixo, r_cima, h, 0.0, 12, mat("pedra", PEDRA))
    friso = cil("friso", r_baixo * 1.12, r_baixo * 1.08, h * 0.09, 0.0, 12,
                mat("pedra_esc", PEDRA_ESC))
    return [corpo, friso]


def plataforma(z, r, esp=0.14):
    return cil("deck", r, r, esp, z, 12, mat("madeira", MADEIRA))


def ameias(z, r, n=8, larg=0.22, alt=0.3):
    """Merlões — a assinatura de silhueta de uma torre medieval."""
    m = mat("pedra", PEDRA)

    def cria(i, a, pos):
        return caixa("ameia%d" % i, larg, larg * 0.75, alt,
                     (pos.x, pos.y, z + alt / 2.0), a, m)
    return anel_de_pecas("ameia", n, r, cria)


def grade(z, r, n=8, alt=0.42):
    """Postes de madeira + corrimão: leitura de posto de arqueiro."""
    mm = mat("madeira_esc", MADEIRA_ESC)

    def cria(i, a, pos):
        return caixa("poste%d" % i, 0.09, 0.09, alt,
                     (pos.x, pos.y, z + alt / 2.0), a, mm)
    ps = anel_de_pecas("poste", n, r, cria)
    rail = cil("corrimao", r + 0.05, r + 0.05, 0.07, z + alt * 0.82, 12, mm)
    ps.append(rail)
    return ps


def telhado(z, r, cor_hex=TELHA):
    """Cone de telhado + ponteira. É o que marca o tier 3 à distância."""
    t = cil("telhado", r, 0.04, r * 1.15, z, 12, mat("telha", cor_hex))
    p = cil("ponteira", 0.05, 0.05, 0.22, z + r * 1.15 - 0.02, 8,
            mat("metal", METAL))
    return [t, p]


def estandarte(z, r, cor_hex):
    """Mastro + bandeira na cor da família — identifica a torre de longe."""
    mastro = cil("mastro", 0.035, 0.035, 0.62, z, 6, mat("metal", METAL))
    pano = caixa("bandeira", 0.34, 0.03, 0.26,
                 (0.17 + 0.035, 0, z + 0.44), 0.0, mat("accent", cor_hex, 0.7))
    return [mastro, pano]


# ───────────────────── torres por família ─────────────────────

def seteiras(z, r, n, alt=0.34, larg=0.075):
    """Frestas de tiro: o detalhe que identifica a torre de arqueiros de longe.
    Recuadas na pedra, bem escuras, pra lerem como vão mesmo a 3 metros."""
    m = mat("fresta", "2a2521", 0.95)

    def cria(i, a, pos):
        return caixa("fresta%d" % i, larg, 0.10, alt,
                     (pos.x * 0.985, pos.y * 0.985, z + alt / 2.0), a, m)
    return anel_de_pecas("fresta", n, r, cria)


def torre_archer(tier, cor):
    """Posto de arqueiros: fuste de pedra esguio + deck de madeira.
    Progressao de massa: o raio E a altura crescem, entao o jogador ve a
    evolucao mesmo de longe.
      t1 posto aberto com cobertura simples
      t2 fuste mais alto, ameias, seteiras e estandarte
      t3 torre cheia: telhado conico, mais ameias, mais seteiras
    """
    H = ALTURA[tier]
    pecas = []

    if tier == 1:
        r = 0.56                      # esguio: le como TORRE, nao como barril
        h_base = H * 0.66
        pecas += base_pedra(h_base, r * 1.16, r)
        pecas += seteiras(h_base * 0.45, r, 3, H * 0.10)
        pecas.append(plataforma(h_base, r + 0.22))
        pecas += grade(h_base + 0.14, r + 0.06, 8, H * 0.17)
        mmad = mat("madeira_esc", MADEIRA_ESC)
        for sx in (-1, 1):
            pecas.append(caixa("sup%d" % sx, 0.075, 0.075, H * 0.16,
                               (sx * (r - 0.02), 0, h_base + 0.14 + H * 0.08),
                               0.0, mmad))
        # cone, nao laje: a 55 graus o topo e a face mais visivel, e uma chapa
        # plana vira so um retangulo de cor. O cone mantem leitura de telhado.
        pecas += telhado(h_base + 0.14 + H * 0.16, r + 0.26)

    elif tier == 2:
        r = 0.62
        h_base = H * 0.68
        pecas += base_pedra(h_base, r * 1.18, r)
        pecas.append(cil("faixa", r * 1.07, r * 1.07, 0.11, h_base * 0.52, 12,
                         mat("pedra_esc", PEDRA_ESC)))
        pecas += seteiras(h_base * 0.30, r, 3, H * 0.10)
        pecas += seteiras(h_base * 0.70, r, 3, H * 0.10)
        pecas.append(plataforma(h_base, r + 0.26))
        pecas += ameias(h_base + 0.14, r + 0.14, 8, 0.21, H * 0.11)
        pecas += grade(h_base + 0.14, r - 0.04, 6, H * 0.12)
        pecas += estandarte(h_base + 0.14 + H * 0.11, r, cor)

    else:
        r = 0.68
        h_base = H * 0.64
        pecas += base_pedra(h_base, r * 1.20, r)
        for zf in (0.34, 0.72):
            pecas.append(cil("faixa", r * 1.07, r * 1.07, 0.10, h_base * zf, 12,
                             mat("pedra_esc", PEDRA_ESC)))
        pecas += seteiras(h_base * 0.22, r, 4, H * 0.09)
        pecas += seteiras(h_base * 0.52, r, 4, H * 0.09)
        pecas.append(plataforma(h_base, r + 0.30))
        pecas += ameias(h_base + 0.14, r + 0.18, 10, 0.20, H * 0.10)
        z_tel = h_base + 0.14 + H * 0.10
        pecas += telhado(z_tel, r + 0.22)
        pecas += estandarte(z_tel + (r + 0.22) * 1.15 - 0.12, r, cor)

    return pecas


FAMILIAS = {"archer": torre_archer}


# ───────────────────────── prévia ─────────────────────────

def render_previa(saida, h, h_ref=3.9):
    w = bpy.data.worlds['World']
    w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.55, 0.72, 0.88, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 0.9
    # chão pra leitura de apoio e sombra
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
    bpy.context.active_object.data.materials.append(mat("grama", "6f9b4a"))
    sol = bpy.ops.object.light_add(type='SUN', location=(4, -5, 8))
    s = bpy.context.active_object
    s.data.energy = 4.0
    s.data.angle = math.radians(8)
    s.rotation_euler = (math.radians(52), 0, math.radians(38))
    bpy.ops.object.light_add(type='AREA', location=(-5, -4, 4))
    bpy.context.active_object.data.energy = 220
    # câmera FIXA pelo tier mais alto: assim dá pra comparar os tiers entre si
    bpy.ops.object.camera_add(location=(h_ref * 1.55, -h_ref * 2.0, h_ref * 0.80),
                              rotation=(math.radians(76), 0, math.radians(38)))
    cam = bpy.context.active_object
    cam.data.lens = 52
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 40
    sc.render.resolution_x, sc.render.resolution_y = 420, 500
    sc.render.filepath = saida
    bpy.ops.render.render(write_still=True)


# ───────────────────────── principal ─────────────────────────

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


def main():
    a = args()
    fam = a.get("familia", "archer")
    tier = int(a.get("tier", "1"))
    cor = a.get("cor", "4e9a4e")
    saida_dir = os.path.expanduser(a.get("saida", "godot/assets/models"))
    previa = a.get("previa", "")

    if fam not in FAMILIAS:
        sys.exit("Família ainda não implementada: " + fam)

    limpar()
    pecas = FAMILIAS[fam](tier, cor)
    torre = juntar(pecas, "SM_Tower_%s_t%d" % (fam.capitalize(), tier))
    bisel(torre, 0.022, 1)

    # shading: liso no telhado/cones, duro no resto → leitura cartoon
    bpy.context.view_layer.objects.active = torre
    bpy.ops.object.shade_flat()

    # origem no chão e centrada: o jogo planta a torre pelo y=0
    aplicar(torre)
    mn = Vector((min((torre.matrix_world @ Vector(c)).x for c in torre.bound_box),
                 min((torre.matrix_world @ Vector(c)).y for c in torre.bound_box),
                 min((torre.matrix_world @ Vector(c)).z for c in torre.bound_box)))
    mx = Vector((max((torre.matrix_world @ Vector(c)).x for c in torre.bound_box),
                 max((torre.matrix_world @ Vector(c)).y for c in torre.bound_box),
                 max((torre.matrix_world @ Vector(c)).z for c in torre.bound_box)))
    torre.location -= Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    aplicar(torre)

    # escala exata pra altura que o jogo espera
    alt = mx.z - mn.z
    k = ALTURA[tier] / alt
    torre.scale = (k, k, k)
    aplicar(torre)

    tris = sum(len(p.vertices) - 2 for p in torre.data.polygons)
    print("TORRE %s t%d | faces=%d tris=%d materiais=%d altura=%.2f"
          % (fam, tier, len(torre.data.polygons), tris,
             len(torre.data.materials), ALTURA[tier]))

    os.makedirs(saida_dir, exist_ok=True)
    nome = "tower_%s_%d" % (fam, tier)
    destino = os.path.join(saida_dir, nome + ".glb")
    bpy.ops.export_scene.gltf(filepath=destino, export_format='GLB',
                              export_apply=True)
    print("GERADO: %s (%d bytes)" % (destino, os.path.getsize(destino)))

    if previa:
        render_previa(previa, ALTURA[tier])
        print("PREVIA: %s" % previa)


main()
