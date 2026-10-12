# Estudo: como a Ironhide fez o Kingdom Rush — e como replicar (o MÉTODO, nunca os assets)

> Objetivo do dev: **mesmo nível de resultado do Kingdom Rush**. Estudo feito pelas
> DUAS sessões (LOCAL = no PC; CLOUD = na nuvem). Nunca usar arquivos do APK/jogo
> deles — só aprender o método. ✅ = confirmado com fonte · ⬦ = inferido · ❓ = em aberto.

---

## 1. Fatos sobre o estúdio e o processo (confirmado)

- ✅ Ironhide (Montevidéu, Uruguai), **3 fundadores**; **KR1 feito em ~6 meses** por 3
  pessoas. Artista único: **Gonzalo Sande** ("Gonzasan"). Programação: Pablo Realini.
- ✅ Lançado em **Flash (ActionScript 3)** em 2011 (Armor Games/Kongregate), código no
  **FlashDevelop**. Depois **refeito do zero em Objective-C + cocos2d** para iOS, e mais
  tarde **Unity (C#)** no Steam/PC. (Correção: não foi AIR/Starling como a 1ª rodada
  LOCAL supôs.)
- ✅ Toda a arte **e a animação** feitas **direto no Flash, em vetor**, com mesa
  digitalizadora (pressão da caneta = **variação de espessura da linha**), quase sem rascunho.
- ✅ Volume com **3+ tons chapados** da mesma cor, **sem gradiente**; textura só sugerida
  com formas (riscos/manchas), nunca pintada. **Sem preto puro**; cores **levemente
  dessaturadas** (um toque de cinza) — por isso tudo combina.
- ✅ Animação **quadro a quadro**, exportada como **sprite sheets** (bitmaps) pro runtime.
- ✅ Personagens aparecem **pequenos** na tela → **silhueta é tudo**: cabeça grande, arma
  grande, cor de identificação forte por tipo.
- ❓ Número exato de quadros por animação e tamanho de canvas por unidade — sem fonte firme
  (estimativa ⬦ ~8–16 quadros por ação).

Fontes: fórum Ironhide "Kingdom Rush Art style" / "How are the sprites made?"; Wikipedia
"Kingdom Rush" e "Iron Marines"; carta "An Open Love Letter to our PC Fans"
(ironhidegames.com); Game Developer "Kingdom Rush – level design"; entrevista Kodeco;
Fandom "Ironhide Game Studio"; Esoteric Software (Spine). (O fórum e o Wayback
**não abriram pela LOCAL** — a CLOUD conseguiu.)

## 2. O que faz o KR parecer KR (checklist visual)
1. **Mapa = uma pintura só** por fase (vista 3/4 de cima), estrada de terra bem legível,
   **círculos de construção** marcados, bordas cheias de árvores/pedras.
2. **Decoração animada no mapa**: água, moinhos, fumaça, pássaros, bandeiras, NPCs
   clicáveis. Pequena, em loop, barata.
3. **Torre = prédio estático + unidades animadas em cima** (arqueiros puxam o arco; mago
   brilha; canhão recua). O prédio muda de desenho por nível (I, II, III) e nas 2
   especializações do nível 4.
4. **Inimigos andam em 3 direções**: de lado (espelhado), **de frente (descendo)** e **de
   costas (subindo)** — cada uma com seu ciclo. + ataque, morte (cai e some com
   fumacinha/sangue cartoon) e às vezes habilidade.
5. **Efeitos desenhados**: flecha em arco, bomba em parábola com sombra, explosão em
   quadros, raio, poça, "puf" de fumaça, números de ouro, sangue cartoon (verde/roxo).
6. **UI de madeira/pergaminho**, ícones grandes, anel de construção radial, caveira
   pulsando (chamar onda cedo = ouro), 2 poderes no canto, 3 estrelas por fase, enciclopédia.
7. **Sombra oval** sob cada unidade; ordenação por profundidade (quem está mais embaixo
   fica na frente).

## 3. Design de jogo (lições)
- Construção **só nos círculos perto da estrada** → escassez de espaço é a estratégia.
- 4 torres-base (Arqueiro, Quartel, Mago, Artilharia), 3 níveis + 2 especializações.
- **Quartel/soldados bloqueiam** a estrada → marca registrada do KR.
- Contra-jogo legível: **armadura física** (mago resolve), **resistência mágica**
  (arqueiro/artilharia), **voadores** (só arqueiro/mago), rápidos, tanques, curandeiros,
  chefes com fases. Prévia da onda + chamar cedo dá ouro. 3 estrelas; Heroico/Ferro; árvore.

## 4. O que a LOCAL testou aqui (protótipo) — o que funciona e o que bugou
Experimento desta sessão (código do rig está **LOCAL, não commitado**):
- ✅ **Canva gera no estilo certo** com o ogro `MAHXvKTpLPs` + bloco STYLE. Warden em
  **perfil 3/4** (media `MAHXvdqRzAE`) e versão **sem fundo/transparente** via
  `remove-background` (media `MAHXvt1sVXk`).
- ✅ **Fantoche de recorte funciona no Godot**: `ModelRig.setup_puppet()` +
  `_animate_puppet()` + carregador de `assets/art/rigs/<id>/rig.json`. Warden montou
  (corpo/cabeça/2 braços) e animou (parado/andar/atacar/morrer) **sem erro**, com flip.
- ❌ **Gargalo = peça de origem ruim.** Cortar um **JPG 200px com fundo branco** deu
  **franja, branco preso (arco), emendas e buracos**. "Bugado" (dev reprovou, com razão).
- **Lições:** (a) precisa de **PNG transparente de alta-res** antes de cortar; (b) o Canva
  via thumbnail só dá **200px JPG** (perde alfa) — alta-res só por **download autenticado
  (`import_canva.py`)** ou **exportar um *design* do Canva** (PNG transparente) + `curl`
  [a validar]; (c) a arquitetura do rig é boa, o custo está em **obter peças limpas**.

## 5. ⚖️ DECISÃO-CHAVE EM ABERTO: como animar (pro dev decidir)
As duas sessões chegaram a abordagens diferentes. Não dá pra ter "o mesmo nível do KR"
sem escolher. Opções:

- **A) 4 quadros-chave da IA + "entre-quadros" do motor** (proposta CLOUD; é o que já
  existe em `model_rig.gd`: squash/bob/lunge). + `walk_down`/`walk_up`. **Barato e rápido**,
  mas o KR NÃO faz assim (eles têm muitos quadros à mão) → risco de ficar "ok", não "KR".
- **B) Rig de recorte 2D no Godot + bake de quadros** (proposta LOCAL; protótipo pronto):
  desenha 1x, corta em peças, anima os ossos liso, e **rasteriza em sprite sheets** —
  **exatamente o runtime do KR** (bitmaps). Mais trabalho de montar; depende de peças limpas.
- **C) Spine de verdade** (há runtime de Spine pra Godot): esqueleto 2D profissional,
  o mais perto do "mesmo nível", mas Spine **é pago** (ferramenta de autoria) → **custa
  dinheiro**, então só com aval do dev.

**Recomendação conjunta a propor:** **B** (rig + bake) como caminho principal — mesmo
método do KR (animar → bitmaps), sem custo, e dá pra `walk/walk_down/walk_up` girando o
rig. **A** vale como fallback enquanto a arte não chega. **C** só se o dev topar o custo.
➡️ **LOCAL e CLOUD precisam bater o martelo aqui, e o dev confirmar.**

## 6. Divisão de trabalho proposta (as duas concordam no grosso)
- **LOCAL = arte + Godot** (só eu baixo alta-res e rodo o motor): gerar no Canva,
  remove-bg, baixar os pixels, cortar/limpar peças, montar rigs, **bakear quadros**, rodar
  headless/prints/GIFs, importar, commitar. Começa pelo **Reino 1**.
- **CLOUD = código + specs + pesquisa** (sem tocar em `portraits/`, `anims/`, `rigs/`,
  `canva_art.json`, nem nos scripts de personagem/rig enquanto a LOCAL mexe):
  1. Escolha de `walk/walk_down/walk_up` pela direção (fallback pro parado).
  2. Torres: camada de atirador animado sobre o prédio
     (`anims/tower_<família>/{idle,attack}_k.png`), recuo/disparo.
  3. Sistema de **efeitos 2D** (`fx/<nome>_<k>.png`): projétil em arco+sombra, explosão,
     fumaça, raio, cura; trocar os anéis/esferas 3D atuais (Fase C).
  4. Ordenação por profundidade + sombra oval; decoração animada no mapa.
  5. Prévias dos menus com os desenhos (sem 3D).
  Tudo com **fallback** (funciona antes de a arte chegar).
- **Contrato de nomes** (LOCAL gera, CLOUD lê):
  `anims/<id>/{idle,walk,walk_down,walk_up,attack,cast,hit,die,fly}_<k>.png`;
  `anims/tower_<família>/{idle,attack}_<k>.png`; `fx/<nome>_<k>.png`.
  fx: arrow, bolt, cannonball, magic_orb, fireball, poison_drop, lightning, explosion,
  smoke_puff, heal, shield, freeze, coin. (Se formos de rig+bake, o bake produz esses
  mesmos arquivos — o contrato continua valendo.)

## 7. Perguntas em aberto (pro dev)
- ❓ **Abordagem de animação: A, B ou C?** (recomendamos B; C custa dinheiro.)
- ❓ Alvo de **resolução por unidade** e **nº de quadros** por animação.
- ❓ Validar o **export de design do Canva** como fonte de PNG transparente alta-res
  automática (senão dependemos do dev baixar).
- ❓ **Quantas unidades** e **prazo/ambição** (define o capricho por unidade).
- ❓ Trocar o STYLE pra "3 tons, sem preto puro, levemente dessaturado" (abaixo)?

## 8. Proposta de STYLE novo (mantendo o ogro de âncora)
O PADRAO atual diz "um tom de sombra"; o KR usa **3 tons** e **sem preto puro**:
```
Simple flat 2D cartoon in the style of classic tower-defense games like Kingdom Rush, matching
the red ogre reference: bold outlines with slight line-weight variation in very dark warm brown
(never pure black), each color shaded with 2-3 flat tones (no gradients, no painted texture),
slightly muted colors, chunky rounded shapes, big head, big readable silhouette.
Plain pure white background, no ground, no text, no frame borders.
```

## Fontes
- Wikipedia — Kingdom Rush: https://en.wikipedia.org/wiki/Kingdom_Rush
- Wikipedia — Iron Marines: https://en.wikipedia.org/wiki/Iron_Marines
- Fandom — Ironhide Game Studio: https://kingdomrushtd.fandom.com/wiki/Ironhide_Game_Studio
- Esoteric Software — Spine (esqueleto 2D): http://esotericsoftware.com/
- Ironhide: carta "An Open Love Letter to our PC Fans" (ironhidegames.com); fórum oficial
  (Art style / How are the sprites made?) — acessível só pela CLOUD; Game Developer
  (level design); entrevista Kodeco. Declarações do artista Gonzalo Sande: toda
  arte/animação em vetor no Flash, à mão com tablet; runtime em sprites bitmap.
