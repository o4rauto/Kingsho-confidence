# Pipeline de assets — o "modo de construção" do vídeo

Mesmo método do vídeo de referência (IA → Blender → animações → engine com o
Claude operando as ferramentas via MCP), adaptado para o Bastion Rush:

| Vídeo | Bastion Rush |
|---|---|
| Nano Banana Pro (imagens) | **ChatGPT / `gpt-image-1`** — `tools/generate_art.py` |
| Tripo (imagem → 3D) | Tripo, a partir das imagens em `pipeline/concept/` |
| Juntar partes no Blender | `blender/assemble_character.py` + ajuste fino (Sculpt ▸ Grab) |
| Óculos sem transparência | `blender/separate_transparent.py` |
| AccuRIG (rig) | AccuRIG (gratuito) |
| Mixamo (animações) | Mixamo — nomes padronizados abaixo |
| Claude + MCP do Blender (animações sob medida) | o mesmo, com `CLAUDE.md` na raiz do repo |
| Unreal | **Godot 4.3** — o jogo já roda e troca os provisórios pelos seus modelos |

O jogo **sempre funciona**: tudo que ainda não tem arte usa um provisório
gerado por código. Cada asset que você termina é só soltar no lugar certo.

---

## 0. Instalação (no seu Kali)

```bash
# Godot 4.3 (editor):  https://godotengine.org/download  (Linux, versão 4.3)
# Blender 4.x:         sudo apt install blender   ou   https://www.blender.org/download/
# Python 3.8+ já vem no Kali.
# Claude Code local:   npm install -g @anthropic-ai/claude-code
# MCP do Blender:      pip install uv   (o .mcp.json da raiz já aponta "uvx blender-mcp")
#   + no Blender: instale o addon do blender-mcp (github.com/ahujasid/blender-mcp),
#     abra a aba "BlenderMCP" na barra lateral (N) e clique em "Connect to Claude".
```

Contas: OpenAI (chave de API com acesso a imagens), Tripo, Mixamo (Adobe) e AccuRIG (ActorCore).

Abra o Claude Code **na raiz deste repositório** — ele lê o `CLAUDE.md` e o
`.mcp.json` e passa a operar o seu Blender como no vídeo.

## 1. Imagens com o ChatGPT (estilo cartoon tipo Clash Royale)

### Jeito grátis — usando o SEU ChatGPT (sem API, sem créditos)

```bash
sudo apt install xclip                                # para copiar o prompt sozinho
pip install pillow                                    # converte/encolhe as imagens
python3 pipeline/tools/chatgpt_helper.py              # começa pelo que mais aparece no jogo
```

O script copia um prompt por vez. Você cola no ChatGPT (Ctrl+V), espera a
imagem e clica em **baixar**. O script percebe o arquivo novo em
`~/Downloads`, converte e coloca no lugar certo do jogo, depois passa para o
próximo prompt. `s`+Enter pula uma imagem; `q`+Enter sai (continua de onde
parou na próxima vez). `--list` mostra o que falta e `--all` inclui as
fichas para o Tripo.

### Jeito automático — API da OpenAI (pago à parte)

```bash
export OPENAI_API_KEY=sk-...                         # nunca coloque no git
python3 pipeline/tools/generate_art.py --dry-run     # mostra prompts e custo (pipeline/prompts.md)
python3 pipeline/tools/generate_art.py --only concept --ids warden   # comece por 1 personagem
python3 pipeline/tools/generate_art.py               # tudo (~109 imagens, ~US$5 em qualidade média)
```

Todos os prompts compartilham um **manual de estilo** único (proporções
"de brinquedo", cabeça grande, silhueta grossa, cores saturadas, pintura suave,
luz de estúdio) — é isso que deixa o jogo inteiro coerente. O estilo é
descrito em palavras em vez de citar o nome de outro jogo: o modelo segue
melhor descrições, e a identidade visual fica sua.

Saídas:
- `pipeline/concept/<id>_turnaround.png` — personagem inteiro, pose A, fundo liso → **vai para o Tripo**
- `pipeline/concept/<id>_parts.png` — o MESMO personagem em partes (cabeça, tronco, pernas, acessórios), gerado a partir do turnaround — a técnica do vídeo
- `godot/assets/art/portraits|realms|boons|ui/` — arte 2D que o jogo usa **direto** (retratos das cartas, fundo dos reinos, ícones, logo, fundo do menu)

Não gostou de uma imagem? `--force --ids <id>` refaz só ela. Arquivos existentes são pulados, então dá pra parar e continuar.

## 2. 3D no Tripo

Para cada personagem, no Tripo:
1. Recorte cada parte do `<id>_parts.png` (cabeça, tronco, pernas, cada acessório) e gere um modelo por parte — dá muito mais qualidade que gerar o corpo inteiro de uma imagem só (como explicado no vídeo).
2. Exporte em **GLB** com os nomes:
   `<id>_head.glb`, `<id>_torso.glb`, `<id>_legs.glb`, `<id>_prop_<nome>.glb`
3. Coloque numa pasta, ex.: `~/bastion_parts/`

Personagens simples (torres, criaturas pequenas) podem ir direto do `_turnaround.png` para um modelo único.

## 3. Montar no Blender

```bash
blender --background --python pipeline/blender/assemble_character.py -- warden ~/bastion_parts ~/bastion_out 1.8
```
Ou peça ao Claude (com o MCP do Blender conectado): *"monte o warden a partir de ~/bastion_parts"*.

Depois, o ajuste fino das emendas (a parte "mais chata" do vídeo): Sculpt ▸
Grab ou edição proporcional para encaixar pescoço/cintura. Óculos, cristais e
gemas transparentes:
```python
exec(open("pipeline/blender/separate_transparent.py").read()); make_transparent(["lens", "crystal"])
```

## 4. Rig (AccuRIG) e animações (Mixamo)

1. Abra `<id>_assembled.glb` no AccuRIG → auto-rig → exporte FBX.
2. Suba o FBX no Mixamo. Baixe as animações abaixo, **com estes nomes de arquivo**:
   - `idle.fbx` — **With Skin** (é a base: malha + esqueleto)
   - `run.fbx`, `attack.fbx`, `hit.fbx`, `die.fbx` — **Without Skin**
   - suporte/magos também `cast.fbx`; voadores `fly.fbx`

| Tipo | Sugestões no Mixamo |
|---|---|
| Warden / arqueiros | Standing Idle, Running, Standing Draw Arrow, Hit Reaction, Dying |
| Melee | Sword And Shield Idle, Sword And Shield Run, Sword And Shield Slash, ... |
| Suporte | Idle, Running, Standing 1H Magic Attack (cast), ... |
| Criaturas/chefes | Mutant Idle, Mutant Run, Mutant Swiping, Mutant Dying |

3. Animações que **não existem** em biblioteca (invocar campeão, pancada do
   chefe, carta sendo jogada...): peça ao Claude via MCP do Blender, como no
   vídeo. Ex.: *"crie uma animação 'cast' de 1s para o sister_vale levantando o
   cajado acima da cabeça, e salve como cast"*. Revise e peça ajustes —
   no vídeo nada saiu de primeira.

## 5. Exportar para a Godot

```bash
blender --background --python pipeline/blender/export_for_godot.py -- warden ~/anims/warden godot/assets/models
```
Gera `godot/assets/models/warden.glb` com todas as animações. **Abra a Godot e
pronto**: o jogo detecta o arquivo, ajusta a escala sozinho e toca
`idle/run/attack/hit/die/cast` nos momentos certos (menu, cartas, batalha,
coleção — os ícones 3D também passam a usar o seu modelo).

### Nomes dos slots (o id é o nome do arquivo)
Veja `pipeline/game_content.json` (gerado a partir do jogo). Resumo:
- Herói: `warden`
- Campeões: `pyre_knight thistle_archer runestone sister_vale wolf_pack frost_warden boulder_golem stormcaller sunspear_lancer ashen_queen`
- Inimigos e chefes: todos os ids em `enemies` (ex.: `wisp`, `ember_imp`, `yeti`, `frost_wyrm`, `the_eclipse`)
- Bastião: `bastion`
- Cenário por bioma: `prop_<bioma>_tree.glb`, `prop_<bioma>_crystal.glb` (biomas: ruins forest swamp keep rift ice desert volcano mire sunspire)

## 6. Sons e música

Arquivos `.ogg`/`.wav` em `godot/assets/audio/` substituem os sons sintetizados:
`shoot hit enemy_die deploy coin click back boon ult boss hurt victory defeat`,
`music` (menu) e `music_<id_do_reino>` (uma trilha por reino).

## 7. Android

Na Godot: *Editor ▸ Manage Export Templates* (baixe os da 4.3) → *Project ▸
Export ▸ Add ▸ Android*. Configure o SDK Android e uma keystore de release
(nunca no git) e exporte o `.aab` para a Play Console.

## Verificação automática (o que eu uso para testar)

```bash
GODOT=/caminho/godot
$GODOT --headless --path godot --quit-after 120                     # carrega tudo, mostra erros
$GODOT --headless --path godot -- --scene=battle --realm=ashen_caldera --auto --level=8
#   joga sozinho em 4x e imprime AUTO_RESULT (vitória, ondas, abates, integridade)
$GODOT --path godot -- --shot=/tmp/tela.png --frames=90 --scene=realm_select   # screenshot
$GODOT --headless --path godot -- --export-data=pipeline/game_content.json   # atualiza a lista de assets
```
