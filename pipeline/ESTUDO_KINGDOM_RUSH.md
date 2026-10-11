# Estudo: como a Ironhide fez o Kingdom Rush — e o que copiamos (o MÉTODO, não os assets)

Objetivo do desenvolvedor: **mesmo nível de resultado do Kingdom Rush**.
Nunca usar arquivos do APK/jogo deles — só aprender o método.

## 1. Fatos sobre o estúdio e o processo
- Ironhide (Montevidéu, Uruguai), 3 fundadores; KR1 feito em **~6 meses** por 3 pessoas.
  Artista único: **Gonzalo Sande** ("Gonzasan"). Lançado em Flash (AS3) em 2011,
  refeito do zero em Objective-C + cocos2d para iOS, depois Unity (C#) no Steam.
- Toda a arte **e animação** feita **direto no Flash, em vetor**, com mesa digitalizadora
  (pressão = **variação de espessura da linha**), quase sem rascunho.
- Volume com **3+ tons chapados da mesma cor**, **sem gradiente**. Textura só sugerida
  com formas/padrões (riscos, manchas), nunca textura pintada.
- **Sem preto puro**; cores **levemente dessaturadas** (um toque de cinza) — por isso
  tudo combina e nada "grita".
- Animação **quadro a quadro**, exportada como **sprite sheets** rasterizadas.
- Os personagens na tela são **pequenos** (silhueta é tudo): cabeça grande, arma grande,
  cor de identificação forte por tipo.

Fontes: fórum Ironhide "Kingdom Rush Art style" e "How are the sprites made?";
Wikipedia "Kingdom Rush"; carta "An Open Love Letter to our PC Fans" (ironhidegames.com);
Game Developer "Kingdom Rush – the wonderful campaign level design"; entrevista Kodeco.

## 2. O que faz o KR parecer KR (checklist visual)
1. **Mapa = uma pintura só** por fase (vista 3/4 de cima), com a estrada de terra bem
   legível e os **círculos de construção** marcados; bordas cheias de árvores/pedras.
2. **Decoração animada no mapa**: água correndo, moinhos, fumaça, pássaros, bandeiras,
   NPCs/easter eggs clicáveis. Pequena, em loop, barata.
3. **Torre = prédio estático + unidades animadas em cima** (os arqueiros na ameia
   puxam o arco e atiram; o mago brilha; o canhão recua). O prédio muda de desenho a
   cada nível (I, II, III) e nas 2 especializações do nível 4.
4. **Inimigos andam em 3 direções**: de lado (espelhado esq/dir), **de frente (descendo)**
   e **de costas (subindo)** — cada uma com seu ciclo de andar. Ataque, morte (cai,
   some com fumacinha/sangue cartoon) e às vezes habilidade.
5. **Efeitos desenhados**: flecha girando em arco, bomba em parábola com sombra no chão,
   explosão em quadros, raio, poça, "puf" de fumaça, números de ouro, sangue cartoon
   (verde/roxo para monstros).
6. **UI de madeira/pergaminho**, ícones grandes, anel de construção radial, caveira
   pulsando para chamar onda cedo (bônus de ouro), dois poderes no canto (Chuva de
   Fogo / Reforços), 3 estrelas por fase, enciclopédia.
7. **Sombra oval** sob cada unidade; unidades ordenadas por profundidade (quem está
   mais embaixo na tela fica na frente).

## 3. Design de jogo (lições)
- Construção **só nos círculos perto da estrada** → escassez de espaço é a estratégia.
- 4 torres-base (Arqueiro, Quartel, Mago, Artilharia), 3 níveis + 2 especializações.
- **Quartel/soldados bloqueiam** a estrada → é o que diferencia o KR.
- Contra-jogo legível: **armadura física** (mago resolve), **resistência mágica**
  (arqueiro/artilharia resolvem), **voadores** (só arqueiro/mago acertam), rápidos
  (passam do suporte), tanques, curandeiros, chefes com fases.
- Prévia da onda (caveira mostra quem vem) + chamar cedo dá ouro.
- 3 estrelas por vidas restantes; modos Heroico/Ferro depois; árvore de melhorias por estrelas.

## 4. Adaptação para o NOSSO pipeline (IA no lugar do Flash)
| KR | Bastion Rush |
|---|---|
| Vetor no Flash com 3+ tons | Canva com âncora de estilo; prompt pede **3 tons chapados, linha com variação, sem preto puro, cores levemente dessaturadas** |
| ~8–16 quadros por ação | Folhas de **4 quadros-chave** da IA + motor faz o "entre-quadros" (squash, bob, lunge) — já existe em `model_rig.gd` |
| Andar em 3 direções | Animações `walk` (lado), **`walk_down`** (frente), **`walk_up`** (costas); motor escolhe pela direção do movimento |
| Torre + atiradores animados | `towers/<família>.png` (prédio) + `anims/tower_<família>/{idle,attack}_k.png` (atirador por cima) |
| Efeitos desenhados | `fx/<nome>_<k>.png` tocados por um sistema de efeitos 2D |
| Mapa pintado + decoração animada | `battle/<reino>.png` + `fx/` em loop posicionados em `GameData.PAINTED` |

## 5. Proposta de ajuste no padrão (precisa de OK das duas sessões + do dev)
O PADRAO_DE_ARTE.md diz "um tom de sombra". O KR usa **3 tons** e **sem preto puro**.
Proposta: trocar o bloco STYLE por
```
Simple flat 2D cartoon in the style of classic tower-defense games like Kingdom Rush, matching
the red ogre reference: bold outlines with slight line-weight variation in very dark warm brown
(never pure black), each color shaded with 2-3 flat tones (no gradients, no painted texture),
slightly muted colors, chunky rounded shapes, big head, big readable silhouette.
Plain pure white background, no ground, no text, no frame borders.
```
(continua usando o ogro como âncora — ele já é quase isso.)
