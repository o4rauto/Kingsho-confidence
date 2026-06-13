// hero.js — MAGO HERÓI chibi heróico (estilo vitrine mobile / Clash-like).
// Original. Reformulado: ombros largos + robe reto (silhueta masculina), BARBA
// de mago (tira a cara de bebê), expressão confiante. Toolkit em chibi.js.
//
// buildHeroMage(opts) → { model: THREE.Group, orb, lights } pronto p/ Rig.

import {
  THREE, vinyl, glow, rbox, ball, blob, cone, capsule, glove,
  eye, outlineAll,
} from './chibi.js';

export function buildHeroMage(opts = {}) {
  const ROBE = opts.robe ?? 0x3550d8;   // azul saturado
  const ROBE2 = opts.robe2 ?? 0x223499;  // sombra/forro
  const SKIN = opts.skin ?? 0xf1b48a;   // pele mais bronzeada (menos "bebê")
  const GOLD = 0xffc73a;
  const HATC = opts.hat ?? 0x2a37b8;
  const ORBC = opts.orb ?? 0x5fe0ff;
  const HAIR = opts.hair ?? 0xe9edf4;   // barba/cabelo grisalho

  const model = new THREE.Group();
  const HEADR = 0.6;
  const HEADY = 1.96;

  // ── botas (só as pontas pra fora do robe) ──
  for (const sx of [-1, 1]) {
    const boot = rbox(0.36, 0.22, 0.5, 0x5a3f74, 0.1);
    boot.position.set(sx * 0.3, 0.13, 0.12); model.add(boot);
  }

  // ── ROBE reto (cilindro com leve taper, NÃO um vestido afunilado) ──
  const robe = new THREE.Mesh(new THREE.CylinderGeometry(0.66, 0.82, 1.5, 28), vinyl(ROBE));
  robe.position.y = 0.84; model.add(robe);
  // barra inferior
  const hem = new THREE.Mesh(new THREE.CylinderGeometry(0.83, 0.86, 0.18, 28), vinyl(ROBE2));
  hem.position.y = 0.2; model.add(hem);
  // painel central da frente (faixa clara com trim dourado)
  const panel = rbox(0.3, 1.35, 0.12, 0xeef2ff, 0.05);
  panel.position.set(0, 0.85, 0.74); model.add(panel);
  for (const sx of [-1, 1]) {
    const trim = rbox(0.05, 1.35, 0.1, GOLD, 0.02);
    trim.position.set(sx * 0.17, 0.85, 0.76); model.add(trim);
  }

  // ── OMBROS largos (silhueta masculina) + ombreiras arredondadas ──
  const shoulders = rbox(1.3, 0.46, 0.66, ROBE, 0.22);
  shoulders.position.y = 1.5; model.add(shoulders);
  for (const sx of [-1, 1]) {
    const pad = blob(0.34, 0.3, 0.36, ROBE2); pad.position.set(sx * 0.62, 1.56, 0.02);
    model.add(pad);
    const rivet = ball(0.08, GOLD); rivet.position.set(sx * 0.62, 1.66, 0.3); model.add(rivet);
  }
  // gola
  const collar = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.42, 0.2, 20), vinyl(ROBE2));
  collar.position.y = 1.74; model.add(collar);

  // ── cinto largo + fivela (mais baixo, sem cintura de ampulheta) ──
  const belt = new THREE.Mesh(new THREE.CylinderGeometry(0.74, 0.78, 0.2, 28), vinyl(0x4a2f1c));
  belt.position.y = 0.86; model.add(belt);
  const buckle = rbox(0.26, 0.22, 0.12, GOLD, 0.05); buckle.position.set(0, 0.86, 0.84); model.add(buckle);

  // ── capa atrás ──
  const cape = rbox(1.0, 1.4, 0.16, ROBE2, 0.3);
  cape.position.set(0, 1.2, -0.46); cape.rotation.x = 0.1; model.add(cape);

  // ── braços curtos + punhos (luva) ──
  const armL = capsule(0.17, 0.34, ROBE); armL.position.set(-0.62, 1.28, 0.06);
  armL.rotation.z = 0.35; model.add(armL);
  const fistL = glove(0.22, SKIN); fistL.position.set(-0.78, 1.0, 0.16); model.add(fistL);
  const cuffL = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.22, 0.14, 16), vinyl(GOLD));
  cuffL.position.set(-0.74, 1.12, 0.12); cuffL.rotation.z = 0.35; model.add(cuffL);

  const armR = capsule(0.17, 0.4, ROBE); armR.position.set(0.6, 1.34, 0.1);
  armR.rotation.z = -0.7; model.add(armR);
  const fistR = glove(0.22, SKIN); fistR.position.set(0.92, 1.62, 0.14); model.add(fistR);

  // ── CABEÇA (chibi, mas pele bronzeada + sem blush = menos bebê) ──
  const head = ball(HEADR, SKIN);
  head.position.y = HEADY; head.scale.set(1.02, 1, 0.98); model.add(head);
  for (const sx of [-1, 1]) {
    const ear = ball(0.12, SKIN); ear.position.set(sx * HEADR * 0.95, HEADY - 0.02, -0.02); model.add(ear);
  }

  // sobrancelhas grossas e anguladas (confiança/seriedade)
  for (const sx of [-1, 1]) {
    const brow = rbox(0.26, 0.08, 0.06, HAIR, 0.03);
    brow.position.set(sx * 0.25, HEADY + 0.16, HEADR * 0.9);
    brow.rotation.z = sx * 0.22; model.add(brow);
  }
  // olhos (um pouco menores e firmes)
  for (const sx of [-1, 1]) {
    const e = eye(0.17, 0x2f74ff, 'normal');
    e.position.set(sx * 0.25, HEADY + 0.0, HEADR * 0.92);
    e.userData.noOutline = true; model.add(e);
  }
  // nariz forte
  const nose = blob(0.09, 0.1, 0.12, 0xe7a074); nose.position.set(0, HEADY - 0.16, HEADR * 0.98); model.add(nose);

  // ── BIGODE + BARBA de mago (tira a cara de bebê e o ar feminino) ──
  // bigode (dois blobs)
  for (const sx of [-1, 1]) {
    const m = blob(0.16, 0.1, 0.12, HAIR); m.position.set(sx * 0.12, HEADY - 0.26, HEADR * 0.86);
    m.rotation.z = sx * 0.4; model.add(m);
  }
  // barba: bloco principal afunilando pra baixo + pontas
  const beard = cone(0.56, 0.95, HAIR, 22);
  beard.position.set(0, HEADY - 0.62, HEADR * 0.5); beard.scale.set(1.05, 1, 0.7);
  model.add(beard);
  const beardBase = blob(0.5, 0.34, 0.4, HAIR); beardBase.position.set(0, HEADY - 0.28, HEADR * 0.62); model.add(beardBase);
  // costeletas ligando barba às orelhas
  for (const sx of [-1, 1]) {
    const s = blob(0.16, 0.26, 0.2, HAIR); s.position.set(sx * 0.46, HEADY - 0.16, HEADR * 0.42); model.add(s);
  }

  // ── CHAPÉU pontudo (aba + banda dourada + estrela) ──
  const brim = new THREE.Mesh(new THREE.CylinderGeometry(0.82, 0.88, 0.1, 28), vinyl(HATC));
  brim.position.y = HEADY + HEADR * 0.66; model.add(brim);
  const hat = cone(0.58, 1.35, HATC, 28);
  hat.position.set(0.05, HEADY + HEADR * 0.66 + 0.72, -0.02);
  hat.rotation.z = -0.13; hat.rotation.x = 0.04; model.add(hat);
  const hatBand = new THREE.Mesh(new THREE.CylinderGeometry(0.6, 0.64, 0.18, 28), vinyl(GOLD));
  hatBand.position.y = HEADY + HEADR * 0.66 + 0.16; model.add(hatBand);
  const star = new THREE.Mesh(starGeo(0.15, 0.07, 5), glow(0xfff3b0));
  star.position.set(0, HEADY + HEADR * 0.66 + 0.18, 0.62); star.userData.noOutline = true; model.add(star);

  // ── CAJADO + ORBE (longe do rosto, à direita) ──
  const staff = capsule(0.08, 2.0, 0x7a4a22);
  staff.position.set(1.06, 1.3, 0.1); staff.rotation.z = -0.05; model.add(staff);
  const holder = new THREE.Mesh(new THREE.TorusGeometry(0.18, 0.05, 10, 18), vinyl(GOLD));
  holder.position.set(1.12, 2.26, 0.1); model.add(holder);
  const orb = new THREE.Mesh(new THREE.IcosahedronGeometry(0.2, 3), glow(ORBC));
  orb.position.set(1.12, 2.36, 0.1); orb.userData.noOutline = true; orb.userData.orb = true; model.add(orb);
  const orbLight = new THREE.PointLight(ORBC, 2.0, 4.2, 2); orbLight.position.copy(orb.position); model.add(orbLight);

  outlineAll(model, 0.05);
  return { model, orb, lights: [orbLight] };
}

function starGeo(outer, inner, points) {
  const s = new THREE.Shape();
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 ? inner : outer;
    const a = (i / (points * 2)) * Math.PI * 2 - Math.PI / 2;
    const x = Math.cos(a) * r, y = Math.sin(a) * r;
    i ? s.lineTo(x, y) : s.moveTo(x, y);
  }
  s.closePath();
  return new THREE.ShapeGeometry(s);
}
