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

// ═══════════════ GRUNT — "Saqueador" (A Maré, Vermelho): saqueador gelo-morto ═══════════════
// Ficha: lab/concept/saqueador.png — carne enregelada, trapos+capuz, cachecol
// vermelho (facção), brasa/calor residual e picareta tosca. Gaunto e curvado.
export function buildGrunt(opts = {}) {
  const SKIN = opts.skin ?? 0x9fb1c2;   // carne enregelada (azul-acinzentado)
  const SKIN2 = opts.skin2 ?? 0x6d8194;  // sombra/gangrena fria
  const BELLY = opts.belly ?? 0xc4d2dd;  // peito/abdômen gelado claro
  const CLOTH = opts.cloth ?? 0x2b2f37;  // trapos escuros
  const STEEL = 0xb8c2cc;
  const RED = opts.red ?? 0xbe392c;     // facção Vermelho (cachecol/faixa)
  const EMBER = 0xff5a28;               // brasa / calor residual (brilho)

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
  // PICARETA tosca (cabo de madeira + cabeça de ferro de dois bicos + brasa)
  const haft = capsule(0.05, 0.9, 0x4a3422); haft.position.set(0.66, 1.5, 0.12); haft.rotation.z = -0.16; model.add(haft);
  const pickH = rbox(0.46, 0.12, 0.1, STEEL, 0.03); pickH.position.set(0.74, 1.96, 0.12); pickH.rotation.z = 0.18; model.add(pickH);
  for (const dx of [-1, 1]) {
    const spike = cone(0.07, 0.26, 0x515a66, 8); spike.position.set(0.74 + dx * 0.24, 1.96 + dx * 0.04, 0.12);
    spike.rotation.z = Math.PI / 2 + dx * 0.18; model.add(spike);
  }
  const heat = new THREE.Mesh(new THREE.IcosahedronGeometry(0.05, 1), glow(EMBER));
  heat.position.set(0.74, 1.96, 0.18); heat.userData.noOutline = true; model.add(heat);

  // ── CABEÇA grande (chibi) levemente projetada pra frente ──
  const head = ball(HEADR, SKIN); head.position.set(0, HEADY, 0.08); head.scale.set(1.04, 0.96, 0.98); model.add(head);

  // CAPUZ esfarrapado (cowl escuro cobrindo topo/atrás) + pontas caídas nas laterais
  const hood = blob(0.62, 0.58, 0.6, CLOTH); hood.position.set(0, HEADY + 0.2, -0.12); model.add(hood);
  const hoodBack = blob(0.5, 0.5, 0.34, 0x1d2027); hoodBack.position.set(0, HEADY + 0.08, -0.42); model.add(hoodBack);
  for (const sx of [-1, 1]) {
    const flap = cone(0.16, 0.52, CLOTH, 10); flap.position.set(sx * 0.5, HEADY - 0.12, -0.04);
    flap.rotation.z = sx * -0.5; model.add(flap);
  }

  // sobrancelha raivosa (bloco escuro angulado pra dentro)
  for (const sx of [-1, 1]) {
    const brow = rbox(0.28, 0.11, 0.08, SKIN2, 0.04);
    brow.position.set(sx * 0.22, HEADY + 0.2, HEADR * 0.9 + 0.08); brow.rotation.z = sx * -0.5; model.add(brow);
  }
  // olhos brasa (calor residual) fundos e brilhantes
  for (const sx of [-1, 1]) {
    const e = eye(0.16, EMBER, 'normal');
    e.position.set(sx * 0.23, HEADY + 0.07, HEADR * 0.92 + 0.08); e.userData.noOutline = true; model.add(e);
    const gl = new THREE.Mesh(new THREE.CircleGeometry(0.1, 14), glow(EMBER));
    gl.position.set(sx * 0.23, HEADY + 0.07, HEADR * 0.9 + 0.06); gl.userData.noOutline = true; model.add(gl);
  }
  // nariz comprido e adunco
  const nose = blob(0.1, 0.1, 0.2, SKIN2); nose.position.set(0, HEADY - 0.08, HEADR * 0.95 + 0.12); model.add(nose);
  // boca com presas (sorriso torto)
  const mouth = fangMouth(0.3); mouth.position.set(0, HEADY - 0.32, HEADR * 0.84 + 0.08);
  mouth.rotation.z = 0.08; model.add(mouth);

  // CACHECOL/faixa vermelha (cor da facção) + brasas residuais espalhadas
  const scarf = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.34, 0.18, 16), vinyl(RED));
  scarf.position.set(0, 1.66, 0.06); model.add(scarf);
  const tail = rbox(0.16, 0.5, 0.06, RED, 0.04); tail.position.set(0.2, 1.4, 0.24); tail.rotation.z = -0.2; model.add(tail);
  for (const p of [[0.0, 1.3, 0.3], [-0.14, 1.14, 0.29]]) {
    const crack = new THREE.Mesh(new THREE.IcosahedronGeometry(0.04, 1), glow(EMBER));
    crack.position.set(...p); crack.userData.noOutline = true; model.add(crack);
  }
  return { model, lights: [] };
}

// ════════════════════════════ SHIELD (orc blindado, tanque) ════════════════════════════
export function buildShield(opts = {}) {
  const SKIN = opts.skin ?? 0x9fb1c2;   // carne enregelada (quase coberta)
  const SKIN2 = opts.skin2 ?? 0x6d8194;
  const IRON = opts.iron ?? 0x8b97a8;   // aço-geada
  const IRON2 = opts.iron2 ?? 0x515b6b;  // aço escuro
  const BRONZE = 0x9fb9cc;               // trim gelo-prata
  const EMBLEM = opts.emblem ?? 0x7fe0ff; // cristal de gelo
  const ICE = 0xaee6f2;                  // brilho gelado (visor/lâmina/cristais)

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

  // ── pauldrons arredondados (sem espinhos — silhueta limpa) ──
  for (const sx of [-1, 1]) {
    const pad = blob(0.34, 0.3, 0.36, IRON); pad.position.set(sx * 0.6, 1.52, 0.02); model.add(pad);
    const trim2 = new THREE.Mesh(new THREE.TorusGeometry(0.2, 0.04, 8, 18), vinyl(BRONZE));
    trim2.rotation.x = Math.PI / 2; trim2.position.set(sx * 0.6, 1.62, 0.04); model.add(trim2);
  }

  // ── CABEÇA: ELMO FECHADO de gelo-aço (sem rosto orc; visor com brilho gelado) ──
  const helm = new THREE.Mesh(new THREE.SphereGeometry(HEADR * 1.16, 20, 16), vinyl(IRON));
  helm.position.set(0, HEADY + 0.04, 0.0); helm.scale.set(1, 1.06, 1); model.add(helm);
  const visor = rbox(HEADR * 1.8, 0.16, 0.12, 0x161a22, 0.05); visor.position.set(0, HEADY + 0.02, HEADR * 1.0); model.add(visor);
  for (const sx of [-1, 1]) {
    const slit = new THREE.Mesh(new THREE.CircleGeometry(0.07, 12), glow(ICE));
    slit.position.set(sx * 0.16, HEADY + 0.02, HEADR * 1.08); slit.userData.noOutline = true; model.add(slit);
  }
  const nasal = rbox(0.1, 0.34, 0.12, IRON2, 0.03); nasal.position.set(0, HEADY - 0.1, HEADR * 1.02); model.add(nasal);
  const crest = rbox(0.08, 0.52, 0.34, IRON2, 0.03); crest.position.set(0, HEADY + 0.5, 0.0); model.add(crest);
  const helmRim = new THREE.Mesh(new THREE.TorusGeometry(HEADR * 1.12, 0.05, 10, 24), vinyl(BRONZE));
  helmRim.rotation.x = Math.PI / 2; helmRim.position.set(0, HEADY - 0.2, 0.0); model.add(helmRim);

  // ── braço direito: punho com espada-curta de gelo apontada p/ baixo (limpo) ──
  const armR = capsule(0.15, 0.34, IRON); armR.position.set(0.6, 1.16, 0.04); armR.rotation.z = -0.25; model.add(armR);
  const fistR = glove(0.2, IRON2); fistR.position.set(0.72, 0.86, 0.12); model.add(fistR);
  const guardR = rbox(0.3, 0.06, 0.1, BRONZE, 0.02); guardR.position.set(0.72, 0.96, 0.12); model.add(guardR);
  const blade = cone(0.09, 0.7, 0xcde2ee, 4); blade.position.set(0.72, 0.5, 0.12); blade.rotation.z = Math.PI; model.add(blade);

  // ── ESCUDÃO no braço esquerdo (domina a silhueta) ──
  const shieldGrp = new THREE.Group(); shieldGrp.position.set(-0.66, 1.02, 0.46); shieldGrp.rotation.y = 0.25;
  const sBack = rbox(1.0, 1.4, 0.12, IRON2, 0.26); shieldGrp.add(sBack);
  const sFace = rbox(0.86, 1.24, 0.14, IRON, 0.24); sFace.position.z = 0.06; shieldGrp.add(sFace);
  const rim = rbox(0.94, 1.32, 0.1, BRONZE, 0.26); rim.position.z = 0.02; shieldGrp.add(rim);
  const boss = ball(0.18, BRONZE); boss.position.z = 0.16; shieldGrp.add(boss);
  // emblema: cristal de gelo (losango) no escudo
  const emblem = new THREE.Mesh(new THREE.OctahedronGeometry(0.28, 0), glow(EMBLEM));
  emblem.scale.set(0.66, 1.15, 0.4); emblem.position.set(0, 0.34, 0.17); emblem.userData.noOutline = true; shieldGrp.add(emblem);
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
// ═══════════ RUNNER — "Batedor" (A Maré, Âmbar): espreitador veloz gelo-morto ═══════════
// Ficha: lab/concept/batedor.png — magro, à caça rápida, frostbitten + acentos âmbar,
// olhos brilhantes, fitas/bandana esvoaçando (= velocidade). Sem tênis (é gelo-morto).
export function buildRunner(opts = {}) {
  const SKIN = opts.skin ?? 0x9fb1c2;   // carne enregelada
  const SKIN2 = opts.skin2 ?? 0x6d8194;  // sombra fria
  const BELLY = opts.belly ?? 0xc4d2dd;
  const SCARF = opts.scarf ?? 0xe7a32a;  // facção Âmbar (bandana/fitas)
  const GLOW = 0xffb733;                 // brilho âmbar (olhos/brasa)
  const RAG = 0x2b2f37;                  // trapos

  const model = new THREE.Group();
  const HEADR = 0.5;
  const HEADY = 1.7;

  // ── pernas esguias + pés com garras (frostbitten), levemente fletidas ──
  for (const sx of [-1, 1]) {
    const thigh = capsule(0.11, 0.32, SKIN); thigh.position.set(sx * 0.2, 0.92, 0.04); thigh.rotation.z = sx * 0.06; model.add(thigh);
    const shin = capsule(0.09, 0.34, SKIN); shin.position.set(sx * 0.2, 0.5, 0.0); model.add(shin);
    const foot = blob(0.15, 0.1, 0.28, SKIN2); foot.position.set(sx * 0.2, 0.09, 0.14); model.add(foot);
    for (const k of [-1, 0, 1]) {
      const claw = cone(0.04, 0.13, 0xe9eef4, 6); claw.position.set(sx * 0.2 + k * 0.08, 0.07, 0.32);
      claw.rotation.x = Math.PI / 2; claw.userData.noOutline = true; model.add(claw);
    }
  }

  // ── corpo magro, curvado pra frente (postura de caça) ──
  const body = blob(0.31, 0.5, 0.3, SKIN); body.position.set(0, 1.24, 0.04); model.add(body);
  const belly = new THREE.Mesh(new THREE.CircleGeometry(0.16, 18),
    new THREE.MeshBasicMaterial({ color: BELLY, toneMapped: false }));
  belly.scale.set(1, 1.9, 1); belly.position.set(0, 1.18, 0.31); belly.userData.noOutline = true; model.add(belly);
  // costelas frias
  for (const i of [0, 1, 2]) {
    const rib = rbox(0.22, 0.02, 0.04, SKIN2, 0.01); rib.position.set(0, 1.08 + i * 0.12, 0.31); model.add(rib);
  }

  // ── braços finos jogados pra trás (corrida) ──
  for (const sx of [-1, 1]) {
    const arm = capsule(0.07, 0.46, SKIN); arm.position.set(sx * 0.32, 1.22, -0.08); arm.rotation.x = -0.5; arm.rotation.z = sx * -0.2; model.add(arm);
    const hand = glove(0.11, SKIN2); hand.position.set(sx * 0.4, 0.96, -0.3); model.add(hand);
  }

  // ── CABEÇA gaunt erguida (rosto legível) ──
  const head = ball(HEADR, SKIN); head.position.set(0, HEADY, 0.02); head.scale.set(1.02, 0.98, 1); model.add(head);
  // orelhas/chifres finos puxados pra trás (silhueta de velocidade)
  for (const sx of [-1, 1]) {
    const ear = cone(0.12, 0.64, SKIN2, 10); ear.position.set(sx * 0.32, HEADY + 0.46, -0.1);
    ear.rotation.z = sx * -0.5; ear.rotation.x = -0.5; model.add(ear);
  }
  // olhos âmbar brilhantes
  for (const sx of [-1, 1]) {
    const e = eye(0.19, GLOW, 'normal'); e.position.set(sx * 0.22, HEADY + 0.02, HEADR * 0.94); e.userData.noOutline = true; model.add(e);
    const gl = new THREE.Mesh(new THREE.CircleGeometry(0.11, 14), glow(GLOW));
    gl.position.set(sx * 0.22, HEADY + 0.02, HEADR * 0.9); gl.userData.noOutline = true; model.add(gl);
  }
  const nose = blob(0.07, 0.06, 0.09, SKIN2); nose.position.set(0, HEADY - 0.14, HEADR * 1.0); nose.userData.noOutline = true; model.add(nose);
  const grin = fangMouth(0.22); grin.position.set(0, HEADY - 0.32, HEADR * 0.86); model.add(grin);

  // ── BANDANA âmbar na testa + fitas esvoaçando (= velocidade) ──
  const band = new THREE.Mesh(new THREE.CylinderGeometry(HEADR * 1.02, HEADR * 1.02, 0.16, 24, 1, true), vinyl(SCARF));
  band.position.set(0, HEADY + 0.14, 0); band.userData.noOutline = true; model.add(band);
  model.add(ribbon(new THREE.Vector3(-0.36, HEADY + 0.16, -0.2), SCARF, 4, 0.32, 0.18, 0.45));
  model.add(ribbon(new THREE.Vector3(-0.42, HEADY + 0.06, -0.18), SCARF, 3, 0.3, 0.14, 0.6));

  // ── cachecol/trapo no pescoço + ponta esvoaçando ──
  const scarf = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.3, 0.16, 16), vinyl(RAG));
  scarf.position.set(0, 1.54, 0.04); model.add(scarf);
  model.add(ribbon(new THREE.Vector3(-0.18, 1.42, -0.22), SCARF, 4, 0.26, 0.16, 0.5));

  return { model, lights: [] };
}
