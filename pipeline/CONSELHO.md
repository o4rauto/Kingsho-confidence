# Conselho C-level do Bastion Rush

Pedido do dev (22/out): "use as skills do kursku com uma equipe C-level para saber o que fazer em cada
etapa de building do jogo". Este arquivo é essa equipe: seis papéis de estúdio (não são pessoas reais),
o mapa de etapas e as atas das reuniões. **Antes de abrir uma etapa nova, o conselho se reúne aqui** — cada
papel dá a sua leitura em poucas linhas, a síntese vira a lista de próximas ações, e o que for trabalho
de uma sessão é anunciado no `COORDENACAO.md` como sempre.

Skills de apoio (instaladas só no ambiente da sessão CLOUD, fora do repo): do kursku/skills —
`kk-game-design`, `kk-game-art`, `kk-game-audio`, `kk-3d-games`, `kk-godot-gdscript-patterns`; e as de
Blender já usadas no elenco 3D (`blender-image-to-3d`, `cc-*`, `rv-*`).

## A equipe

| Papel | Cuida de | Pergunta que sempre faz | Apoio |
|---|---|---|---|
| **CEO — Direção do estúdio** | visão, escopo do MVP, prioridade, custo zero (o dev não quer pagar ferramentas) | "Isso aproxima o jogo de estar na loja?" | — |
| **CPO — Direção de jogo** | loop de 30 s, progressão, dificuldade, variedade de inimigos e heróis | "O jogador entende e se diverte nos primeiros 30 s?" | `kk-game-design` |
| **CTO — Tecnologia** | Godot 4.3 Compatibility, desempenho no celular, arquitetura, testes automáticos | "Roda liso num Android médio? Tem teste que pega se quebrar?" | `kk-godot-gdscript-patterns`, `kk-3d-games` |
| **CCO — Direção de arte** | padrão 3D estilo Clash Royale, câmera 55°, contorno, leitura a 96 px | "Dá para reconhecer cada unidade de cima, pequena, no meio da luta?" | `kk-game-art`, skills de Blender |
| **CAO — Áudio** | efeitos por tipo de golpe, música por reino, mixagem no celular | "Cada ação tem um som que confirma o que aconteceu?" | `kk-game-audio` |
| **CMO — Lançamento** | Play Store, ícone, prints, trailer, primeira impressão, comunidade | "O que mostramos na página da loja?" | (skills de growth do kursku, se precisar) |

## Mapa de etapas

| # | Etapa | Dono | Portão para passar | Situação (22/out) |
|---|---|---|---|---|
| 0 | Visão e escopo do MVP | CEO + CPO | pitch de 1 frase, 10 reinos, heróis = campeões | ✅ (`CLAUDE.md`) |
| 1 | Protótipo do loop | CPO + CTO | construir → onda → ouro → melhorar, divertido em 30 s | ✅ |
| 2 | Elenco 3D | CCO | todo personagem com GLB, idle/run/attack/cast/die | ✅ 48 GLBs (husk à parte) |
| 3 | Sensação do combate | CPO + CCO + CAO | golpes distintos de perto e de longe, impacto visível e audível | 🟡 golpes ok; faltam FX 3D, reação a dano, sons por golpe |
| 4 | Torres e cenário 3D | CCO (faixa LOCAL) | torres 3 níveis × 4 famílias + bastião + cenário dos 10 reinos | 🟡 torres em andamento na LOCAL; cenário não começou |
| 5 | Fatia vertical | todos | Reino 1 inteiro com arte, FX e som finais, rodando no celular | ⏳ |
| 6 | Balanceamento e progressão | CPO | auto-play 2–3★ em todos os reinos no nível esperado; curva de estrelas | 🟡 linha de base ok |
| 7 | UX, menus e tutorial | CPO + CMO | primeiro minuto guiado; menus com prévia 3D | ⏳ |
| 8 | Desempenho Android | CTO | APK em aparelho médio, 30+ fps na onda mais cheia | ⏳ **risco** |
| 9 | Áudio final | CAO | trilha por reino + efeitos de todos os golpes | ⏳ |
| 10 | Lançamento | CMO + CEO | beta fechado na Play Store, página da loja pronta | ⏳ |

## Ata 1 — 22/out — "elenco 3D pronto; e agora?"

- **CEO:** o elenco era o maior bloco de arte e terminou sem custo. Agora o que mais aproxima da loja é
  uma **fatia vertical**: o Reino 1 completo. Não abrir frente nova antes disso.
- **CPO:** com os golpes variados, falta o jogador *sentir* o acerto: reação a dano (clipe `hit`), número
  de dano legível, e o projétil de cada atirador combinando com o gesto (flecha, virote, cuspe, raio, pedra).
- **CTO:** risco escondido: 48 malhas com esqueleto de 2–9 mil triângulos; uma onda cheia pode ter 30–40
  inimigos com animação. No GL Compatibility do celular isso precisa ser medido **já**, com APK num aparelho
  real, antes de mais arte. Ter plano B: versão mais leve (menos triângulos) para inimigos pequenos.
- **CCO:** os personagens leem bem a 96 px. A leitura de cima depende das torres e do chão também; o cenário 3D é
  a maior lacuna visual. Torres são da LOCAL; cenário precisa de dono.
- **CAO:** hoje os golpes novos são mudos. Um som curto por família de golpe (corte, pancada, mordida,
  tiro, magia, cura) já muda a sensação; dá para gerar/filtrar sons gratuitos.
- **CMO:** para a loja, o que vende é o print da batalha com torres e cenário 3D e um vídeo de 15 s. Isso
  sai naturalmente da fatia vertical do Reino 1.

**Síntese / recomendação:** fechar o Reino 1 como fatia vertical, medindo desempenho no celular logo no começo.

**Risco não óbvio:** desempenho no Android com dezenas de personagens animados; descobrir tarde obriga a
refazer arte.

**Próximas ações:**
1. CTO: gerar um APK de teste e medir fps numa onda cheia do Reino 1 (dev roda no celular dele).
2. CCO + CPO: projéteis e impactos 3D casados com cada gesto de ataque; clipe `hit` no kit.
3. CAO: um som por família de golpe, ligado ao `play("attack"/"cast")`.
4. CCO: combinar com a LOCAL quem faz o cenário 3D do Reino 1 (torres seguem com ela).
5. CPO: prévias 3D nos menus (Heróis, Bestiário), já que todo personagem tem GLB.
