// hero.js — PYR, a bruxa de fogo (HERÓI). Refeito INSPIRADO SOMENTE na arte
// conceito (lab/concept/pyr-heroi.png): bruxa jovem esguia/heroica, chapéu escuro
// grande e MOLE (pendendo), capa esvoaçante, cabelo ruivo, cajado alto com chama.
// Paleta terrosa/ilustrativa (sem laranja "de brinquedo"), contorno suave.
// Toolkit sculpt.js (mesh detalhada). buildHeroMage(opts) → { model, orb, lights }.

import {
  THREE, mat, emis, plate, polyShape, slab, lathe, sphere, ellip, caps,
  cyl, cone, torus, glowBall, glowMesh, eye,
} from './sculpt.js';

export function buildHeroMage(opts = {}) {
  const ROBE = 0xc1502a, ROBE2 = 0x8a3417, BODICE = 0x9c3d1c;
  const CAPE = 0xab2f1e, CAPEIN = 0xcf5c34;
  const CREAM = 0xe3cfa2, GOLD = 0xcf9a3a, GOLDD = 0xa5781f;
  const SKIN = 0xeec19a, SKIN2 = 0xd79a6e;
  const HAT = 0x2b3340, HAT2 = 0x1d242e;
  const HAIR = 0x7a4220, HAIR2 = 0x53290f;
  const ORB = 0xff9a2a, FLAME = 0xff5e18, EYEC = 0x9c6a2a;

  const model = new THREE.Group();
  const HEADR = 0.52, HEADY = 2.04;

  // ════════ BOTAS (couro, discretas sob o robe) ════════
  for (const sx of [-1, 1]) {
    const toe = ellip(0.2, 0.17, 0.3, 0x5a3a22); toe.position.set(sx * 0.22, 0.14, 0.14); model.add(toe);
    const sole = plate(0.42, 0.1, 0.52, 0x39271a, 0.05); sole.position.set(sx * 0.22, 0.06, 0.1); model.add(sole);
    const cuff = cyl(0.17, 0.2, 0.18, ROBE2); cuff.position.set(sx * 0.22, 0.28, 0.02); model.add(cuff);
  }

  // ════════ ROBE/SAIA esguia e longa (lathe) + bainha + dobras ════════
  const robe = lathe([
    [0.0,0.12],[0.5,0.12],[0.52,0.18],[0.42,0.62],[0.36,1.12],
    [0.39,1.46],[0.34,1.68],[0.24,1.78],[0.0,1.8],
  ], ROBE, 44);
  model.add(robe);
  const hem = torus(0.5, 0.07, ROBE2, 40); hem.rotation.x = Math.PI/2; hem.position.y = 0.14; hem.scale.set(1,1,0.7); model.add(hem);
  for (let i = 0; i < 9; i++) {
    const a = (i/9) * Math.PI * 2;
    const fold = caps(0.04, 0.62, ROBE2); fold.position.set(Math.cos(a)*0.42, 0.55, Math.sin(a)*0.42);
    fold.scale.set(1,1,0.5); fold.lookAt(Math.cos(a)*2, 0.55, Math.sin(a)*2); fold.rotation.x += Math.PI/2; model.add(fold);
  }
  // avental/painel claro central + cordões
  const apron = plate(0.34, 0.9, 0.06, CREAM, 0.1); apron.position.set(0, 0.6, 0.4); apron.rotation.x = 0.08; model.add(apron);

  // ════════ CINTO + bolsa lateral ════════
  const belt = torus(0.42, 0.08, 0x4a2c18, 32); belt.rotation.x = Math.PI/2; belt.position.y = 1.06; belt.scale.set(1,1,0.85); model.add(belt);
  const buckle = slab(roundRect(0.16, 0.14, 0.04), 0.06, GOLD, 0.02); buckle.position.set(0, 1.06, 0.46); model.add(buckle);
  const pouch = ellip(0.13, 0.15, 0.1, 0x6e4423); pouch.position.set(0.34, 0.98, 0.28); model.add(pouch);

  // ════════ BODICE (torso) + ombros ════════
  const bodice = ellip(0.36, 0.42, 0.3, BODICE); bodice.position.set(0, 1.5, 0.02); model.add(bodice);
  const collar = lathe([[0.22,0],[0.34,0.14],[0.26,0.18]], ROBE2, 26); collar.position.y = 1.74; model.add(collar);
  for (const sx of [-1, 1]) { const pad = ellip(0.2, 0.18, 0.22, ROBE); pad.position.set(sx * 0.36, 1.64, 0.02); model.add(pad); }

  // ════════ CAPA esvoaçante (assimétrica, jogada p/ um lado) ════════
  const capeShape = (() => {
    const s = new THREE.Shape();
    s.moveTo(-0.55, 0.85); s.lineTo(0.5, 0.8);
    s.bezierCurveTo(0.75, 0.1, 0.45, -0.7, 0.7, -1.15);
    s.lineTo(0.2, -1.0); s.quadraticCurveTo(0.0, -0.7, -0.25, -0.95);
    s.lineTo(-0.6, -0.6); s.closePath(); return s;
  })();
  const cape = slab(capeShape, 0.08, CAPE, 0.03); cape.position.set(0.1, 1.2, -0.4); cape.rotation.set(0.12, 0.1, -0.08); model.add(cape);
  const capeIn = slab(capeShape, 0.03, CAPEIN, 0.02); capeIn.scale.set(0.82,0.86,1); capeIn.position.set(0.08, 1.22, -0.33); capeIn.rotation.set(0.12, 0.1, -0.08); model.add(capeIn);
  const clasp = glowBall(0.06, ORB); clasp.position.set(-0.34, 1.76, 0.06); model.add(clasp);

  // ════════ BRAÇOS (esq. baixo; dir. erguido no cajado) ════════
  function arm(sx, raised) {
    const g = new THREE.Group();
    const sleeve = caps(0.14, raised ? 0.4 : 0.36, ROBE);
    const cuff = torus(0.15, 0.045, GOLD, 16);
    const hand = sphere(0.16, SKIN, 20);
    if (raised) {
      sleeve.position.set(0.5, 1.42, 0.08); sleeve.rotation.z = -0.78;
      cuff.position.set(0.72, 1.64, 0.1); cuff.rotation.set(Math.PI/2, 0, -0.78);
      hand.position.set(0.78, 1.72, 0.12);
    } else {
      sleeve.position.set(-0.48, 1.34, 0.06); sleeve.rotation.z = 0.4;
      cuff.position.set(-0.62, 1.12, 0.12); cuff.rotation.set(Math.PI/2, 0, 0.4);
      hand.position.set(-0.66, 1.04, 0.14);
    }
    g.add(sleeve, cuff, hand);
    for (const k of [-1, 0, 1]) {
      const f = caps(0.04, 0.09, SKIN2);
      f.position.copy(hand.position).add(new THREE.Vector3(k * 0.06, raised ? 0.12 : -0.12, 0.05));
      g.add(f);
    }
    return g;
  }
  model.add(arm(-1, false), arm(1, true));

  // ════════ CABEÇA + rosto jovem determinado ════════
  const head = sphere(HEADR, SKIN, 32); head.scale.set(1.0, 1.02, 0.96); head.position.y = HEADY; model.add(head);
  for (const sx of [-1, 1]) { const ear = sphere(0.09, SKIN, 16); ear.position.set(sx * HEADR * 0.96, HEADY - 0.04, -0.02); model.add(ear); }
  for (const sx of [-1, 1]) {
    const e = eye(0.18, EYEC); e.position.set(sx * 0.22, HEADY + 0.0, HEADR * 0.94); model.add(e);
    const lash = slab(arc(0.22, 0.05), 0.025, 0x3a241a, 0.01); lash.position.set(sx * 0.22, HEADY + 0.16, HEADR * 0.92); lash.userData.noOutline = true; model.add(lash);
    const brow = slab(arc(0.2, 0.045), 0.03, HAIR2, 0.01); brow.position.set(sx * 0.22, HEADY + 0.26, HEADR * 0.88); brow.rotation.z = sx * 0.14; model.add(brow);
  }
  const nose = ellip(0.05, 0.05, 0.07, SKIN2); nose.position.set(0, HEADY - 0.12, HEADR * 0.98); model.add(nose);
  const mouth = glowMesh(new THREE.TorusGeometry(0.08, 0.022, 8, 16, Math.PI), 0x8a3318);
  mouth.position.set(0.02, HEADY - 0.26, HEADR * 0.92); mouth.rotation.z = Math.PI - 0.2; model.add(mouth);
  // sardas
  for (const p of [[-0.3,-0.06],[-0.24,-0.12],[0.3,-0.06],[0.24,-0.12]]) {
    const fr = glowMesh(new THREE.CircleGeometry(0.018, 8), 0xc98a64); fr.position.set(p[0], HEADY + p[1], HEADR * 0.93); model.add(fr);
  }

  // CABELO ruivo: massa traseira + mechas que emolduram + franja
  const backHair = sphere(HEADR * 1.04, HAIR, 24); backHair.scale.set(1.04, 1.0, 0.9); backHair.position.set(0, HEADY + 0.02, -0.1); model.add(backHair);
  for (const sx of [-1, 1]) {
    const side = caps(0.15, 0.5, HAIR); side.position.set(sx * 0.5, HEADY - 0.22, 0.04); side.rotation.z = sx * 0.12; model.add(side);
    const sideTip = cone(0.13, 0.32, HAIR2, 12); sideTip.position.set(sx * 0.54, HEADY - 0.56, 0.02); sideTip.rotation.z = Math.PI; model.add(sideTip);
  }
  for (const k of [-2, -1, 0, 1, 2]) {
    const bang = cone(0.13, 0.3, HAIR, 12); bang.position.set(k * 0.18, HEADY + 0.3, HEADR * 0.6);
    bang.rotation.set(0.6, 0, Math.PI + k * 0.06); model.add(bang);
  }

  // ════════ CHAPÉU escuro GRANDE e MOLE (aba ampla + cone que pende em cadeia) ════════
  const brim = lathe([[0.0,0.0],[0.55,-0.02],[0.95,0.04],[1.0,0.1],[0.95,0.12],[0.5,0.06],[0.0,0.05]], HAT, 40);
  brim.position.y = HEADY + HEADR * 0.58; model.add(brim);
  // cone base + segmentos que dobram progressivamente (chapéu pendendo)
  const baseCone = cone(0.55, 0.7, HAT, 28); baseCone.position.set(0.02, HEADY + HEADR * 0.58 + 0.4, -0.02); baseCone.rotation.z = -0.18; model.add(baseCone);
  let px = -0.1, py = HEADY + HEADR * 0.58 + 0.78, pz = 0.02, ang = -0.5, r = 0.34;
  for (let i = 0; i < 4; i++) {
    const seg = cone(r, 0.34, HAT, 20); seg.position.set(px, py, pz); seg.rotation.z = ang; model.add(seg);
    ang -= 0.5; r *= 0.78; px += Math.cos(ang) * 0.22; py += 0.16; pz += 0.04;
  }
  const tip = glowBall(0.08, FLAME); tip.position.set(px + 0.1, py - 0.04, pz); model.add(tip);
  const band = lathe([[0.55,0],[0.64,0.05],[0.62,0.14],[0.53,0.16]], 0x4a2c18, 28); band.position.y = HEADY + HEADR * 0.58 + 0.05; model.add(band);
  const bandStar = glowBall(0.07, ORB); bandStar.position.set(0, HEADY + HEADR * 0.58 + 0.1, 0.54); model.add(bandStar);

  // ════════ CAJADO alto + ORBE DE FOGO (garra de galho segurando a chama) ════════
  const staff = cyl(0.05, 0.06, 2.3, 0x6b4220); staff.position.set(0.92, 1.4, 0.12); staff.rotation.z = -0.04; model.add(staff);
  for (let i = 0; i < 4; i++) { const k = cyl(0.06, 0.05, 0.06, GOLDD); k.position.set(0.92 + i*0.01, 0.6 + i*0.5, 0.12); model.add(k); }
  // garra de 3 dedos de galho segurando o orbe
  for (const a of [-0.5, 0, 0.5]) {
    const finger = lathe([[0.0,0],[0.06,0.06],[0.05,0.26],[0.0,0.32]], 0x4a2c14, 8);
    finger.position.set(0.92 + Math.sin(a)*0.12, 2.42, 0.12 + Math.cos(a)*0.02); finger.rotation.z = a*0.7; model.add(finger);
  }
  const orb = new THREE.Mesh(new THREE.IcosahedronGeometry(0.2, 2), emis(ORB));
  orb.position.set(0.92, 2.6, 0.12); orb.userData.noOutline = true; orb.userData.orb = true; model.add(orb);
  for (let i = 0; i < 6; i++) {
    const a = (i/6) * Math.PI * 2; const fl = cone(0.08, 0.32, i%2?ORB:FLAME, 8);
    fl.material = emis(i%2?ORB:FLAME); fl.userData.noOutline = true;
    fl.position.set(0.92 + Math.cos(a)*0.15, 2.74 + Math.sin(a)*0.05, 0.12 + Math.sin(a)*0.1); model.add(fl);
  }
  const orbLight = new THREE.PointLight(FLAME, 2.6, 5, 2); orbLight.position.set(0.92, 2.64, 0.12); model.add(orbLight);

  return { model, orb, lights: [orbLight] };
}

// retângulo arredondado simples
function roundRect(w, h, r) {
  const s = new THREE.Shape(); const x = -w/2, y = -h/2;
  s.moveTo(x + r, y); s.lineTo(x + w - r, y); s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, y + h - r); s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h); s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, y + r); s.quadraticCurveTo(x, y, x + r, y); return s;
}
// arco fino (cílio/sobrancelha)
function arc(w, h) {
  const s = new THREE.Shape();
  s.moveTo(-w/2, 0); s.quadraticCurveTo(0, h*1.6, w/2, 0); s.quadraticCurveTo(0, h*0.4, -w/2, 0);
  s.closePath(); return s;
}
