# PLAN — Planejamento completo + como vou implementar

> Consolida as **decisões do usuário** (feedback sobre o `RESEARCH.md`) e estabelece
> **a ordem e o COMO** da implementação. É o **plano operacional vigente** — onde
> diverge do `MECHANICS.md`, **este documento prevalece** (o MECHANICS é reconciliado
> conforme cada etapa entra). Ver também `ROADMAP.md` (milestones) e `RESEARCH.md`.

---

## A. Decisões consolidadas (desta rodada)

### ✅ Manter (aprovado)
- **Micro "mover-OU-atirar"** (parado atira, andando não). É a alma do jogo.
- **Roguelite 1-de-3** por horda.
- **Escala** de dificuldade (HP×`diff`, monstro novo a cada 4 níveis, etc.).
- **4 classes de torre** + **upgrades de 3 níveis** + **tier-4 bifurcado** (muda comportamento).
- **Inimigos com contadores** (armadura/voador) + **bounty (ouro) e penalty (vidas)**.
- **Ouro por abate que reseta na fase**; **meta de estrelas → árvore global**.
- **Arquitetura:** Type Object + data-driven, wave data-driven, game loop com cap de `dt`.
- **Identidade:** o herói é o "arqueiro do Archero" **participando ativamente da
  batalha do Kingdom Rush** — *isso é o Bastion Rush*.

### ✂️ Cortar / adiar (não agora)
- **Salas especiais** (anjo / tesouro / diabo). *(pode voltar depois)*
- **"Chamar a onda antes"** (call wave early).

### 🔧 Mudar / novo (decisões novas)
1. **Herói com 3 VIDAS (renasce 3×).** Perde ao **esgotar as vidas** (e, no modo
   Defesa, se a **base for destruída**). Renascer faz sentido porque a torre pode
   estar viva ainda.
2. **Torres liberadas por PROGRESSÃO** (estilo *arenas* do Clash Royale / *metal
   arena* do Archero): avançar nas fases/arenas desbloqueia **quais CLASSES e quais
   NÍVEIS de torre** você pode usar — além do roster de monstros que já escala.
3. **TRÊS moedas, visualmente DISTINTAS** (hoje há confusão amarelo/azul):
   - **Moeda** — **dourada/amarela, redonda** — recurso meta (permanente).
   - **Gema** — **VERDE** (substitui o diamante azul atual) — **premium/comprada**
     (reviver, acelerar). *Não usar "diamante".*
   - **Cristal de Batalha** — **azul, formato de cristal/losango** (distinto do
     amarelo e do verde) — moeda **da run** (constrói/eleva torres na partida; some
     no fim).
4. **Rebalance de economia (dores atuais):**
   - Moeda hoje é **fácil demais** → deixar **mais escassa**.
   - **Torres têm que ser upgradáveis de verdade** (hoje não dá) e com **dano
     significativo** por nível/classe.
5. **Preço de IAP/passe mais barato (~US$ 1,49).**

---

## B. Estado atual (o que já tem × o que falta)
**✅ Tem:** mago 3D que move e **atira do orbe**; **só parado? ainda não**; 2500
fases lineares; 13+3 monstros + elites; iluminação toon + luzes locais; câmera
alta; herói preso à tela; HAB/ULT; bestiário; menu; áudio/i18n; diária + gacha-stub.
**❌ Falta / quebrado:** herói ainda **atira andando**; **sem vida/vidas** no herói;
**torre não upgrada** e **dano baixo**; **moeda fácil demais**; só **1 tipo** de
torre (sem 4 classes, sem tier-4, sem gating); **sem 1-de-3**; **sem 10-hordas**;
**sem moeda de batalha**; "gema" ainda é **diamante azul**.

---

## C. Plano de implementação (etapas → COMO → pronto quando)

> Ordem pensada pra **resolver as dores atuais já na Etapa 1** (torre que upgrada +
> dano + economia) **junto** com o núcleo Archero (que a pesquisa mandou fazer 1º).
> Cada sub-etapa é **verificada headless** e **commitada** antes da próxima.

### ETAPA 1 — Núcleo Archero + torres jogáveis + economia  ✅ CONCLUÍDA
- **1.1 Atira parado / não andando.** *Como:* no `update`, herói só dispara se
  `|input|≈0`; andando, vira pro movimento. *Pronto:* headless mostra parado-atira /
  andando-não.
- **1.2 Vida do herói + 3 vidas + dano de contato.** *Como:* `G.heroHp/heroHpMax`,
  `G.lives=3`, `G.invuln`; inimigo no raio causa dano por cooldown; ao zerar HP →
  **renasce** (i-frames) consumindo 1 vida; sem vidas → `gameOver`. HUD com **barra
  de vida + 3 pips**. *Pronto:* toma dano, morre, renasce 3×, 4ª = derrota.
- **1.3 Torres upgradáveis + dano de verdade.** *Como:* tocar slot constrói; tocar
  de novo **sobe nível (1→3)** com custo/dano crescentes; rebalancear `towerDmg` por
  nível. *Pronto:* dá pra subir a torre e **ver o dano subir** e matar inimigos.
- **1.4 Três moedas + rebalance.** *Como:* `META.coins` (amarelo) + `META.gems`
  **recolorida pra verde** + `G.battle` (cristal azul, só na run); **reduzir drop de
  moeda / subir custos**; desenhar **3 ícones distintos** no HUD. *Pronto:* HUD com
  3 recursos distintos; moeda não-trivial; cristal some ao fim da run.

### ETAPA 2 — 4 classes de torre + tier-4 + gating por progressão
- **2.1 4 classes** (tabela `TOWERS` = Type Object): **arqueiro** (rápido, dano
  baixo) · **mago** (aura/orbe AoE, ignora armadura) · **quartel** (3 unidades que
  bloqueiam) · **artilharia** (bomba AoE, não pega voador). *Como:* tocar slot vazio
  → **menu de classe**.
- **2.2 3 níveis + tier-4 bifurcado** (campo `level 1..4`; no 4, escolhe 1 de 2
  *specs* que mudam o comportamento).
- **2.3 Gating por progressão** (`UNLOCKS` por `clearedMax`/arena → libera classes e
  níveis; UI mostra "libera na fase X").
- *Pronto:* construir as 4 com comportamentos distintos; tier-4 muda algo; classes/
  níveis surgem conforme a progressão.

### ETAPA 3 — Fase = 10 hordas + 1-de-3 + janela de construção
- *Como:* `G.gen` = 10 hordas; **próxima só quando `enemies` vazio**; estado
  **`perk`** (1-de-3 do herói, **stacking multiplicativo** nos projéteis) → estado
  **`build`** (~10s) → próxima horda. *Pronto:* limpar horda abre 1-de-3, depois
  construção, depois a próxima.

### ETAPA 4 — Meta no menu
- Estrelas por fase → **árvore global**; **loja** (habilidades/equip/upgrades de
  torre) com **moeda + gema**, **IAP ~US$1,49**; **heróis** colecionáveis (roster
  **enxuto**) sob um **power score**.

### ETAPA 5 — Sinergias herói×torre + torres inovadoras
- Condutor, killshot, sacrifício, equipamento (necromante), **ímã**, **espelho**, habilidades gêmeas.

### ETAPA 6 — Diretor de IA adaptativo
- Telemetria do jogador → modula composição/posição/tempo das hordas (base determinística + camada adaptativa).

### ETAPA 7 — Chefes bullet-hell
- Param e **atacam o herói** (padrões) + invocam adds; herói desvia, torres seguram os adds.

### ETAPA 8 — Visual PS2 restante
- Malhas dos **monstros**, **materiais** (fosco/metálico/vidro), **animação de cast**
  do mago, **variação de cenário a cada 10 níveis**.

### ETAPA 9 — Modos, primeiro-win, fusão-cidade, LiveOps/social
- **Arena +60% perks / +40% monstros**; **"primeiro win" engenheirado**; fusão com a
  **cidade (Frontier)**; passe/eventos/aliança (servidor → "Em Breve").

---

## D. Como eu trabalho (método, em toda etapa)
1. **Edits cirúrgicos** no single-file (`bastion-rush/index.html`).
2. **Verificação headless** obrigatória: check de sintaxe + screenshot Playwright +
   **ler o PNG** + `ERROS=[]` (e hooks `BR.*` quando útil).
3. **Commit por sub-etapa** com mensagem clara → **push** → mando o **link
   raw.githack com o SHA novo** pra você testar no celular.
4. **0 dependências**, mobile-first 460×880, **CI verde**.
5. Atualizo `MECHANICS.md`/`ROADMAP.md` conforme cada etapa fecha.

---

## E. Pendência de decisão (só 1, e eu já tenho um padrão)
- **Cor/forma do Cristal de Batalha:** vou de **azul, formato de cristal/losango**
  (distinto da moeda amarela e da gema verde). Se quiser outra cor, é 1 linha trocar.
