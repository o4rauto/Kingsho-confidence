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
2. **Quartel** ⚔️ — treine **Infantaria** (reforça a muralha), **Arqueiros**
   (tiro automático em batalha) e **Cavalaria** (potencializa a *Carga*).
3. **Heróis** 🦸 — recrute e promova líderes com bônus permanentes de produção,
   ataque e defesa.
4. **Defesa** 🎯 — escolha o estágio e segure as ondas:
   - **Clique/toque** na arena para **atirar** nos invasores.
   - Seus **arqueiros** disparam sozinhos no inimigo mais próximo.
   - O botão **🐎 Carga** dispara um ataque em área (recarrega com o tempo e
     escala com a quantidade de cavalaria).
   - Não deixe o HP da muralha chegar a zero! Vencer todas as ondas concede
     recompensas e desbloqueia o próximo estágio.

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

Há um teste de fumaça que valida a lógica do motor (economia, filas, tropas,
heróis, combate, persistência e progresso offline) sem precisar de navegador:

```bash
npm test
# ou
node test/smoke.test.js
```

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
