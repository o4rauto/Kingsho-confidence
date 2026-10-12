# Bastion Rush — PADRÃO DE ARTE (fonte única da verdade)

Tudo no jogo é **desenho 2D**, estilo desenho animado de TV (Cartoon Network /
Nickelodeon) com visual de Kingdom Rush. **Nada de 3D** para personagens, torres,
efeitos ou mapas. Toda arte nova segue ESTE arquivo, sem exceção.

Responda o desenvolvedor sempre em **português**.

---

## 1. Âncoras de estilo (use SEMPRE como referência no Canva)

| Papel | Canva media id | O que é |
|---|---|---|
| **ÂNCORA PRINCIPAL** | `MAHXvKTpLPs` | Ogro vermelho com clava (Devastador). É ESTE o estilo. |
| Aprovado | `MAHXvY4CaRE` | Casca Cinzenta redesenhada (goblin) |
| Aprovado | `MAHXvUPX584` | Kael redesenhado (herói) |

O desenvolvedor **rejeitou** o estilo detalhado/realista ("parece jogo da
Nintendo", ferrugem, sujeira, anatomia realista). Se uma imagem gerada tiver
textura, sujeira, brilho realista ou contorno fino → **descarte e gere de novo**.

### Regras visuais
- Contorno **grosso e uniforme**, marrom-escuro / quase preto.
- Cores **chapadas** com no máximo **um** tom de sombra suave. Sem textura, sem gradiente realista.
- Formas **arredondadas, robustas, cabeça grande**, silhueta legível de longe.
- Personagens **olhando para a DIREITA** (o jogo espelha sozinho).
- **Fundo branco puro**, sem chão, sem texto, sem moldura (o importador remove o branco).
- Paleta viva e saturada, mas não neon. Heróis/aliados: quentes e azuis. Monstros: cada reino com a sua cor.

### STYLE (cole no fim de TODO prompt)
```
Simple flat 2D TV cartoon style like Cartoon Network, matching the red ogre reference exactly:
thick uniform dark brown outlines, flat colors with only one soft shadow tone, no texture,
no grime, no realistic detail, rounded chunky shapes, big head, big readable silhouette.
Plain pure white background, no ground, no text, no frame borders.
```

---

## 2. Modelos de prompt (Canva `generate-image`)

Sempre passe a âncora em `imageReferences`. Quando for redesenhar/animar um
personagem que já existe, passe **primeiro o personagem, depois a âncora**.

### 2a. Redesenhar personagem existente (SQUARE_1_1)
refs: `[personagem, MAHXvKTpLPs]`
```
Redraw the character from the FIRST image in the EXACT art style of the SECOND image (the red ogre).
Keep the same character identity: <descrição curta: cores, roupa, arma, pose>. Full body, single
character, facing right. <STYLE>
```

### 2b. Personagem novo (SQUARE_1_1)
refs: `[MAHXvKTpLPs]`
```
Character sprite for a mobile tower-defense game: <descrição>. Full body, single character,
facing right, in the EXACT art style of the reference image. <STYLE>
```

### 2c. Animação quadro a quadro (LANDSCAPE_2_1) — sempre 4 quadros
refs: `[personagem JÁ no estilo padrão, MAHXvKTpLPs]`
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
refs: `[MAHXvKTpLPs]` (e a torre antiga, se for redesenho)
```
Tower sprite for a mobile tower-defense game, Kingdom Rush layout, seen from a slightly high 3/4
front view: <descrição>. Single object, centered, full building visible. <STYLE>
```

### 2e. Efeito / projétil (SQUARE_1_1 para efeito único; LANDSCAPE_2_1 para 4 quadros)
refs: `[MAHXvKTpLPs]`
```
2D cartoon game effect: <flecha / bola de fogo / explosão / raio / poça de veneno / estrela de cura …>.
<para animação: 4 frames in a single horizontal row showing it growing, peaking and fading>. <STYLE>
```

### 2f. Mapa de batalha (PORTRAIT_9_16)
refs: `[MAHXvKTpLPs]` + o mapa do Portão Partido `MAHXvPjG1cg` (para manter o layout de câmera)
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

---

## 4. Lista de trabalho (na ordem)

### Fase A — redesenhar tudo no estilo padrão (modelo 2a)
Já no padrão: `ravager` (âncora), `husk`, `warden`.
- Heróis: pyre_knight, thistle_archer, sister_vale, runestone, wolf_pack, frost_warden,
  boulder_golem, stormcaller, sunspear_lancer, ashen_queen
- Tropas: troop_militia, troop_bowmen (troop_wolves = wolf_pack, troop_knight = pyre_knight — mesmos slots)
- Monstros já desenhados (redesenhar): wisp, ember_imp, sapling, gloombat, drowned,
  bog_lurker, hexmage, sentry, knight, void_spawn, void_mite, ogre
- Monstros ainda sem desenho (modelo 2b): ice_wisp, yeti, scorpion, sand_wraith,
  magma_slime, fire_imp, spore_toad, root_horror, war_drummer, rage_shaman,
  eclipse_knight, radiant_shade (nomes/cores em `game_data.gd`)
- Chefes (redesenhar): the_maw, cinder_treant, drowned_king, siege_titan,
  rift_sovereign, frost_wyrm, sand_colossus, magma_tyrant, bog_mother, the_eclipse
- Torres: comparar as 8 de `towers/` com a âncora; redesenhar (2d) as que estiverem
  detalhadas demais.

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

Já pronto e no estilo: `ravager/attack`. Comece pelo reino 1 (Portão Partido:
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
