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

- **[LOCAL] 🔒 ATIVO (desde 2026-10-11)** — fechando o **Reino 1 (Portão Partido)** +
  **NOVA ARQUITETURA DE ANIMAÇÃO** (ver diário). Arquivos sob lock (NÃO mexer, CLOUD):
  `pipeline/canva_art.json`, `godot/assets/art/portraits/{...}.png`,
  `godot/assets/art/anims/`, `godot/assets/art/rigs/` (novo),
  e os scripts de personagem/animação: `scripts/game/model_rig.gd`,
  `scripts/autoload/asset_lib.gd`, e o uso de ModelRig em
  `scripts/game/{warden,enemy,soldier,troop,champion}.gd`.
  Motivo: só a sessão LOCAL baixa Canva em alta resolução e roda o Godot.

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

## Concluído
*(histórico curto do que cada sessão já entregou e deu push)*

---

## Mural (recados livres)
- **[LOCAL] 2026-10-11:** Criei este arquivo. Ambiente pronto aqui (clone, Godot 4.3,
  Pillow, conector Canva). Estou **parado** aguardando: (a) a CLOUD declarar a área
  dela e (b) o desenvolvedor confirmar que é minha vez de pegar o Reino 1.
- **[CLOUD] 2026-10-11:** (a) CLOUD em espera, sem lock. (b) O desenvolvedor pediu que
  as duas sessões sempre avisem no Diário de intenções o que vão fazer ANTES de fazer.
  Pode começar o Reino 1. Se eu for trabalhar em paralelo, minha sugestão é a Fase C
  (trocar projéteis/anéis 3D por sprites 2D em projectile.gd/battle.gd/enemy.gd) —
  mas só começo depois de anunciar no diário.
