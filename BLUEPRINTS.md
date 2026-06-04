# BLUEPRINTS — como funcionam "Archero" e "Kingdom Rush" (referência de gênero)

> Esqueleto **funcional** dos dois pilares do Bastion Rush. Descreve **mecânicas e
> padrões de sistema** (não protegidos por direitos autorais) — **sem** copiar
> arte, nomes, textos ou balanceamento específico. Serve para projetar a **fusão**
> original (ver `MECHANICS.md`). Números são **aproximados/típicos** do gênero.

---

# A) ARCHERO — roguelite de ação (sala a sala)

**Fantasia (1 linha):** herói solitário limpa salas de monstros; *parar = atira,
mover = desvia*.

### 1. Estrutura de sessão (loop macro)
- **Capítulo** = sequência longa de **salas** (dezenas). Você inicia uma **run**;
  limpa sala após sala; **morrer encerra a run**. Início de run **gasta energia**.
- Salas especiais intercaladas: **cura/anjo**, **sacrifício/diabo** (ganha-perde),
  **loja**, **tesouro**, e **chefe** a cada N salas.

### 2. Combate (loop micro) — o coração
- **Auto-ataque só quando PARADO**; **mover = não atira** (mecânica-assinatura).
- Joystick virtual; herói **auto-mira** no inimigo mais próximo.
- Jogo é **bullet-dodging**: você anda pra desviar de projéteis/contato e **para**
  em janelas seguras pra causar dano.

### 3. Estrutura de sala
- Inimigos aparecem em **ondas dentro da sala**; **limpar tudo abre a saída** →
  próxima sala. (Não há "caminho/base" — é arena fechada.)

### 4. Progressão NA run (roguelite)
- Limpar sala dá **XP**; ao **subir de nível na run** → **escolhe 1 de 3
  habilidades** de um pool aleatório. **Empilham e fazem sinergia**: multishot,
  flechas diagonais/traseiras, ricochete, perfurante, quica-na-parede, **elementais**
  (fogo/veneno/raio), lifesteal, escudo, etc.
- **Resetam a cada run** (é roguelite). **Variedade de build = rejogabilidade.**
- Habilidades têm **raridade** (efeitos maiores em épico/lendário).

### 5. Meta-progressão (permanente, fora da run)
- **Equipamento** (arma, armadura, anel, etc. + **pet/espírito**): **raridades**
  (comum→lendário→mítico), evoluído com ouro + materiais, **fundido** pra subir
  de tier. **A arma define o padrão de tiro base.**
- **Talentos** (árvore de stats permanente, comprada com ouro).
- **Heróis colecionáveis** (cada um com passiva; sobe com fragmentos/gemas).
- **Livros/pergaminhos** que **desbloqueiam novas habilidades** no pool da run.

### 6. Economia & moedas
- **Ouro** (mole; upgrades), **Gemas** (premium), **Energia** (porta as runs),
  **fragmentos/pergaminhos** (gear/heróis), **chaves** (baús), tokens de evento.

### 7. Inimigos & contadores
- Atiradores, corpo-a-corpo, voadores, "tanques", invocadores; **perigos no
  cenário** (espinhos, lava, paredes móveis). O contador é **posicionamento + build**.

### 8. Dificuldade & conteúdo
- Capítulos escalam HP/dano e introduzem inimigos/perigos novos + **chefes**.
- **Morte = recomeço** (do capítulo/checkpoint). Você **grinda gear** pra furar a parede.

### 9. Controles/UX
- **Um polegar** (joystick); mira/ataque **automáticos**. Altíssima acessibilidade.

### 10. Monetização
- Recarga de energia, packs de gema, **baús de gear (gacha)**, passe de batalha,
  **anúncios** (reviver na morte, x2 loot, gema grátis), starter packs, ofertas-relâmpago.
  O **reviver-na-morte** é o momento-chave de gasto.

### 11. Retenção
- **Timers de energia** (volte depois), missões diárias, eventos, **caça ao gear**
  (RNG), ofertas agressivas.

### 12. Tensão central ("segredo")
- **Parar-pra-atirar × mover-pra-desviar** = micro-decisão constante.
- **Aleatoriedade de build** + **power fantasy do gear**. Sessões curtas, dopamina alta.

---

# B) KINGDOM RUSH — tower defense (caminho fixo + ondas)

**Fantasia (1 linha):** comandante posiciona **torres** pra parar **ondas** que
marcham por um **caminho fixo**.

### 1. Estrutura de sessão (loop macro)
- **Campanha** = sequência de **mapas feitos à mão** (caminho fixo, às vezes com
  bifurcações). Desbloqueio linear + mapas extras.
- Por mapa: defender uma **sequência roteirizada de ondas**; o jogo é **pausável**.
- **Rejogar** por **estrelas** (modos Casual/Normal/Veterano/Impossível) e por
  **desafios** (ex.: torres limitadas / sem habilidades).

### 2. Combate (loop micro) — defesa
- **Slots de construção fixos** → escolhe **1 de 4 classes** de torre; cada uma
  **3 níveis** + **especialização de 4º nível** (duas pontas únicas que **mudam o
  comportamento**).
- **4 classes (pedra-papel-tesoura):**
  - **Arqueiro** — rápido, barato, **single-target** físico.
  - **Mago** — mais lento, **dano mágico ignora armadura**.
  - **Quartel** — **invoca soldados** que **BLOQUEIAM/seguram** inimigos no
    caminho corpo-a-corpo (**o único "bloqueador"** — controla o ritmo).
  - **Artilharia** — **bombas em área**, lenta; ótima vs. grupos, **não acerta
    voadores**.
- **Herói** controlável (anda no mapa, auto + **habilidades ativas**, sobe de
  nível, **renasce** após morrer).
- **Magias do jogador** (cooldown): um **dano em área** + **reforços** (convoca
  soldados) — a intervenção direta.

### 3. Estrutura de fase
- **Ondas pré-definidas** de inimigos do spawn até a saída. Inimigo que **escapa**
  tira **vidas**; **zerar vidas = derrota**; **sobreviver às ondas = vitória**.

### 4. Economia DENTRO da fase
- **Ouro por abate** (+ ouro inicial) → gasta **durante a fase** pra construir/subir/
  **vender** torres. **Reseta a cada fase** (não acumula entre mapas).

### 5. Progressão ENTRE fases (meta)
- **Estrelas** (até 3 por mapa, ganhas em modos/desafios mais difíceis) → gastas
  numa **árvore de upgrades global** (torres/magias/herói) que **persiste**.
- Pouco "grind de moeda" — é **perícia + estrelas**. **Heróis** premium à parte.

### 6. Inimigos & contadores (o xadrez)
- **Armadura** (→ mago), **rápidos** (→ lentidão/bloqueio), **voadores** (→ arqueiro/
  mago; artilharia não pega), **curandeiros/invocadores**, **chefes**. A graça é
  **montar a composição certa** + **posicionar** nos **chokepoints**.

### 7. Dificuldade & conteúdo
- Mapas + scripts de onda **à mão**; modos de dificuldade; **desafios heroic/iron**
  por mapa (mais estrelas); modos extra/endless. **Domínio por rejogo.**

### 8. Controles/UX
- **Toque** pra construir/subir/vender/selecionar; toque pra **magias**; arrastar
  o herói. **Estratégia pausável.**

### 9. Monetização
- Clássico: **premium** (compra única) + **heróis pagos** + skins/torres extra.
  **Não** é F2P agressivo (nos títulos originais).

### 10. Tensão central ("segredo")
- **Composição + posicionamento + timing** contra um script conhecido mas
  crescente. As 4 classes são **contadores** dos tipos de inimigo; o **bloqueador
  (quartel)** é o pivô que **controla o ritmo** do caminho.

---

# C) Comparação rápida

| Eixo | Archero | Kingdom Rush |
|---|---|---|
| Unidade do jogador | **1 herói móvel** | **torres fixas** (+ herói) |
| Ataque | auto, **só parado** | torres automáticas |
| Estrutura | **salas** (limpar abre saída) | **caminho + ondas** (não escapar) |
| Progressão na partida | **3-de-3 perks** (roguelite) | **ouro → torres** (some no fim) |
| Meta | gear + heróis + talentos | **estrelas → árvore** |
| Falha | **morre → fim da run** | **vidas zeram → derrota** |
| Ritmo | reflexo/dodge | planejamento/posição |
| Monetização | F2P agressivo | premium |

---

# D) O que cada um entrega para o Bastion Rush (fusão)

**De Archero →** herói **mago móvel**; **parar-pra-atirar / mover-pra-desviar**;
**3-de-3 perks** por horda; **vida do herói** (pode morrer); **gear/heróis** no meta;
energia/revive; dopamina de build. *(MECHANICS §4, §5, §11)*

**De Kingdom Rush →** **4 classes de torre** (incl. o **bloqueador/quartel**);
**4º nível = especialização**; **ouro durante a partida**; **árvore meta**;
inimigos como **contadores**; **chefes**; magias do jogador. *(MECHANICS §6, §11, §12)*

**A fusão (o que nenhum dos dois tem sozinho):**
- **Herói + torres coexistem** → o dilema **parar (atira e dá +20% à torre no raio)
  × mover (desvia, não atira)**. *(MECHANICS §4, §6 torre-humana)*
- **Sinergias herói×torre** (condutor, killshot, espelho, ímã, necromante). *(§7)*
- **Chefes que atacam o herói** (dodge Archero) **enquanto** as torres seguram os
  adds (gestão KR). *(§8)*
- **Diretor de IA adaptativo** que aprende seu estilo e mistura ameaças de ambos os
  mundos. *(§9)*
- **Duas camadas de progressão**: roguelite na run (Archero) **+** árvore/estrelas e
  cidade no meta (KR/Kingshot). *(§5, §11)*

> Conclusão de design: o Bastion Rush usa o **loop micro do Archero** (mover/atirar/
> dodge/perks) como "como se joga segundo a segundo", e o **loop macro do Kingdom
> Rush** (classes de torre, contadores, ondas, meta de estrelas) como "como se
> domina a longo prazo" — costurados pelo **herói móvel** que é, ao mesmo tempo, o
> atirador (Archero) e o comandante que potencializa as torres (KR).
