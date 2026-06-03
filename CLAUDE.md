# CLAUDE.md — Contexto do projeto

Guia para agentes (Claude) trabalhando neste repositório. Leia antes de editar.

## 🎯 Visão geral

Este repositório contém **dois jogos web originais**, ambos **inspirados no gênero**
do **Kingshot** (war-strategy/survival + defesa), criados do zero:

| Jogo | Pasta | Stack | Status |
|---|---|---|---|
| **Frontier Bastion** | raiz (`index.html`, `js/`, `css/`) | JS puro multi-arquivo | estratégia (cidade+tropas+heróis+defesa por tiro) |
| **Bastion Rush** | `bastion-rush/index.html` | **single-file, Canvas 3D puro (0 libs)** | ação/defesa 3D — **jogo principal/ativo** |

> ⚠️ **REGRA DE ORIGINALIDADE (importante):** tudo é **original**, apenas
> *inspirado* no gênero/estilo. **Nunca** reproduzir arte, assets, logos, nomes
> de personagens, textos ou layouts pixel-a-pixel de jogos de terceiros
> (Kingshot, Clash Royale, Kingdom Rush etc.). Padrões de UX e mecânicas de jogo
> não são protegidos; arte/assets/textos específicos são. Tudo aqui é desenhado
> por código (formas/emoji) com nomes e descrições próprios.

## 📁 Estrutura

```
index.html, css/styles.css, js/{data,engine,screens,combat,main}.js  # Frontier Bastion
test/smoke.test.js                  # teste de unidade do motor do Frontier Bastion (Node)
bastion-rush/index.html             # Bastion Rush (jogo principal, single-file)
bastion-rush/README.md
.github/workflows/ci.yml            # CI: node --check + smoke test
.nojekyll                           # serve arquivos como estão (GitHub Pages)
README.md                           # índice dos dois jogos
```

## 🕹️ Bastion Rush — arquitetura (arquivo único `bastion-rush/index.html`)

Jogo de **ação/defesa 3D low-poly**, visão ¾ de cima. O jogador **controla um
herói móvel** (invulnerável) que ataca sozinho inimigos no alcance, enquanto
hordas avançam pelo caminho até a base.

Seções do `<script>` (em ordem):
- **Motor 3D próprio**: `project()` (perspectiva), `box()`/`pushQuad()` (geometria),
  `drawModel()`; iluminação flat + **painter em 2 passadas** (`FLOOR` atrás,
  `FACES` na frente — necessário p/ o chão não cobrir inimigos distantes).
- **Modelos** (caixas): `M_HERO`, `humanoid(body,head,opts)` (opts: bulk/plate/
  horns/staff), `bossModel()`, `M_TOWER`, `MODELS[type]`.
- **Monstros**: `TYPES` (stats + comportamento), `MODELS`, `MONSTER_DESC` (bestiário).
  Comportamentos implementados no loop de `update()`: `armor`, `fly`,
  `regen`, `heal` (cura aliados), `burst` (arrancada), `split` (gera enxames ao
  morrer via `spawnAt`). Bosses: `boss_tank/boss_swift/boss_king`.
- **Campanha procedural**: `TOTAL_LEVELS=2500`. `genLevel(n)` é **determinístico**
  (semente=n via `mulberry`): 3–7 hordas, cada horda uma combinação do `ROSTER`;
  **novo monstro a cada 4 níveis** (`Math.floor((n-1)/4)`); **boss a cada 10**;
  dificuldade `diff = 1+(n-1)*0.05`. Vencer p/ avançar (linear).
- **Recompensa única**: só a primeira vitória de uma fase rende moedas/gemas
  (`G.firstClear = n > META.clearedMax`); replays não soltam moeda.
- **Estados** (`G.state`): `menu`, `campaign`, `bestiary`, `story`, `settings`,
  `playing`, `paused`, `won`, `over`. Loop: `frame()→update()` (só roda lógica em
  `playing`) `+ render()` (sempre).
- **UI** (2D sobre o 3D): menu **estilo Clash Royale** (barra de topo com nível/
  moedas/gemas, **herói no centro** via `renderScene` menuMode, botão BATALHAR,
  FASES/BESTIÁRIO/HISTÓRIA, fileira de baús). Botões via `btn(act,...)` que
  empilham em `G.ui`; clique resolvido em `pointerdown` por `doAction(act)`.
- **Herói móvel**: joystick flutuante (toque) + WASD/setas. **HAB** (`useSkill`,
  dano em área c/ recarga) e **ULT** (`useUlt`, carrega ao causar dano).
- **Áudio**: `SND` sintetiza WAV/oscilador em runtime (sem arquivos). **Haptics**:
  `vibe(ms)`. **Ajustes**: som/vibração/idioma (PT-EN via `t(key)`/`STRINGS`).
- **Economia/meta** (`META`, salvo em `localStorage` chave `bastion-rush-v3`):
  `coins, gems, dmgLvl, rateLvl, clearedMax, seen{}, sound, vibe, lang,
  lastDaily, seenStory`. Diária (`claimDaily`), gacha (`doGacha`), bestiário
  (`META.seen[type]` marcado em `spawnEnemy`).
- **Hooks de teste** (`window.BR`): `start(n)`, `spawn(type)`, `skill()`, `ult()`,
  `go(state)`, `charge()`, `money()`, `cleared(n)`, `gen(n)`, `state()`. Usados só
  para verificação headless (inofensivos em produção).

## 🧪 Como VERIFICAR mudanças (ambiente sem navegador do usuário)

A **CDN é bloqueada neste sandbox** (jsdelivr → 403), por isso jogos com CDN
(ex.: Phaser) não renderizam aqui — **Bastion Rush é Canvas puro de propósito**,
então roda e pode ser testado headless.

1. **Sintaxe** (rápido, sem navegador):
   ```bash
   node -e 'const fs=require("fs");const h=fs.readFileSync("bastion-rush/index.html","utf8");const i=h.split(/<script>/).find(p=>p.includes("BASTION RUSH")).split(/<\/script>/)[0];new Function(i);console.log("OK")'
   ```
2. **Render real + screenshot** (Playwright já instalado globalmente):
   ```bash
   python3 -m http.server 8099 &        # servir
   NODE_PATH="$(npm root -g)" node /tmp/shot.js   # usar BR.* p/ navegar e page.screenshot
   ```
   Padrão do script: `chromium.launch()`, `page.evaluate(()=>BR.start(40))`,
   `page.screenshot(...)`, capturar `console`/`pageerror`. Sempre conferir o PNG
   com a ferramenta de leitura de imagem e logar erros.
3. **Frontier Bastion**: `node test/smoke.test.js` (motor; **deve passar**).

> Cuidado de teste: `startLevel(n)` bloqueia `n > META.clearedMax+1`. Para testar
> fases altas, chame `BR.cleared(N)` antes.

## 🔁 CI / deploy

- CI (`.github/workflows/ci.yml`): roda `node --check js/*.js test/*.js` + o smoke
  test a cada push/PR. Mantenha verde.
- **Pages não pôde ser ligado pelo token** (precisa ativação manual em
  Settings→Pages). Para o usuário jogar agora, usar **raw.githack.com** com o SHA:
  `https://raw.githack.com/o4rauto/Kingsho-confidence/<SHA>/bastion-rush/index.html`

## 🌿 Git

- Branch de trabalho: **`claude/ecstatic-gauss-nCtxQ`** (é a default do repo; o
  repo nasceu vazio). Base do PR: `main` (commit inicial vazio). **PR #1** (draft).
- `git push -u origin claude/ecstatic-gauss-nCtxQ`. Commits terminam com a linha
  de sessão `https://claude.ai/code/session_...`.

## ✅ Feito / 🔜 Próximo / 🌐 Precisa backend

- **Feito:** Bastion Rush 3D; herói móvel; campanha procedural 2500 fases
  (vencer p/ avançar, recompensa única, 3–7 hordas, monstro novo a cada 4
  níveis); ~13 monstros + 3 bosses com comportamentos; bestiário (estilo KR);
  menu estilo Clash Royale com herói no centro; HAB+ULT; áudio+vibração;
  diária+gemas+gacha; ajustes (PT/EN); história do Rei; botões "Em Breve" (FOMO).
- **Próximo (single-player, dá p/ fazer aqui):** heróis colecionáveis (gacha →
  coleção/níveis/skills); estrelas por fase + dificuldades + auto/2x; fusão com o
  Frontier Bastion (modo cidade/recursos/pesquisa entre batalhas); missões
  diárias/semanais + conquistas + passe; mais comportamentos (summoner, multi-
  lane, perigos); animação esqueletal + sombras.
- **Precisa de servidor (mantidos como "Em Breve"/FOMO):** IAP real, login
  Google/Apple + save na nuvem + multi-dispositivo, push, social/PvP/alianças.

## 🎨 Convenções

- Comentários e textos de UI em **PT-BR** (há toggle PT/EN via `t()`).
- **Sem dependências** em runtime (Bastion Rush). Mobile-first (retrato 460×880
  lógico; `Scale` por `dpr`). Cantos arredondados, "juice" (shake/flash/
  partículas/números flutuantes). Não usar emoji em rótulos críticos (renderiza
  como caixa em alguns ambientes) — usar formas desenhadas.
