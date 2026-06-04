# MECHANICS — Bastion Rush (spec técnico da mecânica geral)

> Especificação **técnica e incisiva** do jogo-alvo (fusão **Archero × Kingdom
> Rush**), consolidando tudo que o usuário pediu. Complementa o `ROADMAP.md` (o
> ROADMAP diz **o quê/quando**; este doc diz **como funciona**). Status por item:
> **✅ implementado** · **🔜 planejado** · **✂️ cortado**. Tudo original.

---

## 0. Identidade & pilares
- **Gênero:** ação roguelite (Archero) **+** tower-defense (Kingdom Rush), 3D
  low-poly, retrato, mobile-first, **0 dependências**, offline (APK-ready).
- **Loop nuclear:** herói **mago móvel** que **atira parado e não atira andando**;
  ergue **torres**; sobe perks roguelite a cada horda; **tem vida e pode morrer**.
- **Tensão central:** **parar** (atira + buffa a torre no raio) **vs. mover**
  (desvia, mas não atira). Cada horda força escolhas (perk do herói + construção).

---

## 1. Engine / mundo / câmera (render)  ✅ base
- Resolução **lógica 460×880**, **motor 3D próprio em Canvas 2D** (projeção
  perspectiva, FOV 46°), escala por `dpr`. Câmera fixa **alta e afastada**
  (`camPos≈[0,19.5,19]`, alvo `[0,0.5,-2.5]`).
- **Pipeline de luz por face (`pushQuad`)** ✅: cor = `rgb × (lr,lg,lb)` onde a luz
  é **RGB com cel-shading** — difusa da *key* **quantizada em degraus** (`toon`) +
  ambiente baixo `AMB` (base escura) + `FILL`, **mais point lights locais**
  (`LIGHTS`) com queda quadrática (braseiros quentes + **aura fria do mago**) que
  **clareiam as texturas dentro do raio**. Depois **neblina** por profundidade e
  **vinheta** (a escuridão vem da vinheta, não de véu global).
- **Painter em 3 passadas** (FLOOR → SHADOWS → FACES), ordenadas por `z`; chão em
  mosaico (não 1 quad); **sombras de contato** achatadas no chão.
- **Herói preso à tela** ✅: clamp **ciente da perspectiva** (limita ao trapézio
  visível do piso, ~36px de margem) — não some nas bordas.
- 🔜 **Materiais** (fosco / metálico / vidro do orbe / emissivo) via especular +
  fresnel fake; **malhas mais densas**; **rig/animação** (cast do mago);
  **variação de cenário a cada 10 níveis** (paleta + layout temáticos).

---

## 2. Máquina de estados (`G.state`)  ✅
`menu · campaign · bestiary · story · settings · playing · paused · won · over`.
🔜 acrescentar `build` (janela de construção entre hordas) e `perk` (escolha
3-vias). `update()` só roda lógica de jogo em `playing`. **Nunca** reusar o estado
morto `select`.

---

## 3. Estrutura da partida — **fase = 10 hordas** (gating Archero)  🔜
- Uma **fase** = **10 níveis (hordas)**. **Horda N+1 só inicia quando o último
  monstro da horda N morre** — gating por *clear*, **não por timer**.
- Ciclo por horda: `spawn da horda → limpar → [estado perk: 3-vias do Herói] →
  [estado build: ~10s de torres] → próxima horda`.
- **Recompensa única por 1ª vitória** ✅ (`firstClear`); replay não solta moeda.
- **Vitória** = limpar as 10 hordas; **derrota** = vida do herói a 0 (e, no modo
  Defesa, base a 0).
- Hoje (✅) a fase usa hordas procedurais 3–7 com timer; 🔜 migrar para o gating
  10-hordas + telas perk/build.

---

## 4. Herói (mago): movimento, mira, ataque, vida  ✅ parcial
- **Movimento:** joystick flutuante (toque) **ou** WASD/setas; `sp≈5.2 u/s`;
  vetor normalizado; **clamp ciente de perspectiva** ✅.
- **Atira parado / não atira andando** 🔜: dispara só quando `|input|≈0`; auto-mira
  no inimigo mais próximo no alcance (`range 6.5`).
- **Projétil sai do ORBE do cajado** ✅: origem = posição **local `(0.46,1.28,0.16)`
  do orbe rotacionada por `hero.ang`**; bolt homing (`v≈17 u/s`, vida 1.5s), cor
  cyan do orbe.
- **Vida do herói** 🔜: `heroHp/heroHpMax`; inimigos **atacam o herói** (contato
  com cooldown ~0.8s = `TYPES.dmg`; chefes com projéteis); `heroHp≤0 → over`.
  HUD com barra de vida do herói.
- 🔜 **Cast animation**: erguer cajado + **flash no orbe** no instante do tiro.

---

## 5. Os três caminhos (escolhas na run)  🔜
A cada horda limpa o herói **sobe de nível na run** → escolhe **1 de 3**:
- **Caminho do Herói** — perks do herói: *tiro duplo, ricochete (se errar),
  perfurante, elétrico*, etc. (também tem face no **menu**: comprar habilidades/
  equipamentos permanentes).
- **Caminho do Arquiteto** — janela de **construção/upgrade de torres** (§6).
- **Caminho da Sobrecarga** — velocidade + **caos de projéteis** + feedback visual;
  unificado ao Caminho do Herói (o "juice" foca no herói).
- 🔜 **Habilidades gêmeas:** ao subir, o perk tem **efeito duplo** — um pro herói e
  outro pras **torres de uma classe** específica.
- 🔜 **Raridade de perk** (comum/épico/lendário) + **reroll/banish**; pool semeado
  pelo meta ("livros de habilidade").

---

## 6. Torres — 4 classes (Kingdom Rush) + colocação + tier-4  🔜
Ao construir, escolhe **1 de 4 classes**:
| Classe | Comportamento |
|---|---|
| **Arqueiro** | cadência alta, **dano por tiro baixo** |
| **Mago** | dispara **aura/orbe** com **dano em área** |
| **Quartel** | **invoca 3 unidades** aliadas que **travam** inimigos 1-a-1 e batalham |
| **Artilharia** | **bomba** de munição pesada (AoE forte, lento) |

- **Colocação (2 formas):** (a) **clicar** no slot → escolher classe; **ou**
  (b) **chegar perto** carregando **materiais** e **canalizar** parado (§10).
- **Upgrades por nível**; **4º nível = especialização única** que **muda o
  comportamento** da torre.
- **Torre humana** 🔜: herói **parado** dentro do **raio** da torre → **+20%
  cadência** daquela torre (incentiva risco/posição).
- Hoje (✅) há **1 tipo** de torre genérica nos 4 slots (`SLOTS`), tiro homing
  (`cd 850ms`, range 6.5) — vira a base das 4 classes.

---

## 7. Sinergias herói × torre + torres inovadoras  🔜
- **Tiros condutores:** acertar inimigo **perto de uma torre de ferro** com tiro
  elétrico → o raio **ricocheteia na torre** → **barreira elétrica** temporária.
- **Killshot towers:** acertar a **própria torre** dispara um efeito (ex.:
  **estilhaços** → onda de pregos 360°).
- **Sacrifício de upgrade:** escolhas **ganha/perde** (ex.: torres **+50% dano**,
  **−20% vida máx.** do herói).
- **Sinergia de equipamento:** a arma muda o arquétipo (ex.: **cajado necromante**
  → inimigos mortos **pelas torres** viram **esqueletos aliados** por 5s).
- **Torre Ímã (gravitacional):** **não causa dano**, **puxa** inimigos pro centro.
- **Torre Espelho:** **reflete** o tiro do herói se ele atirar nela → **dobra**
  quantidade/tamanho e manda no inimigo mais próximo.

---

## 8. Inimigos, elites e chefes  ✅ base / 🔜 chefes
- **`TYPES[type]`** = `{hp, speed, scale, dmg, value, color, + comportamento}`.
  Comportamentos lidos na **instância** (`makeEnemy`): `armor` (reduz dano:
  `dano×(1−armor)`), `fly` (reto até o alvo), `regen`, `heal {cd,amount,radius}`,
  `burst {cd,mult,dur}`, `split {into,count}`. ✅
- **Elites (`ELITES`)** ✅: 4 afixos (`veteran/savage/iron/cursed`) = recolor
  (`tint`) + multiplicadores + habilidade extra; a partir da **fase 24**,
  `eliteChance(n)` sobe ~0,85%/fase até teto **55%** (~fase 88).
- **Alvo:** modo Defesa → caminho até a **base**; modo Arena/“perseguir o herói”
  🔜 → beelina/persegue o **herói** e ataca por contato.
- **Chefes bullet-hell** 🔜: a cada 10 níveis; **não** só andam — **param em pontos
  e atacam o herói** com padrões (círculo de fogo, ondas de choque) e **invocam
  adds**. Dilema: **desviar** (herói) **vs.** garantir que as **torres foquem os
  adds** pra não perder a rota.

---

## 9. Diretor de IA adaptativo (o spawn "inteligente")  🔜
Não é só aleatório/combinado/padrão — **aprende como o player joga**.
- **Telemetria por partida** (vetor de features): tempo **parado vs. andando**,
  **classe de torre** preferida, **alvos** que prioriza, **lados** do mapa que
  ocupa, **onde toma dano**, **mortes/quase-mortes**, DPS médio, uso de HAB/ULT.
- **Política do diretor:** ajusta **composição** (tipos/afixos), **posição** (de
  qual entrada/lado vêm) e **timing** das hordas para **pressionar as fraquezas**
  do jogador (ex.: se ele fica parado num canto, manda voadores por trás; se
  spamma uma classe, manda inimigos que a anulam).
- **Determinístico + adaptativo:** base semeada (`mulberry(n)`) garante
  reprodutibilidade; a camada adaptativa modula dentro de limites (anti-frustração).
- 🔜 (lente Century) usar o diretor também como **batida de tensão/monetização**:
  manter na beira de vencer → oferecer **reviver** no clímax.

---

## 10. Construção & economia de materiais na run  🔜
- Inimigos dropam **materiais** (madeira / **mana** / sucata).
- O jogador **carrega** os materiais; ao **parar perto de um local de construção**,
  **canaliza** a montagem/upgrade (barra de progresso) — não atira enquanto canaliza.
- Reforça a tensão **parado/seguro vs. perto-da-torre/arriscado**.

---

## 11. Moedas & meta-progressão (menu, entre partidas)  🔜
- **Duas moedas:** **Moeda de Batalha** (só na run: constrói/eleva torres, compra
  perks na run; zera ao fim) **×** **Moeda Meta** (permanente).
- **Habilidades são compradas** (meta). **Equipamentos** do herói. **Modificações
  das torres** (4 classes). Tudo no menu (o "Caminho do Herói" também é fora da run).
- **Árvore permanente bifurcada:** **Herói (DPS)** × **Comandante (estruturas)**.
- 🔜 (lente Century) **heróis colecionáveis** (gacha + fragmentos + estrelas +
  skills), **gear com sets**, e a **fusão com a cidade (Frontier)** como camada de
  recursos/pesquisa/idle entre batalhas (DNA Kingshot).
- Hoje (✅): `META{coins,gems,dmgLvl,rateLvl,clearedMax,seen,…}` em `localStorage`;
  upgrades `heroDmg()/heroCD()`; diária; gacha (100 gemas).

---

## 12. Modos & dificuldade  🔜 (1 já existe)
- **Defesa** (campanha) ✅ base — proteger a base + sobreviver; linear
  (`n ≤ clearedMax+1`).
- **Arena / Sala** 🔜 — salas fechadas; **perks do herói +60%**, **monstros +40%**
  mais fortes.
- **Escala** ✅: `diff = 1 + (n−1)·0.05` (multiplica HP); **monstro novo a cada 4
  níveis** (`pool = ROSTER.slice(0, ⌊(n−1)/4⌋+1)`); **chefe a cada 10**.
- **2500 fases** procedurais determinísticas ✅. 🔜 **capítulos temáticos**,
  estrelas por fase, auto/2x, e modos de evento (Cerco Infinito/Boss Rush).

---

## 13. Feedback / juice / áudio  ✅ base / 🔜 mais
- Partículas, **números flutuantes**, screen-shake, flash, **projéteis brilhantes**
  (`'lighter'`), **barras de vida** sobre inimigos, aura/marca de elites. ✅
- **Áudio WebAudio** sintetizado (sem arquivos) + **vibração**; **i18n PT/EN**. ✅
- 🔜 alta intensidade de projéteis + impacto (Archero), cinemáticas de chefe,
  cast do mago, feedback **focado no Caminho do Herói**.

---

## 14. Persistência / determinismo / arquitetura  ✅
- **Single-file** `bastion-rush/index.html`, **0 deps**, offline.
- **Procedural determinístico** (`genLevel(n)` com `mulberry(n)`): mesma fase = mesmo
  layout (o diretor adaptativo modula por cima).
- **Save** em `localStorage`; hooks de teste `window.BR` (incl. `BR.hero()`).
- **Verificação headless obrigatória** (sintaxe + screenshot Playwright + ler PNG +
  `ERROS=[]`) antes de commitar — ver `CLAUDE.md` §2.

---

## 15. Cortado (fora de escopo — confirmado)  ✂️
- Mapas 3D **verticalizados destrutíveis** (pilares/barris/pontes que desabam).
- **Bunker de reciclagem** (corpos → moedas).
- "Abate de torre → +5% cadência do herói".
- **Controle de linha de frente** (basta a escolha das 4 classes).

---

### Resumo do estado atual (✅ já jogável)
Mago 3D que se move e atira do orbe; 2500 fases lineares; 13+3 monstros com
comportamentos; elites; iluminação toon + luzes locais; câmera alta; herói preso à
tela; HAB/ULT; bestiário; menu CR-like; áudio/i18n; diária/gacha. **O grande
trabalho à frente é o §3–§11** (gating 10-hordas, vida do herói, 4 classes de
torre, perks/sinergias, 2 moedas + meta, diretor adaptativo) — ordem no `ROADMAP.md`.
