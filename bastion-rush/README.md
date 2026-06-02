# 🎯 Bastion Rush

Jogo **mobile-first** de **merge tower-defense "juicy"**, single-file
(`index.html`), com **Phaser 3** + **Howler.js**. Jogo **original** inspirado
no *gênero* (merge de torres + tower defense + feedback dopaminérgico) — toda a
arte é desenhada por código; nada de assets ou marcas de terceiros.

## 🕹️ Como jogar
- **COMPRAR** gera uma torre nível 1 numa célula livre da grade 3×3.
- **Arraste** uma torre em cima de **outra do mesmo nível** para **fundir**
  (merge) e subir de nível — com flash, partículas e tremida de tela.
- Torres atiram sozinhas nos invasores no alcance. Inimigos que passam pela base
  = **Game Over**.
- A cada **5 ondas** aparece um **BOSS**. Mate inimigos para coletar **moedas**
  (que voam até o contador).

## ✨ "Juice" implementado
Merge com flash dourado + 30 partículas + camera shake · moedas com física de
arco até o HUD + número flutuante + som · barras de onda com shimmer (0.2s) ·
números de dano com contorno · botões com cantos 24px que "pulsam" quando há
saldo · HP bar por inimigo · boss com flash · sons sintetizados (sem arquivos).

## 🔊 Som (Howler.js, sem assets)
Os efeitos são **gerados em runtime**: cada som é sintetizado (tom + envelope +
ruído), codificado como WAV em `data:` URI e tocado pelo Howler. Há botão de
**mudo** 🔊. Se o Howler não carregar (offline), o jogo roda sem som.

## 💾 Save
Progresso salvo em `localStorage` (moedas, onda e o **layout das torres**) — ao
reabrir, você **continua de onde parou**. Guarda também o **recorde de onda**.

## ▶️ Rodar no navegador
```bash
# Basta abrir o arquivo:
xdg-open index.html      # Linux
open index.html          # macOS
start index.html         # Windows

# ou servir localmente:
python3 -m http.server 8000   # acesse http://localhost:8000
```

## 📱 Gerar APK (Android) com Capacitor
A partir da **pasta `bastion-rush/`** (ela já contém só o `index.html`, ideal
como `webDir`):

```bash
npm install -g @capacitor/cli @capacitor/core
npm init -y
npm install @capacitor/core @capacitor/android
npx cap init "Bastion Rush" "com.frontierbastion.rush" --web-dir .
npx cap add android
npx cap copy
npx cap open android   # abre no Android Studio para gerar o APK/AAB
```
> Sempre que editar o `index.html`, rode `npx cap copy` de novo.

## ⚙️ Balanceamento
Todas as variáveis ficam no objeto **`CONFIG`** no topo do `<script>` em
`index.html` (custo da torre, dano/merge, vida e velocidade do inimigo, tamanho
da onda, frequência do boss, etc.). Ajuste para calibrar a dificuldade.
