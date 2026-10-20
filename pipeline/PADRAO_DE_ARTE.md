# Bastion Rush — PADRÃO DE ARTE (fonte única da verdade)

> ⚠️ **DIRETRIZ DO DEV (2026-10-20): o jogo agora é 100% 3D**, estilo cartoon tipo
> Clash Royale. Este arquivo passa a valer só para a **IDENTIDADE do elenco** (§1: as
> folhas e os retratos — são a entrada do imagem→3D e o visual de ícones/cartas/bestiário).
> As partes de produção 2D (folhas de animação, efeitos desenhados, mapas pintados,
> Fases B–D) estão **obsoletas**. Pipeline 3D e lições: `CLAUDE.md` (ART STANDARD) e
> `COORDENACAO.md`.

~~Tudo no jogo é desenho 2D … Nada de 3D~~ (substituído pela diretriz acima).

Responda o desenvolvedor sempre em **português**.

---

## 1. Âncoras de estilo (use SEMPRE como referência)

**Desde 2026-10-19 a referência é o elenco que o desenvolvedor definiu** ("Esses serão
os novos personagens"). As 3 folhas originais ficam em `pipeline/referencias/`:

| Folha | Personagens |
|---|---|
| `personagens_1_monstros.jpg` | bog_lurker, bog_mother, drowned, drowned_king, ember_imp, gloombat, husk, ogre, ravager, the_maw, void_mite, wolf_pack |
| `personagens_2_golens_titas.jpg` | boulder_golem, cinder_treant, frost_wyrm, magma_tyrant, rift_sovereign, runestone, sand_colossus, sapling, sentry, siege_titan, void_spawn, wisp |
| `personagens_3_herois_tropas.jpg` | ashen_queen, frost_warden, hexmage, knight, pyre_knight, sister_vale, stormcaller, sunspear_lancer, the_eclipse, thistle_archer, troop_knight, troop_militia, warden |

Cada um já recortado em `godot/assets/art/portraits/<id>.png`. Para gerar arte NOVA no
mesmo estilo: no Canva, suba a folha certa (ou o retrato do personagem) e passe como
`imageReferences`. As âncoras antigas (ogro `MAHXvKTpLPs`, `MAHXvY4CaRE`, `MAHXvUPX584`)
estão **aposentadas**.

O desenvolvedor **rejeitou** o estilo realista ("parece jogo da Nintendo", ferrugem,
sujeira, anatomia realista). Se sair assim → **descarte e gere de novo**.

### Regras visuais (as das folhas)
- **Chibi**: cabeça grande, corpo atarracado, silhueta legível de longe.
- Contorno **escuro e grosso** em volta de tudo.
- Cores **vivas**, sombreado em **2–3 tons** com brilho suave (como Clash Royale /
  Kingdom Rush). Sem sujeira, sem textura realista.
- Personagens de **corpo inteiro**, de frente ou 3/4, de preferência **olhando para a DIREITA**.
- **Fundo liso** (branco ou pergaminho claro), sem chão; sombra leve sob os pés é tolerada —
  o `cut_roster.py` tira fundo, sombra e nome escrito.
- Heróis/aliados: dourados, vermelhos e azuis. Monstros: cada reino com a sua cor.

### STYLE (cole no fim de TODO prompt)
```
Chibi 2D cartoon mobile game character art like Clash Royale and Kingdom Rush, matching the
reference sheet exactly: big head, chunky body, thick dark outlines, vivid colors with 2-3 tone
cel shading and soft highlights, no grime, no realistic texture, big readable silhouette.
Full body, plain light background, no ground, no text, no frame borders.
```

---

## 2. Modelos de prompt (Canva `generate-image`)

Sempre passe a referência em `imageReferences` (FOLHA = a folha de `pipeline/referencias/` do grupo certo, subida no Canva). Quando for redesenhar/animar um
personagem que já existe, passe **primeiro o personagem, depois a âncora**.

### 2a. Redesenhar personagem existente (SQUARE_1_1)
refs: `[personagem, FOLHA]`
```
Redraw the character from the FIRST image in the EXACT art style of the SECOND image (the reference sheet).
Keep the same character identity: <descrição curta: cores, roupa, arma, pose>. Full body, single
character, facing right. <STYLE>
```

### 2b. Personagem novo (SQUARE_1_1)
refs: `[FOLHA]`
```
Character sprite for a mobile tower-defense game: <descrição>. Full body, single character,
facing right, in the EXACT art style of the reference image. <STYLE>
```

### 2c. Animação quadro a quadro (LANDSCAPE_2_1) — sempre 4 quadros
refs: `[portraits/<id>.png do personagem, FOLHA]`
```
2D game sprite sheet of THIS EXACT character from the FIRST image (same design, same colors),
drawn in the art style of the SECOND image. <ANIMAÇÃO>. 4 frames in a single horizontal row,
evenly spaced with clear white gaps between frames, same size and facing right in every frame.
<STYLE>
```
`<ANIMAÇÃO>` por tipo:
- **walk**: `A WALK CYCLE: legs and arms alternating like a classic cartoon walk`
- **fly** (voadores): `A FLYING LOOP: wings up, wings level, wings down, wings level, body bobbing`
- **attack** (corpo a corpo): `A MELEE ATTACK: 1 ready, 2 wind-up pulling the weapon back, 3 big strike forward with a swoosh trail, 4 follow-through`
- **attack** (à distância): `A SHOOTING ATTACK: 1 ready, 2 draw/aim, 3 release with a small flash, 4 recover`
- **cast** (magos/chefes): `A SPELL CAST: 1 ready, 2 arms raised gathering glowing energy, 3 big magic burst, 4 recover`
- **die**: `A DEFEAT: 1 hit recoil with pained face, 2 stumbling back, 3 falling, 4 lying knocked out with little stars` (monstros: o 4º quadro vira `dissolving into a puff of cartoon smoke`)

### 2d. Torre (SQUARE_1_1)
refs: `[FOLHA]` (e a torre antiga, se for redesenho)
```
Tower sprite for a mobile tower-defense game, Kingdom Rush layout, seen from a slightly high 3/4
front view: <descrição>. Single object, centered, full building visible. <STYLE>
```

### 2e. Efeito / projétil (SQUARE_1_1 para efeito único; LANDSCAPE_2_1 para 4 quadros)
refs: `[FOLHA]`
```
2D cartoon game effect: <flecha / bola de fogo / explosão / raio / poça de veneno / estrela de cura …>.
<para animação: 4 frames in a single horizontal row showing it growing, peaking and fading>. <STYLE>
```

### 2f. Mapa de batalha (PORTRAIT_9_16)
refs: `[FOLHA]` + o mapa do Portão Partido `MAHXvPjG1cg` (para manter o layout de câmera)
```
Top-down 3/4 painted battle map for a mobile tower-defense game in Kingdom Rush style, vertical
portrait: <tema do reino>, <N> dirt roads coming from the top edge and joining at a castle gate
near the bottom, round empty stone build spots beside the roads, lots of trees, rocks, props
along the borders. Same flat cartoon style as the reference: thick outlines, flat colors.
No characters, no text.
```
O número/forma de estradas tem de bater com o `layout`/`lanes` do reino em
`godot/scripts/autoload/game_data.gd`. Depois de importar, trace estradas e
círculos de construção em `GameData.PAINTED` (ver o de `broken_gate`;
coordenadas UV 0–1 da imagem, `end` = v onde fica o portão).

---

## 3. Onde cada arte entra (slots — sem mexer em código)

| Tipo | Arquivo |
|---|---|
| Personagem (desenho base) | `godot/assets/art/portraits/<id>.png` |
| Animação | `godot/assets/art/anims/<id>/<anim>_<k>.png` (k = 0..3) |
| Torre | `godot/assets/art/towers/<família>.png` |
| Mapa de batalha | `godot/assets/art/battle/<realm_id>.png` + entrada em `GameData.PAINTED` |
| Mapa do mundo (miniatura) | `godot/assets/art/realms/<realm_id>.png` |
| Efeitos | `godot/assets/art/fx/<nome>.png` / `fx/<nome>_<k>.png` (código ainda precisa usar — ver §6) |

Animações reconhecidas pelo motor (`scripts/game/model_rig.gd`): `idle, walk,
attack, cast, hit, die, fly`. Quem não tem quadros usa o desenho base com
squash & stretch. Tropas usam as pastas `troop_militia`, `troop_bowmen`,
`troop_wolves`, `troop_knight` (o código já faz o alias).

### Registro obrigatório
Toda imagem aprovada entra em `pipeline/canva_art.json`:
```json
{"n": <próximo>, "title": "Animação: Kael andando", "media_id": "MAH...", "link": "https://www.canva.com/M/MAH...", "slots": ["anims/warden/walk.sheet"]}
```
- Slot `.sheet` = folha de 4 quadros → o importador corta sozinho em `anims/<id>/<anim>_0..3.png`.
- Arte antiga substituída: marque `"obsolete": true` e mova `slots` para `slots_old`.

### Colocar a arte no jogo
- **Na nuvem** só chega a prévia de 200 px (o canva.com é bloqueado pelo proxy).
  Coloque a prévia como provisória:
  `python3 pipeline/tools/import_canva.py --file <n> <caminho da prévia em tool-results>`
- **Alta resolução**: o desenvolvedor roda no PC dele
  `python3 pipeline/tools/import_canva.py` (abre os links em ordem e importa os downloads),
  ou manda as imagens numa **mensagem só de imagens** (aí ficam salvas em
  `.../images/N.webp`; imagens coladas no meio de um turno NÃO ficam salvas).
- Corte manual de folha: `python3 pipeline/tools/split_sheet.py FOLHA.png <id> <anim> --frames 4`
- **Folha de elenco** (vários personagens com o nome embaixo, como as de `pipeline/referencias/`):
  `python3 pipeline/tools/cut_roster.py FOLHA.jpg id1 id2 ... --out /tmp/teste` (ids na
  ordem de leitura; confira e rode sem `--out` para gravar em `portraits/`). Depois marque
  como `obsolete` no `canva_art.json` as entradas antigas desses retratos — senão o
  `import_canva.py` baixa a arte velha por cima.

---

## 4. Lista de trabalho (na ordem)

### Fase A — elenco no estilo padrão
✅ **Feito (2026-10-19)**: os 37 personagens das folhas do dev estão em `portraits/`
(troop_wolves = wolf_pack).
Falta, no MESMO estilo das folhas (modelo 2b, com a folha como referência):
- Tropa: **troop_bowmen** (ainda no desenho antigo).
- Monstros ainda sem desenho: ice_wisp, yeti, scorpion, sand_wraith, magma_slime,
  fire_imp, spore_toad, root_horror, war_drummer, rage_shaman, eclipse_knight,
  radiant_shade (nomes/cores em `game_data.gd`). Sem desenho, o jogo mostra o 3D antigo.
- Torres: comparar as 8 de `towers/` com as folhas; redesenhar (2d) as que destoarem.

Os media ids originais de cada personagem estão em `pipeline/canva_art.json`
(procure pelo slot `portraits/<id>.png`).

### Fase B — animações (modelo 2c), uma folha por linha
| Grupo | Animações |
|---|---|
| Heróis (11) | walk, attack (ou cast para magos/curandeira), die |
| Tropas (militia, bowmen) | walk, attack |
| Monstros runner/brute | walk, attack, die |
| Monstros caster | walk, cast, die |
| Monstros flyer (gloombat, ice_wisp, sand_wraith, radiant_shade) | fly, attack, die |
| Chefes | walk, attack, cast, die |

Nenhuma pronta: o antigo `ravager/attack` era do ogro aposentado e foi para
`pipeline/obsoleto/`. Comece pelo reino 1 (Portão Partido:
warden, troop_militia, troop_bowmen, wisp, husk, ravager, the_maw) para fechar uma
fase inteira e mostrar ao desenvolvedor antes de seguir.

### Fase C — efeitos (modelo 2e) e código
Flecha, bola de fogo, bala de canhão, virote de balista, gota de veneno, raio, explosão,
anel de impacto, cura, escudo, gelo (torre congelada), moeda de ouro.
O código ainda desenha projéteis/anéis em 3D (`scripts/game/projectile.gd`,
`battle.gd` → `ring_fx`, `_bolt`, `_puddle`; `enemy.gd` → `_ring`). Trocar por
`Sprite3D` billboard com essas texturas (mesmo padrão de `ModelRig.setup_sprite`).

### Fase D — mapas de batalha (modelo 2f)
Um por reino (os 9 que faltam; `broken_gate` já existe), cada um com tema, cores e
número de estradas do seu reino. Depois traçar em `GameData.PAINTED`.

### Fase E — sobras de 3D
Menus que ainda montam prévia 3D (`Screen.preview` em `ui/collection.gd`, `ui/hero.gd`,
`ui/encyclopedia.gd`) → mostrar o desenho (`UIKit.art("portraits/<id>.png")`).

---

## 5. Verificação antes de dizer "pronto"
```
godot --headless --path godot --quit-after 120            # sem SCRIPT ERROR
godot --path godot -- --scene=battle --realm=<id> --auto --level=<n>   # ler AUTO_RESULT
godot --path godot -- --shot=/tmp/x.png --frames=300 --scene=battle --realm=<id> --auto --slot=1   # print (precisa de display; use xvfb-run)
```
Olhe o print: todos os personagens no mesmo estilo? pés no chão? tamanho coerente?

## 6. Commits
- Branch `claude/bastion-rush-overhaul-oejz56`, commits pequenos por lote, mensagens em português.
- Nunca grave chaves/tokens em arquivo. Nunca use assets do APK do Kingdom Rush.
- Não use `generate_3d` do Blender (pode custar créditos) sem perguntar.
- Ao fim de cada fase, mostre prints ao desenvolvedor e liste os links do Canva da fase
  (para ele baixar em alta resolução).
