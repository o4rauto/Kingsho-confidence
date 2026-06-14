// chibi.js — toolkit de modelagem CHIBI/"super-deformed" estilo vitrine mobile
// (cabeçudo, formas geométricas primárias, bevels macios, toon "vinil/gelatina",
// specular fake, olhos 2D expressivos, contorno marcado, rig de squash & stretch).
//
// 100% procedural / original — só *inspirado* no estilo (regra do CLAUDE.md).
// Zero CDN: importa Three.js vendorizado via importmap.

import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';

// ───────────────────────────── toon / materiais ─────────────────────────────

// gradiente em degraus p/ MeshToonMaterial (sombreamento cel "chapado")
export function toonGradient(steps = 5) {
  const data = new Uint8Array(steps);
  for (let i = 0; i < steps; i++) {
    // empurra os degraus p/ o claro → look "suculento"/iluminado de mobile
    const t = i / (steps - 1);
    data[i] = Math.round((0.35 + 0.65 * t) * 255);
  }
  const tex = new THREE.DataTexture(data, steps, 1, THREE.RedFormat);
  tex.minFilter = tex.magFilter = THREE.NearestFilter;
  tex.needsUpdate = true;
  return tex;
}
export const GRAD = toonGradient(5);

// material "vinil": toon + leve emissivo da própria cor (tira o preto morto das
// sombras e dá aquele aspecto de brinquedo de plástico saturado)
export function vinyl(color, opts = {}) {
  const c = new THREE.Color(color);
  const m = new THREE.MeshToonMaterial({
    color: c,
    gradientMap: GRAD,
    emissive: opts.emissive !== undefined ? new THREE.Color(opts.emissive) : c.clone().multiplyScalar(0.06),
    emissiveIntensity: opts.emissiveIntensity ?? 1,
    transparent: !!opts.transparent,
    opacity: opts.opacity ?? 1,
  });
  return m;
}

// material que brilha (orbe/runas) — vai forte no bloom
export function glow(color, intensity = 1.6) {
  return new THREE.MeshBasicMaterial({ color, toneMapped: false });
}

// ───────────────────────────── contorno marcado ─────────────────────────────

// infla a geometria ao longo das normais → casca p/ inverted-hull outline
function inflate(geo, dist) {
  const g = geo.clone();
  g.computeVertexNormals();
  const pos = g.attributes.position, nor = g.attributes.normal;
  for (let i = 0; i < pos.count; i++) {
    pos.setXYZ(i,
      pos.getX(i) + nor.getX(i) * dist,
      pos.getY(i) + nor.getY(i) * dist,
      pos.getZ(i) + nor.getZ(i) * dist);
  }
  pos.needsUpdate = true;
  return g;
}

// adiciona contorno preto (estilo vetorial/Flash) a uma mesh, como filho dela
export function outline(mesh, dist = 0.045, color = 0x10141f) {
  const o = new THREE.Mesh(
    inflate(mesh.geometry, dist),
    new THREE.MeshBasicMaterial({ color, side: THREE.BackSide, fog: false })
  );
  o.renderOrder = -1;
  o.userData.outline = true;
  mesh.add(o);
  return o;
}

// percorre um grupo e contorna as meshes "de corpo".
// NOTA: o contorno agora é feito por SILHUETA única no viewer (OutlinePass),
// que dá uma linha limpa em volta do personagem sem riscar as interseções
// internas (o contorno por-peça criava "rachaduras" em cada sobreposição).
// Mantido como no-op p/ não quebrar as chamadas existentes.
export function outlineAll(group, dist = 0.045) {
  return group;
}

// ───────────────────────────── primitivas chibi ─────────────────────────────

// caixa arredondada (bevel generoso = "inflado/macio")
export function rbox(w, h, d, color, radius, opts) {
  const r = radius ?? Math.min(w, h, d) * 0.34;
  const m = new THREE.Mesh(new RoundedBoxGeometry(w, h, d, 5, r), vinyl(color, opts));
  return m;
}

// esfera lisa (cabeça, juntas, "blobs")
export function ball(r, color, opts) {
  const m = new THREE.Mesh(new THREE.IcosahedronGeometry(r, 3), vinyl(color, opts));
  return m;
}

// elipsoide (esfera escalada) — torso/cabeça ovalada
export function blob(rx, ry, rz, color, opts) {
  const m = ball(1, color, opts);
  m.scale.set(rx, ry, rz);
  return m;
}

// cone (chapéu de mago, capuz)
export function cone(r, h, color, seg = 24, opts) {
  const m = new THREE.Mesh(new THREE.ConeGeometry(r, h, seg), vinyl(color, opts));
  return m;
}

// cilindro arredondado (cajado, braços/pernas como cápsulas)
export function capsule(r, len, color, opts) {
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 6, 16), vinyl(color, opts));
  return m;
}

// mão-luva (estilo Mickey/Rayman): blob arredondado, sem dedos
export function glove(r, color, opts) {
  return ball(r, color, opts);
}

// ───────────────────────────── olhos 2D expressivos ─────────────────────────

// catchlight branco (specular fake "molhado/gelatina")
function catchlight(r) {
  const m = new THREE.Mesh(
    new THREE.CircleGeometry(r, 12),
    new THREE.MeshBasicMaterial({ color: 0xffffff, toneMapped: false })
  );
  m.userData.noOutline = true;
  return m;
}

// um olho grande chibi: esclera branca + íris colorida + pupila + 2 catchlights.
// Tudo em planos 2D flutuando na face (trocáveis p/ expressões).
// expr: 'normal' | 'happy' | 'angry' | 'dead'
export function eye(size = 0.5, iris = 0x2b6cff, expr = 'normal') {
  const g = new THREE.Group();
  // esclera (branca, levemente ovalada)
  const sclera = new THREE.Mesh(
    new THREE.CircleGeometry(size, 24),
    new THREE.MeshBasicMaterial({ color: 0xfdfdff, toneMapped: false })
  );
  sclera.scale.set(0.82, 1, 1);
  sclera.userData.noOutline = true;
  // contorno do olho (anel escuro fininho)
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(size * 0.96, size * 1.12, 24),
    new THREE.MeshBasicMaterial({ color: 0x141019, toneMapped: false })
  );
  ring.scale.set(0.82, 1, 1); ring.position.z = -0.001; ring.userData.noOutline = true;
  g.add(ring, sclera);

  if (expr === 'dead') {
    // "X" nos olhos
    for (const a of [Math.PI / 4, -Math.PI / 4]) {
      const bar = new THREE.Mesh(
        new THREE.PlaneGeometry(size * 1.7, size * 0.28),
        new THREE.MeshBasicMaterial({ color: 0x141019, toneMapped: false }));
      bar.rotation.z = a; bar.position.z = 0.01; bar.userData.noOutline = true; g.add(bar);
    }
    return g;
  }

  // íris + pupila
  const ir = new THREE.Mesh(
    new THREE.CircleGeometry(size * 0.6, 24),
    new THREE.MeshBasicMaterial({ color: iris, toneMapped: false }));
  ir.position.set(0, -size * 0.05, 0.01); ir.userData.noOutline = true;
  const pupil = new THREE.Mesh(
    new THREE.CircleGeometry(size * 0.32, 20),
    new THREE.MeshBasicMaterial({ color: 0x0a0a12, toneMapped: false }));
  pupil.position.set(0, -size * 0.05, 0.02); pupil.userData.noOutline = true;
  g.add(ir, pupil);

  // 2 catchlights (o "molhado" gelatinoso)
  const cl1 = catchlight(size * 0.22); cl1.position.set(size * 0.22, size * 0.22, 0.03);
  const cl2 = catchlight(size * 0.11); cl2.position.set(-size * 0.12, -size * 0.12, 0.03);
  g.add(cl1, cl2);

  // pálpebra p/ expressão (sobrepõe a parte de cima)
  if (expr === 'angry' || expr === 'happy') {
    const lid = new THREE.Mesh(
      new THREE.CircleGeometry(size * 1.16, 24),
      new THREE.MeshBasicMaterial({ color: 0x141019, toneMapped: false }));
    lid.scale.set(0.82, 1, 1);
    lid.position.set(0, expr === 'angry' ? size * 0.62 : size * 0.86, 0.04);
    lid.rotation.z = 0; lid.userData.noOutline = true;
    g.add(lid);
  }
  return g;
}

// bochecha rosada (specular fake de "saúde"/juiciness)
export function blush(r = 0.16) {
  const m = new THREE.Mesh(
    new THREE.CircleGeometry(r, 16),
    new THREE.MeshBasicMaterial({ color: 0xff6f7a, transparent: true, opacity: 0.55, toneMapped: false }));
  m.userData.noOutline = true;
  return m;
}

// ───────────────────────────── rig squash & stretch ─────────────────────────

// Envolve um modelo num rig com idle bob + API de squash/stretch preservando
// volume (escala Y * k, X/Z * 1/sqrt(k)). Use rig.update(t) no loop.
export class Rig extends THREE.Group {
  constructor(model) {
    super();
    this.model = model;
    this.add(model);
    this.t0 = Math.random() * 10;
    this._sq = 1;
  }
  // squash/stretch preservando volume; k>1 estica, k<1 esmaga
  set squash(k) {
    this._sq = k;
    const inv = 1 / Math.sqrt(k);
    this.model.scale.set(inv, k, inv);
  }
  get squash() { return this._sq; }

  update(t, opts = {}) {
    const tt = t + this.t0;
    // respiração: bob vertical + leve squash senoidal (vida/juiciness)
    const breathe = 1 + Math.sin(tt * 2.2) * (opts.breathe ?? 0.05);
    this.squash = breathe;
    this.model.position.y = Math.sin(tt * 2.2) * (opts.bob ?? 0.06);
    this.model.rotation.z = Math.sin(tt * 1.3) * (opts.sway ?? 0.02);
  }
}

export { THREE };
