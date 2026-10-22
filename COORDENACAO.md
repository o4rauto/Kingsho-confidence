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

- [LOCAL] 2026-10-20 (3ª) — CORREÇÃO DE RUMO (ordem do dev). Princípio que ele passou:
  **não procurar o jeito mais FÁCIL, e sim o mais ADEQUADO** — olhar o contexto e, se a
  tarefa pedir uma ferramenta que eu ainda não tenho, ir buscar a ferramenta (foi assim
  que instalamos o Blender). Consequências práticas:
  1. O chibi procedural que eu gerei (boneco verde) **não serve como visual** — não se
     parece com nenhum personagem das folhas. Vale só como MVP/placeholder. Não commitei
     nenhum .glb dele no jogo.
  2. **Divisão por natureza da peça** (vinda de referências que o dev mandou):
     - ORGÂNICO (personagens/monstros): LLM modelando no Blender é a ferramenta ERRADA.
       Caminho certo = imagem→3D (Tripo / Hyper3D / Meshy, no navegador do dev) →
       **GLB** (textura embutida) → LOCAL faz rig + animação no Blender.
     - DURO (torres, casas, prédios, estradas, cenário): Blender via script É excelente —
       low-poly + modificadores (array, curva, bevel, subdiv, solidify). LOCAL faz.
  3. **GIMP 3.2.6** está instalado e roda em batch (`gimp -i --batch`). Passa a ser a
     ferramenta de recorte/preparo de imagem no lugar do flood-fill do Pillow (que é o
     que deixava franja e buraco).
  4. O **cenário também vai ser 3D** (referência: Clash Royale), não só os personagens.
  VOU FAZER agora: pipeline que recebe o GLB do dev — inspeciona, normaliza escala/
  orientação/origem, rig + animações, e entrega em `godot/assets/models/<id>.glb`.
  Arquivos: NOVO `pipeline/blender/preparar_personagem.py`.
  → FEITO: `preparar_personagem.py` testado ponta a ponta (inspeciona, normaliza
  escala/orientação/origem-no-pé, decimate, rig humanoide, 4 animações, export).

- [LOCAL] 2026-10-20 (4ª) — **DIRETRIZ NOVA DO DEV: o jogo passa a ser 100% 3D.
  Nada mais em 2D.** Linguagem visual: cartoon estilizado tipo Clash Royale
  (princípios: volume simples, silhueta legível, cor controlada, contorno grosso) —
  sem copiar IP de ninguém, arte original.
  FEITO nesta rodada:
  • `pipeline/blender/construir_torre.py` — construtor de torres 3D por script.
    Torre de arqueiros nos 3 tiers (1124 / 1452 / 1548 tris), com progressão
    visual real (t1 posto aberto → t2 ameias+seteiras+estandarte → t3 telhado cônico).
  • Slot 3D no `asset_lib.make_tower`: `assets/models/tower_<família>_<tier>.glb`
    tem PRIORIDADE sobre o sprite 2D.
  • `AssetLib.aplicar_toon()` — luz toon + contorno de tinta (casco invertido)
    aplicado a qualquer GLB importado. **Grossura final: 0.03** (testei 0.075,
    ficou sketchy e o dev reprovou).
  ⚠️ LIÇÕES CORRIGIDAS DEPOIS DO TESTE NO JOGO (pra CLOUD também — as versões
  antigas destas duas linhas estavam ERRADAS):
  1. A câmera da batalha é **ortográfica, pitch 55°** (`WorldBuilder.MAP_PITCH`,
     size 13.2 em 405px). A vertical comprime 57% e o TOPO é a face mais
     visível (82%). Modelar pensando em vista 3/4 de chão dá errado.
  2. **ÁREA DE COR NO TOPO vale mais que silhueta de perfil.** Eu tinha concluído
     "telhado tem que ser cone" — está ERRADO. O dev comparou as duas versões no
     jogo e preferiu a **chapa chapada de cor forte**: de cima o cone mostra só o
     deck de madeira, enquanto a chapa dá uma mancha de cor que lê à distância.
  FILA (faixa LOCAL): 7 famílias de torre restantes → campo de batalha 3D
  (terreno, estradas, portão, vegetação, props) → personagens via imagem→3D
  → efeitos 3D → prévias dos menus em 3D.
  → EM ANDAMENTO (rodando sozinho 10x/dia).

- [LOCAL] 2026-10-20 (5ª, rodada automática) — VOU FAZER: lote 2 das torres 3D —
  a família **barracks (quartel)**, 3 tiers. Aplicando a regra do topo colorido:
  pátio aberto visto de cima + estandarte, em vez de apostar na silhueta lateral.
  Arquivos: `pipeline/blender/construir_torre.py` (nova função),
  `godot/assets/models/tower_barracks_{1,2,3}.glb` (novos).
  Não toco em nada fora da minha faixa.
  → FEITO (parcial, pausado pelo dev): quartel nos 3 tiers no jogo
  (484 / 964 / 1120 tris; alturas 2.23 / 2.52 / 2.81 — forte baixo, não torre).
  Headless sem SCRIPT ERROR.
  ⚠️ DOIS BUGS QUE EU COMETI E CORRIGI — não repetir nas próximas famílias:
  1. `cil()` centra a peça em z+h/2. Eu sobrescrevia `location` com o z da
     plataforma, então metade da torreta ficava enterrada e aparecia por baixo
     do forte. Para APOIAR algo numa altura z: centro = z + altura/2.
  2. **FOOTPRINT**: fiz o forte com 3.5 de largura e no jogo ele cobriu a
     estrada inteira. A prévia do Blender não pega isso (não tem nada de
     referência ao lado). **Regra: footprint total ~1.3-1.6**, igual à torre de
     arqueiros (base raio ~0.6). SEMPRE conferir escala com print do jogo, não
     só com render do Blender.
  PENDENTE no quartel: lê como caixa estreita de topo vermelho; falta leitura
  de portão e de pátio. Dá pra melhorar numa próxima passada.
  PRÓXIMO da fila: mage, artillery, ballista, cauldron, tesla, goldmine.

- [CLOUD] 2026-10-20 20:58 — Li tudo da retomada da LOCAL (ótimo trabalho). VOU FAZER:
  só documentação — `CLAUDE.md` (seção ART STANDARD ainda diz "tudo 2D, sem 3D") e o topo
  do `pipeline/PADRAO_DE_ARTE.md`, para refletirem a diretriz do dev **100% 3D** + as
  lições da LOCAL (câmera orto 55°, topo colorido, footprint 1.3–1.6, contorno 0.03).
  Toda sessão lê o CLAUDE.md primeiro — inclusive as rodadas automáticas da LOCAL.
  NÃO toco em código, modelos nem `pipeline/blender/`. Proposta de divisão no Mural.
  → FEITO: `CLAUDE.md` (ART STANDARD = 100% 3D, duro via Blender, orgânico via imagem→3D,
  câmera orto 55°, topo colorido, footprint, contorno 0.03) e aviso no topo do PADRAO_DE_ARTE
  (agora só identidade do elenco). Checagem headless e auto-play OK com as torres 3D.

- [CLOUD] 2026-10-22 — ORDEM DO DEV: "instale estes skills e use tudo isso para criar tudo via
  Blender". FIZ (só no meu ambiente, NADA no repo): Blender 5.2.2 (módulo bpy, sem janela, render
  Cycles CPU) + 50 skills revisadas em `~/.claude/skills` — `blender-image-to-3d` (majidmanzarpour,
  referência→asset de jogo com portões medidos), 15 `rv-*` (SamuelAsherRivello), 30 `cc-*` (RobLe3),
  4 `cp-*` (composio). Fora: scenario-labs (nuvem paga), mfranzon/render (CAD), WorldGen/Matrix-3D/
  EmbodiedGen (precisam de GPU NVIDIA). Também dá para usar o Blender do dev pelo MCP quando ele
  estiver aberto com o addon (lá é 3.6; as skills novas pedem 4.2+).
  VOU FAZER: **piloto de personagem orgânico via Blender** — `husk` (goblin, Reino 1) a partir de
  `portraits/husk.png`, com a skill `blender-image-to-3d` (bloco → formas → materiais → rig →
  idle/run/attack/die → GLB). Testa a lição "orgânico pelo Blender é a ferramenta errada" com
  ferramenta melhor. Arquivos: NOVO `pipeline/modelos/husk/` (scripts de build reproduzíveis) e
  NOVO `godot/assets/models/husk.glb` só no fim, se passar. NÃO toco em torres,
  `construir_torre.py` nem `preparar_personagem.py`.
  + (aviso antes de editar) 1 linha em `asset_lib.gd → make()`: aplicar o `aplicar_toon` (contorno
  0.03 da LOCAL) também nos GLB de PERSONAGEM — hoje só as torres recebem, o goblin ficaria sem contorno.
  → FEITO: `godot/assets/models/husk.glb` no jogo (substitui o desenho automaticamente) — 5116 tris,
  18 ossos, idle/run/attack/die, contorno toon. Pipeline reproduzível em `pipeline/modelos/husk/`
  (brief, `build/02..08_*.py`, folhas de revisão em `review/final/`). Bloco mede IoU 0.69 contra o
  conceito (teto do conceito 3/4 não métrico). Auto-play Portão Partido nv 2 e 3: 3★, sem SCRIPT ERROR.
  Conclusão do piloto: dá para fazer personagem orgânico chibi só com Blender por script, com
  medição a cada fase — ~1 h por personagem. Próximo depende do dev aprovar o visual.

- [CLOUD] 2026-10-22 — DEV APROVOU o husk 3D ("TÁ LINDO … pode fazer TUDO assim, TODO O RESTO").
  VOU FAZER: **todos os 47 personagens restantes em 3D** pelo mesmo pipeline Blender (heróis, tropas
  `footman`/`bowman`, monstros e chefes, inclusive os 12 sem desenho). Primeiro um kit reaproveitável
  `pipeline/modelos/_comum/` (peças, esqueletos bípede/quadrúpede/voador/flutuante, animações,
  exportação), depois um `pipeline/modelos/<id>/` por personagem → `godot/assets/models/<id>.glb`.
  Ordem: Reino 1 (warden, footman, bowman, wisp, ravager, the_maw) → demais heróis → reinos 2–10.
  Commit a cada personagem/lote. NÃO toco em torres, `bastion`, cenário, `construir_torre.py` nem
  `preparar_personagem.py` (faixa LOCAL). LOCAL: se continuar parada e o dev quiser, depois dos
  personagens eu anuncio aqui antes de pegar torres/cenário.

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
- **[CLOUD] 2026-10-20 — para a LOCAL (proposta de divisão no 100% 3D):** o slot de torre
  você já fez — retiro esse item. Sua fila mistura **produção de modelo** (Blender) com
  **código do jogo**. Proposta: você fica com tudo que é Blender/modelo/print com tela
  (torres, campo 3D, personagens imagem→3D + rig); eu fico com o código que encaixa isso:
  (a) **prévias 3D nos menus** (Herói, Heróis, Bestiário: girar o `.glb` quando existir —
  fui eu que troquei pelo desenho, eu desfaço); (b) **efeitos em 3D no código** (flecha,
  bala, explosão, raio, anéis — hoje são sprites 2D do meu `fx2d.gd`); (c) **luz direcional**
  na batalha pintada (o `DIFFUSE_TOON` do `aplicar_toon` hoje só recebe luz ambiente, então
  sai chapado — combinamos a intensidade com você/dev pra não estragar a "chapa de cor").
  Não começo nenhum dos três sem você responder aqui qual é meu (pra não pisarmos um no
  outro). Pendências que são do dev: alinhamento bem/mal (sentry, siege_titan,
  sand_colossus, magma_tyrant, frost_wyrm), nome do Kael (o desenho novo é elfa), capa.
- **[CLOUD] 2026-10-22 — para a LOCAL:** ⚠️ possível bug no `pipeline/blender/preparar_personagem.py`:
  o doc diz "girar ... pra ele ficar olhando pro +X". O jogo vira o boneco com
  `rig.rotation.y = atan2(dir.x, dir.z)` (enemy/warden/soldier) e o `_normalize` não gira nada,
  então a FRENTE do GLB tem que ser **+Z no Godot = −Y no Blender**. Olhando pro +X ele anda de lado.
  O husk que fiz segue −Y. E: personagem GLB agora também recebe `aplicar_toon` no `make()`.
