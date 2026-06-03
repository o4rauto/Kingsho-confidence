# CLAUDE.md — Contexto completo do projeto

Guia para agentes (Claude) que pegam este repositório do zero (após `/clear`).
**Leia inteiro antes de editar.** Última atualização: SHA `3fb3474`, branch
`claude/ecstatic-gauss-nCtxQ`.

---

## 1. Visão geral

Repositório com **dois jogos web 100% originais**, **inspirados no gênero** do
**Kingshot** (war-strategy/survival + defesa). Foram pedidos pelo usuário (PT-BR)
e construídos do zero, iterando bastante.

| Jogo | Pasta | Stack | Papel |
|---|---|---|---|
| **Bastion Rush** | `bastion-rush/index.html` | **single-file, Canvas 2D desenhando 3D, 0 libs** | **JOGO PRINCIPAL/ATIVO** — ação/defesa 3D low-poly |
| **Frontier Bastion** | raiz (`index.html`, `js/`, `css/`) | JS puro multi-arquivo + Canvas | 1º protótipo — estratégia (cidade + tropas + heróis + defesa por tiro) |

> ⚠️ **REGRA DE ORIGINALIDADE — INEGOCIÁVEL.** Tudo é **original**, apenas
> *inspirado* no gênero/estilo. **NUNCA** reproduzir arte, assets, sprites,
> logos, nomes de personagens, textos, música ou layouts pixel-a-pixel de jogos
> de terceiros (Kingshot, Clash Royale, Kingdom Rush, Brawl Stars etc.).
> Mecânicas de jogo e padrões de UX **não** são protegidos por direitos autorais;
> arte/assets/textos/personagens específicos **são**. Aqui tudo é desenhado por
> código (formas geométricas + alguns emojis) com nomes e descrições próprios.
> O usuário às vezes manda prints desses jogos como **referência de estilo** — é
> ok inspirar-se na estrutura/feel, nunca copiar o conteúdo.

### O que o usuário quer (resumo da intenção)
Um jogo mobile (Android via Capacitor) "juicy"/dopaminérgico no estilo Kingshot:
visão 3D ¾ de cima, **herói móvel** que ataca sozinho, **hordas** vindo pelo
caminho até a base, **2500 fases** de campanha (vencer p/ avançar, recompensa só
na 1ª vez), **muitos monstros** com comportamentos/aparências variados, **menu
estilo Clash Royale com o personagem no centro**, **bestiário estilo Kingdom
Rush**, áudio, e ganchos de monetização/retenção (mantidos como "Em Breve"
quando exigem servidor).

---

## 2. Ambiente de execução (IMPORTANTE p/ verificar)

- **Sem navegador do usuário** durante o desenvolvimento. Você verifica headless.
- **A CDN é BLOQUEADA neste sandbox** (`jsdelivr` → HTTP 403). Por isso jogos que
  carregam libs por CDN (ex.: Phaser, Howler, Three.js) **não renderizam aqui** e
  você não consegue tirar print deles. **Por isso o Bastion Rush é Canvas puro de
  propósito** (0 dependências) — ele roda no sandbox e pode ser testado headless.
- **Playwright (chromium) já está instalado globalmente** (`npm root -g`).
- **Node 22** disponível. `python3 -m http.server` disponível.

### Como VERIFICAR mudanças (sempre fazer antes de commitar)

1. **Sintaxe do Bastion Rush** (extrai o `<script>` e compila sem rodar):
   ```bash
   node -e 'const fs=require("fs");const h=fs.readFileSync("bastion-rush/index.html","utf8");const i=h.split(/<script>/).find(p=>p.includes("BASTION RUSH")).split(/<\/script>/)[0];new Function(i);console.log("OK "+i.length)'
   ```
2. **Render real + screenshot** (Playwright). Padrão usado (salvar em `/tmp/x.js`):
   ```js
   const { chromium } = require('playwright');
   (async () => {
     const errs=[]; const b=await chromium.launch();
     const p=await b.newPage({viewport:{width:460,height:880}});
     p.on('pageerror',e=>errs.push(e.message)); p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
     await p.goto('http://localhost:8099/bastion-rush/index.html',{waitUntil:'load'});
     await p.waitForTimeout(500);
     await p.evaluate(()=>{ BR.money(); BR.cleared(50); BR.start(40); });   // hooks de teste
     await p.waitForTimeout(1500);
     await p.evaluate(()=>{ ['ogre','flier','healer'].forEach(t=>BR.spawn(t)); });
     await p.waitForTimeout(1200);
     await p.screenshot({path:'/tmp/x.png'});
     console.log('STATE='+await p.evaluate(()=>BR.state())+' ERROS='+JSON.stringify(errs));
     await b.close();
   })().catch(e=>{console.error('FALHA:',e.message);process.exit(1)});
   ```
   Rodar:
   ```bash
   python3 -m http.server 8099 >/tmp/srv.log 2>&1 &
   SRV=$!; sleep 1; NODE_PATH="$(npm root -g)" node /tmp/x.js; kill $SRV
   ```
   **Sempre** abrir o PNG com a ferramenta de leitura de imagem e conferir, e
   logar `pageerror`/`console.error`. `ERROS=[]` é o esperado.
3. **Frontier Bastion** (motor, sem navegador): `node test/smoke.test.js`
   (**64 asserções, deve dar 0 falhas**).

> ⚠️ **Gotcha de teste:** `startLevel(n)` recusa `n > META.clearedMax + 1`. Para
> testar fases altas, chame `BR.cleared(N)` antes de `BR.start(n)`.
> `BR.spawn(type)` só funciona com `G.state==='playing'`.

### `window.BR` — hooks de teste (inofensivos em produção)
`start(n)`, `spawn(type, elite?)` (`elite` = id de afixo: `veteran/savage/iron/
cursed`), `skill()`, `ult()`, `go(state)`, `charge()` (enche a ult), `money()`
(+moedas/gemas), `cleared(n)` (seta clearedMax), `gen(n)` (retorna o objeto da
fase, com `hasElite`), `enemies()` (lista resumida dos inimigos vivos: `type, hp,
dmg, val, armor, elite`), `state()`.

---

## 3. Bastion Rush — arquitetura (arquivo único `bastion-rush/index.html`)

Jogo de **ação/defesa 3D low-poly**, visão ¾ de cima, retrato. O jogador
**controla um herói móvel** (joystick flutuante no toque + WASD/setas),
**invulnerável**, que **ataca sozinho** o inimigo mais próximo no alcance,
enquanto **hordas** avançam pelo caminho até a **base** (que tem HP). Resolução
lógica **460×880** projetada em 3D; escala por `dpr`.

O `<script>` (~660 linhas) está em ordem: helpers → motor 3D → modelos →
monstros → caminho/cenário → campanha → save/META → áudio → estado/loop →
input → update → render → telas/UI → habilidades → narrativa.

### 3.1 Motor 3D próprio (Canvas 2D fazendo 3D)
- `resize()` define `cw,ch,dpr,CX,CY,F` (F = distância focal por FOV 46°).
- Câmera fixa: `camPos=[0,15.5,15]`, `camTarget=[0,0.5,-2.5]`. `setupCam(shx,shy)`
  monta a base (`fwd/rgt/upv`); `project(p)` → `{vis,x,y,depth}` (perspectiva).
- `pushQuad(a,b,c,d,rgb,center)`: calcula normal, orienta p/ fora pelo `center`,
  **backface cull**, **iluminação flat** (`light = 0.42 + 0.58·max(0, n·LIGHT)`),
  empilha em `BUF` (`FLOOR` ou `FACES`) com `z` médio.
- `box(cx,cy,cz, w,h,d, hex, cosA,sinA, pivot)`: cuboide (com rotação Y em torno
  do pivô) → 6 quads.
- `drawModel(parts, wx,wy,wz, ang, sc, tint?)`: desenha um modelo (lista de
  caixas). `tint` (hex) opcional mistura cada cor (fator 0.42, via `tintHex` com
  cache) — usado p/ recolorir as **variantes de elite**.
- **Painter em 2 passadas** (`paint`): `FLOOR` (chão+caminho) ordenado e pintado
  **primeiro**, depois `FACES` (tudo acima do chão). **Por quê:** o chão é
  desenhado como **mosaico de tiles** (`buildFloor`, 7×7) — se fosse 1 quadradão,
  a média de profundidade dele cobriria inimigos distantes (bug que já ocorreu e
  foi corrigido assim). **Não volte a usar 1 quad gigante p/ o chão.**

### 3.2 Modelos (todos feitos de caixas, originais)
- `M_HERO` (cavaleiro azul com elmo + lança), `M_TOWER`.
- `humanoid(body, head, opts)` — corpo+cabeça+olhos+pés; `opts`: `bulk`,
  `plate` (peitoral), `horns`, `staff` (cajado+orbe).
- `bossModel(c1,c2)` — chefe maior com coroa.
- `MODELS[type]` mapeia cada tipo → suas caixas. `flier` é um modelo próprio
  (corpo + 2 asas). Bosses: `boss_tank/boss_swift/boss_king`.

### 3.3 Monstros — `TYPES`, `MODELS`, `MONSTER_DESC`, comportamentos
`TYPES[type]` = `{ hp, speed, scale, dmg, value, color, ...comportamento }`.
Roster atual (13 + 3 bosses), `ROSTER` define a **ordem de desbloqueio**:
`grunt, runner, shield(armor .5), brute, flier(fly), healer(heal), splitter(split
→swarm), revenant(regen), dasher(burst), swarm, armored(armor .6), ogre, wraith
(regen)`. Bosses: `boss_tank, boss_swift, boss_king`.
Comportamentos: o `TYPES` define os defaults, mas o loop `update()` lê os campos
da **instância** do inimigo (`e.armor/regen/heal/burst`), montados em `makeEnemy`.
Isso permite que **elites** adicionem habilidades por cima do tipo. `split` e
`color` continuam lidos do `TYPES` em `killEnemy`.
- `armor` (0..1): reduz dano recebido em `damageEnemy` (`e.armor`).
- `fly`: vai **reto até a base** (ignora o caminho), renderizado a `y≈1.5`.
- `regen`: recupera vida/seg (`e.regen`).
- `heal {cd,amount,radius}`: cura aliados próximos periodicamente (`e.heal`).
- `burst {cd,mult,dur}`: arrancadas de velocidade periódicas (`e.burst`).
- `split {into,count}`: ao morrer (`killEnemy`), gera N do tipo `into` via
  `spawnAt(type, d)` (na mesma posição do caminho).
`MONSTER_DESC[type] = {n:nome, a:habilidade}` alimenta o **bestiário**.

**Variantes de elite (`ELITES`).** Modificadores aplicados na **instância** (não
criam tipos novos nem entradas no bestiário). 4 afixos: `veteran` (dourado,
tankão), `savage` (laranja, +veloz, ganha `burst`), `iron` (prata, ganha
`armor .5`), `cursed` (roxo, ganha `regen`). Cada um tem `tint` + multiplicadores
`hp/dmg/spd/val/sc`. `makeEnemy(type, hpBase, el)` é o ponto único que monta o
inimigo aplicando o afixo. Render: `drawModel(...tint)` recolore o modelo +
`drawFx` desenha **aura pulsante (glow)** + **losango-marca** acima da cabeça
(projetados). Mais dano/vida/recompensa (a recompensa extra só conta em
`firstClear`, como o resto da economia).

### 3.4 Campanha procedural (2500 fases) — `genLevel(n)`
- `TOTAL_LEVELS = 2500`. `genLevel(n)` é **determinístico** (semente=n via
  `mulberry`): **3–7 hordas**; cada horda escolhe 1–3 tipos do `pool` desbloqueado
  (via `shuffle`), com contagem crescente; **boss a cada 10 níveis**; dificuldade
  `diff = 1 + (n-1)*0.05` (multiplica HP no `spawnEnemy`).
- **Novo monstro a cada 4 níveis**: `maxIdx = floor((n-1)/4)` → `pool =
  ROSTER.slice(0, maxIdx+1)`. Vale plenamente até ~**fase 52** (13 arquétipos);
  depois é recombinação + escala.
- **Variantes de elite (✅ feito):** a partir da **fase 24**, cada grupo pode ser
  marcado como elite. `eliteChance(n)` = 0 até a 24, sobe ~0,85%/fase até o teto
  de **55%** (≈fase 88). O sorteio é determinístico (`r()` do próprio `genLevel`)
  e **só consome RNG quando `ec>0`**, então as fases ≤23 mantêm o layout antigo
  (verificado: `BR.gen(≤23).hasElite===false`). `grp.elite` guarda o id do afixo;
  `genLevel` retorna `hasElite` (usado no aviso da tela de Campanha). Isso mantém
  novidade nas fases fundas mesmo depois que todos os arquétipos já apareceram.
- **Aproximação conhecida:** cada horda com vários tipos é "achatada" em
  sub-grupos sequenciais (com pausa de 0.9s entre grupos), então o nº de
  spawn-groups pode passar de 7 — o número de **hordas** é 3–7, mas a contagem de
  grupos internos varia. Dá pra refinar (interleave/mix dentro da horda).
- **Linear:** só joga `n ≤ META.clearedMax + 1`. Vencer avança.
- **Recompensa única:** `G.firstClear = (n > META.clearedMax)`. Se for replay,
  `killEnemy` **não solta moedas** e `win()` não dá recompensa (mostra
  "(replay)" no HUD).

### 3.5 Estado, loop e fluxo
- `G` = estado atual (objeto recriado a cada tela/fase). `META` = progresso
  persistente (ver 3.7).
- `frame()` (rAF): `dt` (cap 0.05), atualiza toast, `update(dt)`, `render()`.
- `update(dt)` só roda lógica de jogo em `G.state==='playing'` (avança `G.t`
  sempre p/ animações de menu). Faz: spawns da fase (de `G.gen.groups`),
  movimento+comportamento dos inimigos, ataque do herói/torres, projéteis
  (homing), moedas voando ao HUD, checagem de vitória (`win`) / derrota
  (`gameOver`).
- **Estados** (`G.state`): `menu`, `campaign`, `bestiary`, `story`, `settings`,
  `playing`, `paused`, `won`, `over`.
  > ⚠️ **NUNCA** use o estado `'select'` — ele foi **removido** (virou
  > `campaign`). Já causou tela travada ("tilt") quando a História terminava
  > indo p/ `'select'`. `doAction('select')` redireciona p/ `campaign` por
  > segurança, mas não crie novos caminhos para `'select'`.

### 3.6 UI 2D sobre o 3D
- `render()` desenha: fundo (gradiente), `renderScene()` (3D), depois a UI 2D.
- **Menu estilo Clash Royale** (`drawMenu` + `drawTopBar` + `drawChestRow`):
  barra de topo (nível=clearedMax, moedas, gemas, hamburger→ajustes), título,
  **herói girando no centro** (em `renderScene`, `menuMode = menu||bestiary`,
  desenha `M_HERO` grande em `(0,0,-2)` escala 3.1 sobre um pódio), botão grande
  **BATALHAR** (`act:'battle'`), **FASES**/**BESTIÁRIO**, e a **fileira de baús**
  (1º = Diária resgatável; outros 3 = "EM BREVE"/FOMO).
- Botões: `btn(act,x,y,w,h,label,sub,color,enabled)` desenha e, se habilitado,
  empilha `{x,y,w,h,act}` em `G.ui`. Clique resolvido em `pointerdown`:
  primeiro trata `story`/`playing` (casos especiais), senão varre `G.ui` e chama
  `doAction(act)`. `doAction` toca `SND.ui()` e roteia todas as ações
  (`battle, campaign, bestiary, camp:prev/next/play, daily, gacha, soon,
  settings, set:sound/vibe/lang, buy:dmg/rate, resume, restart, next, menu`).
- **Campanha** (`drawCampaign`): stepper `‹ Fase N / 2500 ›` + JOGAR (replay de
  fases ≤ clearedMax+1; avisa "sem moedas" em replay) + melhorias (dano/cadência)
  + invocação (gacha).
- **Bestiário** (`drawBestiary`, estilo Kingdom Rush): grade de `BESTIARY_LIST`
  (ROSTER + 3 bosses = 16). Vistos (`META.seen[type]`) mostram `drawMonsterIcon`
  (ícone 2D próprio) + nome + habilidade; não-vistos = "?"/"???".
- **HUD de jogo** (`drawPlayHud`): fase, HP da base, moedas+gemas (`coinHud`),
  progresso `mortos/total`, pause (canto inf. dir.), **HAB**/**ULT**
  (`drawSkillUlt`). **Joystick** flutuante (`drawJoystick`). **Slots de torre**
  projetados (`drawSlots`, toque constrói/melhora). Partículas/números/moedas
  (`drawFx`). `toast` (`drawToast`).
- **História** (`drawStory` + `drawKing`): cutscene de diálogo do "Guardião"
  (texto original em `STORY[]`), aparece **só na 1ª vez que toca BATALHAR**
  (`!META.seenStory`); ao terminar, `startLevel(clearedMax+1)`.
- **Ajustes** (`drawSettings`): som / vibração / idioma (PT-EN).

### 3.7 Save / economia (`META`, `localStorage` chave `bastion-rush-v3`)
`{ coins, gems, dmgLvl, rateLvl, clearedMax, seen{}, sound, vibe, lang,
lastDaily, seenStory }`. `loadMeta()/saveMeta()`. Heró-upgrades permanentes:
`heroDmg()/heroCD()` a partir de `dmgLvl/rateLvl`; custos `costDmg/costRate`.
Diária `claimDaily()`; gacha `doGacha()` (gasta 100 gemas → recompensa
aleatória); `today()` = data ISO p/ resetar a diária.

### 3.8 Habilidades do herói
- **HAB** (`useSkill`): dano em área em volta do herói, recarga 6s.
- **ULT** (`useUlt`): carrega ao causar dano (`G.ultCharge` em `damageEnemy`);
  ao encher, limpa a tela (dano em todos). Botões em `drawSkillUlt`.

### 3.9 Áudio + haptics + i18n
- `SND` (IIFE): **WebAudio** sintetizando tons/ruído em runtime (sem arquivos).
  `SND.resume()` no 1º `pointerdown` (desbloqueio mobile). Respeita `META.sound`.
- `vibe(ms)`: `navigator.vibrate` se `META.vibe`.
- `STRINGS{pt,en}` + `t(key)`. **Cuidado:** `t` é a função de tradução, mas em
  alguns escopos há `const t`/`for (const t of ...)` locais que a sombreiam — ok,
  pois não chamam `t()` ali. (Por isso o hook `BR.spawn` usa o parâmetro `ty`,
  não `t`.)

---

## 4. Frontier Bastion — arquitetura (raiz, multi-arquivo)

1º jogo (protótipo de estratégia). Roda abrindo `index.html`. `index.html`
carrega, **nesta ordem**: `js/data.js → engine.js → screens.js → combat.js →
main.js` (scripts clássicos compartilham escopo léxico global).

- **`js/data.js`** — `const DATA`: `resources`, `buildings` (central, serraria,
  fazenda, pedreira, casa_moeda, armazem, casas, quartel, muralha, academia),
  `troops` (infantry/archer/cavalry), `heroes`, `combat` (inimigos/ondas),
  `research` (árvore), `expeditions`, `missions`, `daily`.
- **`js/engine.js`** — `const Game` (chave save `frontier-bastion-save-v1`):
  estado, `load/save/reset`, produção em tempo real + teto de estoque,
  `applyOffline` (ganhos offline até 12h), filas de construção/treino/pesquisa,
  `researchBonus`, tropas, heróis (recrutar/promover, bônus), expedições,
  missões/diária, `power()`, e derivados de combate (`wallMaxHp, shotDamage,
  archerDps, chargeDamage`).
- **`js/screens.js`** — `const Screens`: `renderCidade, renderQuartel,
  renderHerois, renderPesquisa, renderMundo, renderBatalha, renderMissionsBody`
  + `refresh*` (atualização leve por tick).
- **`js/combat.js`** — `const Combat`: defesa por **tiro no Canvas** (mira/atira,
  arqueiros automáticos, **habilidades de herói** + **Carga**, escudo).
- **`js/main.js`** — orquestração: navegação (6 abas), barra de recursos, loop,
  toasts, modais (offline/missões), wiring do combate.
- **`test/smoke.test.js`** — carrega `data.js`+`engine.js` num sandbox `vm` e roda
  **64 asserções** (economia, filas, tropas, heróis, pesquisa, expedições,
  missões, diária, persistência, offline). **Deve passar.**

> Frontier Bastion **não** usa CDN (tudo local) → também roda/testa no sandbox.
> Está estável mas **não é o foco** — o usuário migrou para o Bastion Rush. Há
> intenção futura de **fundir** os dois (Frontier vira o "modo cidade" entre
> batalhas do Bastion Rush).

---

## 5. CI / deploy

- **CI** (`.github/workflows/ci.yml`): a cada push/PR roda `node --check
  js/*.js test/*.js` + `node test/smoke.test.js`. **Mantenha verde.** (O Bastion
  Rush é HTML single-file; não é coberto pelo `--check`, então valide-o à mão com
  o passo 1 da seção 2.)
- **GitHub Pages NÃO pôde ser ligado pelo token** (o `GITHUB_TOKEN` do Actions dá
  "Resource not accessible by integration" ao tentar **criar** o Pages pela 1ª
  vez — precisa ativação manual em Settings→Pages, e o usuário usa o app do
  GitHub que não tem essa tela). Um workflow `pages.yml` foi tentado e
  **removido** para não ficar vermelho.
- **Para o usuário JOGAR agora** (sem Pages): **raw.githack.com** com o SHA do
  commit (serve os arquivos do GitHub como site, com a CDN acessível no
  navegador DELE):
  `https://raw.githack.com/o4rauto/Kingsho-confidence/<SHA>/bastion-rush/index.html`
  Sempre que fizer push, mande o link com o **novo SHA**.
- **APK:** `bastion-rush/` é single-file e offline → pronto p/ Capacitor
  (instruções no `bastion-rush/README.md`).

---

## 6. Git

- Repositório: `o4rauto/Kingsho-confidence` (o nome tem maiúsculas; nas chamadas
  da API GitHub MCP o usuário às vezes aparece como `o4rauto/kingsho-confidence`).
- Branch de trabalho: **`claude/ecstatic-gauss-nCtxQ`** (é a default; o repo
  nasceu **vazio**, então essa branch virou default no 1º push). Há uma branch
  **`main`** com um **commit inicial vazio** criada só para servir de base do
  **PR #1 (draft)**.
- Sempre: `git push -u origin claude/ecstatic-gauss-nCtxQ`. Após push, garantir
  que o PR draft existe (já existe, #1).
- Commits terminam com a linha de sessão:
  `https://claude.ai/code/session_...`.
- **NÃO** colocar o ID do modelo em commits/PR/código.

---

## 7. Histórico de decisões (por quê)

- Começou como **Frontier Bastion** (estratégia multi-arquivo). O usuário então
  pediu o estilo Kingshot de verdade → fizemos **Bastion Rush**.
- Tentamos primeiro **Phaser/merge tower-defense** → mas a **CDN é bloqueada** no
  sandbox (não dava p/ verificar) e não era o gameplay certo. Migramos para
  **Canvas puro + motor 3D próprio** (verificável, offline, e o gameplay correto:
  herói móvel + horda no caminho).
- O usuário mandou prints do **Kingshot/Clash Royale** como referência de estilo.
  Implementamos **menu estilo CR com herói no centro** e **bestiário estilo KR**,
  sempre com **arte/nomes próprios**.
- Bug corrigido: **chão como 1 quad** cobria inimigos (→ mosaico + painter 2
  passadas). Bug corrigido: **História ia p/ estado `'select'` morto** e travava
  (→ história só no 1º BATALHAR, e ao fim entra direto na fase).

## 8. Roadmap

- **✅ Feito:** Bastion Rush 3D; herói móvel (joystick/WASD); campanha procedural
  2500 fases (vencer p/ avançar, recompensa única, 3–7 hordas, monstro novo a
  cada 4 níveis até ~52); 13 monstros + 3 bosses com comportamentos (heal/split/
  regen/burst/armor/fly); bestiário (KR-like, `META.seen`); menu CR-like com herói
  central + baús; HAB+ULT; áudio (WebAudio) + vibração; diária + gemas + gacha;
  ajustes (PT/EN); história do Guardião (1º play); botões "Em Breve" (FOMO);
  **variantes de elite** (4 afixos: recolor + buffs + habilidade extra, a partir
  da fase 24, com aura/marca e aviso na Campanha).
- **🔜 Próximo (dá p/ fazer aqui, single-player):**
  1. **Heróis colecionáveis** (coleção/níveis/skills, casa com o gacha).
  2. **Capítulos + estrelas por fase + dificuldades + auto/2x**.
  3. **Fusão com Frontier Bastion** (modo cidade/recursos/pesquisa entre
     batalhas).
  4. Missões diárias/semanais + conquistas + passe; mais comportamentos
     (summoner, multi-lane, perigos no caminho); animação esqueletal + sombras.
  5. **Afixos de elite no bestiário** (entradas/legenda explicando os 4 tipos).
- **🌐 Precisa de servidor (manter como "Em Breve"/FOMO):** IAP real, login
  Google/Apple + save na nuvem + multi-dispositivo, push, social/PvP/alianças.

## 9. Convenções e armadilhas (gotchas)

- **PT-BR** em comentários e UI (com toggle PT/EN via `t()`).
- **Zero dependências** em runtime no Bastion Rush. **Mobile-first** (retrato
  460×880 lógico). Cantos arredondados + "juice" (shake/flash/partículas/números
  flutuantes/pulsos).
- **Emojis** podem virar "□" em headless e em alguns aparelhos. Em rótulos
  críticos, **prefira formas desenhadas** (ex.: moedas/gemas/baús são desenhados;
  alguns botões usam 🪙💎🎁🎲 — aceitável, renderiza bem no device, mas pode
  aparecer como caixa nos screenshots do sandbox).
- Sempre **verificar headless + ler o PNG + checar `ERROS=[]`** antes de commitar.
- `startLevel(n)` bloqueia `n > clearedMax+1` (use `BR.cleared`). `BR.spawn` só em
  `playing`.
- Não reintroduzir o estado `'select'`. Não usar 1 quad gigante p/ o chão.
- Edição segura: o `index.html` do Bastion Rush é grande; faça **edits cirúrgicos**
  e rode o check de sintaxe após cada lote.

## 10. Links úteis

- Jogar (último SHA): `https://raw.githack.com/o4rauto/Kingsho-confidence/3fb34740a788d739540f5aaa58fca3d5c89a6941/bastion-rush/index.html`
- PR draft: #1 (base `main` ← `claude/ecstatic-gauss-nCtxQ`).
