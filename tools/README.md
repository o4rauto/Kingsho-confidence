# tools/ — QA / pipeline

Ferramentas de verificação headless. **Nenhuma toca em `bastion-rush/index.html`** —
apenas observam o jogo rodando de verdade.

## Scripts

| Comando | O que faz |
|---|---|
| `npm test` | Smoke test do motor do Frontier Bastion (`test/smoke.test.js`, 64 asserções). |
| `npm run verify` | Sobe `python3 -m http.server`, abre **Bastion Rush** no Chromium headless (Playwright), coleta erros de console/página, exercita os hooks `window.BR` e salva `verify_screenshot.png`. Sai != 0 se houver qualquer erro. |
| `npm run verify:webgl` | **Spike de Modelos:** prova que dá p/ rodar **Three.js (WebGL)** em Chromium headless (SwiftShader, sem GPU) e capturar screenshot (`tools/webgl_spike_screenshot.png`). |

## Rodando no sandbox

A CDN é bloqueada no sandbox, então o `three` é servido **localmente** de
`/node_modules` (instale com `npm install`). Os browsers do Playwright já vêm
pré-instalados em `/opt/pw-browsers`:

```bash
npm install
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers npm run verify
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers npm run verify:webgl
```

## CI

`.github/workflows/ci.yml` roda dois jobs:
- **test** — `node --check` em todos os scripts + smoke test.
- **verify-game** — `npm install` → `playwright install chromium` → `npm test`
  → `node verify.js` → `node tools/verify-webgl.js`, publicando os screenshots
  como artifact `verify-screenshots`.

## Resultado do spike WebGL

Three.js renderiza em WebGL2 headless via SwiftShader (`--use-angle=swiftshader`).
O verificador confirma o contexto `WebGL2RenderingContext`, conta frames
desenhados e prova que o canvas **não está vazio** (lê pixels com
`preserveDrawingBuffer`). Logo, a raia de Modelos pode adotar Three.js sem perder
verificabilidade no CI.
