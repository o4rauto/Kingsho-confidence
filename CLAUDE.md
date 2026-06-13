# CLAUDE.md — Contexto completo do projeto

Guia para agentes (Claude) que pegam este repositório do zero (após `/clear`).
**Leia inteiro antes de editar.** Última atualização: branch
`claude/optimistic-archimedes-1ebr2w` (Gameplay Core Edition — ranged enemies, dodge mechanics, core feel).

---

## 0. CARTA DE DESENVOLVIMENTO (Charter v3.0 — Máxima Autoridade)

O agente ativo não é apenas programador — é o **departamento técnico completo**:
Lead Architect + Technical Director + Gameplay Designer + Performance Engineer.

**Lei suprema de decisão:** *"Isso aumenta a percepção de qualidade do jogador?"* → sim → prioridade alta.

**Workflow obrigatório:** Estudar → Mapear → Documentar → Planejar → Implementar → Validar → Atualizar CLAUDE.md → Continuar.

**Este arquivo é um documento vivo.** Atualizar após cada milestone:
`Current Version`, `Completed Features`, `Known Issues`, `Architecture Changes`, `Next Actions`.

**KPIs oficiais:**
- Visual: 4/10 atual → **meta 8.5/10**
- Sessão média: 5 min atual → **meta 20+ min**
- Todo ataque deve gerar: som + partículas + impacto + shake + feedback visual

**Referências de qualidade:** Kingdom Rush 5, Archero 2, Hades (game feel / feedback / progressão)

**Regra de ouro da performance:** 60 FPS com 100 inimigos simultâneos.

**Critérios Steam (long-term):** 4 mapas, 4 bosses, 20 inimigos, 4 torres, 50 upgrades, ≥8/10 visual, ≥20 min retenção.

### Nota sobre "Living World Edition" e chartes Unity/C#

O usuário enviou chartes que referenciam Unity (MonoBehaviour, ScriptableObjects, FMOD, ShaderGraph). **Esses são PADRÕES DE REFERÊNCIA de qualidade — não instruções literais**. O Bastion Rush é intencionalmente **Canvas 2D single-file sem dependências** (decisão arquitetural registrada na seção 7). Adaptamos os princípios ao nosso stack:
- *BiomeSystem* → variantes de mapa via SLOTS/TREES/LIGHTS por fase
- *EnemyIconSystem* → MODELS[] com caixas únicas por tipo + elite tints + glow
- *TowerFantasySystem* → towerModelFor() com partes extras por nível + LIGHTS coloridos
- *JuiceManager* → screen shake, hit stop, particles, impact rings (já implementados)
- *DamageSystem* → damageEnemy() com crit, armor, doom, drain, freeze, run upgrades
- *Arquitetura src/core/engine/gameplay/...* → seções dentro do script único (helpers → motor 3D → modelos → monstros → campanha → save → áudio → estado/loop → input → update → render → UI)

**NÃO** splittar em múltiplos arquivos nem adicionar build system — quebra o workflow de APK (single-file → Capacitor) e o sandbox de teste.

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
  **backface cull**, **iluminação RGB cel-shading**: key difusa **quantizada em
  degraus** (`toon`) + ambiente baixo `AMB` (base escura) + `FILL`, **mais point
  lights locais** (`LIGHTS`: braseiros quentes + aura fria do mago, queda
  quadrática por distância — clareiam superfícies no raio). Guarda `lr/lg/lb`
  por face e empilha em `BUF` (`FLOOR`, `SHADOWS` ou `FACES`) com `z` médio;
  `paint` multiplica `rgb` por `lr/lg/lb` e aplica a neblina.
- `box(cx,cy,cz, w,h,d, hex, cosA,sinA, pivot)`: cuboide (com rotação Y em torno
  do pivô) → 6 quads.
- `drawModel(parts, wx,wy,wz, ang, sc, tint?)`: desenha um modelo (lista de
  caixas). `tint` (hex) opcional mistura cada cor (fator 0.42, via `tintHex` com
  cache) — usado p/ recolorir as **variantes de elite**.
- **Painter em 3 passadas** (`paint`): `FLOOR` (chão+caminho) → `SHADOWS`
  (sombras de contato) → `FACES` (tudo acima do chão), cada uma ordenada por `z`.
  As **sombras** são quads escuros achatados no chão (`addShadow(x,z,r)`, y≈0.03)
  pintados entre o piso e os modelos → dá "pé no chão" sem alpha. **Por quê o chão
  é mosaico:** desenhado como **tiles** (`buildFloor`, 7×7) — se fosse 1 quadradão,
  a média de profundidade dele cobriria inimigos distantes (bug que já ocorreu e
  foi corrigido assim). **Não volte a usar 1 quad gigante p/ o chão.**

### 3.2 Modelos (todos feitos de caixas, originais)
- `M_HERO` (**mago chibi** estilo Archero × Kingdom Rush: botas, robe + cinto
  dourado, capa, mãos, cabeça chibi com olhos, **chapéu pontudo** e **cajado com
  orbe** brilhante), `M_TOWER`.
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
- **Tema "arena escura" (estilo Archero):** fundo e chão escuros (pedra), caminho
  de pedra clara, **muralhas** ao redor com portão no fundo (`buildWalls`),
  braseiros no lugar das árvores (`buildDeco`), base/decor recoloridos. `render()`
  aplica uma **vinheta** radial (escurece as bordas) logo após `renderScene()`.
- **Juice de combate** (no `drawFx`, projetado em 3D→2D): **glow quente** dos
  braseiros, **projéteis brilhantes** (bolas de energia com `globalCompositeOperation
  'lighter'`), e **barra de vida** sobre cada inimigo (chefe sempre; demais quando
  feridos) além da aura/marca das elites.
- `render()` desenha: fundo (gradiente escuro), `renderScene()` (3D), vinheta,
  depois a UI 2D.
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
- Branch de trabalho ativa: **`claude/optimistic-archimedes-1ebr2w`**. Branch
  legada `claude/ecstatic-gauss-nCtxQ` ainda existe mas a ativa é esta.
  Há uma branch **`main`** com um **commit inicial vazio** criada só para servir
  de base do **PR draft**.
- Sempre: `git push -u origin claude/optimistic-archimedes-1ebr2w`. Após push,
  garantir que o PR draft existe.
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

> 🧭 **Plano-mestre:** ver [`ROADMAP.md`](ROADMAP.md) — visão **unificada** (1 jogo
> só; fusão **Archero × Kingdom Rush**) com milestones **M0–M9** (herói mago que
> atira parado, fase=10 hordas, 3 caminhos, 4 classes de torre, sinergias
> roguelike, diretor de IA adaptativo, chefes bullet-hell, visual PS2, 2 moedas).
> A lista abaixo é **histórico**; o ROADMAP é a **fonte da verdade** do que vem.
> Já feito do M0: clamp do herói à tela (perspectiva) + hook `BR.hero`.

- **✅ Feito (base):** Bastion Rush 3D; herói móvel (joystick/WASD); campanha procedural
  2500 fases (vencer p/ avançar, recompensa única, 3–7 hordas, monstro novo a
  cada 4 níveis até ~52); 13 monstros + 3 bosses com comportamentos (heal/split/
  regen/burst/armor/fly); bestiário (KR-like, `META.seen`); menu CR-like com herói
  central + baús; HAB+ULT; áudio (WebAudio) + vibração; diária + gemas + gacha;
  ajustes (PT/EN); história do Guardião (1º play); botões "Em Breve" (FOMO);
  **variantes de elite** (4 afixos: recolor + buffs + habilidade extra, a partir
  da fase 24, com aura/marca e aviso na Campanha); **visual estilo Archero**
  (arena escura + muralhas + braseiros, sombras de contato, vinheta, projéteis
  brilhantes, barras de vida sobre inimigos);
  **4 tipos de torre** (arqueira/mágica/quartel/artilharia, seleção radial, upgrade
  por nível, slow + AOE + ignoreArmor); herói atira só parado; 3 vidas.
- **✅ Feito (Charter Fases 3+4+5):**
  torres com modelos 3D únicos (Arqueira/Mágica/Quartel/Artilharia), towerModelFor()
  com partes extras por nível 2–5 (bandeira/cristal/cinto/cano → espadarte/runas/pilares/escudo → capacete/runas gold/trim/rebites → coroa dourada), LIGHTS por tipo (verde/roxo/gold/laranja escalando com nível), glow ambiental das torres em drawFx().
- **✅ Feito (Gameplay Core Edition):**
  spawn cadence 50% mais rápido; herói prioriza inimigo mais avançado no caminho (heroTarget);
  zona de perigo (1.8 uni): inimigos viram p/ herói, desaceleram e atacam; dano na base 55% (antes 100%);
  base HP 150 (antes 100); cristais 110 (antes 90); tap-anywhere em won/over para continuar;
  danger pulse vermelho abaixo de 35% HP; HAB range 4.8, cd 5s, dano 3.2×;
  **inimigos com ataques à distância**: revenant (verde, cd 3s) e wraith (roxo, cd 2.2s) disparam
  projéteis em linha reta; boss_tank e boss_swift disparam spread de 3 projéteis;
  telegraph glow (0.4s antes de atirar o inimigo brilha na cor do projétil);
  stop-to-aim (inimigos param 92% ao mirar); anel de alcance sutil ao redor do herói;
  sistema de combo/streak (3×/5×/N× FRENESI com cristais bônus + fire rate acelerado);
  ULT PRONTA banner+flash+som ao encher 100%; encounter banners para novos inimigos especiais;
  impacto VFX (sparks + explosion) quando projétil do inimigo acerta o herói;
  shots de inimigos não disparam à ≤2.2u de distância (anti-unfair ponto-a-ponto).
- **✅ Feito (Charter Fase 8 — Sistema Roguelite):**
  20 upgrades em 4 raridades (Comum/Raro/Épico/Lendário) com efeitos reais:
  dmgMult, cdMult, rangeBon, multiShot (2/3 projéteis), projBig, pierce, critBonus,
  critMult (3×), drainFrac, explodeKill, freezeChance, ultFaster, baseRegen, doomPct, vampKill.
  Tela de escolha entre hordas (overlay premium com 3 cards, cor por raridade). G.run object.
  `G.runUpgrades[]` rastreia poderes escolhidos; chips coloridos no HUD (abaixo do painel esquerdo).
  HUD: painel central mostra "HORDA X/Y" p/ o jogador saber quando o próximo upgrade chega.
- **✅ Feito (Arena Map Overhaul):**
  caminho 67% mais largo (1.05→1.75 half-width) com pedra quente contrastando com chão frio;
  marcadores de pedra nas bordas do caminho; muralhas 70% mais altas (2.0→3.4), torres do portão
  com tochas no topo; 8 braseiros (era 6) para melhor iluminação ambiental; S-curve mais dramática;
  muro frontal da arena. Modelos de inimigo: ogro reconstruído (torso largo, ombros projetados,
  cabeça gigante com presas e olhos vermelhos), couraçado com espaldar + viseira, voador com
  asas 2× maiores + membrana interna mais clara.
- **✅ Feito (Visual Dominance Edition — Charter Fases 1+2+7):**
  screen shake (small/medium/large), hit stop (`G.hitStop`), partículas físicas
  estilizadas (spark/blood/dust/explosion/shockwave), números flutuantes animados
  com punch-in para crits (escala 1.5×), críticos 15% (2× dmg, dourado, shake+stop),
  glow dos braseiros com `'lighter'` pulsante, glow do orbe do mago pulsante,
  trails de projéteis estilo Archero (N pontos 3D → `project()`), flash de hit nos
  inimigos (radial branco, `'lighter'`), HUD com barras gradiente (verde↔laranja↔vermelho
  herói / azul↔vermelho base / ouro progresso), `drawBossBar()` (barra full-width +
  gradiente rosa + nome, visível na fase), `drawBossIntro()` (overlay cinemático
  com fade-in/out, nome grande gradiente, "BOSS APARECEU"), impact rings
  expandindo no hit, embers ambientes dos braseiros (`'lighter'` flutuando).
- **🔜 Próximo (dá p/ fazer aqui, single-player):**
  1. **Loop estilo Archero — "salas fechadas"** (pedido pelo usuário): trocar a
     horda-até-a-base por salas que liberam a saída ao limpar os inimigos. Muda o
     LOOP (não só a estética) e mexe na estrutura da campanha de 2500 fases — por
     isso ficou como passo dedicado, depois do overhaul visual.
  2. **Heróis colecionáveis** (coleção/níveis/skills, casa com o gacha).
  3. **Capítulos + estrelas por fase + dificuldades + auto/2x**.
  4. **Fusão com Frontier Bastion** (modo cidade/recursos/pesquisa entre
     batalhas).
  5. Missões diárias/semanais + conquistas + passe; mais comportamentos
     (summoner, multi-lane, perigos no caminho); animação esqueletal.
  6. **Afixos de elite no bestiário** (entradas/legenda explicando os 4 tipos).
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

- Jogar (último SHA): `https://raw.githack.com/o4rauto/Kingsho-confidence/1f090aab4cf789287953b83cec5849de33337d1c/bastion-rush/index.html`
- PR draft: #2 (base `main` ← `claude/optimistic-archimedes-1ebr2w`).
