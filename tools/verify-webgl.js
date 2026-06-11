#!/usr/bin/env node
/*
 * verify-webgl.js — SPIKE de Modelos: prova que o CI roda Three.js (WebGL) em
 * Chromium headless e captura screenshot.
 *
 * O que faz:
 *   1. Sobe python3 -m http.server na raiz do repo (serve /node_modules/three).
 *   2. Abre tools/webgl-spike.html no Chromium headless com WebGL por software
 *      (SwiftShader/ANGLE) — não precisa de GPU.
 *   3. Espera o renderer Three.js desenhar alguns frames (window.SPIKE).
 *   4. Salva tools/webgl_spike_screenshot.png e prova que o canvas NÃO está vazio
 *      (lê pixels: precisa ter mais de uma cor).
 *   5. Sai != 0 em qualquer erro.
 *
 * NÃO toca no jogo. É um experimento de viabilidade para a raia de Modelos.
 */
'use strict';

const { spawn } = require('child_process');
const net = require('net');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const PAGE = '/tools/webgl-spike.html';
const SHOT = path.join(__dirname, 'webgl_spike_screenshot.png');

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

    // WebGL por software: SwiftShader via ANGLE. Funciona headless sem GPU.
    browser = await chromium.launch({
      executablePath: chromium.executablePath(),
      args: [
        '--no-sandbox',
        '--disable-dev-shm-usage',
        '--use-gl=angle',
        '--use-angle=swiftshader',
        '--enable-unsafe-swiftshader',
        '--ignore-gpu-blocklist',
      ],
    });
    const page = await browser.newPage({ viewport: { width: 460, height: 880 } });
    page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
    page.on('console', (m) => {
      if (m.type() !== 'error') return;
      const txt = m.text();
      if (/Failed to load resource/i.test(txt)) return; // ruído de favicon 404
      errors.push('console.error: ' + txt);
    });

    await page.goto(`http://127.0.0.1:${port}${PAGE}`, { waitUntil: 'load', timeout: 20000 });

    // Espera o renderer Three.js desenhar pelo menos alguns frames.
    await page.waitForFunction(() => window.SPIKE && (window.SPIKE.ready || window.SPIKE.error), null, { timeout: 15000 });
    const spike = await page.evaluate(() => window.SPIKE);
    if (spike.error) errors.push('spike: ' + spike.error);
    await page.waitForTimeout(400);

    // Prova de que o canvas WebGL realmente desenhou (não é tela vazia):
    // conta cores distintas amostradas do canvas.
    const distinct = await page.evaluate(() => {
      const c = document.querySelector('canvas');
      if (!c) return -1;
      const off = document.createElement('canvas');
      off.width = c.width; off.height = c.height;
      const ctx = off.getContext('2d');
      ctx.drawImage(c, 0, 0);
      const { data } = ctx.getImageData(0, 0, off.width, off.height);
      const seen = new Set();
      for (let i = 0; i < data.length; i += 4 * 997) {
        seen.add((data[i] << 16) | (data[i + 1] << 8) | data[i + 2]);
      }
      return seen.size;
    });
    if (distinct < 2) errors.push(`canvas vazio/uniforme (cores distintas=${distinct})`);

    await page.screenshot({ path: SHOT });

    console.log(`SPIKE=three.js renderer=${spike.renderer} frames=${spike.frames} cores=${distinct} SHOT=${path.relative(ROOT, SHOT)}`);
    console.log('ERROS=' + JSON.stringify(errors));
  } finally {
    if (browser) await browser.close();
    stopServer();
  }

  if (errors.length) {
    console.error(`\n✗ verify-webgl.js FALHOU: ${errors.length} erro(s).`);
    process.exit(1);
  }
  console.log('\n✓ verify-webgl.js OK: Three.js renderizou em WebGL headless e o screenshot tem conteúdo.');
}

main().catch((e) => {
  console.error('FALHA verify-webgl.js:', e && e.stack ? e.stack : e);
  process.exit(1);
});
