# HUD.md — Direção Visual da Interface (Bastion Rush)

UI na mesma fusão dos outros docs (magia gótica de mundo bruxo × cor-pop
esfarrapada e "juicy" de space-opera). A HUD é **diegética sempre que dá**: não é
"menu de jogo", é o **instrumental arcano do Arcano** — placas de pedra rúnica,
molduras de bronze manchado, **mostradores de brasa** e sigilos que brilham.
Tudo ancorado nos elementos que o motor já desenha (`drawPlayHud`,
`drawSkillUlt`, `drawJoystick`, `drawSlots`, `coinHud`, `drawTopBar`, `drawFx`,
`drawToast`). **Mobile-first, retrato 460×880**, alcançável com os polegares.

## Princípios

1. **O centro é sagrado.** A ação fica no meio; a HUD vive nas **bordas** (topo =
   status/economia; base-cantos = controles). Nada cobre o herói nem o caminho.
2. **Cor = informação (não decoração).** Mantém o código de cor do jogo: **verde→
   amarelo→vermelho** = vida; **âmbar/ouro** = recurso quente; **ciano/azul** =
   arcano/ULT/base; **rosa** = vidas. O jogador lê de relance.
3. **Linguagem arcana unificada.** Painéis = **lousa de pedra** com canto
   arredondado, **fio de bronze**, runas gravadas; barras = **tubos com brasa/
   geada** correndo dentro; botões = **sigilos** que acendem quando prontos.
4. **Juice é feedback, não enfeite.** Cada pulso/flash diz algo (ult cheia, dano
   na base, moeda coletada). Sem ruído gratuito.

## Mapa de zonas (ergonomia retrato)

```
┌───────────────────────────────────────┐
│ [STATUS: Fase/Herói/Vidas/Base]  [ECONOMIA] │  ← topo (informar)
│            [▮ HORDA: mortos/total ▮]        │
│                                             │
│                 (AÇÃO — livre)              │
│                                             │
│                                       [⏸]   │  ← canto: pausa
│                                       [HAB] │  ← polegar direito
│   (joystick surge onde o polegar toca)[ULT] │
└───────────────────────────────────────┘
   polegar esquerdo = mover      polegar direito = habilidades
```

---

## HUD de jogo (combate)

### 1. Painel do Comandante — status *(topo-esquerda)*
Uma **lousa de pedra rúnica** com fio de bronze. Contém:
- **"Fase N"** (gravado no topo; em replay, selo discreto "(replay)").
- **Barra do HERÓI** — a **vitalidade do Arcano** (a fagulha que ele canaliza).
  Tubo com **brasa âmbar** que esvai p/ amarelo→vermelho conforme cai. Rótulo
  pequeno "HERÓI".
- **3 Vidas** — três **velas/chamas** (hoje pontos rosa). Ao perder uma, a vela
  **se apaga com fumaça** (não some seca).
- **Barra da BASE** — a **Chama do Bastião**, azul-arcana; é o **termômetro
  emocional** da fase. Em HP baixo, **vacila e esfria** (mais azul, treme) e o
  rótulo "BASE" pulsa vermelho.

### 2. Cofre Arcano — economia *(topo-direita)*
Dois mostradores empilhados:
- **Moedas + Gemas** (`coinHud`): **moeda** de ouro (brasa cunhada) e **gema**
  verde (*fagulha da Chama*, per origem). Moldura tipo **bolsa/relicário**; o
  número **pulsa e estica** ao ganhar (já há `coinPulse`).
- **Cristal de Batalha** ("p/ torres"): a moeda da run — **calor recuperado dos
  mortos**. Cristal ciano num **frasco**; **pulsa** ao coletar (`battlePulse`) e
  as moedas-3D **voam do inimigo até este frasco** (arco com rastro).

### 3. Medidor da Horda — progresso *(topo-centro)*
Barra "mortos/total" reimaginada como **maré que recua**: enche de **âmbar**
(terreno reconquistado) empurrando o **azul-gelo** (a Maré). Texto "X/Y
inimigos". Quando vem **chefe**, ganha um **selo de caveira-coroa** e fica
vermelha.

### 4. Sigilos de Habilidade *(borda direita, polegar)*
- **HAB** (`drawSkillUlt`) — **Estouro de Luz** (dano em área). Botão = **sigilo
  âmbar**; em recarga, escurece e mostra **anel de cooldown** varrendo + o número
  de segundos. Pronto: **respira/brilha**.
- **ULT** — **Supernova da Chama** (limpa a tela). Botão = **frasco/sigilo
  ciano** que **enche por baixo** conforme você causa dano (`ultCharge`). Cheio:
  **pulsa forte em ciano**, faíscas, e fica "puxável". Ao disparar: **clarão**
  na tela inteira.

### 5. Pausa *(canto inferior-direito)*
Sigilo discreto com as **duas barras** (||) gravadas em pedra. Fora do polegar de
movimento p/ não pausar sem querer.

### 6. Manche Arcano — joystick *(flutuante, esquerda)*
Surge **onde o polegar toca**: um **anel rúnico no chão** (base) + um **núcleo de
brasa** (manche) que segue o dedo. Em repouso, dica sutil "arraste p/ mover o
herói". Estilo "bússola arcana", translúcido p/ não tampar a ação.

### 7. Nichos de Torre — UI no mundo *(`drawSlots`, projetada em 3D)*
Diegética, no chão (ver `ENVIRONMENT.md`):
- **Vazio:** **anel de runas** tracejado; **pulsa ciano quando dá p/ construir**,
  com ícone **+** e o custo (cristal).
- **Construída:** etiqueta **"Lv N"** flutuante + botão **+** de upgrade (custo);
  no nível 5, selo **"MAX"** dourado.

### 8. Texto flutuante & banners *(`drawFx`/`banner`/`toast`)*
- **Números de dano:** brancos com contorno; **crítico/chefe** maiores e
  **dourados**.
- **Banners centrais:** "Fase N" (entrada), "Reforços!" (diretor de IA) — grandes,
  âmbar, somem rápido.
- **Toast** (recompensas/avisos): pílula de pedra com fio roxo, deslizando.

---

## UI fora de combate (chrome dos menus)

- **Barra de topo** (`drawTopBar`): **selo de Nível** (Nv = clearedMax) +
  Fase atual, **moedas/gemas**, e **hambúrguer → Ajustes**. Mesma lousa+bronze.
- **Menu estilo "carta"** (`drawMenu`): título, **herói girando no pódio** ao
  centro, botão grande **BATALHAR** (âmbar), **FASES**/**BESTIÁRIO**, e a
  **fileira de baús** (diária resgatável + "Em Breve"/FOMO).
- **Telas** (Campanha, Bestiário, História, Ajustes, Pausa, Vitória, Derrota):
  mesmo painel de pedra, mesmo código de cor, botões `btn()` chunky com fio roxo.
- **Botões:** cantos arredondados, **rótulo bold + sub-rótulo**, **fio que acende**
  quando habilitado e **apaga (cinza)** quando bloqueado.

---

## Estados & juice (feedback que comunica)

- **Base em perigo:** **vinheta avermelha** nas bordas + barra da BASE pulsando;
  a chama do farol esfria.
- **ULT pronta:** sigilo ciano pulsa + leve brilho ciano na borda direita.
- **Ganhou recurso:** número estica/pulsa + moeda-3D voa pro frasco/cofre.
- **Acertou/critou:** número salta; chefe solta número dourado.
- **Tomou dano (herói/base):** **flash** curto + **shake** + barra correspondente
  treme.
- **Chefe entra:** flash âmbar + shake + medidor da horda vira vermelho.

## Notas de produção (legibilidade mobile)

- **Toque mínimo 44–48px** nos sigilos (HAB/ULT/pausa) e botões.
- **Contraste:** todo texto sobre painel translúcido escuro; números de jogo com
  **contorno** (lêem sobre o cenário claro/escuro).
- **Emojis com cautela:** em rótulos críticos, **preferir formas desenhadas**
  (moeda/gema/cristal já são vetor) — emojis podem virar "□" em alguns aparelhos.
- **Não tampar o herói/caminho:** painéis só nas bordas; joystick translúcido.
- **Hierarquia constante:** status (topo-esq) ↔ economia (topo-dir) ↔ progresso
  (topo-centro) ↔ controles (base) — nunca trocar de lugar entre fases.
