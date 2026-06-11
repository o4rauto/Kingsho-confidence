#!/usr/bin/env node
/*
 * verify.js — verificação headless do JOGO REAL (Bastion Rush).
 *
 * O que faz (raia QA/FERRAMENTAS):
 *   1. Sobe um servidor estático local (python3 -m http.server) na raiz do repo.
 *   2. Abre bastion-rush/index.html no Chromium headless (Playwright).
 *   3. Coleta erros de Console (console.error) e exceções de página (pageerror).
 *   4. Exercita os hooks de teste window.BR (start/cleared/spawn) p/ rodar o loop.
 *   5. Salva um screenshot em verify_screenshot.png.
 *   6. Sai com código != 0 se houver QUALQUER erro de console/página.
 *
 * NÃO edita o jogo — apenas o observa rodando de verdade.
 *
 * Browsers do Playwright: usa PLAYWRIGHT_BROWSERS_PATH se setado (ex.: sandbox
 * usa /opt/pw-browsers). No CI o passo `playwright install chromium` baixa o
 * binário no cache padrão.
 *
 * Uso:
 *   node verify.js
 *   PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers node verify.js   # sandbox
 */
'use strict';

const { spawn } = require('child_process');
const net = require('net');
const path = require('path');

const ROOT = __dirname;
const GAME_PATH = '/bastion-rush/index.html';
const SHOT = path.join(ROOT, 'verify_screenshot.png');

function findFreePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.unref();
    srv.on('error', reject);
    srv.listen(0, '127.0.0.1', () => {
      const { port } = srv.address();
      srv.close(() => resolve(port));
    });
  });
}

function waitForServer(port, timeoutMs = 8000) {
  const deadline = Date.now() + timeoutMs;
  return new Promise((resolve, reject) => {
    const tryConnect = () => {
      const sock = net.connect(port, '127.0.0.1');
      sock.on('connect', () => { sock.destroy(); resolve(); });
      sock.on('error', () => {
        sock.destroy();
        if (Date.now() > deadline) reject(new Error('servidor não subiu a tempo'));
        else setTimeout(tryConnect, 150);
      });
    };
    tryConnect();
  });
}

async function main() {
  const { chromium } = require('playwright');

  const port = await findFreePort();

  // 1. servidor estático
  const server = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1'], {
    cwd: ROOT,
    stdio: 'ignore',
  });
  const stopServer = () => { try { server.kill('SIGKILL'); } catch (_) {} };
  process.on('exit', stopServer);

  let browser;
  const errors = [];
  try {
    await waitForServer(port);

    // 2. Chromium headless (flags p/ rodar em CI/sandbox sem GPU).
    // Em alguns caches só existe o chromium completo (sem o chrome-headless-shell);
    // fixamos o executável resolvido p/ não exigir o shell separado.
    browser = await chromium.launch({
      executablePath: chromium.executablePath(),
      args: ['--no-sandbox', '--disable-dev-shm-usage'],
    });
    const page = await browser.newPage({ viewport: { width: 460, height: 880 } });

    const isFavicon = (u) => /\/favicon\.ico(\?|$)/.test(u || '');

    page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
    page.on('console', (m) => {
      if (m.type() !== 'error') return;
      const txt = m.text();
      // Ignora o ruído genérico de recurso 404: o 404 real (não-favicon) já é
      // capturado por 'response' abaixo com a URL exata.
      if (/Failed to load resource/i.test(txt)) return;
      errors.push('console.error: ' + txt);
    });
    page.on('response', (r) => {
      const s = r.status();
      if (s >= 400 && !isFavicon(r.url())) errors.push(`http ${s}: ${r.url()}`);
    });
    page.on('requestfailed', (r) => {
      if (isFavicon(r.url())) return;
      errors.push(`requestfailed: ${r.url()} (${r.failure() && r.failure().errorText})`);
    });

    const url = `http://127.0.0.1:${port}${GAME_PATH}`;
    await page.goto(url, { waitUntil: 'load', timeout: 20000 });
    await page.waitForTimeout(500);

    // 3. window.BR existe?
    const hasBR = await page.evaluate(() => typeof window.BR === 'object' && window.BR !== null);
    if (!hasBR) errors.push('fatal: window.BR não disponível (hooks de teste ausentes)');

    let state = 'unknown';
    if (hasBR) {
      // 4. exercita o loop: libera fase alta, começa, spawna inimigos
      await page.evaluate(() => { BR.money(); BR.cleared(50); BR.start(40); });
      await page.waitForTimeout(1500);
      await page.evaluate(() => {
        ['ogre', 'flier', 'healer'].forEach((ty) => { try { BR.spawn(ty); } catch (_) {} });
      });
      await page.waitForTimeout(1200);
      state = await page.evaluate(() => { try { return BR.state(); } catch (_) { return 'unknown'; } });
    }

    // 5. screenshot
    await page.screenshot({ path: SHOT });

    console.log(`GAME=bastion-rush STATE=${state} SHOT=${path.relative(ROOT, SHOT)}`);
    console.log('ERROS=' + JSON.stringify(errors));
  } finally {
    if (browser) await browser.close();
    stopServer();
  }

  if (errors.length) {
    console.error(`\n✗ verify.js FALHOU: ${errors.length} erro(s) detectado(s).`);
    process.exit(1);
  }
  console.log('\n✓ verify.js OK: jogo carregou e rodou sem erros de console/página.');
}

main().catch((e) => {
  console.error('FALHA verify.js:', e && e.stack ? e.stack : e);
  process.exit(1);
});
