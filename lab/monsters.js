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

// ════════════════════════════ SHIELD (orc blindado, tanque) ════════════════════════════
export function buildShield(opts = {}) {
  const SKIN = opts.skin ?? 0x88a256;   // pele orc verde-acinzentada
  const SKIN2 = opts.skin2 ?? 0x5f7438;
  const IRON = opts.iron ?? 0x828ea1;   // ferro
  const IRON2 = opts.iron2 ?? 0x515a69;  // ferro escuro
  const BRONZE = 0xcf9438;
  const EMBLEM = opts.emblem ?? 0xd13b3b;

  const model = new THREE.Group();
  const HEADR = 0.42;
  const HEADY = 1.62;

  // ── pernas curtas e grossas, blindadas ──
  for (const sx of [-1, 1]) {
    const leg = rbox(0.34, 0.5, 0.42, IRON, 0.1); leg.position.set(sx * 0.28, 0.42, 0); model.add(leg);
    const boot = rbox(0.4, 0.26, 0.56, IRON2, 0.08); boot.position.set(sx * 0.28, 0.15, 0.08); model.add(boot);
    const knee = ball(0.13, BRONZE); knee.position.set(sx * 0.28, 0.55, 0.22); model.add(knee);
  }

  // ── TORSO largo e quadrado (silhueta de tanque) ──
  const torso = rbox(1.02, 0.92, 0.62, IRON, 0.16); torso.position.y = 1.1; model.add(torso);
  // peitoral com sulco + rebites
  const plate = rbox(0.7, 0.66, 0.12, IRON2, 0.1); plate.position.set(0, 1.14, 0.34); model.add(plate);
  for (const sx of [-1, 1]) for (const yy of [1.32, 1.0]) {
    const rivet = ball(0.05, BRONZE); rivet.position.set(sx * 0.26, yy, 0.42); model.add(rivet);
  }
  // cinto
  const belt = rbox(1.04, 0.16, 0.64, 0x3a2a1c, 0.05); belt.position.y = 0.78; model.add(belt);
  const buckle = rbox(0.2, 0.16, 0.1, BRONZE, 0.04); buckle.position.set(0, 0.78, 0.36); model.add(buckle);

  // ── pauldrons (ombreiras grandes) ──
  for (const sx of [-1, 1]) {
    const pad = blob(0.32, 0.28, 0.34, IRON); pad.position.set(sx * 0.6, 1.5, 0.02); model.add(pad);
    const spike = cone(0.1, 0.24, IRON2, 10); spike.position.set(sx * 0.66, 1.7, 0.02); spike.rotation.z = sx * -0.3; model.add(spike);
  }

  // ── CABEÇA: rosto orc bravo sob elmo aberto ──
  const head = ball(HEADR, SKIN); head.position.set(0, HEADY, 0.04); head.scale.set(1.05, 0.95, 1); model.add(head);
  // elmo (skullcap ACIMA dos olhos + protetor de nariz + laterais)
  const helm = new THREE.Mesh(new THREE.SphereGeometry(HEADR * 1.14, 20, 16, 0, Math.PI * 2, 0, Math.PI * 0.5), vinyl(IRON));
  helm.position.set(0, HEADY + 0.14, 0.0); model.add(helm);
  const helmRim = new THREE.Mesh(new THREE.TorusGeometry(HEADR * 1.12, 0.05, 10, 24), vinyl(BRONZE));
  helmRim.rotation.x = Math.PI / 2; helmRim.position.set(0, HEADY + 0.16, 0.0); model.add(helmRim);
  const nasal = rbox(0.09, 0.3, 0.1, IRON, 0.03); nasal.position.set(0, HEADY + 0.04, HEADR * 1.02); model.add(nasal);
  for (const sx of [-1, 1]) {
    const cheek = rbox(0.09, 0.26, 0.34, IRON, 0.04); cheek.position.set(sx * HEADR * 1.04, HEADY - 0.02, 0.0); model.add(cheek);
    const horn = cone(0.1, 0.36, BRONZE, 10); horn.position.set(sx * 0.44, HEADY + 0.5, -0.02); horn.rotation.z = sx * -0.7; model.add(horn);
  }

  // sobrancelha pesada + olhos raivosos brilhando
  for (const sx of [-1, 1]) {
    const brow = rbox(0.22, 0.09, 0.07, SKIN2, 0.03); brow.position.set(sx * 0.18, HEADY + 0.13, HEADR * 0.92); brow.rotation.z = sx * -0.4; model.add(brow);
    const e = eye(0.14, 0xffcf2a, 'normal'); e.position.set(sx * 0.18, HEADY + 0.02, HEADR * 0.94); e.userData.noOutline = true; model.add(e);
  }
  // nariz achatado + rosnado entre presas (underbite)
  const nose = blob(0.13, 0.08, 0.13, SKIN2); nose.position.set(0, HEADY - 0.14, HEADR * 1.0); model.add(nose);
  const jaw = blob(0.3, 0.16, 0.2, SKIN); jaw.position.set(0, HEADY - 0.3, HEADR * 0.78); model.add(jaw);
  const snarl = new THREE.Mesh(new THREE.CircleGeometry(0.16, 16),
    new THREE.MeshBasicMaterial({ color: 0x2a0d10, toneMapped: false }));
  snarl.scale.set(1.2, 0.55, 1); snarl.position.set(0, HEADY - 0.28, HEADR * 0.95); snarl.userData.noOutline = true; model.add(snarl);
  for (const sx of [-1, 1]) {
    const tusk = cone(0.07, 0.26, 0xeae3cf, 8); tusk.position.set(sx * 0.16, HEADY - 0.22, HEADR * 0.96);
    tusk.userData.noOutline = true; model.add(tusk);
  }

  // ── braço direito com maça ──
  const armR = capsule(0.15, 0.3, SKIN); armR.position.set(0.62, 1.18, -0.02); armR.rotation.z = -0.5; model.add(armR);
  const fistR = glove(0.2, SKIN2); fistR.position.set(0.84, 1.42, 0.06); model.add(fistR);
  const haft = capsule(0.06, 0.5, 0x5a3719); haft.position.set(0.92, 1.7, 0.06); model.add(haft);
  const maceHead = ball(0.2, IRON2); maceHead.position.set(0.96, 2.0, 0.06); model.add(maceHead);
  for (const a of [0, 1.05, 2.1, 3.15, 4.2, 5.25]) {
    const spk = cone(0.07, 0.16, IRON, 8);
    spk.position.set(0.96 + Math.cos(a) * 0.22, 2.0 + Math.sin(a) * 0.22, 0.06);
    spk.rotation.z = a - Math.PI / 2; model.add(spk);
  }

  // ── ESCUDÃO no braço esquerdo (domina a silhueta) ──
  const shieldGrp = new THREE.Group(); shieldGrp.position.set(-0.66, 1.02, 0.46); shieldGrp.rotation.y = 0.25;
  const sBack = rbox(1.0, 1.4, 0.12, IRON2, 0.26); shieldGrp.add(sBack);
  const sFace = rbox(0.86, 1.24, 0.14, IRON, 0.24); sFace.position.z = 0.06; shieldGrp.add(sFace);
  const rim = rbox(0.94, 1.32, 0.1, BRONZE, 0.26); rim.position.z = 0.02; shieldGrp.add(rim);
  const boss = ball(0.18, BRONZE); boss.position.z = 0.16; shieldGrp.add(boss);
  // emblema (estrela) no escudo
  const emblem = new THREE.Mesh(starGeoM(0.26, 0.12, 4), glow(EMBLEM));
  emblem.position.set(0, 0.36, 0.15); emblem.userData.noOutline = true; shieldGrp.add(emblem);
  const armL = capsule(0.14, 0.26, SKIN); armL.position.set(-0.5, 1.16, 0.18); armL.rotation.z = 0.4; model.add(armL);
  model.add(shieldGrp);

  outlineAll(model, 0.05);
  return { model, lights: [] };
}

// estrela utilitária (também usada pelo escudo)
function starGeoM(outer, inner, points) {
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
