ASSET      CH_Husk — "Casca Cinzenta", goblin inimigo do Reino 1 (id do jogo: husk)

CATEGORY   character, biped (chibi goblin, ~2 cabeças de altura)

VIEWS      ref/concept.png (136x224 px, recorte de pipeline/referencias/personagens_1_monstros.jpg):
           conceito com o CORPO DE FRENTE e a CABEÇA virada ~20° para a direita da imagem, perspectiva
           desenhada (NÃO ortográfico). Câmera estimada por varredura de IoU: azimute 0°, elevação
           15°, lente ~50 mm (az 20 dava 0.65, az 0/el 15 deu 0.70 no mesmo bloco). O sujeito ocupa
           100% da altura (o recorte já tira fundo/sombra/nome); chão na base da imagem (y = 224).
           Serve para silhueta, proporções aproximadas e cores; lados e costas são inferidos.

SCALE      Sem pista real de escala. Usado: altura total 1.20 m até a ponta do espigão
           (# inferred — goblin do tamanho de uma criança). 1 px da ref = 1.20/224 = 0.00536 m.
           O jogo reescala pela altura (model_rig._normalize), então só as proporções importam.

PROPORTIONS (fração da altura total H, medidas na ref; perspectiva leve → tolerância de blockout)
           P1  ponta do espigão 1.00 H; base do espigão 0.89 H
           P2  topo da cúpula do capacete 0.885 H; aba frontal do capacete 0.72 H
           P3  queixo 0.50 H  → cabeça+capacete = metade da altura (chibi)
           P4  olhos 0.635 H; boca 0.555 H
           P5  orelhas: 0.70–0.78 H; envergadura ponta-a-ponta 0.567 H (127 px)
           P6  largura do capacete (guardas da bochecha) 0.37 H (83 px); guardas descem até 0.50 H
           P7  linha dos ombros 0.47 H; largura ombro-a-ombro 0.245 H (55 px)
           P8  cinto 0.34 H; largura no cinto 0.205 H (46 px)
           P9  virilha 0.25 H; barra da tanga 0.19 H (rasgada, pontas até 0.17 H)
           P10 joelho 0.14 H; tornozelo 0.06 H; comprimento do pé 0.16 H
           P11 mãos: base em 0.18 H, tamanho ~0.11 H (mãos grandes); faixas no antebraço 0.36–0.40 H
           P12 distância entre os pés (centros) 0.23 H
           P13 tronco magro: largura no peito ~0.22 H; braços finos (~0.035 H de raio)

PARTS      (ordem de construção/sobreposição; todas rígidas ao osso indicado, exceto o corpo)
           Body (tronco+pescoço+braços+pernas, skin_chain)   deforma   esqueleto inteiro
           Head (crânio+focinho+mandíbula)                    rígida    DEF-head
           Nose (nariz comprido pontudo)                      rígida    DEF-head
           Ear.L / Ear.R (orelhas grandes, pontudas)         rígida    DEF-head
           Eye.L / Eye.R (amarelo-claro, separados p/ sombreado) rígida DEF-head
           Teeth (fileira de dentes tortos)                   rígida    DEF-head
           Helmet_Dome (cúpula enferrujada)                   rígida    DEF-head
           Helmet_Bands (aro + faixa central + faixa lateral, aço) rígida DEF-head
           Helmet_Cheek.L/.R (guardas descendo até o queixo)  rígida    DEF-head
           Helmet_Spike (cone no topo)                        rígida    DEF-head
           Hand.L / Hand.R (mão com 3 dedos grossos + polegar) rígida   DEF-hand.L/R
           Foot.L / Foot.R (pés compridos, 3 dedos)           rígida    DEF-foot.L/R
           Loincloth (saia de pano rasgada, solidify)         deforma   DEF-hips/thigh
           Belt (+ Buckle)                                    rígida    DEF-hips
           Wrap_Arm.L/.R, Wrap_Ankle.L/.R (faixas de pano bege) deforma DEF-forearm/shin

SILHOUETTE 1. capacete redondo grande com espigão no topo
           2. orelhas enormes e pontudas saindo dos lados do capacete
           3. braços compridos e finos terminando em mãos grandes
           4. tanga rasgada + pernas finas dobradas com pés grandes
           5. postura meio agachada, cabeça projetada para frente

MATERIALS  (cartoon: cor chapada forte, rugosidade alta; o contorno de tinta é aplicado no jogo)
           pele      vermelho  #B8362B (sombra #8A2620 só como 2ª cor em dobras, se precisar)
           cúpula    marrom-ferrugem #7A4A2A, rugosidade 0.8
           faixas    aço cinza #A2A2A2, metálico 0.3, rugosidade 0.5
           olhos     amarelo-claro #F2E2A0 (emissão leve 0.2 p/ ler no escuro)
           dentes    marfim #EFE6CF; boca/gengiva #4A1410
           tanga     oliva-marrom #7A6A3F; cinto #4A3020; fivela #9A9A9A
           faixas    bege #C8B08C

ARTICULATION humanoide simplificado: DEF-root, hips, spine, chest, neck, head, upper_arm/forearm/hand
           .L/.R, thigh/shin/foot .L/.R (18 ossos). Sockets: hand.R (arma futura), head.
           Animações pedidas: idle (loop), run (loop, no lugar), attack (golpe de garra),
           die (cai e fica). Nomes exatamente: idle, run, attack, die.

INFERRED   costas inteiras do corpo e do capacete (simetria + continuidade das faixas);
           lado esquerdo do rosto (simetria — a ref é 3/4); planta dos pés; profundidade de
           todas as peças (a ref não tem vista lateral); altura real de 1.20 m.

TARGET     Godot 4.3 (GL Compatibility, celular), GLB, orçamento ~3–6 mil triângulos,
           1 material por papel, sem texturas (cor chapada) — mapas assados ficam para depois.
           Câmera do jogo: ortográfica, pitch 55° de cima, inimigo com ~70–100 px de altura
           na tela (gameplay-px 96). Frente do modelo: −Y no Blender (= +Z no Godot).

REBUILD    (Blender 4.2+; a nuvem usa 5.2 sem janela) — na pasta pipeline/modelos/husk:
           blender -b --python <skill>/scripts/init_master.py -- --out CH_Husk_master.blend --name CH_Husk \
             --height 1.20 --ref-front ref/concept.png --subject-frac 1.0 --ground-frac 0.0 --cam-elev 55 --cam-az 0 --fps 24
           for s in 02_blockout 03_forms 05_materials 06_rig 08_anim; do
             blender -b --python build/$s.py -- --master CH_Husk_master.blend; done
           blender -b --python <skill>/scripts/export_delivery.py -- --blend CH_Husk_master.blend --out exports \
             --name CH_Husk --format GLB --collections EXPORT,RIG_DEF,SOCKETS
           cp exports/CH_Husk.glb ../../../godot/assets/models/husk.glb
           (<skill> = skill blender-image-to-3d, github.com/majidmanzarpour/blender-game-skills)

RESULT     bloco IoU 0.69 contra o conceito (teto: conceito pintado 3/4 com a cabeça virada — não
           métrico); 5116 tris, 18 ossos, 0 vértices sem peso, 9 materiais; clipes idle 2.0 s,
           run 0.67 s, attack 0.54 s, die 1.13 s; altura reimportada 1.185 m (−1.2 %, o jogo reescala).
           Sem LOD1/LOD2 (personagem pequeno na tela). Contorno toon do jogo serrilha um pouco onde
           peças separadas se cruzam (cada peça tem seu casco).
