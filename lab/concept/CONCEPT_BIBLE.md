# Bíblia de Arte — Bastion Rush (concepts do usuário)

Fichas de arte conceitual **originais do usuário** (geradas por ele) que definem a
direção visual + narrativa oficial. Imagens em `lab/concept/`. São **referência**
para construir os modelos 3D (pipeline esqueleto→volume) — não copiar pixel, mas
seguir proporção/silhueta/paleta/tema.

## Narrativa-mãe
Uma invasão congelada — **"A Maré"** (horda gelo-morta do "Longo Inverno") — avança
contra a base. Cada unidade carrega uma **cor de facção** (a "bênção" que recebeu).
O herói é **Pyr** (fogo), guiado pelo mentor **O Guardião** (elemental de fogo).
Tema central: **fogo (vida/herói) vs. gelo (morte/Maré)**; brasa quente vs. cristal.

## Principal
| Arquivo | Personagem | Papel | Traços de anatomia/estilo |
|---|---|---|---|
| `pyr-heroi.png` | **Pyr** | Herói (jogável) | bruxa chibi, chapéu pontudo, robe/capa laranja-vermelho, cajado com orbe de **fogo**. Cabeça grande, postura ágil. |
| `guardiao-mentor.png` | **O Guardião** | Mentor (história) | elemental de **fogo** humanoide, cabeça/coroa de chama, tocha-cajado. Só cutscene. |

## Monstros — ordem do ranking (ROSTER de desbloqueio)
| # | `concept` | Nome (A Maré) | roster `type` | Cor | Comportamento/silhueta |
|---|---|---|---|---|---|
| 1 | `saqueador.png` | Saqueador | `grunt` | Vermelho | básico; saqueador com martelo/picareta, calor residual |
| 2 | `batedor.png` | Batedor | `runner` | Âmbar | rápido, esguio, cauteloso (scout) |
| 3 | `escudeiro.png` | Escudeiro | `shield` | Aço | guarda com **escudo-torre**; tanque frontal |
| 4 | `brutamonte-martelo-gelo.png` | Brutamonte (Martelo-Gelo) | `brute` | — | ferreiro pesado/lento, **martelo-gelo** enorme |
| 5 | `viajador-corvo.png` | Viajador (Corvo-da-Cinza) | `flier` | Turquesa | **voador** corvídeo espectral, assalto aéreo |
| 6 | `curandeiro-clerigo.png` | Curandeiro (Clérigo) | `healer` | Verde | clérigo encurvado, aura de cura, sereno/arrepiante |
| 7 | `splitter-ninho.png` | Ninho de Gelo | `splitter` | Bege-Âmbar | incubador grotesco; ao morrer gera enxame |
| 8 | `spectre-soldado.png` | Spectre (Soldado recosturado) | `revenant` | Oliva | soldado remendado, **regenera** (teimoso) |
| 9 | `investidor-dasher.png` | Investidor (Caçador espasmódico) | `dasher` | Rosa | arrancadas espasmódicas (burst de velocidade) |
| 10 | `enxame-swarm.png` | Enxame | `swarm` | Amarelo | "cinza viva", miniatura faminta, vem em massa |
| 11 | `couracado-armored.png` | Couraçado | `armored` | Aço | armadura oca pesada, "muralha que anda" |
| 12 | `ogro.png` | Ogro | `ogre` | Marrom | neve acumulada, montanha lerda e enorme |
| 13 | `assombracao-wraith.png` | Assombração | `wraith` | Violeta | veloz + regenera, fumaça que ataca |

## Bosses (a cada 10 fases)
| `concept` | Nome | boss `type` | Tema |
|---|---|---|---|
| `murk-boss-tanque.png` | **Murk, o Colosso** | `boss_tank` | golem de gelo/cristal, "imparável" |
| `skarn-boss-veloz.png` | **Skarn, o Algoz** | `boss_swift` | assassino veloz, silencioso e letal |
| `gorr-boss-final.png` | **Gorr, o Rei Faminto** | `boss_king` | rei gelo-morto coroado (boss final) |

## Afixos de Elite (recolor + brasa/espinhos por cima da instância)
| `concept` | Afixo | id `ELITES` | Cor/assinatura |
|---|---|---|---|
| `elite-veterano-dourado.png` | Veterano | `veteran` | Dourado (tankão) |
| `elite-selvagem-laranja.png` | Selvagem | `savage` | Laranja (veloz, brasa, +espinhos) |
| `elite-fereo-prata.png` | Féreo (The Ferrous) | `iron` | Prata (placas rebitadas, +armor) |
| `elite-maldito-roxo.png` | Maldito (The Cursed) | `cursed` | Roxo (runas, névoa, +regen) |

> Padrão recorrente das fichas: **estudos de movimento/postura**, **atributo de
> elite "a brasa se extingue"** (brilho some ao morrer → "morte completa" vira
> escultura de gelo/pedra), **paleta + materiais** (gelo-rachado, brasa quente,
> couro velho, prata-geada). Útil p/ animação e variantes futuras.
