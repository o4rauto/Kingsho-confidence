# RESEARCH — Deep-dive citado: Archero × Kingdom Rush + arquitetura → Bastion Rush

> Estudo de "laboratório" (pesquisa multi-fonte, 5 frentes em paralelo) de **como
> funcionam** Archero (Habby) e Kingdom Rush (Ironhide), a **arquitetura técnica**
> do gênero, e a **fusão/hybrid-casual** — para orientar o Bastion Rush.
> Complementa `BLUEPRINTS.md` (skeleton de conhecimento) com **fontes citadas**.
> **Só mecânicas/padrões** (não protegidos) — nada de copiar arte/nomes/assets.

## 0. Método & confiança (ler primeiro)
- 5 agentes de pesquisa rodaram WebSearch + WebFetch em paralelo (design Archero;
  economia Archero; sistemas KR; arquitetura técnica; fusão/hybrid-casual).
- **Ressalva forte:** no sandbox o **`WebFetch` retornou HTTP 403** na maioria dos
  domínios premium (Deconstructor of Fun, Game Developer/Gamasutra, Naavik,
  gameprogrammingpatterns.com, gafferongames, Medium, Fandom). As conclusões vêm
  dos **resumos do mecanismo de busca dessas mesmas páginas** → bem corroboradas,
  porém **de segunda mão** (não verificadas contra o texto renderizado).
- **Números** (%, energia, drop rates, receita, retenção) são **dependentes de
  versão/patch** e, no caso de receita, **estimativas de terceiros** (Sensor
  Tower/ThinkGaming/appfigures-style). Tratar como ordem de grandeza.
- Confiança por tipo: **Alta** = padrão corroborado por várias fontes
  (ex.: mover-OU-atirar; 4 classes; tier-4; Type Object). **Média** = números de
  guias/wiki (energia, %s de habilidade, drop rates). **Baixa** = receita/retenção
  e detalhes pós-launch.

---

# 1. ARCHERO (Habby, 2019) — deconstrução

### 1.1 Loop micro — "mover-OU-atirar" (Alta)
Binário duro: **parado = auto-dispara no inimigo mais próximo (auto-mira); ao
mover, o tiro para.** Nunca os dois ao mesmo tempo. Controle **um polegar**,
retrato, joystick. Armas/efeitos com *charge* recompensam ainda mais ficar parado.
Como a mira é automática, **a perícia é 100% posicionamento + timing**: quando é
seguro plantar e atirar vs. reposicionar. [scottfinegamedesign; levelwinner]

### 1.2 Estrutura macro (Média)
**Capítulos → estágios (salas).** Tem que **limpar tudo numa run contínua**;
morrer volta ao início do capítulo. Sala = arena de tela única; **matar todos abre
a porta**. Dois formatos: **capítulos "dungeon" de 50 estágios** e **"arena" de
20**. **Boss a cada 10º estágio** nos dungeons. Salas especiais em cadência fixa:
- **Anjo (cura/recompensa):** dungeon nos estágios 5,15,25,35,45; arena em 2,4,7,9,…
- **Tesouro** (moeda/exp/coração): estágios terminados em 9 (9,19,29,39).
- **Diabo (sacrifício ganha-perde):** só aparece se você **vencer um boss sem tomar
  dano** → habilidade forte **em troca de uma fatia de HP máx.**
- **Loja** na rotação. [archero.fandom; empyreanrule]

### 1.3 Roguelite na run (Alta no padrão; Média nos %s)
Cada **level-up na run → escolhe 1 de 3 habilidades aleatórias**; **temporárias**
(somem ao morrer/terminar) ≠ **talentos** (permanentes). Raridades **verde/Fine,
azul/Rare, roxa/Epic, laranja/Legendary**. A profundidade é **stacking + sinergia**
(modificadores se aplicam a *cada* projétil):
- **Multishot** (≈ −15% atk speed, −10% dano), **Front Arrow +1 / diagonais /
  traseiras** (flechas extras a ≈ 25% do dano base), **Ricochete** (3 hits, −30%/hit),
  **Perfurante** (−33% no 2º alvo; se houver os dois, **Ricochete tem prioridade**),
  **Quica-na-parede** (−50% após quicar), **elementais** (fogo/veneno/raio/gelo),
  **lifesteal/escudo/heal/HP**.
- Combo célebre: **Ricochete + Multishot + contagem-de-flechas (+ quica/perfurante)**
  → "tempestade de flechas" que limpa a sala sozinha.
  [archero.fandom; levelwinner; progameguides] *(%s variam por patch — Média.)*

### 1.4 Teto de habilidade (Alta)
Como a ofensiva é automática, **desviar é A perícia**. Guias insistem: "se não sabe
desviar, não termina o último capítulo". Teto alto escondido sob controle casual.

### 1.5 Meta & economia (Média)
- **Moedas:** ouro (mole; gear/talentos), **gemas** (premium; $0.99→100 gemas),
  **energia** (máx 20; **−5/run**; **+1 a cada ~12 min** = 0→20 em 4h; ad +5 até
  4×/dia; 100 gemas enche), **scrolls** (material por tipo), **fragmentos de herói**
  (50 p/ desbloquear), chaves/baús.
- **Gear:** 7 tipos / 9 slots (**arma define o padrão de tiro**, + armadura/anel/
  bracelete/locket/pet-espírito/grimório). **8 raridades** (Common→Great→Rare→Epic→
  Perfect Epic→Legendary→Ancient Legendary→Mythic). **Sobe o SLOT** com ouro+scrolls
  (nada se perde) + **fusão** (3 iguais sobem 1 tier; Legendary precisa de 2).
- **Talentos:** árvore **permanente** de stats (Strength/Power/Crit/Agile/Recover),
  **1 talento aleatório por upgrade pago**, limitado pelo nível de conta.
- **Heróis:** passiva própria; **50 frags** p/ desbloquear (premium ~4000 gemas);
  sobe estrela com frags. **Skill books** liberam habilidades no pool da run.

### 1.6 Monetização (Média)
- **Gacha:** Baú Dourado **60 gemas** (~80% Common/20% Great); Baú Obsidiana
  **300 gemas** (Epic garantido a cada 9; ~4% Epic/40% Rare/56% Fine).
- **Reviver na morte:** **30 gemas, timer ~5s** — **o melhor ponto de conversão**:
  aversão à perda da build sortuda acumulada (não-repetível). Bundles revelados
  progressivamente (barato 1º) p/ escalar o gasto.
- **Battle Pass $4.99** (relatado top IAP do Archero nos EUA). **Ads** (gemas
  grátis ~30/ad, energia, x2 loot) — "tentar, nunca forçar". Split ≈ **60% IAP / 40% ads**.

### 1.7 "Parede" e números (Baixa p/ receita)
- **Capítulo 7** = a parede canônica (precisa ~tudo épico). Cada capítulo novo
  começa sub-poderoso → loop de farm.
- Launch (mai/2019) **$8.5M / 10M downloads**; **~$263M líquido vitalício / 96M+
  downloads até 2020**; receita mensal **caiu pela metade** até 2020;
  **retenção D1 49% / D7 23% / D30 11%**. (DoF enquadrou cedo como "$25M/$35M".)

### 1.8 Secret sauce
**Acessibilidade hyper-casual (um polegar, auto-mira) fundida com profundidade
midcore (variância roguelite + teto real de dodge + meta de RPG)** → CPI baixo,
retenção forte, hábito diário.

---

# 2. KINGDOM RUSH (Ironhide, 2011) — deconstrução

### 2.1 As 4 classes de torre (Alta)
- **Arqueiro:** cadência alta, barato, **single-target físico**; acerta **voador em
  qualquer nível**. É o "backbone" de dano.
- **Mago:** **bolt mágico que IGNORA armadura** (só reduzido por resistência
  mágica); acerta chão **e** ar; mais dano, mais lento; anti-armadura.
- **Artilharia:** **a torre de AoE**; lenta; ótima vs. grupos; **não acerta voador**
  por padrão; combina com bloqueio do Quartel.
- **Quartel:** treina **soldados que BLOQUEIAM/seguram** no corpo-a-corpo — **o
  único bloqueador**; **Rally Point** move os soldados; respawnam. "Segurar e
  atrasar a coluna pra dar janela de tiro às outras torres."

### 2.2 Upgrades + tier-4 bifurcado (Alta)
**3 melhorias** e então **escolhe entre 2 upgrades finais** com habilidades
distintas. Em KR1–Origins os 3 primeiros níveis são genéricos; **especialização +
habilidade especial só no tier-4**. Ex.: mago → **Arcane Wizard** (single-target
ignora-armadura) *ou* **Sorcerer** (vira-ovelha + invoca elemental); artilharia →
**Tesla** (raio em cadeia, acerta voador porém fraco) *ou* **Big Bertha** (canhão
AoE pesado); quartel → ordem sagrada *ou* bárbaros (acertam voador, respawn rápido).
Vender devolve parte. (Vengeance/Alliance especializam em **todo** tier.)

### 2.3 Herói + magias (Alta)
**Herói** controlável anda no mapa, auto-ataca, habilidades ativas em cooldown,
**renasce** após morrer, **sobe de nível na missão** (pontos → 5 habilidades).
Muitos heróis são **premium**. Duas **magias** do jogador em cooldown: **Rain of
Fire** (meteoros, dano alto, cd ~90s) + **Reforços** (2–3 milícias que bloqueiam
como soldados do quartel).

### 2.4 Inimigos & contadores (Alta)
**Armadura → magos; voador → arqueiro/mago** (não artilharia/quartel); **rápido →
bloqueio + lentidão do quartel**. Auras especiais (cura, +armadura, +resistência
mágica), invocadores e **chefes**. Cada inimigo tem **Bounty** (ouro) e **Penalty**
(vidas) ao escapar.

### 2.5 Mapas / ondas / economia na fase (Alta)
Mapas **feitos à mão**, **caminhos fixos** (às vezes bifurcados), **ondas
roteirizadas**, **slots de construção fixos perto da estrada** (spamar barato
**esgota** os slots), **chokepoints**. **Chamar a onda antes** = ouro bônus + cd de
magia. Inimigo que escapa tira **vidas**. **Ouro por abate** (+ inicial), gasto na
fase (build/upgrade/vender), **reseta a cada fase**; há **teto de ouro por onda**.

### 2.6 Meta-progressão (Alta)
**Até 3 estrelas/mapa** (1 por dificuldade); 3-estrelas libera **Heroic** e **Iron**
(Iron dá **estrela extra**). KR1–Origins: estrelas → **árvore global persistente**
(6 árvores: 1 por torre + 1 por magia, cada uma com 5 upgrades). Dificuldades
**Casual/Normal/Veteran** (Vengeance: **Impossible**); dificuldade escala HP (±20%
em KR1). **Heróis premium** = IAP principal. (Vengeance/Alliance: estrela é
cosmética, upgrades usam "Upgrade Points".)

### 2.7 Secret sauce
Puzzle determinístico de **composição + posicionamento + timing** contra um
**script conhecido e crescente**: a torre certa (mago vs. armadura, arqueiro/mago
vs. ar, artilharia vs. swarm) no **chokepoint** certo, com o **quartel como pivô de
ritmo**. Recompensa **rejogo por maestria** (3 estrelas → Heroic/Iron), não RNG.

---

# 3. ARQUITETURA TÉCNICA (mapeada ao Canvas single-file)

### 3.1 Engine vs "sem engine" (Alta)
Estúdios usam **Unity** (editor, multiplataforma, ads/monetização) ou **Cocos2d-x**
(2D leve, C++, builds pequenos). Para uma arena 2D com poucas centenas de
entidades, **Canvas + motor próprio, 0 deps** é defensável: fica **abaixo do limiar**
onde a engine compensa e **dribla o bloqueio de CDN** do sandbox. O preço: você
implementa à mão loop/pooling/serialização (abaixo). [gamixlabs; redappletech]

### 3.2 Game loop + cap de dt (Alta)
`update(dt)` por entidade (**Update Method**) dentro do loop. O robusto usa
**acumulador de timestep fixo** + interpolação; **clampar o frameTime (~0.25s)**
evita a **"spiral of death"**. O **cap de `dt=0.05`** do Bastion Rush é o
equivalente leve — evita o "teleporte" ao voltar de aba. [Fiedler "Fix Your
Timestep"; gameprogrammingpatterns/game-loop]

### 3.3 Type Object + data-driven (Alta) — já fazemos isso
Em vez de 1 subclasse por monstro, **1 tipo/breed** e cada instância **referencia**
o tipo; centenas de tipos via **tabela/JSON** sem recompilar. **É exatamente o
`TYPES[type]` do Bastion Rush**, e os **afixos de elite** são a extensão de manual
(modificador na instância, sem classe nova). ECS generaliza (entidade=id,
componentes=dados, sistemas=lógica) — **overkill** p/ centenas; o que importa é a
**metade data-driven**. [gameprogrammingpatterns/type-object; ecs-faq]

### 3.4 Wave/spawn data-driven (Alta) — já fazemos
Onda = **lista de sub-ondas** `{tipo, count, path, delay, intervalo}`; um spawn
manager emite por timer. **= `genLevel(n).groups`**; escala por `diff`
(`1+(n-1)*0.05`). [softwarefaster TD; UE wave manager]

### 3.5 Targeting, projéteis, pooling (Alta)
Modos de alvo: **First/Closest/Strongest**. **Projétil homing**: direção por frame,
**acerto = distância < limiar**, e **tratar alvo que morre em voo** (null-check →
fizzle/retarget). **Object Pool** p/ projéteis/inimigos/partículas evita **pausas de
GC**. **No Canvas/JS o stutter de GC é o maior risco de frame** → **pool + evitar
alocação por frame** (reusar vetores; **nada de `.map`/`.filter` no hot-loop**).
[terresquall; gameprogrammingpatterns/object-pool]

### 3.6 Pathfinding (Alta)
**Waypoint/spline** (lerp entre nós) domina e é o mais barato p/ TD; A*/flow-field
só p/ grid livre ou muitos agentes. **O caminho fixo do Bastion Rush está certo.**

### 3.7 Máquina de estados (Alta)
FSM (um estado por vez, transições explícitas) p/ `menu/playing/paused/won/over`.
enum+switch é o mais simples (e o idiomático p/ jogo pequeno = nosso `G.state`).
**O estado `'select'` removido é um *dangling state* real** — a literatura de FSM
alerta exatamente contra isso.

### 3.8 Save + PRNG semeado (Alta)
**Save:** `JSON.stringify`→`localStorage` (5–10MB) = nosso `META`. **Determinismo:**
**PRNG semeado** (mulberry32: 32-bit, período ~4 bi, minúsculo/rápido, não-cripto):
mesma seed **+ mesma ordem de chamadas** = mesmo resultado → **frágil a mudança de
ordem**. Por isso o guard "**só consome RNG quando `eliteChance>0`**" (preservando
o layout das fases ≤23) é o tratamento **correto** dessa restrição.
[4rknova mulberry32; emanueleferonato]

### 3.9 Performance p/ muitas entidades (Alta)
Prioridade no Canvas: (a) **object pooling** (mata GC); (b) **zero alocação por
frame**; (c) **grid espacial uniforme** (substitui O(n²) — ~5.000 checagens já com
100 entidades — por consulta a vizinhos). Grid > quadtree quando tudo se move.
[buildnewgames; peerdh]

### 3.10 Backend/LiveOps F2P (Média)
Cliente + **BaaS**: **Remote Config** (ajustar balance **sem build**), **analytics
de evento** (Firebase/Mixpanel/BigQuery), **A/B + segmentação**, IAP validado no
servidor, leaderboards, crash. **Mapeia direto nos stubs "Em Breve"** — desenhar a
economia como **objeto de config** (já é o caso do `META`/custos) é o que depois
vira remote-config. [firebase/games; metaplay]

---

# 4. FUSÃO: hybrid-casual + playbook (Century/Kingshot)

- **Hybrid-casual** = **core simples + meta profundo**; receita **40–60 IAP/ads**.
  O meta existe p/ converter um install de **CPI baixo** num **pagante D120**.
- **Funil de UA:** "fake ads" de alto CTR → correção = **embutir o minigame
  anunciado no onboarding / como modo real** + **engenheirar um "primeiro win"
  rápido**.
- **Roguelite × TD é tendência 2026** (Dungeon Defenders, EverSiege…): jogadores
  **querem um herói controlável p/ "consertar erros em tempo real"** → **valida o
  herói móvel + torres do Bastion Rush**. Armadilha do Archero: meta **grindy** por
  descompasso entre velocidade de upgrade e contribuição real.
- **Profundidade de meta:** empilhar **vetores de poder paralelos** (árvore de
  talentos como espinha + **gear com substats/sets** + **heróis colecionáveis por
  frags + star-up**) sob um **power score** unificado — mas **roster enxuto**.
- **LiveOps:** **battle pass = mais importante (10–40% da receita)**; LiveOps deve
  **alimentar o core loop** com **ritmo previsível**; dailies/weeklies + leaderboard
  = hábito.
- **Century Games (Kingshot/Whiteout):** **combate = camada de ação que alimenta um
  meta 4X de cidade + guerra de aliança.** Whiteout ~US$1bi rápido (~US$3bi
  acumulado; pico ~US$136M/mês). Kingshot **US$100M em 117 dias**, **US$500M em ~11
  meses**. Insight do soft-launch do Kingshot: **onboarding liderado por TD
  (inspirado em Thronefall) → "primeiro win" rápido, depois o 4X pesado.** → o
  **blueprint** p/ o Bastion Rush virar a ação de um meta-cidade (fusão Frontier).
- **Diretor de IA/DDA:** monitora desempenho/estresse e ajusta spawns/ritmo; em F2P
  vira **batida de monetização** (quase-derrota → oferta de revive).
- **Ética (incisivo):** *extrativo* = fake-ads, pacing-de-grind que empurra compra,
  DDA mirando quase-derrota p/ vender revive, FOMO, paredes de gacha. *Pró-jogador*
  = meta legível e longo, **primeiro-win rápido**, LiveOps que alimenta o loop,
  social/aliança, power score legível. **A linha:** pacing honesto, RNG limitado,
  eventos que **ligam** ao core (não interrompem).

---

# 5. SÍNTESE ACIONÁVEL → Bastion Rush (decisões do "laboratório")

**Micro (de Archero) — confirma o §4 do MECHANICS:**
1. **Mover-OU-atirar** é o coração: parado dispara, andando não. **Auto-mira** no
   mais próximo. (M1)
2. **Dodge = a perícia** → inimigos precisam de **telegrafia** clara e o **herói
   precisa de vida** (M1). Salas/hordas devem ter **janelas seguras** p/ plantar.
3. **3-de-3 por horda** com **stacking multiplicativo** (modificadores aplicam a
   cada projétil) + **raridade** → a variância vira rejogabilidade. (M2/M5)

**Macro (de Kingdom Rush) — §6–§8:**
4. **4 classes com contadores** (mago=anti-armadura, arqueiro/mago=anti-ar,
   artilharia=anti-swarm, **quartel=bloqueador/pivô de ritmo**) + **tier-4
   bifurcado** que muda comportamento. (M3)
5. **Ouro de batalha por abate** que **reseta na fase** × **meta persistente**
   (estrelas/árvore) — exatamente as **duas moedas** do §11.
6. **Chamar onda antes** (ouro/tempo) e **slots fixos** com chokepoints são alavancas
   de tensão baratas e testadas.

**Arquitetura — confirma e aponta o próximo investimento:**
7. **Manter `TYPES` + afixos (Type Object) e `genLevel.groups` (wave data-driven)** —
   já é o padrão de manual; **estender por dados, não por classes.**
8. **Próximo investimento de perf** quando a contagem subir: **object pooling**
   (projéteis/partículas/números) + **grid espacial** p/ targeting/AoE — JS puro,
   0 dep.
9. **Cap de `dt`**, **`G.state` FSM** e **guard de RNG por ordem de chamada** estão
   *corretos* (defesas documentadas). Não regredir.
10. **Economia como objeto de config** (já no `META`) = a costura p/ futuro
    remote-config/LiveOps.

**Produto (de hybrid-casual/Century):**
11. **Engenheirar o "primeiro win"** (1ª fase roteirizada, vitória rápida e juicy)
    antes de abrir o meta.
12. **Vetores de poder paralelos sob 1 power score**, **roster de heróis enxuto**.
13. **Battle pass + ritmo previsível de eventos que alimentam o core**; social/
    aliança e a **fusão com a cidade (Frontier)** como teto de retenção (DNA
    Kingshot).
14. **Ética:** pacing honesto, gacha limitado, **sem** DDA mirando quase-derrota
    p/ vender revive.

> **Tese de design (uma linha):** o Bastion Rush usa o **micro do Archero**
> (mover/atirar/dodge/3-de-3) como "como se joga por segundo" e o **macro do
> Kingdom Rush** (4 classes/contadores/ondas/estrelas) como "como se domina no
> longo prazo", **costurados pelo herói móvel** que é atirador (Archero) **e**
> comandante que potencializa as torres (KR) — embrulhado num **primeiro-win
> rápido + meta de cidade/aliança** estilo Century.

---

# 6. Fontes (lidas via resumos de busca; fetch direto 403 na maioria)

**Archero (design/monetização):** Game Developer "Finding the Fun: Archero"
pt.1–3 (gamedeveloper.com) e o original scottfinegamedesign.com; Deconstructor of
Fun (why-archero-banked + Habby's Hybridcasual Empire); Archero Fandom
(Abilities/Ricochet/The Capital/Angels/Energy/Equipment/Talent); levelwinner;
progameguides; empyreanrule; levelskip; allclash; pocketgamer; touchtapplay; udonis;
thinkgaming; wnhub; hubpages; naavik (survivor.io/Archero); gameanalytics.

**Kingdom Rush:** en.wikipedia.org/wiki/Kingdom_Rush; kingdomrushtd.fandom.com
(Upgrades/Melee_Towers/Militia_Barracks/Heroes/Hero_Spell/Difficulty/Iron_Challenge/
Heroic_Challenge/Gold/Arcane_Wizard); tvtropes.org (VideoGame/KingdomRush);
tropedia.fandom.com; gamedeveloper.com (KR campaign level design); thegamer.com.

**Arquitetura técnica:** gameprogrammingpatterns.com (game-loop/update-method/
type-object/object-pool); gafferongames.com (fix_your_timestep); gamedev.net;
studyplan.dev (type-objects); habrador.com (state-pattern); softwarefaster (TD
architecture); dev.epicgames (wave manager); quakatoo; gamedevacademy; terresquall;
forum.unity (object pooling); 4rknova + emanueleferonato + github/cprosche
(mulberry32); buildnewgames (broad-phase); peerdh (spatial partitioning);
github/SanderMertens (ecs-faq); en.wikipedia (ECS); gamefromscratch + shaggydev
(FSM); blog.logrocket (localStorage); gamixlabs + redappletech (Unity vs Cocos);
firebase.google.com/docs/games; metaplay.io.

**Fusão/hybrid-casual/Century:** Deconstructor of Fun (Hybridcasual Gamble; Archero);
Naavik (4X Evolution of Century Games; Century 4X Portfolio; Survivor.io); udonis
(hybrid-casual); Game Developer (Archero pt.2); gamegrowthadvisor (LiveOps);
lancaric.me + rplg.io (fake ads); thinkingdata.io (Kingshot; Whiteout case studies);
appfigures (Kingshot $500M); asotools.io + sensortower.com (Whiteout revenue);
dlcompare (EverSiege); towersdefense.org; meegle + adriancrook (DDA).
