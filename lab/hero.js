// hero.js — PYR, a bruxa de fogo (HERÓI jogável). Original, baseado na ficha de
// arte do usuário (lab/concept/pyr-heroi.png): bruxa chibi, chapéu pontudo dobrado,
// robe + capa laranja-vermelho, cajado com ORBE DE FOGO. Tema fogo (vida) vs. gelo
// (A Maré). Proporção pelo esqueleto `hero` (cabeça grande, postura ágil).
// Contorno = silhueta única no viewer (OutlinePass); aqui só volumes limpos.
//
// buildHeroMage(opts) → { model, orb, lights } (nome mantido p/ não quebrar imports).

import {
  THREE, vinyl, glow, rbox, ball, blob, cone, capsule, glove,
  eye, blush,
} from './chibi.js';

export function buildHeroMage(opts = {}) {
  const ROBE = opts.robe ?? 0xd8472a;   // laranja-vermelho vivo (brasa)
  const ROBE2 = opts.robe2 ?? 0x9c2c18;  // forro/sombra (vermelho fundo)
  const CREAM = 0xffe6c0;                // painel/estola clara
  const GOLD = 0xffc23a;
  const SKIN = opts.skin ?? 0xf4c79c;   // pele jovem
  const HATC = opts.hat ?? 0x352b46;    // chapéu ameixa-escuro
  const HAIR = opts.hair ?? 0x8a4a24;   // cabelo ruivo-acobreado
  const ORBC = opts.orb ?? 0xffb02e;    // fogo (orbe)
  const FLAME = 0xff7a1e;

  const model = new THREE.Group();
  const HEADR = 0.58;
  const HEADY = 1.9;

  // ── botas (pontas pra fora do robe) ──
  for (const sx of [-1, 1]) {
    const boot = rbox(0.34, 0.22, 0.5, 0x6b3f22, 0.1);
    boot.position.set(sx * 0.26, 0.13, 0.12); model.add(boot);
    const cuff = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.22, 0.12, 14), vinyl(ROBE2));
    cuff.position.set(sx * 0.26, 0.26, 0.04); model.add(cuff);
  }

  // ── ROBE (cone suave de bruxa — feminino, mas silhueta limpa) ──
  const robe = new THREE.Mesh(new THREE.CylinderGeometry(0.56, 0.9, 1.5, 28), vinyl(ROBE));
  robe.position.y = 0.84; model.add(robe);
  const hem = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 0.94, 0.16, 28), vinyl(ROBE2));
  hem.position.y = 0.2; model.add(hem);
  // estola/painel central claro com trim dourado
  const panel = rbox(0.26, 1.3, 0.12, CREAM, 0.06); panel.position.set(0, 0.86, 0.7); model.add(panel);
  for (const sx of [-1, 1]) {
    const trim = rbox(0.04, 1.3, 0.1, GOLD, 0.02); trim.position.set(sx * 0.15, 0.86, 0.72); model.add(trim);
  }

  // ── cinto + fivela de brasa ──
  const belt = new THREE.Mesh(new THREE.CylinderGeometry(0.7, 0.74, 0.18, 28), vinyl(0x53321e));
  belt.position.y = 0.9; model.add(belt);
  const buckle = ball(0.13, GOLD); buckle.scale.set(1, 1, 0.5); buckle.position.set(0, 0.9, 0.78); model.add(buckle);
  const gem = new THREE.Mesh(new THREE.IcosahedronGeometry(0.07, 1), glow(FLAME));
  gem.position.set(0, 0.9, 0.84); gem.userData.noOutline = true; model.add(gem);

  // ── ombros (estreitos, femininos) + gola ──
  const shoulders = rbox(1.0, 0.38, 0.56, ROBE, 0.2); shoulders.position.y = 1.48; model.add(shoulders);
  for (const sx of [-1, 1]) {
    const pad = blob(0.26, 0.24, 0.28, ROBE2); pad.position.set(sx * 0.48, 1.54, 0.02); model.add(pad);
  }
  const collar = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.38, 0.18, 20), vinyl(ROBE2));
  collar.position.y = 1.7; model.add(collar);

  // ── CAPA esvoaçante atrás (vermelho fundo, forro quente) ──
  const cape = rbox(0.96, 1.5, 0.14, ROBE2, 0.32);
  cape.position.set(0, 1.18, -0.46); cape.rotation.x = 0.12; model.add(cape);
  const capeIn = rbox(0.7, 1.3, 0.06, 0xc2381f, 0.28);
  capeIn.position.set(0, 1.2, -0.4); capeIn.rotation.x = 0.12; model.add(capeIn);

  // ── braços: esquerdo baixo, direito erguido segurando o cajado ──
  const armL = capsule(0.15, 0.36, ROBE); armL.position.set(-0.52, 1.24, 0.06);
  armL.rotation.z = 0.32; model.add(armL);
  const handL = glove(0.19, SKIN); handL.position.set(-0.66, 0.96, 0.14); model.add(handL);
  const cuffL = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.2, 0.12, 14), vinyl(GOLD));
  cuffL.position.set(-0.62, 1.08, 0.12); cuffL.rotation.z = 0.32; model.add(cuffL);

  const armR = capsule(0.15, 0.42, ROBE); armR.position.set(0.52, 1.32, 0.1);
  armR.rotation.z = -0.72; model.add(armR);
  const handR = glove(0.19, SKIN); handR.position.set(0.82, 1.58, 0.14); model.add(handR);

  // ── CABEÇA chibi (feminina: sem barba, olhos grandes, bochecha rosada) ──
  const head = ball(HEADR, SKIN); head.position.y = HEADY; head.scale.set(1.02, 1, 0.98); model.add(head);
  for (const sx of [-1, 1]) { const ear = ball(0.1, SKIN); ear.position.set(sx * HEADR * 0.95, HEADY - 0.04, -0.02); model.add(ear); }

  // franja + mechas de cabelo (sob o chapéu)
  const fringe = blob(0.56, 0.22, 0.3, HAIR); fringe.position.set(0, HEADY + 0.3, HEADR * 0.5); model.add(fringe);
  for (const sx of [-1, 1]) {
    const lock = blob(0.16, 0.42, 0.18, HAIR); lock.position.set(sx * 0.5, HEADY - 0.18, HEADR * 0.32);
    lock.rotation.z = sx * 0.12; model.add(lock);
    // ponta da mecha (cone) pra dar bico
    const tip = cone(0.12, 0.3, HAIR, 12); tip.position.set(sx * 0.54, HEADY - 0.5, HEADR * 0.28);
    tip.rotation.z = Math.PI + sx * 0.2; model.add(tip);
  }

  // sobrancelhas finas + olhos grandes (teal, complementar do robe quente) + nariz/boca
  for (const sx of [-1, 1]) {
    const brow = rbox(0.2, 0.05, 0.05, HAIR, 0.02); brow.position.set(sx * 0.23, HEADY + 0.2, HEADR * 0.9);
    brow.rotation.z = sx * -0.12; model.add(brow);
    const e = eye(0.2, 0x2fc6d6, 'normal'); e.position.set(sx * 0.23, HEADY + 0.02, HEADR * 0.92);
    e.userData.noOutline = true; model.add(e);
  }
  const nose = blob(0.06, 0.06, 0.08, 0xe7a878); nose.position.set(0, HEADY - 0.14, HEADR * 0.98); model.add(nose);
  for (const sx of [-1, 1]) { const b = blush(0.13); b.position.set(sx * 0.34, HEADY - 0.12, HEADR * 0.86); model.add(b); }
  // sorriso confiante (arco escuro)
  const smile = new THREE.Mesh(new THREE.TorusGeometry(0.1, 0.022, 8, 16, Math.PI),
    new THREE.MeshBasicMaterial({ color: 0x7a2a1a, toneMapped: false }));
  smile.position.set(0, HEADY - 0.26, HEADR * 0.92); smile.rotation.z = Math.PI; smile.userData.noOutline = true; model.add(smile);

  // ── CHAPÉU pontudo DOBRADO (aba larga + cone + ponta caída com pompom de brasa) ──
  const brim = new THREE.Mesh(new THREE.CylinderGeometry(0.92, 0.98, 0.1, 28), vinyl(HATC));
  brim.position.y = HEADY + HEADR * 0.62; brim.scale.set(1, 1, 0.92); model.add(brim);
  const coneLo = cone(0.6, 0.9, HATC, 26); coneLo.position.set(0.02, HEADY + HEADR * 0.62 + 0.5, -0.02);
  coneLo.rotation.z = -0.1; model.add(coneLo);
  const coneHi = cone(0.32, 0.7, HATC, 22); coneHi.position.set(-0.16, HEADY + HEADR * 0.62 + 1.0, -0.06);
  coneHi.rotation.z = -0.6; model.add(coneHi);
  const tip = ball(0.12, FLAME); tip.position.set(-0.5, HEADY + HEADR * 0.62 + 1.18, -0.08);
  tip.userData.noOutline = true; model.add(tip);
  // banda dourada + brasa
  const band = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.7, 0.16, 26), vinyl(GOLD));
  band.position.y = HEADY + HEADR * 0.62 + 0.12; model.add(band);
  const bandGem = new THREE.Mesh(new THREE.IcosahedronGeometry(0.1, 1), glow(ORBC));
  bandGem.position.set(0, HEADY + HEADR * 0.62 + 0.14, 0.6); bandGem.userData.noOutline = true; model.add(bandGem);

  // ── CAJADO + ORBE DE FOGO (à direita, longe do rosto) ──
  const staff = capsule(0.07, 2.0, 0x6e4322); staff.position.set(0.96, 1.28, 0.1); staff.rotation.z = -0.05; model.add(staff);
  const claw = new THREE.Mesh(new THREE.TorusGeometry(0.17, 0.045, 10, 18, Math.PI * 1.5), vinyl(0x4a2c14));
  claw.position.set(1.0, 2.2, 0.1); model.add(claw);
  const orb = new THREE.Mesh(new THREE.IcosahedronGeometry(0.21, 3), glow(ORBC));
  orb.position.set(1.0, 2.32, 0.1); orb.userData.noOutline = true; orb.userData.orb = true; model.add(orb);
  // labaredas (cones quentes saindo do orbe)
  for (const a of [0, 1, 2]) {
    const fl = cone(0.1, 0.34, FLAME, 10); fl.userData.noOutline = true;
    fl.position.set(1.0 + Math.cos(a * 2.1) * 0.16, 2.46 + a * 0.06, 0.1 + Math.sin(a * 2.1) * 0.1);
    fl.material = glow(a % 2 ? ORBC : FLAME); model.add(fl);
  }
  const orbLight = new THREE.PointLight(FLAME, 2.4, 4.6, 2); orbLight.position.copy(orb.position); model.add(orbLight);

  return { model, orb, lights: [orbLight] };
}
