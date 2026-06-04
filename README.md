# 🎯 Bastion Rush

Jogo web **original** de **ação + tower-defense 3D low-poly** (visão ¾ de cima),
*inspirado no gênero* war-strategy/survival. Você controla um **herói móvel** que
**ataca sozinho** enquanto **hordas** avançam pelo caminho até a sua **base** — e
ergue **torres** para segurar a linha. Roda **100% no navegador**, **sem
dependências e sem build**: é um **único arquivo** (`bastion-rush/index.html`)
com **motor 3D próprio em Canvas 2D**. Mobile-first e pronto para virar **APK**.

> ⚠️ **Projeto original e independente.** Código, arte (geometria desenhada por
> código + alguns emojis), nomes e textos são de **criação própria**. Apenas
> *inspirado* nos gêneros — não é afiliado a, nem reutiliza conteúdo de, nenhum
> título existente. Mecânicas/padrões de UX não são protegidos; arte/assets/
> personagens específicos, sim — e **nada disso é copiado**.

## 🚀 Jogar agora

Servido direto do GitHub (sempre a última versão da branch de trabalho):

**▶️ https://raw.githack.com/o4rauto/Kingsho-confidence/claude/ecstatic-gauss-nCtxQ/bastion-rush/index.html**

> A cada push, o link acima reflete o estado mais novo. Para uma versão
> "congelada", troque o nome da branch por um **SHA** de commit.

## 🎮 Controles
- **Mover:** arraste na tela (joystick flutuante) ou **WASD / setas**.
- O herói **mira e ataca sozinho** o inimigo mais próximo no alcance.
- **HAB** (dano em área) e **ULT** (limpa a tela, carrega causando dano).
- **Torres:** toque nos slots para construir/melhorar.
- O herói fica **sempre dentro da tela** (área limitada ao piso visível).

## 🧭 Para onde o jogo está indo
O Bastion Rush está evoluindo para uma **fusão Archero × Kingdom Rush**: herói
**mago** que atira parado e desvia, **upgrades roguelike a cada horda**, **4
classes de torre** (arqueiro/mago/quartel/artilharia) com especialização de 4º
nível, **chefes bullet-hell**, **diretor de IA adaptativo**, duas moedas e
progressão meta. O plano completo e a ordem de implementação estão no
**[`ROADMAP.md`](ROADMAP.md)**.

---

## 🏰 Também neste repo: Frontier Bastion (protótipo)
Na **raiz** (`index.html` + `js/` + `css/`) vive o **Frontier Bastion**, o 1º
protótipo — um jogo de **estratégia de sobrevivência** (construção de fortaleza,
recursos, tropas, heróis, pesquisa, expedições e defesa por tiro no Canvas).
Está **estável e testado**, mas **fora de foco**: a intenção é reaproveitá-lo
como o futuro **"modo cidade"/meta** do Bastion Rush (ver `ROADMAP.md` §0).

```
bastion-rush/index.html   # 🎯 JOGO PRINCIPAL — single-file, motor 3D em Canvas, 0 libs
index.html                # 🏰 Frontier Bastion — carrega os scripts abaixo
css/styles.css            # tema/responsivo do Frontier
js/ data engine screens combat main   # motor e telas do Frontier
test/smoke.test.js        # teste de fumaça do motor do Frontier (Node)
ROADMAP.md                # plano-mestre da fusão Archero × Kingdom Rush
CLAUDE.md                 # contexto completo p/ agentes
```

## 🧪 Testes / CI
O motor do Frontier tem um **teste de fumaça (64 asserções)** que roda sem
navegador; o **GitHub Actions** (`.github/workflows/ci.yml`) executa
`node --check js/*.js test/*.js` + o smoke test a cada push/PR.

```bash
npm test            # node test/smoke.test.js
python3 -m http.server 8000   # e abra http://localhost:8000 (Frontier) ou /bastion-rush/
```

O Bastion Rush é single-file (não coberto pelo `--check`); valide-o headless com
Playwright (ver `CLAUDE.md` §2).

## 📜 Licença
MIT — veja [`LICENSE`](LICENSE).
