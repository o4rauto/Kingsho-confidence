// hero.js — MAGO HERÓI chibi (centro do menu, estilo vitrine mobile).
// Original. Construído com o toolkit chibi.js (cabeçudo, bevels, toon vinil,
// olhos 2D, contorno marcado, orbe brilhante p/ bloom).
//
// buildHeroMage(opts) → { model: THREE.Group, orb, lights } pronto p/ Rig.

import {
  THREE, vinyl, glow, rbox, ball, blob, cone, capsule, glove,
  eye, blush, outlineAll,
} from './chibi.js';

export function buildHeroMage(opts = {}) {
  const ROBE = opts.robe ?? 0x3a52d6;   // azul-violeta saturado
  const ROBE2 = opts.robe2 ?? 0x2b3aa8;  // sombra do robe
  const SKIN = opts.skin ?? 0xffd9b0;
  const GOLD = 0xffc73a;
  const HATC = opts.hat ?? 0x2c3bb0;
  const ORBC = opts.orb ?? 0x5fe0ff;

  const model = new THREE.Group();
  const HEADR = 0.62;
  const HEADY = 1.78;

  // ── botas (cotocos arredondados sob o robe) ──
  for (const sx of [-1, 1]) {
    const boot = rbox(0.34, 0.26, 0.46, 0x6b4a86, 0.12);
    boot.position.set(sx * 0.26, 0.16, 0.06);
    model.add(boot);
  }

  // ── robe (saia cônica larga = silhueta forte de "triângulo") ──
  const skirt = cone(0.74, 1.15, ROBE, 28);
  skirt.position.y = 0.74;
  model.add(skirt);
  // barra inferior do robe (faixa mais escura)
  const hem = new THREE.Mesh(new THREE.CylinderGeometry(0.75, 0.78, 0.16, 28), vinyl(ROBE2));
  hem.position.y = 0.24; model.add(hem);

  // ── torso curto + cinto dourado (sem pescoço) ──
  const torso = blob(0.5, 0.42, 0.45, ROBE);
  torso.position.y = 1.18; model.add(torso);
  const belt = new THREE.Mesh(new THREE.TorusGeometry(0.4, 0.085, 12, 28), vinyl(GOLD));
  belt.rotation.x = Math.PI / 2; belt.position.y = 1.02; model.add(belt);
  const buckle = ball(0.12, GOLD); buckle.position.set(0, 1.02, 0.42); model.add(buckle);

  // ── capa atrás (placa curva) ──
  const cape = rbox(0.9, 1.2, 0.16, ROBE2, 0.3);
  cape.position.set(0, 1.0, -0.42); cape.rotation.x = 0.12; model.add(cape);

  // ── braços curtos (cápsulas) + mãos-luva ──
  // braço esquerdo (do personagem) repousado
  const armL = capsule(0.16, 0.34, ROBE); armL.position.set(-0.5, 1.12, 0.08);
  armL.rotation.z = 0.5; model.add(armL);
  const handL = glove(0.2, SKIN); handL.position.set(-0.66, 0.86, 0.12); model.add(handL);
  // braço direito segurando o cajado, levantado
  const armR = capsule(0.16, 0.4, ROBE); armR.position.set(0.52, 1.22, 0.12);
  armR.rotation.z = -0.8; model.add(armR);
  const handR = glove(0.2, SKIN); handR.position.set(0.86, 1.62, 0.16); model.add(handR);

  // ── CABEÇA enorme (≈45% da altura) ──
  const head = ball(HEADR, SKIN);
  head.position.y = HEADY; head.scale.set(1.05, 1, 0.98); model.add(head);

  // orelhas pequenas
  for (const sx of [-1, 1]) {
    const ear = ball(0.13, SKIN); ear.position.set(sx * HEADR * 0.96, HEADY - 0.02, -0.02);
    model.add(ear);
  }

  // olhos 2D grandes (na frente da cabeça)
  for (const sx of [-1, 1]) {
    const e = eye(0.2, 0x2b6cff, 'normal');
    e.position.set(sx * 0.24, HEADY + 0.05, HEADR * 0.9);
    e.userData.noOutline = true;
    model.add(e);
  }
  // sobrancelhas (faixas curtas) p/ personalidade confiante
  for (const sx of [-1, 1]) {
    const brow = rbox(0.2, 0.05, 0.05, 0x6b4a2e, 0.02);
    brow.position.set(sx * 0.24, HEADY + 0.28, HEADR * 0.88);
    brow.rotation.z = sx * -0.18; model.add(brow);
  }
  // nariz botãozinho + bochechas rosadas
  const nose = ball(0.07, 0xf6b98a); nose.position.set(0, HEADY - 0.04, HEADR * 0.98); model.add(nose);
  for (const sx of [-1, 1]) {
    const b = blush(0.13); b.position.set(sx * 0.34, HEADY - 0.12, HEADR * 0.86); model.add(b);
  }

  // ── CHAPÉU de mago pontudo (cone alto) com aba + emblema ──
  const brim = new THREE.Mesh(new THREE.CylinderGeometry(0.78, 0.82, 0.1, 28), vinyl(HATC));
  brim.position.y = HEADY + HEADR * 0.62; model.add(brim);
  const hat = cone(0.56, 1.25, HATC, 28);
  hat.position.set(0.04, HEADY + HEADR * 0.62 + 0.66, -0.02);
  hat.rotation.z = -0.12; hat.rotation.x = 0.05;
  // ponta tomba um pouquinho (charme)
  model.add(hat);
  const hatBand = new THREE.Mesh(new THREE.CylinderGeometry(0.58, 0.62, 0.16, 28), vinyl(GOLD));
  hatBand.position.y = HEADY + HEADR * 0.62 + 0.14; model.add(hatBand);
  // estrela-emblema (4 pontas, original) na frente da aba
  const star = new THREE.Mesh(starGeo(0.14, 0.07, 4), glow(0xfff3b0));
  star.position.set(0, HEADY + HEADR * 0.62 + 0.16, 0.6);
  star.userData.noOutline = true; model.add(star);

  // ── CAJADO + ORBE brilhante (alimenta o bloom) ──
  const staff = capsule(0.07, 1.95, 0x8a5a2b);
  staff.position.set(1.04, 1.28, 0.14); staff.rotation.z = -0.05; model.add(staff);
  const holder = new THREE.Mesh(new THREE.TorusGeometry(0.17, 0.05, 10, 18), vinyl(GOLD));
  holder.position.set(1.1, 2.18, 0.14); model.add(holder);
  const orb = new THREE.Mesh(new THREE.IcosahedronGeometry(0.19, 3), glow(ORBC));
  orb.position.set(1.1, 2.26, 0.14); orb.userData.noOutline = true;
  orb.userData.orb = true; model.add(orb);
  const orbLight = new THREE.PointLight(ORBC, 2.2, 4.5, 2);
  orbLight.position.copy(orb.position); model.add(orbLight);

  // contorno marcado em tudo que é "corpo"
  outlineAll(model, 0.05);

  return { model, orb, lights: [orbLight] };
}

// estrela de N pontas (geometria de shape própria)
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
