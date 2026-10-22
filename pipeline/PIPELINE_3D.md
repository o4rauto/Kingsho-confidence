# Procedimento completo de produção 3D — Bastion Rush

Fonte única da verdade para **cenários, assets, personagens, construções, HUD,
mecânica e animações**. O jogo é 100% 3D: não entra arte 2D nova.

Quem trabalha aqui são duas sessões (LOCAL no PC do dev, CLOUD na nuvem) que se
coordenam pelo `COORDENACAO.md`. **Regra nº 1: anunciar no Diário de intenções
antes de fazer.**

---

## 0. Restrições que mandam em tudo

Estas não são preferências. São limites medidos, e quase todo erro de produção
que já aconteceu veio de ignorar um deles.

| Restrição | Valor | Por quê importa |
|---|---|---|
| **Câmera da batalha** | Ortográfica, pitch **55°**, `size 13.2` em 405 px | `WorldBuilder.MAP_PITCH` |
| **Compressão vertical** | 57% | Altura some; detalhe lateral se perde |
| **Face mais visível** | **O topo** (82%) | É onde o investimento tem que ir |
| **Footprint de construção** | **1.3 – 1.6** de largura total | Maior que isso cobre a estrada |
| **Blender** | **3.6.23 — nunca 4.x** | GPU é Intel HD 4000, OpenGL 4.2 |
| **Plataforma** | Mobile | Orçamento de polígono é real |

### A regra que mais pesa no visual

> **Área de cor no topo vale mais que silhueta de perfil.**

Decisão do dev, confirmada comparando duas versões dentro do jogo: uma chapa
chapada de cor forte lê melhor que um cone bem modelado, porque de cima o cone
mostra só o deck. Modelar pensando em vista 3/4 de chão **dá errado**.

### Orçamento de polígonos

| Tipo | Alvo |
|---|---|
| Torre / construção | 1 000 – 1 600 tris |
| Personagem | ~7 000 tris |
| Prop de cenário | < 400 tris (usar instancing) |

---

## 1. Personagens

O elenco é **procedural em Blender**, construído por script. Não é imagem→3D.

### Estrutura

```
pipeline/modelos/
  _comum/
    kit.py        ← primitivas: sphere, along, lock, eyes…
    biped.py      ← esqueleto e proporções (BP.params)
  <id>/
    modelo.py     ← o personagem: PALETA + params + geometria
    stats.json    ← tris, verts, bones, materials, height, clips, attack_frame
    review/
      folha.png   ← folha de contato para revisão visual
```

### Anatomia de um `modelo.py`

```python
NOME = "CR_Yeti"
ATAQUE_QUADRO = 10                      # quadro do golpe (sincroniza o dano)
PALETA = {"Fur": "EEF4FA", "Skin": "7894B4", ...}
P = BP.params(hunch=0.1, head_c=(...), shoulder_z=0.7, ...)

def head(hc, hr): ...                   # monta por partes, cada uma com osso
def fur(J): ...
```

Pontos obrigatórios:

- **Paleta nomeada**, nunca cor solta. Mantém coerência entre o elenco.
- Cada peça recebe o **osso de deformação** (`DEF-head`, etc.) na criação.
- Proporções vêm de `BP.params` — é o que mantém a família consistente.
- `ATAQUE_QUADRO` sincroniza a animação com o dano no jogo.

### Procedimento

1. Ler a descrição em `godot/scripts/autoload/game_data.gd` (tipo, cor, habilidade).
2. Criar `pipeline/modelos/<id>/modelo.py` a partir de um vizinho do mesmo `kind`.
3. Definir `PALETA` e `BP.params` — silhueta e proporção antes de detalhe.
4. Construir: volumes primários → secundários → detalhe seletivo.
5. Rigar e assar os clipes: `idle`, `run`, `attack`, `die` (+ `cast`, `fly`, `hit`).
6. Exportar `godot/assets/models/<id>.glb`.
7. Gravar `stats.json` e a folha em `review/folha.png`.
8. **Olhar a folha.** Comparar com a referência. Se não parecer o personagem, voltar ao 3.

### Personagem vindo de fora (imagem→3D)

Se um `.glb` chegar de Tripo / Hyper3D / Meshy:

```bash
blender --background --python pipeline/blender/preparar_personagem.py -- \
  --entrada ~/Downloads/<arquivo>.glb --id <id> --altura 1.8 --tipo hero \
  --girar 0 --maxfaces 6000 --previa /tmp/<id>.png
```

Inspeciona, normaliza escala/orientação/**origem no pé**, decimate, rig
humanoide, 4 animações, export. Se já vier rigado, preserva o rig original.
**Formato sempre GLB** — é o único que leva a textura embutida.

---

## 2. Construções (torres)

```bash
blender --background --python pipeline/blender/construir_torre.py -- \
  --familia archer --tier 1 --cor 4e9a4e --saida godot/assets/models \
  --previa /tmp/torre.png
```

Gera `tower_<família>_<tier>.glb` (tier 1–3), já na altura que o jogo espera e
com a origem no chão.

### Regras de construção

- **Progressão visível**: o jogador tem que *ver* que evoluiu. Massa e altura
  crescem; t1 simples → t2 ganha ameias/estandarte → t3 ganha telhado.
- **Nem toda torre é torre.** O quartel é forte baixo e largo —
  `ALTURA_FAM` controla isso. Forçar altura de torre nele dá cara de silo.
- **Apoiar peça numa altura `z`**: o centro vai em `z + altura/2`.
  `cil()` centra em `z + h/2`; sobrescrever `location` com o `z` da base enterra
  metade da peça. Esse bug já aconteceu.
- **Conferir footprint no jogo**, não no Blender. A prévia do Blender não tem
  nada de referência ao lado, então não pega erro de escala.

### Estado

| Família | Situação |
|---|---|
| archer | ✅ 3 tiers |
| barracks | ✅ 3 tiers (lê como caixa estreita — melhorar) |
| mage, artillery, ballista, cauldron, tesla, goldmine | ⬜ pendente |

---

## 3. Cenário

Ainda **não implementado em 3D** — hoje é mapa pintado (`GameData.PAINTED`).
É a maior área da tela e o maior item aberto.

Procedimento previsto:

1. **Blockout** do terreno: planos e volumes, zero detalhe.
2. **Estradas** com modificadores (array + curva), seguindo o `layout` do reino.
3. **Pontos de construção** marcados na geometria.
4. **Portão do castelo** — ponto focal da composição.
5. **Vegetação e props** por **instancing** (nunca 2 000 árvores independentes).
6. Iluminação: key + fill + ambiente, serviço à legibilidade do gameplay.
7. **LOD** para o que fica longe.

Cada reino tem tema, paleta, `lanes` e `hazard` próprios em `game_data.gd` —
o cenário tem que refletir isso, não ser um terreno genérico reaproveitado.

---

## 4. HUD e menus

Ainda **2D**. Procedimento previsto: converter as prévias de personagem para
3D (os `.glb` já existem) e manter a UI funcional — HUD de jogo não deve
competir com o campo de batalha por atenção.

---

## 5. Mecânica e código

- `scripts/autoload/game_data.gd` — torres, campeões, 34 inimigos, 10 reinos
- `scripts/game/battle.gd` — economia, ondas, combate, auto-play
- `scripts/game/model_rig.gd` — API de animação: `rig.play("idle"|"run"|…)`
- `scripts/autoload/asset_lib.gd` — monta personagens e torres

### Slots de integração (sem mexer em código)

| Asset | Caminho | Prioridade |
|---|---|---|
| Personagem | `godot/assets/models/<id>.glb` | sobre o desenho 2D |
| Torre | `godot/assets/models/tower_<família>_<tier>.glb` | sobre o sprite |

Soltar o arquivo no lugar já troca no jogo.

### Linguagem visual no motor

```gdscript
AssetLib.aplicar_toon(no, 0.03)   # luz toon + contorno de tinta
```

Contorno por casco invertido (`CULL_FRONT` + `grow`). **Grossura 0.03** —
0.075 foi testado e reprovado por ficar sketchy. Sem contorno o modelo some no
meio da arte.

---

## 6. Animação

Clipes reconhecidos: `idle`, `run`, `attack`, `cast`, `hit`, `die`, `fly`.
O motor casa por nome de forma frouxa (`Run`, `run_fast` também servem).

`ATAQUE_QUADRO` no `modelo.py` marca o quadro do golpe, para o dano sair junto
com o impacto e não antes.

---

## 7. Verificação — obrigatória, não opcional

Nada é "pronto" sem estes quatro passos:

```bash
# 1. sem erro de script
godot --headless --path godot --quit-after 120

# 2. print do jogo (xvfb — não precisa de tela)
xvfb-run -a -s "-screen 0 900x1600x24" godot --path godot \
  --rendering-driver opengl3 -- --shot=/tmp/x.png --frames=420 \
  --scene=battle --realm=broken_gate --auto --slot=1

# 3. auto-play: ler o AUTO_RESULT

# 4. OLHAR o print
```

> **Não presuma que o código produziu a aparência certa. Olhe.**

O passo 4 é o que mais pega erro. Escala errada, peça enterrada, cor que some
no fundo — nada disso aparece no log, e a prévia do Blender não pega porque não
tem referência de tamanho ao lado.

---

## 8. Nomenclatura

```
SM_Tower_Archer_t1      malha estática
tower_archer_1.glb      arquivo no jogo
CR_Yeti                 personagem
DEF-head                osso de deformação
```

Nunca `Cube.001`, `Material.034`.

---

## 9. Ambiente

| Ferramenta | Caminho | Observação |
|---|---|---|
| Godot | `~/.local/bin/godot` | 4.3 |
| Blender | `~/.local/bin/blender` | **3.6.23 — nunca 4.x** |
| GIMP | `gimp -i --batch` | tratamento de imagem |
| gh | `~/.local/bin/gh` | autenticado |

Rodadas automáticas: `~/bastion_rodada.sh` (cron horário, :17), credencial em
`~/.bastion_env` (modo 600, **fora do repo**). Log em `~/bastion_rodadas.log`.

---

## 10. Propriedade intelectual

Toda arte é **original**. "Estilo Clash Royale" significa extrair os princípios
— volume simples, silhueta legível, cor controlada, contorno marcado,
legibilidade à distância — e **nunca** reproduzir personagem, logo ou design de
jogo existente. Também não se usa asset extraído de APK de ninguém.

---

## 11. Checklist antes de dizer "pronto"

- [ ] Anunciei no `COORDENACAO.md` antes de começar
- [ ] Olhei o resultado (folha de review **e** print do jogo)
- [ ] Comparei com a referência
- [ ] Dentro do orçamento de polígonos
- [ ] Footprint conferido **no jogo**
- [ ] Headless sem `SCRIPT ERROR`
- [ ] Auto-play roda
- [ ] Commit + push, e o Diário fechado com o resultado
- [ ] Se é placeholder, **está declarado como placeholder**
