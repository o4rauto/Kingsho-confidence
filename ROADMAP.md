# 🎯 Bastion Rush — Roadmap (visão unificada Archero × Kingdom Rush)

> Este documento **organiza tudo** que foi pedido e define a **ordem de
> implementação**. É a fonte da verdade do design. Atualize o **status** dos
> milestones conforme forem saindo. Tudo aqui é **original**, apenas *inspirado*
> nos gêneros (ver regra de originalidade no `CLAUDE.md`).
>
> 🔧 **Mecânica técnica detalhada** (como o jogo deve funcionar, "do jeito que o
> usuário quer"): ver [`MECHANICS.md`](MECHANICS.md).
>
> 📐 **Como funcionam os gêneros de base** (Archero + Kingdom Rush, esqueleto
> funcional): ver [`BLUEPRINTS.md`](BLUEPRINTS.md).

---

## 0. Decisão de arquitetura: **UM jogo só**

O repositório tinha **dois** jogos (Frontier Bastion = protótipo de estratégia;
Bastion Rush = ação/defesa 3D). A dúvida era se viraria 3. **Decisão: NÃO.**

- **O jogo é o Bastion Rush.** Ele absorve toda a visão abaixo (torres, classes,
  roguelike, herói mago, chefes, etc.).
- **Frontier Bastion não é apagado.** Vira a base do **"modo cidade"/meta** (entre
  batalhas: recursos, pesquisa, loja) numa fase futura. Por enquanto fica como
  legado, estável e testado.
- Resultado: **1 jogo jogável** + 1 base de sistemas para reaproveitar. Sem 3º jogo.

---

## 1. Pilares (o que o jogo é)

Uma **fusão**: o **herói** e o *feel* de **Archero** (move, desvia, **atira só
parado**, upgrades roguelike a cada horda, equipamentos, árvores de talento) +
o **tower-defense** de **Kingdom Rush** (4 classes de torre, especialização de
4º nível, chefes). Visão 3D ¾ de cima, mobile-first, **0 dependências**.

**Dilema central do jogador:** ficar **parado** (atira, e fortalece a torre em
cujo raio está) **vs. mover** (desvia dos inimigos/chefe, mas não atira). Cada
horda dá uma escolha de **upgrade do herói** e uma janela pra **construir/evoluir
torres**.

---

## 2. Sistemas (detalhado)

### 2.1 Loop de partida — **fase = 10 hordas**
- Uma **fase** tem **10 níveis (hordas)**. A horda seguinte só é lançada quando
  **o último monstro da anterior morre** (estilo Archero — não por timer).
- Ao limpar uma horda → **tela de 3 vias do Herói** (escolha 1 de 3 upgrades da
  run) → depois **~10 s de fase de construção** (torres) → próxima horda.
- **Vida:** o **herói tem vida e pode morrer** (no modo principal também). Os
  inimigos passam a **atacar o herói** (contato/projétil), não só a base.

### 2.2 Herói **mago** (movimento e combate)
- **Atira parado, não atira andando** (núcleo Archero). Auto-mira no alvo mais
  próximo no alcance quando o joystick/teclas estão soltos.
- **Mago:** ataque é **lançar um projétil mágico** (animação de *cast*).
- **Área limitada:** o herói **não pode sair da tela** (clamp à arena visível).
- Rig/animação mais trabalhados (ver 2.9).

### 2.3 Três caminhos na run (escolhas durante a partida)
- **Caminho do Herói** — upgrades do herói na run (tiro duplo, ricochete,
  perfurante, elétrico, …). É a árvore de **3 vias** que aparece ao limpar a horda.
  Também tem face **no menu** (compra permanente de habilidades/equipamentos).
- **Caminho do Arquiteto** — a janela de **construção/evolução de torres** (as 4
  classes, abaixo). Upgrades por nível + **4º nível = especialização única** que
  **muda o comportamento** da torre.
- **Caminho da Sobrecarga** — velocidade + **caos de projéteis** + feedback visual.
  Unificado ao Caminho do Herói (o "juice" foca no herói).

### 2.4 Quatro classes de torre (Kingdom Rush) + colocação
Ao construir, escolhe **1 de 4 classes**:
- **Arqueiro** — cadência alta, dano por tiro **baixo**.
- **Mago** — dispara **aura/orbe** com **dano em área**.
- **Quartel** — **invoca 3 unidades aliadas** que **travam** inimigos 1‑a‑1 e
  batalham (bloqueio de rota, estilo KR).
- **Artilharia** — **bomba** de **munição pesada** (AoE forte, lento).

**Colocação (duas formas):**
1. **Clicar** no slot → escolher a classe; **ou**
2. **Chegar perto** carregando **materiais** (madeira/mana/sucata dropados pelos
   inimigos) e **canalizar** a montagem/upgrade ao ficar parado no local.

**Torre humana:** herói **parado** dentro do **raio** de uma torre dá a ela
**+20% de cadência** (incentiva risco/posicionamento).

### 2.5 Sinergias Herói × Torre (roguelike)
- **Tiros elementais condutores:** acertar inimigo **perto de uma torre** com tiro
  elétrico → o raio **ricocheteia na torre** e cria uma **barreira elétrica** temp.
- **Killshot towers:** acertar a **própria torre** com um tiro dispara um efeito
  (ex.: torre de **estilhaços** → onda de pregos 360°).
- **Sacrifício de upgrade:** escolhas **ganha/perde** (ex.: torres +50% dano, mas
  −20% da vida máx. do herói).
- **Sinergia de equipamento:** a arma muda o arquétipo (ex.: **cajado necromante**
  → inimigos mortos pelas **torres** podem **reviver como esqueletos aliados** 5 s).
- **Habilidades gêmeas:** ao subir de nível na run, a habilidade tem **efeito
  duplo** — um pro **herói** e outro pras **torres** de uma classe específica.

### 2.6 Duas moedas + progressão meta (menu)
- **Moeda de Batalha** — só durante a partida (constrói/evolui torres, compra
  habilidades na run). Zera ao fim.
- **Moeda Meta** (intrínseca) — **progressão permanente** no menu: comprar
  **habilidades** e **equipamentos** do herói, e **modificações das torres** (4
  classes).
- **Árvore permanente bifurcada:** focar em **Herói (DPS)** ou **Comandante
  (estruturas)**.

### 2.7 Diretor de IA **adaptativo**
- O spawn **não** é só aleatório/combinado/padrão: um **diretor** observa **como o
  player joga** (movimento, alvos preferidos, classes de torre usadas, tempo
  parado vs. andando, onde toma dano, mortes) e **adapta** composição/posição/tempo
  das hordas. Mantém uma base **determinística** (semente) + camada adaptativa.

### 2.8 Chefes **bullet-hell** (KR × Archero)
- Chefes **não** andam só até o fim: **param em pontos** e **atacam o herói**
  diretamente com **padrões** (círculo de fogo, ondas de choque) e **invocam adds**.
- **Dilema:** o herói **desvia** dos padrões enquanto garante que as **torres**
  foquem os **adds** pra não perder a rota.

### 2.9 Visual "PlayStation 2" (mesh / rig / materiais / cenário)
- **Neblina por profundidade** (objetos longe somem no escuro) — maior ganho de
  "cara de 3D".
- **Materiais:** sombreamento que sugira **fosco / brilhante / metálico /
  transparente** (especular + fresnel fake), não só cor sólida.
- **Malhas mais detalhadas:** mais polígonos que o "boneco de caixas" atual;
  herói **mago** com **rig** e **animação de cast** mais suave.
- **Cenário mais bonito** e **variação a cada 10 níveis** (paleta + disposição).
- Restrição honesta: *texture mapping* real é inviável sem lib; buscamos o **feel**
  de PS2 (neblina + materiais + malha + iluminação), não texturas tremidas reais.

### 2.10 Variantes de jogo e modificadores
- **Defesa** (campanha) — proteger a base + sobreviver.
- **Arena / Sala** — salas fechadas; **perks do herói +60%** e **monstros +40%
  mais fortes**.

---

## 3. Milestones (ordem de implementação)

> Ordem pensada pra **fundação primeiro** (cada milestone é jogável/verificável).
> Legenda: ✅ feito · 🚧 em andamento · ⬜ a fazer.

- **M0 — Fundação & vitrine** 🚧
  - ✅ Decisão "1 jogo só" + este ROADMAP.
  - 🚧 Vitrine do repo (README Bastion-Rush-first, `package.json`, PR #1).
  - 🚧 **Clamp do herói à tela** (não sumir).
- **M1 — Núcleo Archero** ⬜
  - Atira parado / não atira andando.
  - **Vida do herói** + inimigos perseguem/atacam o herói → game over por morte.
  - HUD de vida do herói.
- **M2 — Estrutura fase=10 hordas** ⬜
  - Horda seguinte só após limpar a anterior; tela **3 vias do Herói**; janela de
    **construção (~10 s)**; recompensa por horda.
- **M3 — 4 classes de torre + colocação** ⬜
  - Arqueiro / Mago / Quartel / Artilharia; clicar-pra-escolher **ou**
    chegar-perto-com-materiais; **4º nível = especialização**; **torre humana** +20%.
- **M4 — Duas moedas + meta no menu** ⬜
  - Moeda de Batalha × Moeda Meta; loja de habilidades/equipamentos/torres; árvore
    permanente **Herói (DPS) × Comandante**.
- **M5 — Sinergias Herói×Torre** ⬜
  - Condutores, killshot, sacrifício, equipamento (necromante), habilidades gêmeas.
- **M6 — Diretor de IA adaptativo** ⬜
- **M7 — Visual PS2 (mesh/rig/materiais/cenário + variação/10 níveis)** 🚧
  - ✅ Iluminação **toon/cel-shading** + **luzes locais** (braseiros + aura do mago).
  - ✅ Herói virou **mago detalhado**; câmera mais alta/afastada; cenário mais claro.
  - ⬜ Malhas dos **monstros** mais detalhadas, **materiais** (fosco/metálico/vidro),
    **animação de cast** do mago, **variação de cenário a cada 10 níveis**.
- **M8 — Chefes bullet-hell** ⬜
- **M9 — Variantes & dificuldade** ⬜ (Arena +60%/+40%, auto/2x, estrelas, capítulos).

> A ordem pode ser repriorizada a pedido (ex.: puxar o visual/M7 pra frente).

---

## 4. Cortes (fora de escopo — "viagem", confirmado pelo usuário)
- Mapas 3D verticalizados **destrutíveis** (pilares/barris/pontes que desabam).
- **Bunker de reciclagem** (corpos → moedas).
- "Abate de torre → +5% cadência do herói".
- **Controle de linha de frente** (não necessário; basta a escolha das 4 classes).

---

## 5. Restrições técnicas (não esquecer)
- **0 dependências** no Bastion Rush (roda/testa no sandbox; vira APK offline).
- **CDN bloqueada** no sandbox → nada de libs por CDN.
- **Sempre verificar headless** (check de sintaxe + screenshot Playwright + ler o
  PNG + `ERROS=[]`) antes de commitar — ver `CLAUDE.md` §2.
- Lógico **460×880** retrato; edits **cirúrgicos** no `index.html` (arquivo grande).
