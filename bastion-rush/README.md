# 🎯 Bastion Rush 3D

Jogo **3D low-poly** de **horde/lane defense**, single-file (`index.html`), feito
em **Canvas puro — sem nenhuma biblioteca** (motor 3D próprio). Você defende a
base de uma horda que avança **em fila pelo caminho**; herói e torres atiram
sozinhos. Visão ¾ de cima, no estilo do gênero.

> ⚠️ **Original.** Motor 3D, modelos (herói, inimigos, boss, torres, base,
> cenário) e arte são criados por código, do zero. Apenas *inspirado* no gênero —
> nada de assets/marcas de terceiros.

## 🧱 Motor 3D próprio (0 dependências)
- Modelos montados a partir de **caixas** (vértices + faces) — cada personagem é
  "modelado" no código.
- **Câmera em perspectiva** ¾, **iluminação flat** (direcional) e **ordenação por
  profundidade** em duas passadas (chão atrás, objetos na frente).
- Roda **100% offline** (não depende de CDN), ideal para empacotar como APK.

## 🕹️ Como jogar
- A horda surge ao fundo e segue o caminho até a **base** (canto inferior).
- O **herói** e as **torres** miram e atiram automaticamente; inimigos explodem e
  soltam **moedas** (que voam até o contador).
- Toque nos **slots** (círculos tracejados) para **construir/melhorar torres**.
- Use os botões **DANO**, **CADÊNCIA** e **CURAR** para evoluir.
- A cada **5 ondas** vem um **BOSS**. Se o HP da base zerar, fim de jogo.

## ✨ Juice
Tremida de câmera nos impactos, flashes, partículas de explosão, números de dano
flutuantes, moedas em arco até o HUD com pulso no contador, botões e painéis
arredondados, marcadores de torre pulsando quando há saldo.

## 💾 Save
Progresso em `localStorage` (moedas, onda, upgrades, torres, HP) — você
**continua de onde parou** — além do **recorde de onda**.

## ▶️ Rodar
```bash
# abrir direto:
xdg-open index.html      # Linux   (open / start no macOS / Windows)
# ou servir (recomendado p/ o save):
python3 -m http.server 8000   # http://localhost:8000/
```

## 📱 Gerar APK (Capacitor)
Da pasta `bastion-rush/` (ela já contém só o `index.html`):
```bash
npm install -g @capacitor/cli @capacitor/core
npm init -y && npm install @capacitor/core @capacitor/android
npx cap init "Bastion Rush" "com.frontierbastion.rush" --web-dir .
npx cap add android
npx cap copy && npx cap open android
```
Como não usa CDN, o jogo funciona **offline** dentro do app.

## ⚙️ Balanceamento
No topo do `<script>` (custos, dano, vida/velocidade dos inimigos, tamanho da
onda, boss). Modelos em `M_HERO`, `M_GRUNT`, `M_BOSS`, `M_TOWER`. Câmera em
`camPos`/`camTarget`. Ajuste à vontade.
