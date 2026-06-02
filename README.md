# 🏰 Frontier Bastion

**Frontier Bastion** é um jogo web **original** de estratégia de sobrevivência,
inspirado no *gênero* de jogos de guerra/sobrevivência com construção de cidade
e defesa por tiro. Você comanda uma fortaleza no limite da civilização: gerencia
recursos, ergue edifícios, treina tropas, recruta heróis e repele hordas de
invasores em batalhas de defesa em tempo real.

> ⚠️ **Projeto original e independente.** Toda a nomenclatura, balanceamento,
> código e arte (emoji/CSS) são de criação própria. O jogo é apenas *inspirado*
> no gênero — não é afiliado a, nem reutiliza conteúdo de, nenhum título
> existente.

Roda 100% no navegador, sem dependências e sem etapa de build — é só abrir o
`index.html`.

---

## 🎮 Como jogar

1. **Fortaleza** 🏰 — construa e melhore edifícios:
   - **Serraria / Fazenda / Pedreira / Casa da Moeda** geram recursos com o tempo.
   - **Armazém** aumenta a capacidade de estoque (sem espaço, a produção é perdida).
   - **Casas** abrigam habitantes que dão bônus global de produção.
   - **Academia** aumenta a produção de todos os recursos.
   - **Quartel** libera e amplia o treino de tropas.
   - **Muralha** aumenta muito o HP de defesa nas batalhas.
   - O **Centro de Comando** define o nível máximo dos demais edifícios — eleve-o
     para destravar melhorias.
2. **Pesquisa** 🔬 — árvore de tecnologia com três ramos (**Economia**,
   **Militar**, **Defesa**). Cada nó dá bônus permanentes (produção, estoque,
   dano, muralha, slots de expedição) e é destravado pelo nível da Academia.
   Tem **fila própria**, paralela à de construção.
3. **Quartel** ⚔️ — treine **Infantaria** (reforça a muralha), **Arqueiros**
   (tiro automático em batalha) e **Cavalaria** (potencializa a *Carga* e as
   expedições).
4. **Mundo** 🗺️ — envie tropas em **expedições PvE** (coleta, saque, caçada,
   comboios e a Toca do Colosso). As tropas ficam ocupadas durante a missão e
   retornam com recompensas. O nº de expedições simultâneas vem dos **slots de
   marcha** (pesquisa de Cartografia).
5. **Heróis** 🦸 — recrute e promova líderes com bônus permanentes **e** uma
   **habilidade ativa** usável no combate (cura, escudo, saraivada ou dano em área).
6. **Defesa** 🎯 — escolha o estágio e segure as ondas:
   - **Clique/toque** na arena para **atirar** nos invasores.
   - Seus **arqueiros** disparam sozinhos no inimigo mais próximo.
   - O botão **🐎 Carga** e as **habilidades de herói** ficam na barra inferior,
     cada um com seu tempo de recarga.
   - Não deixe o HP da muralha chegar a zero! Vencer todas as ondas concede
     recompensas e desbloqueia o próximo estágio.

Use o botão **📜 Missões** (topo) para acompanhar objetivos, resgatar
recompensas e pegar o **bônus diário**.

O progresso é **salvo automaticamente** no navegador (`localStorage`) e a
fortaleza **continua produzindo enquanto você está ausente** (até 12h de
produção offline ao voltar).

---

## 🚀 Executando

A forma mais simples é abrir o arquivo diretamente:

```bash
# Abra no navegador:
xdg-open index.html        # Linux
open index.html            # macOS
start index.html           # Windows
```

Ou sirva por um servidor local (opcional, recomendado):

```bash
python3 -m http.server 8000
# acesse http://localhost:8000
```

Não há dependências para instalar.

---

## 🧪 Testes

Há um teste de fumaça (**64 asserções**) que valida a lógica do motor —
economia, filas, tropas, heróis, **pesquisa**, **expedições**, **missões**,
**recompensa diária**, combate, persistência e progresso offline — sem precisar
de navegador:

```bash
npm test
# ou
node test/smoke.test.js
```

O mesmo roda no **GitHub Actions** (`.github/workflows/ci.yml`) a cada push/PR.

---

## 📁 Estrutura

```
.
├── index.html          # Página principal e ordem de carregamento dos scripts
├── css/
│   └── styles.css       # Tema visual e layout responsivo (mobile-first)
├── js/
│   ├── data.js          # Definições e balanceamento (edifícios, tropas, heróis, combate)
│   ├── engine.js        # Estado, save/load, produção, filas, heróis, poder
│   ├── screens.js       # Telas de UI (Fortaleza, Quartel, Heróis, Defesa)
│   ├── combat.js        # Combate de defesa no Canvas (mira, tiros, ondas)
│   └── main.js          # Orquestração: navegação, loop, eventos, toasts
└── test/
    └── smoke.test.js    # Teste de fumaça do motor (Node)
```

---

## ⚙️ Detalhes técnicos

- **HTML5 + CSS + JavaScript puro** (sem frameworks, sem build).
- Combate renderizado em **Canvas 2D** com `requestAnimationFrame` e física
  simples (projéteis, colisões, partículas).
- UI baseada em DOM com **delegação de eventos** e atualizações leves por tick.
- Estado persistido em `localStorage`; cálculo de **produção offline** ao
  retornar.
- Layout **responsivo** e otimizado para toque (joga bem no celular).

## 📜 Licença

MIT — veja [`LICENSE`](LICENSE).
