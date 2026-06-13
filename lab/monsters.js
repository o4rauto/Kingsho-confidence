// monsters.js — monstros chibi do roster (originais), com o toolkit chibi.js.
// Mesmo padrão do herói: silhueta forte, toon vinil, contorno, olhos 2D,
// porém com "cara de monstro" (presas, chifres/orelhas, expressão raivosa).

import {
  THREE, vinyl, glow, rbox, ball, blob, cone, capsule, glove, eye, outlineAll,
} from './chibi.js';

// ── boca raivosa com presas (grupo 2D+3D na frente da face) ──
function fangMouth(width = 0.5, color = 0x3a0d12, fangColor = 0xfdfdff) {
  const g = new THREE.Group();
  const mouth = new THREE.Mesh(
    new THREE.CircleGeometry(width, 20),
    new THREE.MeshBasicMaterial({ color, toneMapped: false }));
  mouth.scale.set(1, 0.52, 1); mouth.userData.noOutline = true; g.add(mouth);
  // presas (cones brancos) — 2 de baixo p/ cima, 2 de cima p/ baixo
  const mkFang = (x, up) => {
    const f = new THREE.Mesh(new THREE.ConeGeometry(width * 0.16, width * 0.5, 4),
      new THREE.MeshBasicMaterial({ color: fangColor, toneMapped: false }));
    f.position.set(x, up ? -width * 0.12 : width * 0.12, 0.02);
    f.rotation.z = up ? 0 : Math.PI; f.userData.noOutline = true; return f;
  };
  g.add(mkFang(-width * 0.5, true), mkFang(width * 0.5, true),
        mkFang(-width * 0.22, false), mkFang(width * 0.22, false));
  return g;
}

// ════════════════════════════ GRUNT (goblin atarracado) ════════════════════════════
export function buildGrunt(opts = {}) {
  const SKIN = opts.skin ?? 0x74b03e;   // verde saturado
  const SKIN2 = opts.skin2 ?? 0x4f7d27;  // sombra/verde escuro
  const BELLY = opts.belly ?? 0xc8e38c;  // barriga clara
  const CLOTH = opts.cloth ?? 0x7a4a22;  // tanga
  const WOOD = 0x8a5a2b;

  const model = new THREE.Group();
  const HEADR = 0.6;
  const HEADY = 1.28;

  // ── pés/pernas atarracadas ──
  for (const sx of [-1, 1]) {
    const foot = blob(0.28, 0.2, 0.34, SKIN2); foot.position.set(sx * 0.3, 0.16, 0.08); model.add(foot);
    // dedões (garras)
    for (const k of [-1, 0, 1]) {
      const toe = new THREE.Mesh(new THREE.ConeGeometry(0.05, 0.12, 4),
        new THREE.MeshBasicMaterial({ color: 0xe9e4d0, toneMapped: false }));
      toe.position.set(sx * 0.3 + k * 0.09, 0.14, 0.4); toe.rotation.x = Math.PI / 2;
      toe.userData.noOutline = true; model.add(toe);
    }
  }

  // ── corpo: barrigudo (ovo) ──
  const body = blob(0.6, 0.56, 0.55, SKIN); body.position.y = 0.66; model.add(body);
  const belly = new THREE.Mesh(new THREE.CircleGeometry(0.34, 20),
    new THREE.MeshBasicMaterial({ color: BELLY, toneMapped: false }));
  belly.scale.set(1, 1.15, 1); belly.position.set(0, 0.62, 0.56); belly.userData.noOutline = true; model.add(belly);
  // tanga
  const cloth = new THREE.Mesh(new THREE.CylinderGeometry(0.6, 0.66, 0.34, 20), vinyl(CLOTH));
  cloth.position.y = 0.36; model.add(cloth);
  const clothFlap = rbox(0.34, 0.4, 0.1, CLOTH, 0.05); clothFlap.position.set(0, 0.34, 0.56); model.add(clothFlap);

  // ── braços curtos e grossos ──
  const armL = capsule(0.16, 0.28, SKIN); armL.position.set(-0.58, 0.78, 0.06); armL.rotation.z = 0.6; model.add(armL);
  const fistL = glove(0.21, SKIN2); fistL.position.set(-0.74, 0.54, 0.14); model.add(fistL);
  // braço direito levantado com porrete
  const armR = capsule(0.16, 0.3, SKIN); armR.position.set(0.56, 0.92, 0.08); armR.rotation.z = -0.7; model.add(armR);
  const fistR = glove(0.22, SKIN2); fistR.position.set(0.78, 1.18, 0.12); model.add(fistR);

  // porrete nodoso
  const club = capsule(0.1, 0.7, WOOD); club.position.set(0.95, 1.5, 0.1); club.rotation.z = -0.25; model.add(club);
  const head1 = ball(0.26, 0x6b4321); head1.position.set(1.06, 1.82, 0.1); model.add(head1);
  for (const a of [0, 2.1, 4.2]) {
    const knob = ball(0.1, 0x5a3719);
    knob.position.set(1.06 + Math.cos(a) * 0.24, 1.82 + Math.sin(a) * 0.24, 0.12); model.add(knob);
  }

  // ── CABEÇA grande (chibi) ──
  const head = ball(HEADR, SKIN); head.position.y = HEADY; head.scale.set(1.08, 0.96, 0.98); model.add(head);

  // orelhas pontudas enormes (silhueta!)
  for (const sx of [-1, 1]) {
    const ear = cone(0.2, 0.6, SKIN, 14); ear.position.set(sx * 0.66, HEADY + 0.12, -0.05);
    ear.rotation.z = sx * -1.15; ear.rotation.y = sx * 0.3; model.add(ear);
    const earIn = cone(0.1, 0.4, SKIN2, 12); earIn.position.set(sx * 0.6, HEADY + 0.12, 0.02);
    earIn.rotation.z = sx * -1.15; earIn.rotation.y = sx * 0.3; earIn.userData.noOutline = true; model.add(earIn);
  }

  // testa/sobrancelha raivosa (bloco escuro angulado pra dentro)
  for (const sx of [-1, 1]) {
    const brow = rbox(0.3, 0.12, 0.08, SKIN2, 0.04);
    brow.position.set(sx * 0.24, HEADY + 0.2, HEADR * 0.9); brow.rotation.z = sx * -0.5; model.add(brow);
  }
  // olhos arregalados amarelos (a fúria vem das sobrancelhas anguladas)
  for (const sx of [-1, 1]) {
    const e = eye(0.18, 0xffd23a, 'normal');
    e.position.set(sx * 0.25, HEADY + 0.06, HEADR * 0.92); e.userData.noOutline = true; model.add(e);
  }
  // nariz bulboso
  const nose = blob(0.13, 0.11, 0.16, SKIN2); nose.position.set(0, HEADY - 0.06, HEADR * 1.0); model.add(nose);
  // boca com presas
  const mouth = fangMouth(0.34); mouth.position.set(0, HEADY - 0.32, HEADR * 0.86); model.add(mouth);

  // par de chifrinhos pequenos no topo
  for (const sx of [-1, 1]) {
    const horn = cone(0.1, 0.26, 0xe9e0c8, 10); horn.position.set(sx * 0.26, HEADY + HEADR * 0.85, 0.02);
    horn.rotation.z = sx * -0.3; model.add(horn);
  }

  outlineAll(model, 0.05);
  return { model, lights: [] };
}
