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

// ════════════════════════════ GRUNT (goblin magrelo/esquálido) ════════════════════════════
export function buildGrunt(opts = {}) {
  const SKIN = opts.skin ?? 0x74b03e;   // verde saturado
  const SKIN2 = opts.skin2 ?? 0x4f7d27;  // sombra/verde escuro
  const BELLY = opts.belly ?? 0xbfdc84;  // barriga/peito claro
  const CLOTH = opts.cloth ?? 0x7a4a22;  // tanga
  const STEEL = 0xb8c2cc;

  const model = new THREE.Group();
  const HEADR = 0.5;
  const HEADY = 1.82;   // cabeça grande no alto de um corpo magro e alongado

  // ── pernas finas, longas e tortas (com joelho) ──
  for (const sx of [-1, 1]) {
    const shin = capsule(0.08, 0.4, SKIN); shin.position.set(sx * 0.2, 0.34, 0.04);
    shin.rotation.z = sx * 0.1; model.add(shin);
    const thigh = capsule(0.095, 0.3, SKIN); thigh.position.set(sx * 0.17, 0.78, 0.02);
    thigh.rotation.z = sx * -0.16; model.add(thigh);
    const knee = ball(0.095, SKIN2); knee.position.set(sx * 0.2, 0.58, 0.05); model.add(knee);
    // pé comprido com garras
    const foot = blob(0.15, 0.1, 0.26, SKIN2); foot.position.set(sx * 0.2, 0.09, 0.12); model.add(foot);
    for (const k of [-1, 0, 1]) {
      const toe = new THREE.Mesh(new THREE.ConeGeometry(0.04, 0.11, 4),
        new THREE.MeshBasicMaterial({ color: 0xe9e4d0, toneMapped: false }));
      toe.position.set(sx * 0.2 + k * 0.08, 0.08, 0.32); toe.rotation.x = Math.PI / 2;
      toe.userData.noOutline = true; model.add(toe);
    }
  }

  // ── tanga puída baixa no quadril (deixa o abdômen magro à mostra) ──
  const cloth = new THREE.Mesh(new THREE.CylinderGeometry(0.24, 0.3, 0.26, 16), vinyl(CLOTH));
  cloth.position.y = 0.98; model.add(cloth);
  for (const sx of [-1, 0, 1]) {
    const rag = rbox(0.11, 0.3, 0.08, CLOTH, 0.03); rag.position.set(sx * 0.16, 0.86, 0.24); model.add(rag);
  }

  // ── TRONCO: coluna FINA e ALTA (cintura magrela visível) ──
  const torso = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.26, 0.66, 18), vinyl(SKIN));
  torso.position.set(0, 1.4, 0.05); model.add(torso);
  const torsoTop = blob(0.25, 0.2, 0.23, SKIN); torsoTop.position.set(0, 1.66, 0.05); model.add(torsoTop);
  // peito/abdômen claro alto e fino
  const chest = new THREE.Mesh(new THREE.CircleGeometry(0.16, 18),
    new THREE.MeshBasicMaterial({ color: BELLY, toneMapped: false }));
  chest.scale.set(1, 2.4, 1); chest.position.set(0, 1.4, 0.28); chest.userData.noOutline = true; model.add(chest);
  // costelinhas (linhas escuras)
  for (const i of [0, 1, 2, 3]) {
    const rib = rbox(0.24, 0.022, 0.04, SKIN2, 0.01); rib.position.set(0, 1.2 + i * 0.13, 0.28); model.add(rib);
  }
  // ombros ossudos pontudos
  for (const sx of [-1, 1]) { const sh = ball(0.13, SKIN); sh.position.set(sx * 0.27, 1.66, 0.04); model.add(sh); }

  // ── braços longos e finos ──
  // esquerdo pendendo (quase até o joelho)
  const armL = capsule(0.07, 0.66, SKIN); armL.position.set(-0.34, 1.2, 0.05);
  armL.rotation.z = 0.2; model.add(armL);
  const handL = glove(0.12, SKIN2); handL.position.set(-0.42, 0.78, 0.08); model.add(handL);
  // direito erguido empunhando uma adaga enferrujada
  const armR = capsule(0.07, 0.54, SKIN); armR.position.set(0.36, 1.42, 0.08);
  armR.rotation.z = -0.85; model.add(armR);
  const handR = glove(0.12, SKIN2); handR.position.set(0.62, 1.66, 0.12); model.add(handR);
  // adaga (cabo + lâmina serrilhada)
  const grip = capsule(0.05, 0.18, 0x3a2a1c); grip.position.set(0.66, 1.64, 0.12); grip.rotation.z = -0.2; model.add(grip);
  const guard = rbox(0.22, 0.05, 0.08, 0x6b5224, 0.02); guard.position.set(0.69, 1.76, 0.12); model.add(guard);
  const blade = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.5, 4), vinyl(STEEL));
  blade.position.set(0.73, 2.06, 0.12); blade.rotation.z = -0.12; model.add(blade);

  // ── CABEÇA grande (chibi) levemente projetada pra frente ──
  const head = ball(HEADR, SKIN); head.position.set(0, HEADY, 0.08); head.scale.set(1.04, 0.96, 0.98); model.add(head);

  // orelhas pontudas enormes (silhueta!)
  for (const sx of [-1, 1]) {
    const ear = cone(0.18, 0.62, SKIN, 14); ear.position.set(sx * 0.6, HEADY + 0.14, -0.02);
    ear.rotation.z = sx * -1.2; ear.rotation.y = sx * 0.3; model.add(ear);
    const earIn = cone(0.09, 0.42, SKIN2, 12); earIn.position.set(sx * 0.55, HEADY + 0.14, 0.04);
    earIn.rotation.z = sx * -1.2; earIn.rotation.y = sx * 0.3; earIn.userData.noOutline = true; model.add(earIn);
  }

  // sobrancelha raivosa (bloco escuro angulado pra dentro)
  for (const sx of [-1, 1]) {
    const brow = rbox(0.28, 0.11, 0.08, SKIN2, 0.04);
    brow.position.set(sx * 0.22, HEADY + 0.2, HEADR * 0.9 + 0.08); brow.rotation.z = sx * -0.5; model.add(brow);
  }
  // olhos arregalados amarelos (a fúria vem das sobrancelhas)
  for (const sx of [-1, 1]) {
    const e = eye(0.17, 0xffd23a, 'normal');
    e.position.set(sx * 0.23, HEADY + 0.07, HEADR * 0.92 + 0.08); e.userData.noOutline = true; model.add(e);
  }
  // nariz comprido e adunco
  const nose = blob(0.1, 0.1, 0.2, SKIN2); nose.position.set(0, HEADY - 0.08, HEADR * 0.95 + 0.12); model.add(nose);
  // boca com presas (sorriso torto)
  const mouth = fangMouth(0.3); mouth.position.set(0, HEADY - 0.32, HEADR * 0.84 + 0.08);
  mouth.rotation.z = 0.08; model.add(mouth);

  outlineAll(model, 0.045);
  return { model, lights: [] };
}

// fita esvoaçante (cachecol/cauda): cadeia de blocos achatados afunilando
function ribbon(start, color, segs = 4, len = 0.34, w = 0.26, curve = 0.5) {
  const g = new THREE.Group();
  let p = start.clone(), ang = curve;
  for (let i = 0; i < segs; i++) {
    const ww = w * (1 - i / (segs + 1));
    const seg = rbox(ww, 0.06, len, color, 0.03);
    ang += curve * (i % 2 ? -1 : 1) * 0.5 - 0.25; // ondinha
    seg.rotation.x = ang;
    seg.position.copy(p);
    g.add(seg);
    p.add(new THREE.Vector3(0, Math.sin(ang) * len * 0.9, -Math.cos(ang) * len * 0.9));
  }
  return g;
}

// ════════════════════════════ RUNNER (batedor veloz, digitígrado) ════════════════════════════
export function buildRunner(opts = {}) {
  const SKIN = opts.skin ?? 0xd07a38;   // terracota
  const SKIN2 = opts.skin2 ?? 0x9c531f;  // sombra
  const BELLY = opts.belly ?? 0xf0c98c;
  const SCARF = opts.scarf ?? 0xe23b3b;  // cachecol vermelho (velocidade)

  const FOOT = 0x3a2c22;
  const model = new THREE.Group();
  const HEADR = 0.52;
  const HEADY = 1.72;

  // ── pernas esguias e longas + pés esportivos grandes ──
  for (const sx of [-1, 1]) {
    const thigh = capsule(0.12, 0.32, SKIN); thigh.position.set(sx * 0.21, 0.92, 0.02); model.add(thigh);
    const shin = capsule(0.1, 0.34, SKIN); shin.position.set(sx * 0.21, 0.5, 0.0); model.add(shin);
    // tênis/pé grande (velocidade)
    const foot = rbox(0.26, 0.18, 0.5, FOOT, 0.08); foot.position.set(sx * 0.21, 0.13, 0.14); model.add(foot);
    const sole = rbox(0.28, 0.07, 0.52, 0xe8e2d2, 0.03); sole.position.set(sx * 0.21, 0.05, 0.14); model.add(sole);
  }

  // ── corpo magro ──
  const body = blob(0.32, 0.5, 0.3, SKIN); body.position.set(0, 1.24, 0); model.add(body);
  const belly = new THREE.Mesh(new THREE.CircleGeometry(0.17, 18),
    new THREE.MeshBasicMaterial({ color: BELLY, toneMapped: false }));
  belly.scale.set(1, 1.9, 1); belly.position.set(0, 1.18, 0.29); belly.userData.noOutline = true; model.add(belly);

  // ── braços finos levemente pra trás ──
  for (const sx of [-1, 1]) {
    const arm = capsule(0.075, 0.46, SKIN); arm.position.set(sx * 0.33, 1.22, -0.08); arm.rotation.x = -0.45; arm.rotation.z = sx * -0.2; model.add(arm);
    const hand = glove(0.12, SKIN2); hand.position.set(sx * 0.4, 0.96, -0.28); model.add(hand);
  }

  // ── CABEÇA ereta e redonda (rosto bem legível) ──
  const head = ball(HEADR, SKIN); head.position.set(0, HEADY, 0); head.scale.set(1.02, 1, 1); model.add(head);

  // orelhas altas levemente pra trás (silhueta), mas visíveis
  for (const sx of [-1, 1]) {
    const ear = cone(0.15, 0.66, SKIN, 12); ear.position.set(sx * 0.34, HEADY + 0.5, -0.08);
    ear.rotation.z = sx * -0.5; ear.rotation.x = -0.35; model.add(ear);
    const earIn = cone(0.07, 0.44, SCARF, 10); earIn.position.set(sx * 0.32, HEADY + 0.48, -0.02);
    earIn.rotation.z = sx * -0.5; earIn.rotation.x = -0.35; earIn.userData.noOutline = true; model.add(earIn);
  }

  // olhos GRANDES e ansiosos (a bandana já emoldura o rosto; sem sobrancelha flutuante)
  for (const sx of [-1, 1]) {
    const e = eye(0.2, 0xff9a2a, 'normal'); e.position.set(sx * 0.23, HEADY + 0.02, HEADR * 0.94); e.userData.noOutline = true; model.add(e);
  }
  // focinho/nariz pequeno + grande sorriso
  const nose = blob(0.09, 0.07, 0.1, 0x2a1c14); nose.position.set(0, HEADY - 0.14, HEADR * 1.0); nose.userData.noOutline = true; model.add(nose);
  const grin = fangMouth(0.22); grin.position.set(0, HEADY - 0.32, HEADR * 0.86); model.add(grin);

  // ── BANDANA na testa com duas pontas esvoaçando pra trás (= velocidade) ──
  const band = new THREE.Mesh(new THREE.CylinderGeometry(HEADR * 1.02, HEADR * 1.02, 0.16, 24, 1, true), vinyl(SCARF));
  band.position.set(0, HEADY + 0.16, 0); band.userData.noOutline = true; model.add(band);
  model.add(ribbon(new THREE.Vector3(-0.36, HEADY + 0.18, -0.2), SCARF, 4, 0.32, 0.18, 0.45));
  model.add(ribbon(new THREE.Vector3(-0.42, HEADY + 0.08, -0.18), SCARF, 3, 0.3, 0.14, 0.6));

  // ── cauda fina esvoaçando ──
  model.add(ribbon(new THREE.Vector3(0, 1.02, -0.26), SKIN, 4, 0.3, 0.2, 0.4));

  outlineAll(model, 0.045);
  return { model, lights: [] };
}
