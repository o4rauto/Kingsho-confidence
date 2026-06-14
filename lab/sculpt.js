// sculpt.js — TOOLKIT de modelagem de ALTA DENSIDADE (estilo Clash Royale).
// Substitui o chibi.js de primitivas cruas: aqui as peças têm BEVEL (cantos
// chanfrados/robustos), perfis LATHE (revolução suave) e geometria subdividida,
// com material TOON de sombreado macio. O contorno é a silhueta única (OutlinePass)
// no viewer — então NÃO desenhamos contorno por-peça.
//
// Meta visual: formas grandes e arredondadas, bordas chanfradas "de brinquedo",
// cores saturadas, muito detalhe de superfície (placas, rebites, dobras, tiras).

import { THREE } from './chibi.js';

// ── material TOON macio (Clash: poucas bandas, transição suave) ──
function makeGrad(stops) {
  const data = new Uint8Array(stops.length * 4);
  stops.forEach((v, i) => { const c = Math.round(v * 255); data[i*4]=c; data[i*4+1]=c; data[i*4+2]=c; data[i*4+3]=255; });
  const t = new THREE.DataTexture(data, stops.length, 1, THREE.RGBAFormat);
  t.needsUpdate = true; t.minFilter = THREE.LinearFilter; t.magFilter = THREE.LinearFilter;
  return t;
}
export const TOON = makeGrad([0.32, 0.5, 0.72, 0.9, 1.0]);

export function mat(color, opts = {}) {
  return new THREE.MeshToonMaterial({ color, gradientMap: TOON, ...opts });
}
export function emis(color) { return new THREE.MeshBasicMaterial({ color, toneMapped: false }); }

// ── shapes 2D ──
export function roundRect(w, h, r) {
  const s = new THREE.Shape();
  const x = -w/2, y = -h/2;
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y); s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, y + h - r); s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h); s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, y + r); s.quadraticCurveTo(x, y, x + r, y);
  return s;
}
// polígono/estrela/losango por raio
export function polyShape(points) {
  const s = new THREE.Shape();
  points.forEach((p, i) => i ? s.lineTo(p[0], p[1]) : s.moveTo(p[0], p[1]));
  s.closePath(); return s;
}

// ── peça CHANFRADA (extrude com bevel) — placas, escudos, lâminas, fivelas ──
export function slab(shape, depth = 0.2, color = 0xffffff, bevel = 0.04) {
  const g = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: true, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 3, steps: 1,
  });
  g.center(); g.computeVertexNormals();
  return new THREE.Mesh(g, mat(color));
}
export function plate(w, h, depth, color, r = 0.08, bevel = 0.035) {
  return slab(roundRect(w, h, r), depth, color, bevel);
}

// ── LATHE (revolução de um perfil [[x,y],...]) — orbe, elmo, sino do robe, cajado ──
export function lathe(profile, color, seg = 36) {
  const pts = profile.map(p => new THREE.Vector2(p[0], p[1]));
  const g = new THREE.LatheGeometry(pts, seg); g.computeVertexNormals();
  return new THREE.Mesh(g, mat(color));
}

// ── primitivas suaves (alta subdivisão) ──
export function sphere(r, color, seg = 28) { return new THREE.Mesh(new THREE.SphereGeometry(r, seg, seg), mat(color)); }
export function ellip(rx, ry, rz, color, seg = 28) { const m = sphere(1, color, seg); m.scale.set(rx, ry, rz); return m; }
export function caps(r, len, color) { return new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 10, 18), mat(color)); }
export function cyl(rt, rb, h, color, seg = 28) { return new THREE.Mesh(new THREE.CylinderGeometry(rt, rb, h, seg), mat(color)); }
export function cone(r, h, color, seg = 24) { return new THREE.Mesh(new THREE.ConeGeometry(r, h, seg), mat(color)); }
export function torus(r, t, color, seg = 28, arc = Math.PI * 2) { return new THREE.Mesh(new THREE.TorusGeometry(r, t, 14, seg, arc), mat(color)); }

// ── peças emissivas (orbe/olhos/brasa) — sem contorno ──
export function glowBall(r, color, seg = 20) { const m = new THREE.Mesh(new THREE.IcosahedronGeometry(r, 2), emis(color)); m.userData.noOutline = true; return m; }
export function glowMesh(geo, color) { const m = new THREE.Mesh(geo, emis(color)); m.userData.noOutline = true; return m; }

// ── olho cartoon (esclera branca + íris + brilho), montado em grupo plano ──
export function eye(size = 0.2, iris = 0x2fc6d6, glowEye = false) {
  const g = new THREE.Group();
  const sclera = glowEye ? emis : mat;   // monstros podem ter olho que brilha
  const white = new THREE.Mesh(new THREE.CircleGeometry(size, 22), sclera(glowEye ? iris : 0xf4f8ff));
  const ir = new THREE.Mesh(new THREE.CircleGeometry(size * 0.62, 20), sclera(iris)); ir.position.z = 0.01;
  const pup = new THREE.Mesh(new THREE.CircleGeometry(size * 0.3, 16), mat(0x141824)); pup.position.z = 0.02;
  const sh = new THREE.Mesh(new THREE.CircleGeometry(size * 0.16, 12), emis(0xffffff));
  sh.position.set(size * 0.22, size * 0.24, 0.03);
  g.add(white, ir, pup, sh); g.traverse(o => o.userData.noOutline = true);
  return g;
}

// ── utilidades ──
// agrupa N peças idênticas espelhadas em x (sx = -1 e 1)
export function mirror(build) { const g = new THREE.Group(); for (const sx of [-1, 1]) g.add(build(sx)); return g; }

export { THREE };
