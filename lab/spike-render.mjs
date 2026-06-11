// Spike de render (Etapa 0 / M7) — prova que Playwright headless consegue
// renderizar WebGL (Three.js vendorizado) e tirar screenshot, inclusive em CI.
//
// O que faz:
//   1. sobe um servidor HTTP estático servindo a raiz do repo (zero CDN);
//   2. abre lab/models.html no Chromium headless (swiftshader/ANGLE);
//   3. espera o modelo glTF carregar e o turntable renderizar alguns frames;
//   4. lê de volta os pixels do canvas e confirma que NÃO está vazio;
//   5. salva lab/spike-render.png e falha (exit != 0) se algo der errado.
//
// Uso:  node lab/spike-render.mjs
// Requer: playwright (chromium). NODE_PATH pode apontar p/ o global se preciso.

import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join, normalize, extname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = normalize(join(__dirname, '..'));
const PORT = 8137;

const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.glb': 'model/gltf-binary', '.png': 'image/png',
  '.css': 'text/css', '.wasm': 'application/wasm',
};

const server = http.createServer(async (req, res) => {
  try {
    const url = decodeURIComponent(req.url.split('?')[0]);
    const path = normalize(join(ROOT, url));
    if (!path.startsWith(ROOT)) { res.writeHead(403).end(); return; }
    const data = await readFile(path);
    res.writeHead(200, { 'content-type': MIME[extname(path)] || 'application/octet-stream' });
    res.end(data);
  } catch { res.writeHead(404).end('not found'); }
});

function fail(msg) { console.error('SPIKE FALHOU:', msg); process.exitCode = 1; }

await new Promise(r => server.listen(PORT, r));

// resolve playwright via require (honra NODE_PATH e o node_modules global)
const require = (await import('node:module')).createRequire(import.meta.url);
let chromium;
try {
  chromium = require('playwright').chromium;
} catch {
  try {
    const gp = require('node:child_process').execSync('npm root -g').toString().trim();
    chromium = require(join(gp, 'playwright')).chromium;
  } catch (e) { server.close(); fail('playwright não encontrado: ' + e.message); process.exit(1); }
}
if (!chromium) { server.close(); fail('chromium indisponível no playwright'); process.exit(1); }

const errs = [];
const browser = await chromium.launch({
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--ignore-gpu-blocklist', '--enable-webgl'],
});
const page = await browser.newPage({ viewport: { width: 720, height: 1000 } });
page.on('pageerror', e => errs.push('pageerror: ' + e.message));
page.on('console', m => { if (m.type() === 'error') errs.push('console.error: ' + m.text()); });

await page.goto(`http://localhost:${PORT}/lab/models.html`, { waitUntil: 'load' });
await page.waitForFunction(() => window.LAB && (window.LAB.ready || window.LAB.error), { timeout: 25000 }).catch(() => {});
await page.waitForTimeout(1500);

const state = await page.evaluate(() => ({
  ready: LAB.ready, error: LAB.error, frames: LAB.frames,
  rev: LAB.rev, anim: LAB.anim, webgl: LAB.webgl,
}));

// readback dos pixels do canvas (preserveDrawingBuffer está ligado em models.html)
const pixels = await page.evaluate(() => {
  const c = document.getElementById('c');
  const tmp = document.createElement('canvas');
  tmp.width = c.width; tmp.height = c.height;
  tmp.getContext('2d').drawImage(c, 0, 0);
  const d = tmp.getContext('2d').getImageData(0, 0, c.width, c.height).data;
  let nonBg = 0, lum = 0;
  for (let i = 0; i < d.length; i += 4) {
    lum += d[i] + d[i + 1] + d[i + 2];
    if (Math.abs(d[i] - 16) + Math.abs(d[i + 1] - 20) + Math.abs(d[i + 2] - 31) > 40) nonBg++;
  }
  return { total: d.length / 4, nonBg, avgLum: lum / (d.length / 4 * 3) };
});

await page.screenshot({ path: join(__dirname, 'spike-render.png') });
await browser.close();
server.close();

console.log('STATE  =', JSON.stringify(state));
console.log('PIXELS =', JSON.stringify(pixels));
console.log('ERROS  =', JSON.stringify(errs));

if (state.error) fail('erro na página: ' + state.error);
else if (!state.ready) fail('cena não ficou ready');
else if (errs.length) fail('erros de console/página');
else if (pixels.nonBg < 50000) fail('canvas praticamente vazio (nonBg=' + pixels.nonBg + ')');
else console.log('SPIKE OK — WebGL renderizado e capturado em headless ✔  (PNG: lab/spike-render.png)');
