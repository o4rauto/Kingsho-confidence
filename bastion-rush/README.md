# 🎯 Bastion Rush

Jogo **3D low-poly** de **ação/defesa**, single-file (`index.html`), feito em
**Canvas puro — sem nenhuma biblioteca** (motor 3D próprio). Você **controla um
herói** pelo campo (invulnerável) que ataca sozinho os inimigos no alcance,
enquanto a horda avança **em fila pelo caminho** até a sua base. Visão ¾ de cima.

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
- **Mova o herói**: arraste na tela (joystick flutuante) ou **WASD/setas**. Ele
  ataca sozinho o inimigo mais próximo no alcance.
- **HAB** (habilidade em área, com recarga) e **ULT** (ultimate que carrega
  conforme você causa dano) — botões na lateral direita.
- Toque nos **slots** (círculos tracejados) para **construir/melhorar torres**.
- **7 fases** com composições próprias de inimigos: **saqueador, batedor,
  brutamonte, escudeiro, voador** e **bosses variados** (colosso, algoz, rei).
- **Menu, seleção de fases e pause**. Vença a fase para desbloquear a próxima.

## 🧩 Sistemas
- 🔊 **Áudio** (sintetizado, sem arquivos) + **vibração** no celular.
- 👑 **Intro narrativa do Guardião** + dica de tutorial.
- 💎 **Gemas + moedas**, **recompensa diária**, **invocação (gacha)** e
  **melhorias permanentes** (dano/cadência) na seleção de fases.
- ⚙️ **Ajustes**: som, vibração, idioma (PT/EN).
- 🔒 **Em breve** (Alianças/PvP/Eventos) — placeholders de FOMO.

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
