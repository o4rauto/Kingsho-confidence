// hero.js — PYR, a bruxa de fogo (HERÓI). REFEITO no toolkit de alta densidade
// (sculpt.js): formas chanfradas/lathe, sombreado toon macio, muito detalhe de
// superfície — alvo estilo Clash Royale. Base: lab/concept/pyr-heroi.png.
// Contorno = silhueta única (OutlinePass no viewer).
//
// buildHeroMage(opts) → { model, orb, lights } (nome mantido p/ os imports).

import {
  THREE, mat, emis, plate, polyShape, slab, lathe, sphere, ellip, caps,
  cyl, cone, torus, glowBall, glowMesh, eye,
} from './sculpt.js';

export function buildHeroMage(opts = {}) {
  const ROBE = 0xe04a26, ROBE2 = 0x9c2c18, CREAM = 0xffe7c4, GOLD = 0xffc23a, GOLDD = 0xcf8f1c;
  const SKIN = 0xf6c79a, SKIN2 = 0xe2a374;
  const HATC = 0x3a2f4e, HATC2 = 0x2a2238;
  const HAIR = 0x9c5226, HAIR2 = 0x6f3717;
  const ORB = 0xffb02e, FLAME = 0xff6a1e, EYEC = 0x2fc6d6;

  const model = new THREE.Group();
  const HEADR = 0.6, HEADY = 1.96;

  // ════════ BOTAS chunky (biqueira arredondada + cano + sola) ════════
  for (const sx of [-1, 1]) {
    const toe = ellip(0.24, 0.2, 0.34, 0x6b3f22); toe.position.set(sx * 0.27, 0.16, 0.16); model.add(toe);
    const sole = plate(0.5, 0.12, 0.6, 0x3a2418, 0.06); sole.position.set(sx * 0.27, 0.06, 0.12); model.add(sole);
    const cuff = cyl(0.22, 0.26, 0.2, ROBE2); cuff.position.set(sx * 0.27, 0.3, 0.02); model.add(cuff);
    const fold = torus(0.2, 0.04, GOLD, 18); fold.rotation.x = Math.PI/2; fold.position.set(sx * 0.27, 0.38, 0.02); model.add(fold);
  }

  // ════════ ROBE em sino (lathe suave) + bainha + dobras ════════
  const robe = lathe([
    [0.0,0.16],[0.62,0.16],[0.64,0.22],[0.54,0.55],[0.46,0.95],
    [0.49,1.26],[0.43,1.48],[0.3,1.54],[0.0,1.56],
  ], ROBE, 44);
  robe.position.y = 0; model.add(robe);
  const hem = torus(0.62, 0.08, ROBE2, 40); hem.rotation.x = Math.PI/2; hem.position.y = 0.18; hem.scale.set(1,1,0.6); model.add(hem);
  // dobras verticais (relevo de pano) ao redor do sino
  for (let i = 0; i < 10; i++) {
    const a = (i/10) * Math.PI * 2;
    const fold = caps(0.045, 0.7, ROBE2); fold.position.set(Math.cos(a)*0.5, 0.55, Math.sin(a)*0.5);
    fold.scale.set(1,1,0.5); fold.lookAt(Math.cos(a)*2, 0.55, Math.sin(a)*2); fold.rotation.x += Math.PI/2; model.add(fold);
  }

  // estola central clara + trims dourados (vai do peito à bainha)
  const stole = plate(0.3, 1.3, 0.1, CREAM, 0.06); stole.position.set(0, 0.86, 0.52); stole.rotation.x = 0.04; model.add(stole);
  for (const sx of [-1, 1]) {
    const trim = plate(0.05, 1.3, 0.08, GOLD, 0.02); trim.position.set(sx * 0.16, 0.86, 0.55); model.add(trim);
  }
  // botões/gemas na estola
  for (const yy of [1.3, 1.06, 0.82]) {
    const b = glowBall(0.05, FLAME); b.position.set(0, yy, 0.6); model.add(b);
  }

  // ════════ CINTO + fivela losango com brasa ════════
  const belt = torus(0.5, 0.1, 0x53321e, 32); belt.rotation.x = Math.PI/2; belt.position.y = 0.92; belt.scale.set(1,1,0.85); model.add(belt);
  const buckle = slab(polyShape([[0,0.16],[0.14,0],[0,-0.16],[-0.14,0]]), 0.08, GOLD, 0.02);
  buckle.position.set(0, 0.92, 0.56); model.add(buckle);
  const bgem = glowBall(0.07, FLAME); bgem.position.set(0, 0.92, 0.62); model.add(bgem);

  // ════════ TRONCO/ombros + gola ════════
  const chest = ellip(0.44, 0.4, 0.36, ROBE); chest.position.set(0, 1.4, 0.02); model.add(chest);
  for (const sx of [-1, 1]) {
    const pad = ellip(0.28, 0.24, 0.3, ROBE2); pad.position.set(sx * 0.46, 1.52, 0.02); model.add(pad);
    const pt = torus(0.16, 0.04, GOLD, 16); pt.rotation.x = Math.PI/2; pt.position.set(sx * 0.46, 1.62, 0.04); model.add(pt);
  }
  const collar = lathe([[0.26,0],[0.4,0.16],[0.3,0.2]], ROBE2, 28); collar.position.y = 1.64; model.add(collar);

  // ════════ CAPA atrás (placa chanfrada com barra recortada) ════════
  const capeShape = (() => {
    const s = new THREE.Shape();
    s.moveTo(-0.5, 0.8); s.lineTo(0.5, 0.8);
    s.lineTo(0.42, -0.7); s.quadraticCurveTo(0.25, -0.8, 0.15, -0.6);
    s.quadraticCurveTo(0, -0.78, -0.15, -0.6); s.quadraticCurveTo(-0.25, -0.8, -0.42, -0.7);
    s.closePath(); return s;
  })();
  const cape = slab(capeShape, 0.1, ROBE2, 0.04); cape.position.set(0, 1.1, -0.42); cape.rotation.x = 0.14; model.add(cape);
  const capeIn = slab(capeShape, 0.04, 0xc2381f, 0.02); capeIn.scale.set(0.8,0.86,1); capeIn.position.set(0, 1.12, -0.34); capeIn.rotation.x = 0.14; model.add(capeIn);

  // ════════ BRAÇOS (manga + luva com dedos) ════════
  function arm(sx, raised) {
    const g = new THREE.Group();
    const sleeve = caps(0.16, raised ? 0.42 : 0.36, ROBE);
    const cuff = torus(0.17, 0.05, GOLD, 18);
    const hand = sphere(0.18, SKIN, 20);
    if (raised) {
      sleeve.position.set(0.56, 1.34, 0.08); sleeve.rotation.z = -0.7;
      cuff.position.set(0.78, 1.56, 0.1); cuff.rotation.z = -0.7; cuff.rotation.x = Math.PI/2;
      hand.position.set(0.84, 1.62, 0.12);
    } else {
      sleeve.position.set(-0.54, 1.26, 0.06); sleeve.rotation.z = 0.34;
      cuff.position.set(-0.66, 1.04, 0.12); cuff.rotation.z = 0.34; cuff.rotation.x = Math.PI/2;
      hand.position.set(-0.7, 0.96, 0.14);
    }
    g.add(sleeve, cuff, hand);
    // dedos (3 capsulinhas)
    for (const k of [-1, 0, 1]) {
      const f = caps(0.045, 0.1, SKIN2);
      f.position.copy(hand.position).add(new THREE.Vector3(k * 0.07, raised ? 0.14 : -0.14, 0.06));
      g.add(f);
    }
    return g;
  }
  model.add(arm(-1, false), arm(1, true));

  // ════════ CABEÇA + rosto detalhado ════════
  const head = sphere(HEADR, SKIN, 32); head.scale.set(1.02, 1, 0.98); head.position.y = HEADY; model.add(head);
  for (const sx of [-1, 1]) { const ear = sphere(0.1, SKIN, 16); ear.position.set(sx * HEADR * 0.96, HEADY - 0.04, -0.02); model.add(ear); }

  // olhos grandes + cílios + sobrancelhas
  for (const sx of [-1, 1]) {
    const e = eye(0.2, EYEC); e.position.set(sx * 0.24, HEADY + 0.02, HEADR * 0.93); model.add(e);
    const lash = slab(roundRectArc(0.24, 0.05), 0.03, 0x3a241a, 0.01); lash.position.set(sx * 0.24, HEADY + 0.2, HEADR * 0.92); lash.userData.noOutline = true; model.add(lash);
    const brow = slab(roundRectArc(0.22, 0.05), 0.04, HAIR, 0.01); brow.position.set(sx * 0.24, HEADY + 0.3, HEADR * 0.88); brow.rotation.z = sx * -0.1; model.add(brow);
  }
  const nose = ellip(0.06, 0.06, 0.08, SKIN2); nose.position.set(0, HEADY - 0.12, HEADR * 0.98); model.add(nose);
  const smile = glowMesh(new THREE.TorusGeometry(0.11, 0.025, 8, 18, Math.PI), 0x9c3318);
  smile.position.set(0, HEADY - 0.26, HEADR * 0.92); smile.rotation.z = Math.PI; model.add(smile);
  for (const sx of [-1, 1]) { const bl = glowMesh(new THREE.CircleGeometry(0.1, 16), 0xff9a86); bl.position.set(sx * 0.36, HEADY - 0.12, HEADR * 0.85); bl.material.transparent = true; bl.material.opacity = 0.5; model.add(bl); }

  // CABELO: franja em mechas + duas tranças laterais
  for (const k of [-2, -1, 0, 1, 2]) {
    const lock = cone(0.14, 0.34, HAIR, 14); lock.position.set(k * 0.2, HEADY + 0.34, HEADR * 0.62);
    lock.rotation.x = 0.5; lock.rotation.z = Math.PI + k * 0.05; model.add(lock);
  }
  for (const sx of [-1, 1]) {
    const l1 = caps(0.13, 0.4, HAIR); l1.position.set(sx * 0.52, HEADY - 0.18, HEADR * 0.3); model.add(l1);
    const l2 = cone(0.12, 0.34, HAIR2, 12); l2.position.set(sx * 0.54, HEADY - 0.5, HEADR * 0.26); l2.rotation.z = Math.PI; model.add(l2);
  }

  // ════════ CHAPÉU pontudo dobrado (aba + cones + ponta + banda) ════════
  const brim = torus(0.82, 0.16, HATC, 36); brim.rotation.x = Math.PI/2; brim.scale.set(1, 0.5, 1); brim.position.y = HEADY + HEADR * 0.6; model.add(brim);
  const brimTop = lathe([[0,0.0],[0.5,0.02],[0.82,0.06],[0.82,0.0]], HATC2, 36); brimTop.position.y = HEADY + HEADR * 0.6; model.add(brimTop);
  const coneLo = cone(0.6, 0.9, HATC, 28); coneLo.position.set(0.04, HEADY + HEADR * 0.6 + 0.5, -0.02); coneLo.rotation.z = -0.12; model.add(coneLo);
  const coneHi = cone(0.34, 0.75, HATC, 24); coneHi.position.set(-0.18, HEADY + HEADR * 0.6 + 1.04, -0.06); coneHi.rotation.z = -0.66; model.add(coneHi);
  const tip = glowBall(0.12, FLAME); tip.position.set(-0.54, HEADY + HEADR * 0.6 + 1.22, -0.08); model.add(tip);
  const band = lathe([[0.6,0],[0.7,0.06],[0.68,0.16],[0.58,0.18]], GOLD, 30); band.position.y = HEADY + HEADR * 0.6 + 0.06; model.add(band);
  const bandGem = glowBall(0.1, ORB); bandGem.position.set(0, HEADY + HEADR * 0.6 + 0.12, 0.58); model.add(bandGem);

  // ════════ CAJADO + ORBE DE FOGO ════════
  const staff = cyl(0.06, 0.07, 2.0, 0x6e4322); staff.position.set(0.98, 1.3, 0.12); staff.rotation.z = -0.05; model.add(staff);
  for (const yy of [0.7, 1.3, 1.9]) { const ring = torus(0.08, 0.02, GOLDD, 16); ring.rotation.x = Math.PI/2; ring.position.set(0.98 + (1.3-yy)*0.05, yy, 0.12); model.add(ring); }
  const claw = lathe([[0.0,0],[0.16,0.04],[0.2,0.16],[0.12,0.28],[0.0,0.3]], 0x4a2c14, 8);
  claw.position.set(1.0, 2.12, 0.12); model.add(claw);
  const orb = new THREE.Mesh(new THREE.IcosahedronGeometry(0.22, 2), emis(ORB));
  orb.position.set(1.0, 2.36, 0.12); orb.userData.noOutline = true; orb.userData.orb = true; model.add(orb);
  for (let i = 0; i < 5; i++) {
    const a = (i/5) * Math.PI * 2; const fl = cone(0.09, 0.34, i%2?ORB:FLAME, 8);
    fl.material = emis(i%2?ORB:FLAME); fl.userData.noOutline = true;
    fl.position.set(1.0 + Math.cos(a)*0.16, 2.5 + Math.sin(a)*0.06, 0.12 + Math.sin(a)*0.1); model.add(fl);
  }
  const orbLight = new THREE.PointLight(FLAME, 2.6, 5, 2); orbLight.position.set(1.0, 2.4, 0.12); model.add(orbLight);

  return { model, orb, lights: [orbLight] };
}

// arco achatado p/ cílio/sobrancelha (retângulo arredondado bem fino)
function roundRectArc(w, h) {
  const s = new THREE.Shape();
  s.moveTo(-w/2, 0); s.quadraticCurveTo(0, h*1.6, w/2, 0); s.quadraticCurveTo(0, h*0.4, -w/2, 0);
  s.closePath(); return s;
}
