# NARRATIVE.md — A História de Bastion Rush

> **Roteiro 100% original.** Inspirado no *gênero* (defesa/ação estilo Kingdom
> Rush × Archero), **sem** reproduzir arte, nomes, textos ou personagens de
> terceiros. Tudo aqui foi escrito do zero para este jogo. Mundo, personagens e
> falas são exclusivos de *Bastion Rush*.

Este documento segue as **5 fases do processo de Narrative Design** (concepção →
estrutura → personagens → roteiro/integração → testes), aplicadas a um jogo de
**ação rápida com agência do jogador**: a história não é só assistida, ela é
*jogada*. Por isso o texto é **curto e cortável**, e a defesa do jogador é, ela
mesma, o arco dramático (ver Fase 5).

A implementação técnica vive em `bastion-rush/index.html` (blocos `INTRO`,
`INTERLUDES`, `ACTS`, `openStory`, `drawStory`). Este `.md` é a **fonte da
verdade do roteiro**; o código é o reflexo dele.

---

## Fase 1 — Concepção e Pilares (a base)

### Premissa básica (High Concept)
> **"O último mago vivo defende a derradeira fogueira do mundo contra uma horda
> de mortos famintos de calor — e descobre que apagar essa fogueira é o único
> jeito de salvar todo mundo."**

Uma frase, um conflito: **calor × fome**, com uma reviravolta moral embutida (a
solução exige sacrifício).

### Alinhamento com o gameplay (a história justifica as mecânicas)
O jogo é **ação rápida** (herói móvel que ataca sozinho, hordas vindo pelo
caminho, fases curtas). A narrativa **se dobra a isso**:

| Mecânica | Justificativa na história |
|---|---|
| Herói **invulnerável** que ataca sozinho | Pyr canaliza a **Chama**; enquanto há luz, ele não cai. |
| **Base com HP** no fim do caminho | É o **Bastião**, o farol que guarda a última brasa. Se apaga, tudo esfria. |
| **Hordas pela estrada** | A **Maré Cinérea** sobe pela única estrada do vale rumo à luz. |
| **Torres** construídas na run | Faróis-menores reacesos com **cristais de batalha** (calor recuperado dos mortos). |
| **Recompensa só na 1ª vez** | Cada fase é um trecho de estrada **reconquistado** — replay é treino, não conquista. |
| **2500 fases** subindo a dificuldade | A estrada **sobe** literalmente: do vale (Ato I) ao trono congelado de Vharn (Ato III). |
| **Variantes de elite** (fase 24+) | Os generais (Murm, Skarn) começam a **"abençoar"** tropas com o frio. |

**Regra de ouro do pacing:** nada de diálogo longo no meio do combate. A história
acontece **entre** as fases (interlúdios de 2–4 linhas) e no **cenário** (ver
Fase 4). O combate nunca para para "ler".

### Tom e Universo (Worldbuilding)
- **Atmosfera:** fantasia sombria *aconchegante* — melancólica, mas com calor
  humano. Não é grimdark niilista; é "a última vela acesa numa noite imensa".
- **Estética casa com o motor:** arena escura, braseiros quentes, neve azulada,
  low-poly PS2. O contraste **quente vs. frio** é o tema virando arte-direção.
- **Regras do mundo:**
  1. **Calor é vida e alma.** Onde o calor falha, a morte não descansa: levanta.
  2. **A Chama** é o último fogo "vivo" — não queima lenha, queima *vontade*.
  3. **O Longo Inverno** não é clima: é uma **entidade faminta** que faz pactos.
  4. **Pactos cobram juros eternos.** Quem troca calor por sobrevivência vira
     parte da Maré.
- **Escopo:** um **vale** (Auren), uma **estrada**, um **trono** no alto (Vharn).
  Pequeno de propósito — foco e clareza para o jogador mobile.

### Pilares narrativos (3 frases-guia para qualquer decisão de roteiro)
1. **Curto corta fundo.** Toda fala cabe em um respiro entre fases.
2. **O vilão tem razão pela metade.** Gorr fez o que o jogador faria por amor.
3. **A luz é o jogador.** No fim, o herói *é* a solução e o preço.

---

## Fase 2 — Estrutura Narrativa e Macrotrama

### Arco principal (3 atos clássicos)

**ATO I — A Vigília** *(fases 1–499)*
Introdução do conflito. O vale já caiu; o Bastião resiste. O jogador aprende a
defender. A ameaça ganha rosto: a Maré "sente" o calor da Chama e ataca com
vontade. Primeiros generais surgem no horizonte (Murm, o Colosso; Skarn, o
Algoz). **Pergunta dramática plantada:** *de onde vem esse frio?*

**ATO II — A Maré Sobe** *(fases 500–1499)*
Complicação. Defender não basta — o jogador parte para **reacender faróis** e
empurrar a Maré. Aqui vem a **virada de meio**: o frio é um **pacto** (o rei
Gorr trocou o calor do seu povo pela sobrevivência) **e** — pior — a própria
Chama do Bastião se alimenta do mesmo calor roubado. O herói não é tão "puro"
quanto pensava. **Aposta sobe:** vencer a Maré pode significar destruir a si.

**ATO III — O Rei Faminto** *(fases 1500–2500)*
Clímax e resolução. A estrada sobe a Vharn, o trono congelado. Gorr se revela
**trágico, não monstruoso**: oferece ao jogador o mesmo pacto. Clímax na fase
2500: Gorr cai — mas o ciclo só quebra se o Bastião **apagar** por escolha,
devolvendo o calor roubado ao vale. **Resolução agridoce:** a primavera volta a
Auren; a última luz (o herói) se entrega para que todos vivam.

### Draft de progressão (mapeamento marco a marco)
A história avança por **interlúdios de fase-marco** (tocam **1 vez**, no primeiro
clear). Implementados em `INTERLUDES[]`.

| Fase | Ato | Quem fala | Beat narrativo |
|---:|:--|:--|:--|
| (pré-1) | — | O Guardião | **Intro**: o mundo, o herói, a missão. |
| 10 | I | O Guardião | A Maré provou o calor da Chama; agora tem fome de verdade. |
| 50 | I | **Skarn, o Algoz** | O caçador se apresenta — corre à frente e marca os vivos. |
| 100 | I | O Guardião | As vilas se calam; **Murm, o Colosso** aparece no horizonte. |
| 250 | II | O Guardião | Vire o jogo: **reacenda os faróis**, empurre a Maré. |
| 500 | II | O Guardião | **Revelação 1:** o frio é um **pacto** feito pelo rei Gorr. |
| 1000 | II | O Guardião | **Revelação 2 (virada moral):** a Chama do Bastião também é calor **roubado**. |
| 1500 | III | O Guardião | A estrada sobe a **Vharn**, o trono congelado. |
| 2000 | III | **Gorr, o Rei Faminto** | O vilão se explica e **oferece o pacto** ao herói. |
| 2500 | III | O Guardião | **Final:** Gorr cai; apague o Bastião e devolva o calor. Primavera. |

> Os bosses de gameplay aparecem a cada 10 fases (`genLevel`); os interlúdios
> ficam nos **marcos-chave** acima para não interromper demais (Fase 5 / pacing).

### Definição de agência: **linear, com releitura**
- **Estrutura linear** (campanha de 2500 fases; vencer para avançar): garante que
  **todo jogador** vê o arco completo — ideal p/ mobile de sessão curta.
- **A agência está no *como*, não no *qual*:** o jogador escolhe rota, torres,
  habilidades, ritmo. A **persistência** dele *é* a narrativa (ver Pilar 3).
- **Final único, mas reenquadrado:** a fase 2500 transforma retroativamente tudo
  que o jogador fez ("você estava se queimando o tempo todo para nos aquecer").
  É o pagamento emocional sem precisar de ramificação cara.
- **Gancho p/ ramificação futura (opcional):** na fase 2000 Gorr oferece o pacto
  — base pronta para, um dia, um **final alternativo** ("aceitar o pacto") sem
  reescrever o jogo.

---

## Fase 3 — Desenvolvimento de Personagens

### Protagonista — **Pyr, o último Arcano** (o herói jogável)
- **Arquétipo:** o Guardião-relutante / portador da luz.
- **Quer:** manter a última Chama acesa e proteger os sobreviventes.
- **O que o impede:** a Maré é infinita e o próprio remédio (a Chama) é parte da
  doença (o pacto).
- **Se falhar:** o Bastião apaga, o vale congela para sempre, e Pyr vira só mais
  um faminto na Maré.
- **Perfil de gameplay:** mago **chibi** que **ataca sozinho** o alvo mais
  próximo (a Chama "decide" por ele — ele canaliza, não mira). Move-se com
  joystick; é **invulnerável** enquanto há luz (encarna a esperança literal).
  HAB (estouro de luz em área) e ULT (clarão que limpa a tela) = "a Chama
  transbordando". Silencioso no roteiro — é o **jogador** quem age.

### Mentor/Narrador — **O Guardião** (a Chama feita voz)
- **Arquétipo:** o velho sábio / a tocha que fala.
- **Quer:** que a luz sobreviva — a qualquer custo, **inclusive ele mesmo**.
- **Segredo:** sabe desde o início que o Bastião se alimenta de calor roubado;
  esconde do herói até a fase 1000 para não tirar sua esperança cedo demais.
- **Função:** dá objetivos, contexto e o peso emocional do final. Voz calorosa,
  cansada, paternal.

### Antagonista — **Gorr, o Rei Faminto** (boss final, `boss_king`)
- **Arquétipo:** o espelho trágico do herói (o que Pyr poderia virar).
- **Quer:** acabar com a própria fome eterna — calor que nunca o sacia.
- **Motivação (a "razão pela metade"):** era um rei amado de **Vharn**; para
  salvar seu povo da fome do Inverno, ofereceu o calor deles ao Inverno. O
  Inverno aceitou e **nunca devolveu** — condenando todos à não-morte faminta.
  Gorr não é maligno: é **um pai que pagou o preço errado por amor**.
- **Se "vencer":** o vale inteiro vira Maré e a fome se espalha pelo mundo.
- **Perfil de gameplay:** chefe final enorme, lento, coroado (`boss_king`, HP
  1000) — uma muralha de tristeza que o jogador precisa atravessar.

### Generais (coadjuvantes/bosses)
- **Murm, o Colosso** (`boss_tank`): a **avalanche em forma de gigante**. O
  escudo de Gorr; tanque imenso e lento. Pouca fala, pura ameaça física.
- **Skarn, o Algoz** (`boss_swift`): o **caçador da Maré**. Corre à frente,
  marca os vivos (casa com o comportamento `dasher`/`burst`). Provocador, rápido,
  cruel — o "rosto" ativo do inimigo no Ato I.

### O Bestiário como elenco (a Maré tem história)
Cada arquétipo de monstro é **gente que caiu** — reforça o tema "o inimigo já
foi como você". (Sabor narrativo; descrições in-game ficam curtas por clareza de
gameplay.)

| Tipo | Quem foi, antes do frio |
|---|---|
| Saqueador (`grunt`) | Aldeões — os primeiros a cair. |
| Batedor (`runner`) | Batedores de Skarn, marcando a estrada. |
| Escudeiro (`shield`) | A velha guarda da muralha de Vharn. |
| Brutamonte (`brute`) | Ferreiros engrossados pela geada. |
| Voador (`flier`) | Corvos-da-cinza, mensageiros do Inverno. |
| Curandeiro (`healer`) | Clérigos que rezaram **ao** Inverno. |
| Divisor (`splitter`) | Ninhos de gelo que estouram em cinza viva. |
| Espectro (`revenant`) | Mortos que se recusam a ficar mortos. |
| Investidor (`dasher`) | Caçadores marcados por Skarn. |
| Enxame (`swarm`) | A cinza viva — fome pura, sem rosto. |
| Couraçado (`armored`) | Cavaleiros de Vharn em armadura congelada. |
| Ogro (`ogre`) | Os "filhos" de Murm, gigantes menores. |
| Assombração (`wraith`) | A vontade de Gorr — sussurros que correm. |

---

## Fase 4 — Roteirização e Integração Sistêmica

### Escrita de diálogos e textos
- **Cutscenes (interlúdios):** ver `INTRO` e `INTERLUDES` em `index.html`. Cada
  uma: **2–4 linhas**, uma ideia por linha, sempre cortável com um toque.
- **Localização PT/EN:** todo texto é `{ pt, en }`, resolvido por `L()` e `t()`.
- **Tela de história (`drawStory`):** mostra **nome de quem fala** (título),
  **a linha atual**, **pontos de progresso** e "toque para continuar ›".
- **Voz por personagem:**
  - *Guardião* — caloroso, antigo, frases que terminam em esperança ou peso.
  - *Skarn* — curto, provocador, frio ("O frio sempre chega primeiro").
  - *Gorr* — melancólico, grandioso, convida em vez de ameaçar.
- **Barks de UI (já no jogo):** `banner('Fase N')`, "arraste p/ mover o herói",
  toasts de recompensa. São **diegéticos o suficiente** sem custar ritmo.

### Narrativa ambiental (Environmental Storytelling)
O cenário **já conta a história sem palavras** — alinhe futuras artes a isto:
- **Muralhas com portão ao fundo** = o Bastião sitiado.
- **Braseiros no lugar de árvores** = o calor é o recurso precioso; o vale
  perdeu a vida natural.
- **Chão de pedra escura + neblina + vinheta** = o mundo esfriando nas bordas,
  foco na ilha de luz central.
- **Estrada única subindo** = a jornada do vale ao trono (Ato I→III).
- **Aura/marca das elites (frio colorido)** = a "bênção" dos generais sobre a
  tropa, visível antes de qualquer texto.
- **A base é literalmente a última coisa quente da tela** — sua barra de HP é o
  termômetro emocional da fase.

> **Diretrizes para novas artes** (mantendo o tema): quanto mais **fundo** na
> estrada (fases altas/Ato III), mais **azul/gelo** o cenário; ruínas com
> pertences deixados (botas, brinquedos congelados) reforçam "aqui morava gente".

### Ferramentas narrativas
- O fluxo de cutscene é uma **máquina de estados leve** própria (`G.state ===
  'story'` + `G.story = { page, then, title, seq }` + `openStory(then,...)`),
  equivalente a um *grafo Twine/Ink* enxuto, suficiente para narrativa **linear**.
- `then` define o destino pós-cutscene (`'intro'` → começa a campanha; `'won'` →
  tela de vitória; `'menu'` → volta ao menu). Pronto para crescer (ex.: `then`
  ramificado) se um dia houver escolhas.

### Integração sistêmica (onde a história "encaixa" no código)
- `META.seenStory` — a intro toca **1 vez** (primeiro BATALHAR).
- `META.seenInterludes{}` — cada interlúdio de marco toca **1 vez** (no
  `firstClear` daquela fase, dentro de `win()`).
- `actTitle(n)` — rotula o Ato atual na tela de **Campanha** (estrutura visível).
- `TYPE_LABEL` / `MONSTER_DESC` — nomes próprios dos bosses (Murm/Skarn/Gorr).
- **Tudo persistente** no save (`localStorage`), então a história respeita o
  progresso entre sessões.

---

## Fase 5 — Testes e Refinamento (iteração)

### Pacing (ritmo)
- **Interlúdios só em 10 marcos** ao longo de 2500 fases → a história "pulsa"
  sem virar muro de texto. A densidade é **alta no Ato I** (10/50/100 — quando o
  jogador ainda está aprendendo o mundo) e **espaçada depois** (250→2500).
- **Cada cutscene é cortável** a qualquer toque: respeita o jogador apressado.
- **Combate nunca é interrompido** por diálogo: a narrativa fica nas bordas
  (antes da campanha, depois da vitória) e no cenário.

### Corte de excessos
- Linhas reduzidas a **uma ideia cada**; nada de parágrafos.
- Sem "lore dump": a maior parte do mundo (bestiário, Vharn, o pacto) é
  **opcional/ambiental**, não obrigatória de ler.
- Boss names curtos no bestiário (cabem no card sem cortar — verificado headless).

### Como testar (headless, sem navegador do usuário)
Hooks de teste em `window.BR`:
- `BR.intro()` — abre a introdução.
- `BR.interlude(lv)` — abre o interlúdio da fase `lv` (10/50/100/250/500/1000/
  1500/2000/2500).
- `BR.go('campaign')` + `BR.cleared(n)` — checar o rótulo de Ato.
- Idioma: `META.lang='en'` e reabrir para validar PT/EN.

**Verificado nesta entrega** (Playwright, viewport 460×880, `ERROS=[]`):
intro PT/EN, interlúdios 500 (3 linhas) e 2000 (fala do Gorr), rótulo "Ato III"
na Campanha, nomes de boss no Bestiário sem overflow, e os dois caminhos de
`win()` (fase 1 → vitória direta; fase 10 → interlúdio → vitória).

---

## Apêndice — Glossário do mundo (referência rápida)

| Termo | O que é |
|---|---|
| **Vale de Auren** | O reino-vale onde o jogo acontece; antes verde, agora gelado. |
| **A Chama / o Bastião** | A última fogueira viva e o farol-fortaleza que a guarda. |
| **O Longo Inverno** | A entidade-frio faminta que faz pactos e levanta os mortos. |
| **A Maré Cinérea** | A horda morta-viva que sobe a estrada rumo à luz. |
| **Vharn** | O reino caído de Gorr, hoje um trono congelado no alto da estrada. |
| **Pyr** | O último Arcano — o herói jogável, portador da fagulha. |
| **O Guardião** | A Chama feita voz; mentor e narrador. |
| **Gorr, o Rei Faminto** | Vilão trágico; trocou o calor do povo pela sobrevivência. |
| **Murm, o Colosso** | General-tanque de Gorr (avalanche viva). |
| **Skarn, o Algoz** | General-caçador de Gorr (rápido, marca os vivos). |

---

### Resumo em uma linha (para a loja/pitch)
> *Bastion Rush* — **Você é a última luz de um mundo que esfria.** Defenda a
> derradeira fogueira contra uma horda faminta, suba a estrada gelada até o trono
> do Rei Faminto e descubra que salvar todos custa exatamente uma chama: a sua.
