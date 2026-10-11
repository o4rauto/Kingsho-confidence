# Estudo: como a Ironhide fez o Kingdom Rush — e como replicar no nosso Godot

> Objetivo do dev: **mesmo nível de resultado** do Kingdom Rush. Este doc é o
> estudo (LOCAL começa; CLOUD completa) antes de voltar a produzir. Em aberto =
> marcado com ❓. Nada de "achismo" vendido como fato.

## 1. Fatos confirmados (com fonte)

- **Motor original = Adobe Flash / ActionScript 3**, jogado no navegador
  (Armor Games / Kongregate, 2011). Código escrito no **FlashDevelop**.
- **Divisão da dupla fundadora:** Pablo Realini = programação; **Gonzalo Sande =
  TODA a arte e a animação**, feitas **dentro do Flash**, desenhando **à mão com
  tablet** (ele cita usar a sensibilidade à pressão do tablet no Flash).
- Runtime usa **sprites de bitmap** ("bitmap fills / sprites of bitmaps").
- **Port para iOS** feito pelo Realini em ~4 meses; +100 milhões de downloads.
- Estilo de arte: **cartum detalhado, chapado, contorno marcado** (Sande).

Ou seja: a arte do KR **não** é "1 PNG conceito + 4 quadros". É **animação
quadro a quadro / recorte, desenhada à mão por um artista no Flash**, e entregue
ao jogo como **sequências de bitmap (sprite sheets)**.

## 2. Como funciona na prática (confirmado + inferido, marcado)

- **Autoria (Flash):** cada unidade é um *MovieClip* com uma timeline de
  animação. O artista combina **quadro a quadro** (desenhado à mão) com
  **tween/recorte** (girar/mover peças do boneco na timeline) → movimento liso
  com poucos desenhos-chave. ✅ autoria à mão no Flash confirmada; ⬦ a mistura
  tween+quadro-a-quadro é o fluxo padrão do Flash (inferido).
- **Runtime (mobile):** ⬦ inferido — o padrão Flash→mobile da época é
  **Adobe AIR + Starling (Stage3D/GPU)** com **texture atlases**: a animação do
  Flash é **rasterizada em quadros bitmap** e empacotada em folhas. No aparelho
  roda **sprite-sheet frame-by-frame** (barato na GPU), não um rig vivo.
- **Resolução:** ⬦ arte feita grande e escalada por aparelho (HD). ❓ número
  exato de quadros por animação e tamanho do canvas por unidade — não achei fonte.
- **Jogos novos (Iron Marines 2017+, KR Vengeance):** ❓ provável migração para
  **Unity + Spine (esqueleto 2D)** — NÃO confirmado nas fontes que acessei. CLOUD
  deve verificar.

### Lição central
O "segredo" do KR é **um artista animando à mão, liso, com muitos quadros/tween**,
entregue como **bitmaps**. Qualidade vem de (a) desenho limpo, (b) animação com
antecipação/overshoot/follow-through, (c) muitos quadros, (d) silhueta legível.
Não há atalho mágico — mas dá pra chegar perto com **rig + bake de quadros**.

## 3. O que testei aqui (protótipo LOCAL) — o que funciona e o que bugou

Experimento feito nesta sessão (código do rig está LOCAL, **não commitado**):

- ✅ **Canva gera no estilo certo** (chapado, contorno grosso) com o ogro
  `MAHXvKTpLPs` de referência + bloco STYLE. Consegui o warden em **perfil 3/4**
  (media `MAHXvdqRzAE`) e uma versão **sem fundo / transparente** via
  `remove-background` (media `MAHXvt1sVXk`).
- ✅ **Arquitetura de fantoche de recorte funciona no Godot**: criei
  `ModelRig.setup_puppet()` + `_animate_puppet()` e um carregador de
  `assets/art/rigs/<id>/rig.json`. O warden montou (corpo/cabeça/2 braços) e
  animou (parado/andar/atacar/morrer) **sem erro de script**, com flip de direção.
- ❌ **Gargalo = qualidade da peça de origem.** Cortei um **JPG de 200px com
  fundo branco** em peças → deu **franja branca**, **branco preso dentro do arco**,
  **emendas das caixas** e **buracos** quando removi branco agressivo. Ficou
  "bugado" (o dev viu e reprovou, com razão).

### Conclusões do teste
1. **Não dá pra cortar arte chapada de baixa-res / fundo branco** e esperar
   qualidade KR. Precisa de **PNG transparente de alta resolução**.
2. A **limitação do Canva na nuvem/thumbnail** é 200px JPG (perde alfa). A
   alta-res (1264) só vem por **download autenticado** (dev clicando no
   `import_canva.py`) **ou** por **exportar um *design* do Canva** (PNG
   transparente) e baixar com `curl` — caminho ainda a validar.
3. A **arquitetura do rig é boa**; o trabalho pesado é **gerar/obter peças
   limpas e separadas** (como o artista do KR fazia à mão).

## 4. Plano de replicação no nosso Godot 4.3 (opções)

**Fonte de arte (a parte crítica):** obter cada unidade como **PNG transparente,
alta-res**, e separada em peças limpas. Rotas, da melhor pra pior:
- (R1) Canva `generate-image` → `remove-background` → **export do design em PNG
  transparente** (1264px) → `curl` local. [validar o export de design]
- (R2) Canva `separate-image-layers` pra quebrar o personagem em elementos →
  export de cada camada transparente. [testar se separa anatomia de forma útil]
- (R3) Dev baixa a alta-res pelo `import_canva.py` (fluxo já existente).

**Animação (duas opções, podem se combinar — igual ao KR):**
- **A) Rig de recorte em runtime** (fantoche no Godot; protótipo já existe). Poucos
  assets, liso, flip grátis. Exige peças limpas + pivôs.
- **B) Bake de quadros**: animo o rig no Godot e **exporto folhas de sprite com
  muitos quadros** (12–16), que é **exatamente o runtime do KR** (bitmaps) e
  reusa o sistema de frames que o jogo já tem (`asset_lib.anim_frames`).
- **Recomendação:** **A pra autoria + B pro runtime** — rigar uma vez, bakear
  quadros lisos por unidade. Caminho idêntico ao do KR (animar → rasterizar).

**Qualidade (regras tipo KR):** contorno grosso uniforme, cores chapadas + 1
sombra, silhueta legível; animação com antecipação, overshoot e follow-through;
12+ quadros por ciclo; pés plantados; sombra no chão.

## 5. Divisão de trabalho proposta (LOCAL × CLOUD)

**LOCAL (PC do dev) — o que só eu consigo:**
- Gerar no Canva em alta-res (remove-bg + export), **baixar os pixels de verdade**.
- Cortar/limpar peças, montar rigs, **bakear quadros**, rodar **Godot** (headless,
  prints e GIFs), importar pro jogo, commitar/push.

**CLOUD — pesquisa e specs (não depende do PC):**
- Confirmar os pontos ❓: ferramentas dos jogos novos (Unity/Spine?), nº de quadros
  por animação, canvas, breakdowns/GDC, achar o fórum da Ironhide por outro caminho.
- Escrever a **spec de animação por tipo de unidade** (quais anims, timing, quadros)
  e **reescrever o `PADRAO_DE_ARTE.md`** pra essa estrutura (rig + bake).
- Fase C (projéteis/efeitos 2D) e código **que não seja** o de personagem/rig.
- Preparar prompts de arte e specs de rig.pivô pra eu executar.

## 6. Perguntas em aberto (pro CLOUD e pro dev)

- ❓ **A ou B** (rig runtime vs frames bakeados) como padrão? (recomendo A+B)
- ❓ Alvo de **resolução por unidade** e **nº de quadros** por animação?
- ❓ Validar o **export de design do Canva** como fonte de PNG transparente alta-res
  automática (senão, dependemos do dev baixar).
- ❓ Quantas unidades no total e qual **prazo/ambição** (define quanto dá pra
  caprichar por unidade)?
- ❓ Vale testar **Spine** de verdade (há runtime de Spine pra Godot) pra chegar
  no "mesmo nível", ou ficamos no rig próprio + bake?

## Fontes
- Wikipedia — Kingdom Rush: https://en.wikipedia.org/wiki/Kingdom_Rush
  (Realini=programação, Sande=arte "cartum detalhado", base Flash, port iOS)
- Wikipedia — Iron Marines: https://en.wikipedia.org/wiki/Iron_Marines
- Fandom — Ironhide Game Studio: https://kingdomrushtd.fandom.com/wiki/Ironhide_Game_Studio
- Esoteric Software — Spine (esqueleto 2D): http://esotericsoftware.com/
- (Buscas) declarações do artista Gonzalo Sande: toda arte/animação no Flash, à
  mão com tablet; runtime em sprites de bitmap; código no FlashDevelop.
  Fórum oficial `forums.ironhidegames.com` está **fora do ar** (ENOTFOUND) e o
  Wayback está bloqueado aqui → CLOUD tentar por outro proxy.
