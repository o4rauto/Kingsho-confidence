# PROJECT_STATE.md — estado vivo do projeto

> Registro **curto e datado** do que está feito/em andamento por raia. Fonte de
> design: `ROADMAP.md` (+ `PLAN.md`, `MECHANICS.md`). Este arquivo registra
> **status de execução** e decisões de spike. Atualize ao concluir cada etapa.

Última atualização: **2026-06-11**.

---

## Raias

| Raia | Branch | Escopo | Não toca |
|---|---|---|---|
| **MODELOS** | `lab/*` (spike) | Migração de render p/ Three.js (M7): mesh/rig/materiais | **Nunca** edita `bastion-rush/index.html` |

---

## M7 — Visual PS2 (render) · raia MODELOS

### ✅ Etapa 0 — SPIKE de render (2026-06-11) — **APROVADA**
Provar que dá p/ migrar o render do Bastion Rush p/ **Three.js** mantendo as
restrições do projeto (zero CDN, verificável headless).

- **(a) Three.js vendorizado — zero CDN.** `three@0.160.0` (r160, MIT) baixado via
  `npm pack` e commitado em `vendor/`:
  - `vendor/three.module.js` + `vendor/addons/` (GLTFLoader, EffectComposer,
    RenderPass, UnrealBloomPass, OutputPass, shaders…). Carregado por
    `importmap` — **nenhuma** requisição a CDN em runtime. Procedência/licenças em
    `vendor/README.md`.
- **(b) Personagem CC0 animado em glTF.** `vendor/models/RobotExpressive.glb`
  (CC0, by Tomás Laulhé / mod. Don McCurdy) carregado em `lab/models.html` com:
  - **turntable** (gira o modelo);
  - **toon shading** real (`MeshToonMaterial` + `gradientMap` de 4 degraus,
    convertendo os materiais PBR do glTF);
  - **bloom** (`UnrealBloomPass` via `EffectComposer`);
  - neblina por profundidade + luzes key/fill/rim/ember (feel PS2);
  - animação `Idle` tocando (`AnimationMixer`).
- **(c) Prova de WebGL headless no CI.** `lab/spike-render.mjs` sobe um servidor
  estático, abre a página no **Chromium headless (swiftshader/ANGLE)**, espera o
  modelo, **lê os pixels do canvas** (≠ vazio) e salva `lab/spike-render.png`.
  Workflow `lab-render.yml` roda isso no GitHub Actions e publica o PNG como
  artefato.
  - Resultado local: `STATE.ready=true`, `webgl=webgl2`, `anim=Idle`,
    `ERROS=[]`, `nonBg≈371k/720k`. **PNG lido e conferido** — robô toon renderiza
    nítido sobre a arena escura com bloom. ✔
- **Gotcha registrado:** `THREE.Box3().setFromObject()` **infla a caixa em meshes
  SKINNED** (inclui ossos) → normalização de escala saía minúscula (modelo
  "sumia"). Correção: medir o bounding a partir das `geometry.boundingBox` das
  meshes (ver `lab/models.html`).

> **Conclusão:** a screenshot saiu → **migração de render APROVADA**. Three.js
> vendorizado roda e é verificável headless, sem violar "zero CDN".

### ⬜ Próximos passos da raia (pós-spike, ainda em `lab/`)
- Materiais (fosco/metálico/vidro via fresnel fake), animação de **cast** do mago,
  variação de cenário a cada 10 níveis.
- Avaliar custo/tamanho do `three.module.js` (1.3 MB) p/ o bundle do APK e como
  conviver com o atual motor Canvas do `bastion-rush/index.html` (decisão de
  arquitetura antes de tocar no jogo principal).

---

## Restrições herdadas (não esquecer)
- **Zero CDN** em runtime; **verificar headless** + **ler o PNG** + `ERROS=[]`.
- A raia MODELOS trabalha **só** em `lab/`+`vendor/` e **não** edita o jogo
  principal (`bastion-rush/index.html`) — integração é decisão posterior.
