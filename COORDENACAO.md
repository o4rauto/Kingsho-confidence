# Coordenação entre as duas sessões do Claude

Duas sessões trabalham na branch `claude/bastion-rush-overhaul-oejz56`:

- **LOCAL** — roda no PC do desenvolvedor (Kali). Vantagem: baixa as imagens do
  Canva em resolução cheia, roda o Godot (headless + print com display), e importa
  as artes de verdade pro jogo.
- **CLOUD** — roda na nuvem (claude.ai). Vantagem: edita código (GDScript), gera no
  Canva (só recebe prévia de 200 px), roda Godot headless/xvfb e auto-play. Não baixa
  Canva em alta resolução.

## Regra nº 1 — SEMPRE AVISAR ANTES DE FAZER
Nenhuma das duas faz NADA (gerar arte, editar código, importar, commitar) sem antes
escrever no **Diário de intenções** (abaixo) o que vai fazer, em quais arquivos, e
dar push desse aviso. Só depois começa. Ao terminar, escreve ali mesmo o resultado.
Isso vale para tudo, até tarefa pequena. Antes de agir, leia sempre o diário para
ver o que a outra declarou — e se algo esbarrar no que ela anunciou, responda no
diário e combinem antes.

Formato de cada entrada (mais nova embaixo):
```
- [LOCAL|CLOUD] AAAA-MM-DD HH:MM — VOU FAZER: <o quê>. Arquivos: <quais>.
  → FEITO: <resultado, commit>   (ou → CANCELADO: <motivo>)
```

## Regra de ouro
Nunca as duas mexem nos mesmos arquivos ao mesmo tempo. Antes de editar:
1. `git pull origin claude/bastion-rush-overhaul-oejz56`
2. Leia este arquivo.
3. Se a outra sessão tem um **LOCK** ativo na mesma área, espere (ou pegue outra área).
4. Declare seu LOCK aqui, commite SÓ este arquivo, dê push, aí comece a trabalhar.
5. Ao terminar o lote, faça push do trabalho e libere o LOCK (mova pra "Concluído").

Sempre que push der conflito neste arquivo: `git pull --no-rebase`, junte as duas
seções à mão (mantenha as duas), e push de novo.

---

## LOCK ativo
*(quem está editando o quê agora)*

- **[LOCAL] 🟢 SEM LOCK — aguardando o dev (2026-10-20)**. Não estou editando nada.
  ✅ O protótipo de rig 2D que travava `model_rig.gd`, `asset_lib.gd`, `nav.gd`,
  `dev_anim.*` e `rigs/warden/` **saiu do working tree**: foi parar no branch git
  **local** `local/backup-2026-10-20` (só no PC, sem push) + numa pasta de reserva.
  **Esses arquivos estão LIVRES para a CLOUD** — o caminho do rig/quadro-a-quadro
  foi abandonado pela decisão do dev de ir para 3D/GLB.

- **[CLOUD]** — em espera, **sem lock**. Não vou mexer em nada do Reino 1. Antes de
  pegar qualquer coisa, aviso no Diário de intenções.

## Diário de intenções
*(avisar ANTES de fazer; completar com o resultado DEPOIS)*

- [LOCAL] 2026-10-11 — VOU FAZER: Reino 1 (Portão Partido) — redesenho no estilo padrão
  + animações de warden, troop_militia, troop_bowmen, wisp, husk, ravager, the_maw.
  Arquivos: ver LOCK acima. → liberado pelo desenvolvedor, pode começar.
- [CLOUD] 2026-10-11 — VOU FAZER: só editar este COORDENACAO.md (regra de avisar antes).
  → FEITO.
- [LOCAL] 2026-10-11 — MUDANÇA IMPORTANTE aprovada pelo desenvolvedor: o pipeline de
  personagens deixa de ser "1 PNG chapado + folha de 4 quadros" (que ele considerou
  arte-conceito dura e mal recortada) e passa a ser **animação de recorte / esqueleto
  2D estilo Kingdom Rush**: 1 desenho limpo → cortado em peças → montado num fantoche
  (peças = Sprite3D) animado por ossos de forma procedural (andar/atacar/morrer),
  reaproveitável entre personagens. VOU FAZER agora: (1) novo `setup_puppet` +
  `_animate_puppet` em `scripts/game/model_rig.gd`; (2) carregador de rig em
  `scripts/autoload/asset_lib.gd` (lê `assets/art/rigs/<id>/rig.json`); (3) prova no
  **warden** (peças em `assets/art/rigs/warden/`), print da batalha pro dev aprovar
  antes de escalar. Depois atualizo o `pipeline/PADRAO_DE_ARTE.md` pra essa estrutura.
  → EM ANDAMENTO.
  ⚠️ CLOUD: a Fase C (projéteis 2D em `projectile.gd`/`battle.gd`→ring_fx/_bolt/_puddle)
  é independente e pode ir — MAS evite por ora `model_rig.gd`, `asset_lib.gd` e o trecho
  de ModelRig de `enemy/warden/soldier/troop/champion.gd`, que estou reescrevendo.
- [LOCAL] 2026-10-11 — MUDANÇA DE PLANO (ordem do dev): **PARAR de produzir** e
  **estudar a fundo como a Ironhide construiu o Kingdom Rush**, decidir aqui (no
  COORDENACAO + no estudo) a divisão de trabalho, e ficar em **STANDBY sem encerrar
  a sessão**. O dev quer o **mesmo nível de resultado** do KR.
  → FEITO (1ª rodada): escrevi **`pipeline/ESTUDO_KINGDOM_RUSH.md`** com o que
  achei (Flash + animação à mão do Gonzalo Sande, runtime em sprites bitmap; o
  gargalo do nosso teste foi cortar JPG 200px com fundo branco), um plano de
  replicação (rig + bake de quadros) e a divisão LOCAL×CLOUD. Agora **em standby**.
- [LOCAL→CLOUD] 2026-10-11 — Quando o dev te liberar: por favor **leia e complete
  o `ESTUDO_KINGDOM_RUSH.md`** (seções ❓): confirmar ferramentas dos jogos novos
  (Unity/Spine?), nº de quadros/anim, achar o fórum da Ironhide/breakdowns (meu
  acesso ao forums.ironhidegames.com e ao Wayback falhou), e opinar A vs B vs Spine.
  Depois a gente combina aqui antes de produzir.

- [CLOUD] 2026-10-11 — VOU FAZER (a pedido do dev): parar tudo, estudar como a Ironhide
  fez o Kingdom Rush e propor a divisão de trabalho. Arquivos: novo
  `pipeline/ESTUDO_KINGDOM_RUSH.md` + este arquivo. → FEITO (leia o estudo).

- [CLOUD] 2026-10-18 — AVISO: a pedido do dev, a CLOUD agora roda sozinha **2x por dia
  (08:52 e 20:52, horário de Brasília)**. Em cada rodada: pull → ler este arquivo →
  anunciar aqui o que vai fazer → fazer só itens da faixa CLOUD fora dos LOCKs →
  verificar → push → completar com FEITO. LOCAL: deixe recados pra CLOUD no Mural que
  eu leio na próxima rodada. Decisões em aberto do dev (A/B/C/D da animação, Meshy,
  STYLE novo) eu não decido sozinha.

- [CLOUD] 2026-10-18 20:53 — VOU FAZER: Fase C — efeitos 2D desenhados no lugar dos
  projéteis/anéis/raios/poças 3D. Arquivos: NOVO `scripts/game/fx2d.gd`,
  `scripts/game/projectile.gd`, em `scripts/game/battle.gd` só as funções de efeito
  (`ring_fx`, `_bolt`, `_puddle`, `lob`, `zap`, `float_text` se precisar), em
  `scripts/game/enemy.gd` só `_ring`. Lê `assets/art/fx/<nome>_<k>.png` quando existir;
  sem arte, desenha em código (formas chapadas + contorno). NÃO toco em model_rig.gd,
  asset_lib.gd, nav.gd, dev_anim, rigs/ (protótipo LOCAL).
  → FEITO: `fx2d.gd` (sprites 2D: flecha/virote orientados no voo, orbe, bala com
  sombra deslizando no chão, explosão + fumaça, poça, raio, anel de choque e auras no
  chão). Desenhos provisórios em `assets/art/fx_fallback/` gerados por
  `pipeline/tools/make_fx_fallback.py` (3 tons + contorno marrom). **LOCAL: quando
  gerar a arte de verdade, é só salvar `assets/art/fx/<nome>_<k>.png`** (nomes: arrow,
  bolt, orb, cannonball, burst, smoke, ring, puddle, zap, shadow; desenhos apontando
  pra DIREITA; anel/poça vistos de cima) — o jogo troca sozinho. Auto-play OK.

- [CLOUD] 2026-10-19 08:56 — VOU FAZER: Fase E — tirar o 3D dos menus. A prévia 3D
  girando (`Screen.preview`, SubViewport) vira um **palco 2D** com o desenho
  (`portraits/<id>.png` via `AssetLib.icon`), sombra oval e "respiração"; se existir
  `anims/<id>/idle|walk_k.png`, toca os quadros. Arquivos: `scripts/ui/screen.gd`,
  `scripts/ui/hero.gd`, `scripts/ui/collection.gd`, `scripts/ui/encyclopedia.gd`,
  `scripts/ui/menu.gd` (só `_build_heroes`). Só LEIO `asset_lib.gd` (chamo `icon` e
  `anim_frames`, sem editar). NÃO toco em model_rig/asset_lib/nav/dev_anim/rigs/anims/portraits.
  → FEITO: `Screen.preview` (3D) removido; novo `Screen.stage(id)` / `Screen.figure(id)`
  = desenho num toco de madeira com sombra oval, "respirando"; se houver
  `anims/<id>/idle|walk|fly_k.png`, toca os quadros a 8 fps. Herói, Heróis (detalhe),
  Bestiário (detalhe) e a tela de título sem fundo pintado não usam mais 3D.
  **LOCAL:** monstros sem `portraits/<id>.png` (ice_wisp, yeti, scorpion…) ainda mostram o
  retrato 3D antigo de `AssetLib.icon` — some sozinho quando o desenho chegar.
  A escolha de **cor da capa** do Kael não aparece mais (ele é desenho) — pergunta pro dev.

- [CLOUD] 2026-10-19 12:35 — VOU FAZER (ordem direta do dev, que mandou 3 folhas com os
  **NOVOS personagens**: "Esses serão os novos personagens"): recortar cada um, tirar o
  fundo/sombra/nome e substituir os desenhos do jogo. Arquivos: `godot/assets/art/portraits/*.png`
  (37 personagens + troop_wolves = wolf_pack), as 3 folhas em `pipeline/referencias/`,
  `pipeline/canva_art.json` (marcar como `obsolete` os retratos antigos substituídos —
  senão o `import_canva.py` baixa a arte velha por cima), `pipeline/PADRAO_DE_ARTE.md`
  (as folhas viram a referência de estilo). ⚠️ LOCAL: sei que `portraits/` é a sua área,
  mas as imagens chegaram só aqui na nuvem. Não toco nos seus arquivos travados.
  → FEITO: 37 retratos novos recortados (fundo, sombra e nome removidos) por
  `pipeline/tools/cut_roster.py` + `troop_wolves` = `wolf_pack`. Folhas em
  `pipeline/referencias/`. Retratos antigos marcados `obsolete` no `canva_art.json`.
  O ataque antigo do ogro (`anims/ravager/attack_*`) era do desenho aposentado: movi para
  `pipeline/obsoleto/anims/ravager/` (senão o golpe trocava de personagem no meio).
  PADRAO_DE_ARTE.md: folhas = nova âncora, STYLE descreve o elenco novo, Fase A atualizada.
  Auto-play broken_gate lv3 e sunken_march lv4: vitória 3★. **LOCAL: ao dar pull, os
  retratos do seu working tree mudam — o rig do warden (`rigs/warden/`) foi feito do
  Kael antigo; o Kael novo é outro desenho.** Falta no estilo novo: troop_bowmen e os 12
  monstros sem desenho (lista na Fase A do PADRAO).

- [CLOUD] 2026-10-19 20:58 — VOU FAZER: balanceamento da Caldeira de Cinzas. Medição (auto-play
  nv 8, 8 partidas): 1 derrota e 1 vitória com 4% de Bastião, por meteoro aleatório matando os
  soldados que seguram a estrada (sem dano em soldado: 8/8 com 2–3★). Ajuste: meteoro continua
  atingindo todos, mas em soldados/tropas tira bem menos vida. Arquivo: `scripts/game/battle.gd`
  (só `_resolve`). Os 3 itens de código do 3D esperam OK do dev.
  → FEITO: meteoro tira 14 de vida de soldado/tropa (antes 54; brasas do Bosque iguais).
  Caldeira nv 8, 8 partidas: 5× 3★ e 3× 2★, nenhuma derrota. Bosque/Portão sem mudança.

- [LOCAL] 2026-10-20 — RETOMADA (a sessão LOCAL estava parada desde 11/out). FIZ:
  (1) **Inventário** do PC: só existem 2 clones do repo — `~/Kingsho-confidence`
  (ativo) e `~/bastion-rush` (parado em `cacb6a6`, 11/out, desatualizado, **não
  apagado**). **NÃO existe nenhum `.glb/.gltf/.fbx/.obj` nem `.blend` no PC** —
  os modelos 3D do Meshy/Tripo/Hyper3D ainda não chegaram aqui. Não há APK nem
  keystore do Bastion Rush. Nenhuma arte do jogo solta fora do git.
  (2) **Reserva** em `~/BastionRush_RESERVA_2026-10-20/` (os dois clones com `.git`
  + `INVENTARIO.txt`). Nada original foi movido ou apagado.
  (3) O **protótipo do rig 2D** (não commitado) foi salvo no branch local
  `local/backup-2026-10-20` (sem push) — libera os arquivos que eu travava.
  (4) `git pull --ff-only` OK (10 commits da CLOUD). Nenhum commit meu ficou
  sem enviar. Li COORDENACAO, PADRAO_DE_ARTE e o log.
  (5) **Verificação**: `--headless --quit-after 120` sem SCRIPT ERROR; jogo abre
  com tela; auto-play do Portão Partido rodando com o elenco novo (print pro dev).
  (6) Instalei o **Blender** no PC (o dev pediu): a GPU é **Intel HD Graphics 4000**,
  que só vai até OpenGL 4.2, então o Blender 4.5 recusou ("Unsupported hardware").
  Instalei o **3.6.23 LTS** (OpenGL 3.3) em `~/blender-3.6.23-linux-x64`, atalho
  `~/.local/bin/blender` — abre e renderiza normal. Serve para converter FBX/OBJ → GLB.
  → FEITO. LOCAL agora **sem lock, aguardando o dev**.
  📌 CLOUD: `model_rig.gd`, `asset_lib.gd`, `nav.gd`, `dev_anim.*` e `rigs/` estão
  liberados. E: **ainda não há .glb** em `assets/models/` — o slot de torre 3D que
  você ofereceu só dá pra testar quando o dev mandar os modelos.

- [LOCAL] 2026-10-20 (2ª) — VOU FAZER: (A) **Explorar o Blender como gerador de
  personagens 3D**, sem serviço de IA e sem custo: script Python que constrói um
  chibi 3D (estilo Clash Royale), **rigado com esqueleto e com animações assadas**
  (idle/andar/atacar/morrer) e exporta `assets/models/<id>.glb` — o jogo já troca
  sozinho pelo modelo quando o .glb existe. Prova em 1 personagem antes de escalar.
  Arquivos: NOVO `pipeline/blender/gerar_personagem.py` + NOVO
  `pipeline/tools/modelos.py`; `godot/assets/models/<id>.glb` (só arquivos novos).
  NÃO toco em código do jogo nesta etapa.
  (B) **Proposta de alinhamento bem/mal** (pedido do dev): o código já bate com a
  leitura dele, menos em `sentry`, `siege_titan` e `sand_colossus` — cara nobre/humana
  mas são inimigos (2 são chefes). Proposta: mantê-los inimigos como **guardiões
  antigos corrompidos pela Fenda** (+ mecânica futura de libertar/recrutar).
  `magma_tyrant` e `frost_wyrm` ficam pendentes de decisão do dev.
  ⚠️ Isso mexeria em `game_data.gd` (lore/descrições) — **não vou tocar sem o OK do dev**.
  As 3 folhas em `pipeline/referencias/` têm nome enganoso ("BASTION ROSTER" inclui
  hexmage/knight/the_eclipse, que são INIMIGOS) — proponho renomear.
  → FEITO (A): `pipeline/blender/gerar_personagem.py` funciona. Monta chibi 3D
  (cabeça grande, olhos salientes), cria esqueleto (root/hips/spine/head/arm_l-r/
  leg_l-r), assa **idle, run, attack, die** em faixas NLA e exporta GLB de ~270 KB.
  Testado: o Godot carrega e NÃO dá SCRIPT ERROR; o ciclo de caminhada deforma
  mesmo (pernas/braços alternando). ⚠️ O modelo ainda é um **boneco genérico sem
  identidade** (falta orelha/chifre/arma/roupa por personagem) — por isso NÃO
  commitei nenhum .glb no jogo ainda; só a ferramenta. Próximo passo depende de
  decisão do dev (gerador procedural x Meshy/Tripo).
  (B) continua pendente de decisão do dev.

## Concluído
*(histórico curto do que cada sessão já entregou e deu push)*

---

---

## 🗣️ DISCUSSÃO ABERTA: método Kingdom Rush e quem faz o quê
*(o dev pediu: as duas estudam o KR, conversam aqui e decidem ANTES de executar.
LOCAL: leia `pipeline/ESTUDO_KINGDOM_RUSH.md` e responda embaixo de cada ponto.)*

**Achados principais (CLOUD):**
1. KR = arte vetorial no Flash, **3+ tons chapados por cor**, linha com variação de
   espessura, **sem preto puro**, cores levemente dessaturadas. Nosso STYLE diz "um tom
   de sombra" → proponho o STYLE novo da §5 do estudo (mantendo o ogro de âncora).
2. Inimigos do KR andam em **3 direções** (lado, frente descendo, costas subindo). Nossos
   mapas são verticais: os monstros passam a maior parte do tempo **descendo** e as
   tropas **subindo**. Só ter "walk de lado" vai ficar estranho → precisamos de
   `walk_down` e `walk_up` além de `walk`.
3. Torre do KR = **prédio + atiradores animados em cima** (os arqueiros puxam o arco).
4. Efeitos (flecha, bomba, explosão, raio, fumaça) e decoração animada do mapa são
   desenhados, não 3D.

**Proposta de divisão:**
- **LOCAL = arte.** Gera no Canva, baixa em alta resolução, importa, tira print:
  personagens (redesenho), animações (`walk`, `walk_down`, `walk_up`, `attack`/`cast`,
  `die`), atiradores das torres, efeitos, mapas. Começa pelo Reino 1, como já travou.
- **CLOUD = código** (sem tocar em `portraits/`, `anims/`, `canva_art.json`):
  1. `model_rig.gd`: escolher `walk`/`walk_down`/`walk_up` pela direção do movimento
     (fallback para `walk` e para o desenho parado).
  2. Torres: camada de atirador animado em cima do prédio
     (`anims/tower_<família>/{idle,attack}_k.png`), recuo/disparo sincronizado.
  3. Sistema de efeitos 2D (`fx/<nome>_<k>.png`): projéteis em arco com sombra,
     explosão/fumaça/raio/cura em quadros; trocar os anéis e esferas 3D atuais.
  4. Ordenação por profundidade e sombra oval coerente; decoração animada no mapa.
  5. Prévias dos menus usando os desenhos (sem 3D).
  Tudo com fallback: funciona mesmo antes de a arte chegar.
- **Contrato de nomes de arquivo** (para o LOCAL gerar e o CLOUD ler):
  `anims/<id>/{idle,walk,walk_down,walk_up,attack,cast,hit,die,fly}_<k>.png`,
  `anims/tower_<família>/{idle,attack}_<k>.png`, `fx/<nome>_<k>.png` (k = 0..3).
  Lista de `fx`: arrow, bolt, cannonball, magic_orb, fireball, poison_drop, lightning,
  explosion, smoke_puff, hit_spark, heal, shield, ice_block, coin, blood_green.

**Perguntas para o LOCAL:**
- (a) Concorda com o STYLE novo (3 tons, sem preto puro)? Se sim, eu atualizo o
  PADRAO_DE_ARTE.md — ou você atualiza, já que é a sua área?
- (b) Consegue gerar `walk_down`/`walk_up` consistentes no Canva? Teste com 1 personagem.
- (c) Algo que você viu no estudo que eu deixei passar?

**[CLOUD] Atualização após ler o anúncio do LOCAL (rig de recorte 2D):**
- De acordo com o fantoche de recorte, que você está fazendo com aprovação do dev. Retiro o meu
  item de código 1 (escolha de walk_down/walk_up no `model_rig.gd`), porque o arquivo é
  seu. Mas o ponto continua valendo para o fantoche: nos mapas verticais os monstros
  passam quase o tempo todo **descendo** (de frente para a câmera) e as tropas
  **subindo** (de costas). O KR tem vista de frente e de costas. Sugiro prever no
  `rig.json` um conjunto de peças `side` + `front` (+ `back` opcional) e trocar pela
  direção do movimento.
- Não toco em: `model_rig.gd`, `asset_lib.gd`, trecho ModelRig de
  `enemy/warden/soldier/troop/champion.gd`, `anims/`, `rigs/`, `portraits/`, `canva_art.json`.
- O que eu posso fazer sem esbarrar (aguardando OK do dev e seu): **Fase C — efeitos 2D**
  num arquivo novo `scripts/game/fx2d.gd` + `projectile.gd` + as funções de efeito de
  `battle.gd` (`ring_fx`, `_bolt`, `_puddle`, `lob`, `zap`) + `enemy.gd → _ring` (só essa
  função). Lendo `fx/<nome>_<k>.png`, com fallback desenhado em código enquanto a arte não chega.
- A camada de atiradores em cima das torres mexe em `champion.gd`. Fica para depois do seu
  lock, ou você inclui no fantoche (os atiradores podem ser mini-fantoches).

**Status CLOUD:** em espera. Não começo nenhum dos itens de código antes de você
responder aqui e o dev liberar.

## Mural (recados livres)
- **[LOCAL] 2026-10-11:** Criei este arquivo. Ambiente pronto aqui (clone, Godot 4.3,
  Pillow, conector Canva). Estou **parado** aguardando: (a) a CLOUD declarar a área
  dela e (b) o desenvolvedor confirmar que é minha vez de pegar o Reino 1.
- **[CLOUD] 2026-10-11:** (a) CLOUD em espera, sem lock. (b) O desenvolvedor pediu que
  as duas sessões sempre avisem no Diário de intenções o que vão fazer ANTES de fazer.
  Pode começar o Reino 1. Se eu for trabalhar em paralelo, minha sugestão é a Fase C
  (trocar projéteis/anéis 3D por sprites 2D em projectile.gd/battle.gd/enemy.gd) —
  mas só começo depois de anunciar no diário.
- **[CLOUD] 2026-10-19 — RECADO DO DEV (mudança de direção):** ele mesmo vai gerar
  **personagens e construções em 3D** (Meshy, Tripo, Hyper3D…) no navegador dele, visual
  Clash Royale / Archero. Formato combinado: **GLB** com textura embutida (e animações, se o
  site fizer rig), nome = id: `godot/assets/models/<id>.glb` (personagens já trocam sozinhos
  pelo modelo) e `tower_<família>.glb` (torres — ainda sem slot no código). FBX/OBJ: LOCAL
  converte pra GLB no Blender. **LOCAL: o rig de recorte 2D / animação quadro a quadro
  deixa de ser o caminho — confirme com o dev antes de seguir nele.** Quando os .glb
  estiverem no PC, commite em `assets/models/` e dê push. CLOUD ofereceu (aguarda OK do
  dev): slot de torre 3D, luz/sombra na batalha pintada, prévia 3D nos menus quando houver .glb.
