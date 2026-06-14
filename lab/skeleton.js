// skeleton.js — ESQUELETO PARAMÉTRICO (a "verdade estrutural" de cada personagem).
//
// Filosofia (anatomia-primeiro): antes de qualquer forma/órgão/músculo, define-se
// o ESQUELETO — juntas (joints) numa hierarquia + ossos (bones) ligando-as, com
// PROPORÇÕES paramétricas. Mesmo sendo criaturas fictícias, a estrutura respeita
// a lógica de um ser vivo (coluna, cintura escapular/pélvica, membros segmentados
// com cotovelo/joelho). Dar "aspectos únicos" = EDITAR essas proporções (cabeça
// maior, braços longos, coluna curvada…), não empilhar blobs soltos.
//
// Saída de buildSkeleton: { joints:{nome:[x,y,z]}, bones:[[a,b],...], name }.
// Espaço: y p/ cima (pés em 0), frente em +z, x = lados (simétrico).
//
// Esta é a base p/ a PRÓXIMA etapa: pendurar volumes (músculo/tecido) nos ossos.

import { THREE } from './chibi.js';

const V = (x, y, z) => new THREE.Vector3(x, y, z);

// ── proporções base (chibi equilibrado). Presets só sobrescrevem o que mudam. ──
const BASE = {
  pelvisH: 0.95,      // altura do quadril (centro pélvico)
  hipW: 0.18,         // meia-largura do quadril
  shoulderW: 0.28,    // meia-largura dos ombros
  spineLow: 0.18, spineMid: 0.20, spineUp: 0.22, // segmentos da coluna (→ altura do tronco)
  neckLen: 0.14,
  headR: 0.50,        // raio da cabeça (chibi = cabeça grande)
  hunch: 0.0,         // curvatura/inclinação da coluna p/ frente (z acumulado por segmento)
  // membros superiores
  upperArm: 0.34, foreArm: 0.30, handLen: 0.12,
  armOut: 0.34, armFwd: 0.05,    // direção do braço (p/ fora / p/ frente)
  // membros inferiores
  thigh: 0.42, shin: 0.40, footLen: 0.26, footH: 0.10,
  legOut: 0.10, kneeFwd: 0.04,   // joelho empurrado p/ frente (flexão)
};

// ── PRESETS: cada um é a "anatomia única" de um arquétipo, via proporções. ──
export const SKELETONS = {
  // herói mago: equilibrado, cabeça grande, postura ereta e digna
  hero: { headR: 0.52, hunch: 0.0, upperArm: 0.30, foreArm: 0.26, armOut: 0.30,
          thigh: 0.34, shin: 0.30, pelvisH: 0.85 },

  // goblin magrelo: cabeça ENORME, coluna curvada, braços longos (quase ao joelho),
  // joelhos flexionados, pés compridos — esquálido e oportunista.
  goblin: { headR: 0.56, hunch: 0.05, shoulderW: 0.26, hipW: 0.15,
            spineLow: 0.20, spineMid: 0.24, spineUp: 0.22,
            upperArm: 0.40, foreArm: 0.40, armOut: 0.22, armFwd: 0.10,
            thigh: 0.40, shin: 0.38, footLen: 0.34, kneeFwd: 0.10, legOut: 0.12 },

  // fera veloz (runner): tronco curto e inclinado p/ frente, pernas potentes
  // semi-digitígradas (joelho bem flexionado), braços curtos — pronto p/ disparar.
  beast: { headR: 0.50, hunch: 0.10, shoulderW: 0.30, hipW: 0.20,
           spineLow: 0.14, spineMid: 0.16, spineUp: 0.16, neckLen: 0.10,
           upperArm: 0.26, foreArm: 0.22, armOut: 0.26,
           thigh: 0.44, shin: 0.42, footLen: 0.30, kneeFwd: 0.16, legOut: 0.16, pelvisH: 0.98 },

  // brutamonte (shield): tronco largo e maciço, ombros altíssimos, pescoço curto,
  // pernas grossas e curtas — tanque que aguenta o impacto.
  brute: { headR: 0.48, hunch: 0.04, shoulderW: 0.40, hipW: 0.26,
           spineLow: 0.16, spineMid: 0.18, spineUp: 0.22, neckLen: 0.08,
           upperArm: 0.36, foreArm: 0.32, armOut: 0.42,
           thigh: 0.34, shin: 0.30, footLen: 0.30, legOut: 0.20, pelvisH: 0.82 },
};

// monta as posições das juntas a partir das proporções (cumulativo: pélvis→cima/baixo).
export function buildSkeleton(name = 'hero') {
  const P = { ...BASE, ...(SKELETONS[name] || {}) };
  const J = {};
  const up = V(0, 1, 0);

  // ── eixo central: pélvis → coluna → pescoço → cabeça ──
  const pelvis = V(0, P.pelvisH, 0);
  J.pelvis = pelvis.clone();
  const s1 = pelvis.clone().add(V(0, P.spineLow, P.hunch));            J.spineLow = s1;
  const s2 = s1.clone().add(V(0, P.spineMid, P.hunch));                J.spineMid = s2;
  const chest = s2.clone().add(V(0, P.spineUp, P.hunch));              J.chest = chest;
  const neck = chest.clone().add(V(0, P.neckLen, P.hunch * 0.5));      J.neck = neck;
  const head = neck.clone().add(V(0, P.headR, 0));                     J.head = head;       // centro da cabeça
  J.headTop = head.clone().add(V(0, P.headR, 0));

  // ── cintura escapular + braços (segmentados: ombro→cotovelo→punho→mão) ──
  const armDir = V(0, -1, P.armFwd).normalize();        // queda do braço (frente leve)
  const foreDir = V(0, -1, P.armFwd + 0.10).normalize(); // antebraço cai p/ frente
  for (const s of [-1, 1]) {
    const tag = s < 0 ? 'L' : 'R';
    const shoulder = chest.clone().add(V(s * P.shoulderW, 0.02, 0));
    const outArm = V(s * P.armOut, 0, 0);
    const elbow = shoulder.clone().add(armDir.clone().multiplyScalar(P.upperArm)).add(outArm.clone().multiplyScalar(0.5));
    const wrist = elbow.clone().add(foreDir.clone().multiplyScalar(P.foreArm)).add(outArm.clone().multiplyScalar(0.25));
    const hand = wrist.clone().add(foreDir.clone().multiplyScalar(P.handLen));
    J['shoulder' + tag] = shoulder; J['elbow' + tag] = elbow;
    J['wrist' + tag] = wrist;       J['hand' + tag] = hand;
  }

  // ── cintura pélvica + pernas (quadril→joelho→tornozelo→pé) ──
  for (const s of [-1, 1]) {
    const tag = s < 0 ? 'L' : 'R';
    const hip = pelvis.clone().add(V(s * P.hipW, -0.02, 0));
    const knee = hip.clone().add(V(s * P.legOut, -P.thigh, P.kneeFwd));   // joelho flexionado p/ frente
    const ankle = knee.clone().add(V(-s * P.legOut * 0.4, -P.shin, -P.kneeFwd * 0.6));
    const foot = ankle.clone().add(V(0, -ankle.y + P.footH * 0.5, P.footLen)); // ponta do pé no chão, à frente
    J['hip' + tag] = hip;   J['knee' + tag] = knee;
    J['ankle' + tag] = ankle; J['foot' + tag] = foot;
  }

  // ── ossos (pares de juntas) ──
  const bones = [
    ['pelvis', 'spineLow'], ['spineLow', 'spineMid'], ['spineMid', 'chest'],
    ['chest', 'neck'], ['neck', 'head'], ['head', 'headTop'],
  ];
  for (const tag of ['L', 'R']) {
    bones.push(['chest', 'shoulder' + tag], ['shoulder' + tag, 'elbow' + tag],
      ['elbow' + tag, 'wrist' + tag], ['wrist' + tag, 'hand' + tag],
      ['pelvis', 'hip' + tag], ['hip' + tag, 'knee' + tag],
      ['knee' + tag, 'ankle' + tag], ['ankle' + tag, 'foot' + tag]);
  }

  // serializa Vector3 → array simples
  const joints = {};
  for (const k in J) joints[k] = [J[k].x, J[k].y, J[k].z];
  return { joints, bones, name };
}

// ── BLUEPRINT: malha do esqueleto (ossos = cápsulas, juntas = esferas) p/ o esboço.
// Estilo "raio-x/projeto": ciano emissivo sobre fundo escuro. É a base visual a ser
// APROVADA antes de receber músculo/tecido.
export function buildSkeletonMesh(skel, opts = {}) {
  const boneColor = opts.boneColor ?? 0x6fd0ff;
  const jointColor = opts.jointColor ?? 0xffe48a;
  const g = new THREE.Group();
  const J = skel.joints;

  const boneMat = new THREE.MeshBasicMaterial({ color: boneColor, toneMapped: false, transparent: true, opacity: 0.92 });
  const jointMat = new THREE.MeshBasicMaterial({ color: jointColor, toneMapped: false });
  const jointGeo = new THREE.SphereGeometry(0.05, 12, 10);

  // osso = cilindro fino alinhado de a→b
  const up = new THREE.Vector3(0, 1, 0);
  for (const [na, nb] of skel.bones) {
    const a = new THREE.Vector3(...J[na]), b = new THREE.Vector3(...J[nb]);
    const dir = b.clone().sub(a), len = dir.length();
    if (len < 1e-4) continue;
    const m = new THREE.Mesh(new THREE.CylinderGeometry(0.028, 0.028, len, 10), boneMat);
    m.position.copy(a).add(b).multiplyScalar(0.5);
    m.quaternion.setFromUnitVectors(up, dir.clone().normalize());
    m.userData.noOutline = true; g.add(m);
  }
  // juntas
  for (const k in J) {
    const s = new THREE.Mesh(jointGeo, jointMat);
    s.position.set(...J[k]);
    // crânio um pouco maior p/ leitura
    if (k === 'head') s.scale.setScalar(1.0 + 0.0);
    s.userData.noOutline = true; g.add(s);
  }
  // contorno do crânio (anel) p/ sugerir a caixa craniana
  const headR = (new THREE.Vector3(...J.headTop)).y - (new THREE.Vector3(...J.head)).y;
  const skull = new THREE.Mesh(
    new THREE.TorusGeometry(headR, 0.015, 8, 28),
    new THREE.MeshBasicMaterial({ color: boneColor, toneMapped: false, transparent: true, opacity: 0.5 }));
  skull.position.set(...J.head); skull.userData.noOutline = true; g.add(skull);

  return g;
}

export { THREE };
