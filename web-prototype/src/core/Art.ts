import Phaser from 'phaser';
import { Palette, shade, tint, cssHex } from './Palette';
import { RNG } from './RNG';
import { CHAMPIONS } from '../data/champions';
import { ENEMIES } from '../data/enemies';

/**
 * Art — the procedural texture forge.
 *
 * Every sprite in Bastion Rush is generated at boot from code: no external art,
 * nothing to license, one consistent hand. We use Canvas2D for anything that
 * wants a real gradient (glows, orbs, soft shadows) and Phaser Graphics for the
 * crisp, outlined vector figures (champions, enemies, towers, icons).
 *
 * Look: bold flat silhouettes, a dark navy outline, and a top rim-light — high
 * contrast so units stay readable on a small phone screen in the dark.
 */

const OUTLINE = Palette.night0;

/** Standard figure canvas. Origin is authored at bottom-center (feet). */
export const FIG_W = 112;
export const FIG_H = 128;

export function buildAllTextures(scene: Phaser.Scene) {
  buildFx(scene);
  buildProjectiles(scene);
  buildIcons(scene);
  buildBastion(scene);
  buildPedestal(scene);
  buildWarden(scene);
  for (const c of CHAMPIONS) {
    buildChampion(scene, c.id, c.color, c.role, false);
    buildChampion(scene, c.id, c.color, c.role, true);
  }
  for (const e of ENEMIES) {
    buildEnemy(scene, e.id, e.color, e.kind, e.radius);
  }
}

// ────────────────────────────────────────────────────────────
// Canvas2D gradient helpers
// ────────────────────────────────────────────────────────────

function canvasTex(
  scene: Phaser.Scene,
  key: string,
  w: number,
  h: number,
  draw: (ctx: CanvasRenderingContext2D) => void,
) {
  if (scene.textures.exists(key)) scene.textures.remove(key);
  const tex = scene.textures.createCanvas(key, w, h);
  if (!tex) return;
  const ctx = tex.getContext();
  draw(ctx);
  tex.refresh();
}

/** A soft radial dot — the workhorse for glows and particles. */
function softCircle(scene: Phaser.Scene, key: string, size: number, color: number, hardness = 0) {
  canvasTex(scene, key, size, size, (ctx) => {
    const r = size / 2;
    const grad = ctx.createRadialGradient(r, r, r * hardness, r, r, r);
    grad.addColorStop(0, cssHex(color));
    grad.addColorStop(0.55, hexA(color, 0.55));
    grad.addColorStop(1, hexA(color, 0));
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);
  });
}

/** A glowing orb: bright white-hot core fading to a colored halo. */
function orb(scene: Phaser.Scene, key: string, size: number, color: number) {
  canvasTex(scene, key, size, size, (ctx) => {
    const r = size / 2;
    const grad = ctx.createRadialGradient(r, r, 0, r, r, r);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(0.35, cssHex(tint(color, 0.3)));
    grad.addColorStop(0.75, hexA(color, 0.9));
    grad.addColorStop(1, hexA(color, 0));
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);
  });
}

function hexA(n: number, a: number): string {
  const r = (n >> 16) & 0xff;
  const g = (n >> 8) & 0xff;
  const b = n & 0xff;
  return `rgba(${r},${g},${b},${a})`;
}

// ────────────────────────────────────────────────────────────
// FX & projectiles
// ────────────────────────────────────────────────────────────

function buildFx(scene: Phaser.Scene) {
  softCircle(scene, 'fx:soft', 64, Palette.white);
  softCircle(scene, 'fx:glow-ember', 128, Palette.ember2);
  softCircle(scene, 'fx:glow-aether', 128, Palette.aether1);
  softCircle(scene, 'fx:glow-rush', 128, Palette.rush2);
  orb(scene, 'fx:orb', 48, Palette.ember1);

  // Spark: a small bright diamond.
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(Palette.white, 1);
  g.fillPoints(
    [
      new Phaser.Geom.Point(8, 0),
      new Phaser.Geom.Point(11, 8),
      new Phaser.Geom.Point(8, 16),
      new Phaser.Geom.Point(5, 8),
    ],
    true,
  );
  g.generateTexture('fx:spark', 16, 16);
  g.clear();

  // Ring: a thin stroked circle for shockwaves.
  g.lineStyle(6, Palette.white, 1);
  g.strokeCircle(64, 64, 58);
  g.generateTexture('fx:ring', 128, 128);
  g.clear();

  // Soft square smoke puff.
  softCircle(scene, 'fx:smoke', 48, 0xbfc8dd, 0.1);

  // Shadow blob.
  canvasTex(scene, 'fx:shadow', 96, 48, (ctx) => {
    const grad = ctx.createRadialGradient(48, 24, 0, 48, 24, 48);
    grad.addColorStop(0, 'rgba(0,0,0,0.5)');
    grad.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.save();
    ctx.translate(48, 24);
    ctx.scale(1, 0.5);
    ctx.beginPath();
    ctx.arc(0, 0, 48, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  });

  g.destroy();
}

function buildProjectiles(scene: Phaser.Scene) {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);

  // Arrow (points right, +x).
  g.fillStyle(Palette.ember0, 1);
  g.fillRect(2, 6, 20, 4);
  g.fillStyle(Palette.ember2, 1);
  g.fillTriangle(20, 2, 30, 8, 20, 14);
  g.fillStyle(shade(Palette.ember3, 0.2), 1);
  g.fillRect(0, 5, 6, 6);
  g.generateTexture('proj:arrow', 32, 16);
  g.clear();

  // Bolt (aether shard).
  g.fillStyle(Palette.aether0, 1);
  g.fillPoints(
    [
      new Phaser.Geom.Point(0, 8),
      new Phaser.Geom.Point(18, 3),
      new Phaser.Geom.Point(28, 8),
      new Phaser.Geom.Point(18, 13),
    ],
    true,
  );
  g.generateTexture('proj:bolt', 28, 16);
  g.clear();

  g.destroy();

  // Orbs (round glows).
  orb(scene, 'proj:orb', 28, Palette.ember1);
  orb(scene, 'proj:aether', 26, Palette.aether0);
  orb(scene, 'proj:enemy', 24, Palette.rush2);
  orb(scene, 'proj:heal', 24, Palette.good);
}

// ────────────────────────────────────────────────────────────
// Figures (champions & enemies)
// ────────────────────────────────────────────────────────────

/** Draw a stylized humanoid body into g centered at (cx, feetY). */
function drawBody(
  g: Phaser.GameObjects.Graphics,
  cx: number,
  feetY: number,
  color: number,
  opts: { wide?: number; tall?: number; headR?: number } = {},
) {
  const wide = opts.wide ?? 30;
  const tall = opts.tall ?? 52;
  const headR = opts.headR ?? 17;
  const bodyTop = feetY - tall;
  const headCy = bodyTop - headR + 4;

  // Ground shadow.
  g.fillStyle(OUTLINE, 0.28);
  g.fillEllipse(cx, feetY, wide * 1.5, 14);

  // Outline pass (draw slightly larger dark shapes first).
  g.fillStyle(OUTLINE, 1);
  g.fillRoundedRect(cx - wide / 2 - 3, bodyTop - 3, wide + 6, tall + 6, 12);
  g.fillCircle(cx, headCy, headR + 3);

  // Body fill.
  g.fillStyle(color, 1);
  g.fillRoundedRect(cx - wide / 2, bodyTop, wide, tall, 10);
  // Body shading (lower half darker).
  g.fillStyle(shade(color, 0.28), 1);
  g.fillRoundedRect(cx - wide / 2, bodyTop + tall * 0.55, wide, tall * 0.45, 10);
  // Rim light (top-left).
  g.fillStyle(tint(color, 0.4), 0.9);
  g.fillRoundedRect(cx - wide / 2 + 3, bodyTop + 3, wide * 0.4, tall * 0.4, 6);

  // Head.
  const skin = 0xf2c9a0;
  g.fillStyle(skin, 1);
  g.fillCircle(cx, headCy, headR);
  g.fillStyle(shade(skin, 0.18), 1);
  g.fillCircle(cx + headR * 0.32, headCy + headR * 0.28, headR * 0.7);
  g.fillStyle(skin, 1);
  g.fillCircle(cx - headR * 0.1, headCy - headR * 0.1, headR * 0.9);

  return { bodyTop, headCy, headR };
}

function eyes(g: Phaser.GameObjects.Graphics, cx: number, cy: number, glow: number) {
  g.fillStyle(glow, 1);
  g.fillCircle(cx - 5, cy, 2.6);
  g.fillCircle(cx + 5, cy, 2.6);
}

function buildChampion(
  scene: Phaser.Scene,
  id: string,
  color: number,
  role: string,
  evo: boolean,
) {
  const key = evo ? `champ:${id}:evo` : `champ:${id}`;
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  const cx = FIG_W / 2;
  const feetY = FIG_H - 12;
  const accent = evo ? tint(color, 0.25) : color;
  const glow = evo ? Palette.ember0 : Palette.aether0;

  // Evolved figures get an aura ring behind them.
  if (evo) {
    g.fillStyle(Palette.ember1, 0.12);
    g.fillCircle(cx, feetY - 30, 52);
  }

  switch (id) {
    case 'boulder-golem': {
      // Stone titan: broad, blocky, glowing seams.
      g.fillStyle(OUTLINE, 0.28);
      g.fillEllipse(cx, feetY, 78, 18);
      g.fillStyle(OUTLINE, 1);
      g.fillRoundedRect(cx - 33, feetY - 74, 66, 74, 14);
      g.fillStyle(accent, 1);
      g.fillRoundedRect(cx - 30, feetY - 71, 60, 68, 12);
      g.fillStyle(shade(accent, 0.3), 1);
      g.fillRoundedRect(cx - 30, feetY - 30, 60, 30, 12);
      g.fillStyle(tint(accent, 0.3), 0.8);
      g.fillRoundedRect(cx - 24, feetY - 66, 22, 20, 6);
      // Glowing core seam.
      g.fillStyle(evo ? Palette.ember1 : Palette.aether0, 1);
      g.fillRect(cx - 3, feetY - 60, 6, 40);
      g.fillCircle(cx, feetY - 40, 7);
      eyes(g, cx, feetY - 56, evo ? Palette.ember0 : Palette.aether0);
      break;
    }
    case 'wolf-pack': {
      // A single wolf silhouette (deploys as 3 in-game).
      g.fillStyle(OUTLINE, 0.28);
      g.fillEllipse(cx, feetY, 60, 14);
      g.fillStyle(OUTLINE, 1);
      g.fillRoundedRect(cx - 30, feetY - 34, 58, 30, 10);
      g.fillTriangle(cx + 22, feetY - 40, cx + 46, feetY - 30, cx + 20, feetY - 14);
      g.fillStyle(accent, 1);
      g.fillRoundedRect(cx - 27, feetY - 31, 52, 25, 9);
      g.fillTriangle(cx + 22, feetY - 37, cx + 42, feetY - 29, cx + 21, feetY - 16);
      g.fillStyle(shade(accent, 0.3), 1);
      g.fillRoundedRect(cx - 27, feetY - 16, 52, 10, 8);
      // Ears.
      g.fillStyle(accent, 1);
      g.fillTriangle(cx + 30, feetY - 40, cx + 36, feetY - 52, cx + 40, feetY - 38);
      eyes(g, cx + 32, feetY - 30, Palette.danger);
      // Legs.
      g.fillStyle(shade(accent, 0.35), 1);
      g.fillRect(cx - 20, feetY - 10, 6, 10);
      g.fillRect(cx + 12, feetY - 10, 6, 10);
      break;
    }
    case 'runestone':
    case 'frost-warden':
    case 'stormcaller': {
      // Towers: a floating rune / crystal on a plinth.
      const crystal = accent;
      g.fillStyle(OUTLINE, 0.3);
      g.fillEllipse(cx, feetY, 66, 16);
      // Plinth.
      g.fillStyle(shade(Palette.stroke, 0.1), 1);
      g.fillRoundedRect(cx - 26, feetY - 22, 52, 22, 6);
      g.fillStyle(Palette.strokeHi, 1);
      g.fillRoundedRect(cx - 26, feetY - 22, 52, 8, 4);
      // Floating crystal.
      const cyc = feetY - 58;
      g.fillStyle(OUTLINE, 1);
      g.fillPoints(diamond(cx, cyc, 26, 40), true);
      g.fillStyle(crystal, 1);
      g.fillPoints(diamond(cx, cyc, 20, 34), true);
      g.fillStyle(tint(crystal, 0.5), 0.9);
      g.fillPoints(diamond(cx - 4, cyc - 4, 8, 18), true);
      g.fillStyle(Palette.white, 0.9);
      g.fillCircle(cx, cyc, 5);
      break;
    }
    case 'ashen-queen': {
      const r = drawBody(g, cx, feetY, accent, { wide: 32, tall: 56, headR: 16 });
      // Crown.
      g.fillStyle(evo ? Palette.ember0 : Palette.ember1, 1);
      const cyTop = r.headCy - r.headR - 2;
      g.fillTriangle(cx - 14, cyTop + 8, cx - 14, cyTop - 6, cx - 8, cyTop + 4);
      g.fillTriangle(cx - 4, cyTop + 6, cx, cyTop - 10, cx + 4, cyTop + 6);
      g.fillTriangle(cx + 8, cyTop + 4, cx + 14, cyTop - 6, cx + 14, cyTop + 8);
      g.fillRect(cx - 14, cyTop + 6, 28, 5);
      // Cape flare.
      g.fillStyle(shade(accent, 0.25), 1);
      g.fillTriangle(cx - 16, feetY - 50, cx - 34, feetY - 4, cx - 6, feetY - 8);
      eyes(g, cx, r.headCy, Palette.ember0);
      // Flame in hand.
      g.fillStyle(Palette.ember0, 0.9);
      g.fillCircle(cx + 22, feetY - 40, 8);
      break;
    }
    default: {
      // Generic humanoid champion with role props.
      const r = drawBody(g, cx, feetY, accent);
      eyes(g, cx, r.headCy, glow);
      addRoleProp(g, cx, feetY, r, role, accent, evo);
    }
  }

  g.generateTexture(key, FIG_W, FIG_H);
  g.destroy();
}

/** The Warden — a distinct, heroic ember-armored archer you pilot. */
function buildWarden(scene: Phaser.Scene) {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  const cx = FIG_W / 2;
  const feetY = FIG_H - 10;
  const gold = Palette.ember1;
  const bodyTop = feetY - 60;
  const headR = 18;
  const headCy = bodyTop - headR + 6;

  // Ground shadow.
  g.fillStyle(OUTLINE, 0.3);
  g.fillEllipse(cx, feetY, 56, 15);

  // Flowing cape behind.
  g.fillStyle(shade(Palette.ember3, 0.15), 1);
  g.fillPoints(
    [np(cx - 6, bodyTop + 4), np(cx - 26, feetY + 2), np(cx - 2, feetY - 6), np(cx + 8, bodyTop + 8)],
    true,
  );

  // Outline pass.
  g.fillStyle(OUTLINE, 1);
  g.fillRoundedRect(cx - 20, bodyTop - 3, 40, 66, 13);
  g.fillCircle(cx, headCy, headR + 3);

  // Armored body.
  g.fillStyle(gold, 1);
  g.fillRoundedRect(cx - 17, bodyTop, 34, 60, 11);
  g.fillStyle(shade(gold, 0.3), 1);
  g.fillRoundedRect(cx - 17, bodyTop + 34, 34, 26, 11);
  // Chest emblem.
  g.fillStyle(Palette.ember0, 1);
  g.fillCircle(cx, bodyTop + 22, 7);
  g.fillStyle(shade(gold, 0.2), 1);
  g.fillCircle(cx, bodyTop + 22, 3);
  // Rim light.
  g.fillStyle(tint(gold, 0.45), 0.9);
  g.fillRoundedRect(cx - 14, bodyTop + 3, 12, 22, 6);
  // Shoulder pauldrons.
  g.fillStyle(tint(gold, 0.15), 1);
  g.fillCircle(cx - 17, bodyTop + 8, 8);
  g.fillCircle(cx + 17, bodyTop + 8, 8);

  // Head + hood.
  const skin = 0xf2c9a0;
  g.fillStyle(skin, 1);
  g.fillCircle(cx, headCy, headR);
  g.fillStyle(shade(skin, 0.16), 1);
  g.fillCircle(cx + 5, headCy + 4, headR * 0.7);
  g.fillStyle(skin, 1);
  g.fillCircle(cx - 2, headCy - 2, headR * 0.85);
  // Ember hood/helm.
  g.fillStyle(shade(gold, 0.1), 1);
  g.fillRoundedRect(cx - headR, headCy - headR - 3, headR * 2, headR, 8);
  g.fillTriangle(cx - headR, headCy - 4, cx - headR - 5, headCy + 8, cx - headR + 4, headCy + 6);
  g.fillTriangle(cx + headR, headCy - 4, cx + headR + 5, headCy + 8, cx + headR - 4, headCy + 6);
  // Crest.
  g.fillStyle(Palette.ember0, 1);
  g.fillRect(cx - 2, headCy - headR - 12, 4, 12);
  // Glowing eyes.
  g.fillStyle(Palette.ember0, 1);
  g.fillCircle(cx - 5, headCy, 2.8);
  g.fillCircle(cx + 5, headCy, 2.8);

  // Radiant bow in hand.
  g.lineStyle(5, OUTLINE, 1);
  g.beginPath();
  g.arc(cx + 24, bodyTop + 18, 26, -1.2, 1.2, false);
  g.strokePath();
  g.lineStyle(3, Palette.ember0, 1);
  g.beginPath();
  g.arc(cx + 24, bodyTop + 18, 26, -1.2, 1.2, false);
  g.strokePath();
  g.lineStyle(1.5, tint(gold, 0.4), 0.9);
  g.lineBetween(
    cx + 24 + 26 * Math.cos(-1.2),
    bodyTop + 18 + 26 * Math.sin(-1.2),
    cx + 24 + 26 * Math.cos(1.2),
    bodyTop + 18 + 26 * Math.sin(1.2),
  );

  g.generateTexture('warden', FIG_W, FIG_H);
  g.destroy();
}

function addRoleProp(
  g: Phaser.GameObjects.Graphics,
  cx: number,
  _feetY: number,
  r: { bodyTop: number; headCy: number; headR: number },
  role: string,
  color: number,
  evo: boolean,
) {
  const metal = evo ? Palette.ember0 : 0xcdd6ea;
  if (role === 'melee') {
    // Helmet crest.
    g.fillStyle(shade(color, 0.2), 1);
    g.fillRoundedRect(cx - r.headR, r.headCy - r.headR - 2, r.headR * 2, r.headR, 8);
    g.fillStyle(evo ? Palette.ember1 : Palette.danger, 1);
    g.fillRect(cx - 2, r.headCy - r.headR - 12, 4, 12);
    // Sword.
    g.fillStyle(OUTLINE, 1);
    g.fillRect(cx + 16, r.bodyTop - 14, 6, 46);
    g.fillStyle(metal, 1);
    g.fillRect(cx + 17, r.bodyTop - 12, 4, 40);
    g.fillStyle(shade(color, 0.1), 1);
    g.fillRect(cx + 13, r.bodyTop + 24, 12, 5);
    // Shield.
    g.fillStyle(OUTLINE, 1);
    g.fillRoundedRect(cx - 30, r.bodyTop + 8, 16, 26, 6);
    g.fillStyle(tint(color, 0.15), 1);
    g.fillRoundedRect(cx - 28, r.bodyTop + 10, 12, 22, 5);
  } else if (role === 'ranged') {
    // Hood.
    g.fillStyle(shade(color, 0.15), 1);
    g.fillCircle(cx, r.headCy - 3, r.headR + 1);
    g.fillStyle(color, 1);
    g.fillCircle(cx, r.headCy + 1, r.headR - 1);
    // Bow.
    g.lineStyle(4, OUTLINE, 1);
    g.beginPath();
    g.arc(cx + 20, r.bodyTop + 16, 24, -1.1, 1.1, false);
    g.strokePath();
    g.lineStyle(2.4, metal, 1);
    g.beginPath();
    g.arc(cx + 20, r.bodyTop + 16, 24, -1.1, 1.1, false);
    g.strokePath();
    g.lineStyle(1.5, Palette.textDim, 0.9);
    g.lineBetween(cx + 20 + 24 * Math.cos(-1.1), r.bodyTop + 16 + 24 * Math.sin(-1.1),
      cx + 20 + 24 * Math.cos(1.1), r.bodyTop + 16 + 24 * Math.sin(1.1));
  } else if (role === 'support') {
    // Staff with a glowing head.
    g.fillStyle(OUTLINE, 1);
    g.fillRect(cx + 18, r.bodyTop - 18, 5, 52);
    g.fillStyle(0x8a6a4a, 1);
    g.fillRect(cx + 19, r.bodyTop - 16, 3, 48);
    g.fillStyle(Palette.good, 1);
    g.fillCircle(cx + 20, r.bodyTop - 20, 8);
    g.fillStyle(Palette.white, 0.8);
    g.fillCircle(cx + 20, r.bodyTop - 20, 3);
    // Hood halo.
    g.lineStyle(2, Palette.ember0, 0.7);
    g.strokeCircle(cx, r.headCy - r.headR - 4, 8);
  }
}

function diamond(cx: number, cy: number, halfW: number, halfH: number): Phaser.Geom.Point[] {
  return [
    new Phaser.Geom.Point(cx, cy - halfH),
    new Phaser.Geom.Point(cx + halfW, cy),
    new Phaser.Geom.Point(cx, cy + halfH),
    new Phaser.Geom.Point(cx - halfW, cy),
  ];
}

function buildEnemy(
  scene: Phaser.Scene,
  id: string,
  color: number,
  kind: string,
  radius: number,
) {
  const key = `enemy:${id}`;
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  const size = Math.max(FIG_W, radius * 3);
  const cx = size / 2;
  const feetY = size - 8;
  const rng = new RNG(id);

  if (kind === 'boss') {
    // Bosses: hulking mass with jagged crown of spikes and a burning core.
    const bw = radius * 1.7;
    g.fillStyle(OUTLINE, 0.32);
    g.fillEllipse(cx, feetY, bw * 1.5, 20);
    g.fillStyle(OUTLINE, 1);
    g.fillCircle(cx, feetY - radius, radius + 5);
    g.fillStyle(color, 1);
    g.fillCircle(cx, feetY - radius, radius);
    g.fillStyle(shade(color, 0.35), 1);
    g.fillEllipse(cx, feetY - radius * 0.5, radius * 1.6, radius);
    // Spikes.
    g.fillStyle(shade(color, 0.15), 1);
    for (let i = 0; i < 9; i++) {
      const a = -Math.PI + (i / 8) * Math.PI;
      const sx = cx + Math.cos(a) * radius;
      const sy = feetY - radius + Math.sin(a) * radius;
      const len = radius * rng.range(0.5, 0.9);
      g.fillTriangle(
        sx + Math.cos(a - 0.14) * 6,
        sy + Math.sin(a - 0.14) * 6,
        sx + Math.cos(a + 0.14) * 6,
        sy + Math.sin(a + 0.14) * 6,
        sx + Math.cos(a) * len,
        sy + Math.sin(a) * len,
      );
    }
    // Molten core + eyes.
    g.fillStyle(Palette.ember1, 1);
    g.fillCircle(cx, feetY - radius * 0.9, radius * 0.34);
    g.fillStyle(Palette.ember0, 1);
    g.fillCircle(cx, feetY - radius * 0.9, radius * 0.16);
    g.fillStyle(Palette.danger, 1);
    g.fillCircle(cx - radius * 0.4, feetY - radius * 1.3, 5);
    g.fillCircle(cx + radius * 0.4, feetY - radius * 1.3, 5);
  } else if (kind === 'flyer') {
    // Bat-like: body + wings, drawn hovering.
    const cy = feetY - radius - 12;
    g.fillStyle(OUTLINE, 0.2);
    g.fillEllipse(cx, feetY, radius * 2, 10);
    // Wings.
    g.fillStyle(shade(color, 0.25), 1);
    g.fillTriangle(cx - 4, cy, cx - radius * 2.4, cy - radius, cx - radius * 1.4, cy + radius * 0.8);
    g.fillTriangle(cx + 4, cy, cx + radius * 2.4, cy - radius, cx + radius * 1.4, cy + radius * 0.8);
    // Body.
    g.fillStyle(OUTLINE, 1);
    g.fillCircle(cx, cy, radius + 3);
    g.fillStyle(color, 1);
    g.fillCircle(cx, cy, radius);
    g.fillStyle(shade(color, 0.3), 1);
    g.fillEllipse(cx, cy + radius * 0.4, radius * 1.3, radius * 0.9);
    eyes(g, cx, cy - 1, Palette.warn);
  } else if (kind === 'brute') {
    // Big lumpy body, heavy shoulders.
    g.fillStyle(OUTLINE, 0.3);
    g.fillEllipse(cx, feetY, radius * 2.6, 16);
    g.fillStyle(OUTLINE, 1);
    g.fillRoundedRect(cx - radius, feetY - radius * 2.2, radius * 2, radius * 2.2, radius * 0.6);
    g.fillStyle(color, 1);
    g.fillRoundedRect(cx - radius * 0.92, feetY - radius * 2.1, radius * 1.84, radius * 2, radius * 0.55);
    g.fillStyle(shade(color, 0.3), 1);
    g.fillRoundedRect(cx - radius * 0.92, feetY - radius * 0.9, radius * 1.84, radius * 0.9, radius * 0.5);
    // Shoulders.
    g.fillStyle(shade(color, 0.12), 1);
    g.fillCircle(cx - radius * 0.9, feetY - radius * 1.7, radius * 0.5);
    g.fillCircle(cx + radius * 0.9, feetY - radius * 1.7, radius * 0.5);
    eyes(g, cx, feetY - radius * 1.6, Palette.danger);
    // Jaw.
    g.fillStyle(Palette.night0, 1);
    g.fillRoundedRect(cx - radius * 0.5, feetY - radius * 1.2, radius, radius * 0.35, 3);
  } else if (kind === 'caster') {
    // Robed floating mage: pointed hood, no legs.
    const cy = feetY - radius - 6;
    g.fillStyle(OUTLINE, 0.22);
    g.fillEllipse(cx, feetY, radius * 2, 10);
    g.fillStyle(OUTLINE, 1);
    g.fillTriangle(cx, cy - radius * 1.6, cx - radius, feetY, cx + radius, feetY);
    g.fillStyle(color, 1);
    g.fillTriangle(cx, cy - radius * 1.4, cx - radius * 0.85, feetY - 2, cx + radius * 0.85, feetY - 2);
    g.fillStyle(shade(color, 0.3), 1);
    g.fillTriangle(cx, cy, cx - radius * 0.7, feetY - 2, cx + radius * 0.7, feetY - 2);
    // Face void.
    g.fillStyle(Palette.night0, 1);
    g.fillCircle(cx, cy - radius * 0.2, radius * 0.5);
    eyes(g, cx, cy - radius * 0.2, 0xd14bff);
    // Orb.
    g.fillStyle(Palette.rush2, 0.9);
    g.fillCircle(cx + radius * 0.9, cy + radius * 0.4, radius * 0.35);
  } else {
    // Runner: a lean sprinting husk.
    g.fillStyle(OUTLINE, 0.26);
    g.fillEllipse(cx, feetY, radius * 2, 10);
    g.fillStyle(OUTLINE, 1);
    g.fillRoundedRect(cx - radius * 0.7, feetY - radius * 2, radius * 1.4, radius * 2, radius * 0.5);
    g.fillCircle(cx, feetY - radius * 2 + 2, radius * 0.72);
    g.fillStyle(color, 1);
    g.fillRoundedRect(cx - radius * 0.6, feetY - radius * 1.9, radius * 1.2, radius * 1.8, radius * 0.45);
    g.fillCircle(cx, feetY - radius * 2 + 2, radius * 0.62);
    g.fillStyle(shade(color, 0.3), 1);
    g.fillRoundedRect(cx - radius * 0.6, feetY - radius * 0.8, radius * 1.2, radius * 0.8, radius * 0.4);
    eyes(g, cx, feetY - radius * 2 + 2, Palette.warn);
    // Claws.
    g.fillStyle(shade(color, 0.2), 1);
    g.fillTriangle(cx + radius * 0.5, feetY - radius, cx + radius * 1.3, feetY - radius * 0.7, cx + radius * 0.5, feetY - radius * 0.6);
  }

  g.generateTexture(key, size, size);
  g.destroy();
  scene.textures.get(key).setFilter(Phaser.Textures.FilterMode.LINEAR);
}

// ────────────────────────────────────────────────────────────
// Bastion, pedestal, icons
// ────────────────────────────────────────────────────────────

function buildBastion(scene: Phaser.Scene) {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  const S = 200;
  const cx = S / 2;

  // Base rock.
  g.fillStyle(OUTLINE, 0.3);
  g.fillEllipse(cx, S - 20, 180, 40);
  g.fillStyle(shade(Palette.stroke, 0.2), 1);
  g.fillRoundedRect(cx - 78, S - 74, 156, 60, 12);

  // Keep body.
  g.fillStyle(OUTLINE, 1);
  g.fillRoundedRect(cx - 60, 44, 120, S - 96, 10);
  g.fillStyle(0x3a4a6e, 1);
  g.fillRoundedRect(cx - 56, 48, 112, S - 104, 8);
  // Battlements.
  for (let i = 0; i < 5; i++) {
    g.fillStyle(0x2c3a5c, 1);
    g.fillRect(cx - 56 + i * 24, 36, 16, 18);
  }
  // Door.
  g.fillStyle(Palette.night0, 1);
  g.fillRoundedRect(cx - 18, S - 96, 36, 60, 16);
  // Ember beacon at the top.
  g.fillStyle(Palette.ember1, 1);
  g.fillCircle(cx, 30, 12);
  g.fillStyle(Palette.ember0, 1);
  g.fillCircle(cx, 28, 6);
  // Window glows.
  g.fillStyle(Palette.ember1, 0.9);
  g.fillCircle(cx - 30, 90, 6);
  g.fillCircle(cx + 30, 90, 6);
  g.fillCircle(cx, 120, 6);

  g.generateTexture('bastion', S, S);
  g.destroy();

  softCircle(scene, 'bastion:glow', 260, Palette.ember1);
}

function buildPedestal(scene: Phaser.Scene) {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(OUTLINE, 0.3);
  g.fillEllipse(40, 54, 68, 18);
  g.fillStyle(Palette.stroke, 1);
  g.fillEllipse(40, 46, 56, 20);
  g.fillStyle(Palette.strokeHi, 1);
  g.fillEllipse(40, 42, 56, 18);
  g.fillStyle(shade(Palette.stroke, 0.2), 1);
  g.fillEllipse(40, 44, 40, 12);
  g.generateTexture('pedestal', 80, 64);
  g.destroy();
}

/** Simple glyph icons for boons & currencies, drawn from primitives. */
function buildIcons(scene: Phaser.Scene) {
  const draw = (key: string, color: number, fn: (g: Phaser.GameObjects.Graphics) => void) => {
    const g = scene.make.graphics({ x: 0, y: 0 }, false);
    g.fillStyle(color, 1);
    g.lineStyle(4, color, 1);
    fn(g);
    g.generateTexture(`icon:${key}`, 48, 48);
    g.destroy();
  };
  const C = 24;

  draw('flame', Palette.ember2, (g) => {
    g.fillStyle(Palette.ember2, 1);
    g.fillPoints(
      [np(24, 4), np(36, 26), np(30, 40), np(18, 40), np(12, 26)],
      true,
    );
    g.fillStyle(Palette.ember0, 1);
    g.fillCircle(24, 30, 7);
  });
  draw('bolt', Palette.warn, (g) => {
    g.fillPoints([np(26, 4), np(14, 26), np(23, 26), np(20, 44), np(34, 20), np(25, 20)], true);
  });
  draw('boot', Palette.aether0, (g) => {
    g.fillRoundedRect(16, 8, 10, 26, 3);
    g.fillRoundedRect(16, 30, 22, 8, 3);
  });
  draw('heart', Palette.danger, (g) => {
    g.fillCircle(17, 18, 8);
    g.fillCircle(31, 18, 8);
    g.fillTriangle(9, 21, 39, 21, 24, 40);
  });
  draw('eye', Palette.text, (g) => {
    g.fillEllipse(C, C, 34, 20);
    g.fillStyle(Palette.night0, 1);
    g.fillCircle(C, C, 7);
    g.fillStyle(Palette.aether0, 1);
    g.fillCircle(C, C, 4);
  });
  draw('arrow', Palette.ember0, (g) => {
    g.fillRect(8, 21, 26, 6);
    g.fillTriangle(30, 14, 42, 24, 30, 34);
  });
  draw('fork', Palette.ember1, (g) => {
    g.lineStyle(4, Palette.ember1, 1);
    g.lineBetween(8, 24, 24, 24);
    g.lineBetween(24, 24, 40, 12);
    g.lineBetween(24, 24, 40, 36);
  });
  draw('target', Palette.danger, (g) => {
    g.lineStyle(4, Palette.danger, 1);
    g.strokeCircle(C, C, 16);
    g.strokeCircle(C, C, 8);
    g.fillCircle(C, C, 3);
  });
  draw('blade', Palette.text, (g) => {
    g.fillTriangle(14, 40, 34, 8, 38, 12);
    g.fillRect(10, 36, 10, 6);
  });
  draw('drop', Palette.danger, (g) => {
    g.fillTriangle(24, 8, 34, 30, 14, 30);
    g.fillCircle(24, 30, 10);
  });
  draw('gem', Palette.aether0, (g) => {
    g.fillPoints(diamond(24, 24, 15, 18), true);
    g.fillStyle(Palette.white, 0.7);
    g.fillPoints(diamond(20, 20, 5, 8), true);
  });
  draw('horn', Palette.ember1, (g) => {
    g.lineStyle(5, Palette.ember1, 1);
    g.beginPath();
    g.arc(24, 30, 16, -2.4, -0.3, false);
    g.strokePath();
  });
  draw('shield', Palette.good, (g) => {
    g.fillPoints([np(24, 6), np(40, 12), np(38, 30), np(24, 42), np(10, 30), np(8, 12)], true);
    g.fillStyle(tint(Palette.good, 0.4), 1);
    g.fillPoints([np(24, 12), np(33, 16), np(32, 28), np(24, 34)], true);
  });
  draw('brick', 0xc98a5a, (g) => {
    g.fillRoundedRect(8, 14, 32, 20, 2);
    g.fillStyle(Palette.night0, 1);
    g.fillRect(23, 14, 2, 20);
    g.fillRect(8, 23, 32, 2);
  });
  draw('lightning', Palette.aether0, (g) => {
    g.fillPoints([np(28, 4), np(12, 28), np(22, 28), np(18, 44), np(36, 20), np(26, 20)], true);
  });
  draw('ember', Palette.ember3, (g) => {
    g.fillCircle(24, 28, 12);
    g.fillStyle(Palette.ember0, 1);
    g.fillCircle(24, 30, 6);
    g.fillStyle(Palette.ember3, 1);
    g.fillTriangle(18, 18, 30, 18, 24, 6);
  });
  draw('snow', Palette.aether0, (g) => {
    g.lineStyle(3, Palette.aether0, 1);
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI;
      g.lineBetween(24 - Math.cos(a) * 16, 24 - Math.sin(a) * 16, 24 + Math.cos(a) * 16, 24 + Math.sin(a) * 16);
    }
  });
  draw('coin', Palette.warn, (g) => {
    g.fillCircle(C, C, 16);
    g.fillStyle(shade(Palette.warn, 0.25), 1);
    g.fillCircle(C, C, 12);
    g.fillStyle(Palette.warn, 1);
    g.fillCircle(C, C, 9);
  });

  // Currency icons reuse coin/gem plus a shard + core.
  const g2 = scene.make.graphics({ x: 0, y: 0 }, false);
  g2.fillStyle(Palette.aether0, 1);
  g2.fillPoints(diamond(24, 24, 10, 20), true);
  g2.fillStyle(Palette.white, 0.6);
  g2.fillPoints(diamond(21, 18, 3, 8), true);
  g2.generateTexture('icon:shard', 48, 48);
  g2.clear();
  g2.fillStyle(Palette.ember2, 1);
  g2.fillCircle(24, 24, 15);
  g2.fillStyle(Palette.ember0, 1);
  g2.fillCircle(24, 24, 8);
  g2.fillStyle(Palette.white, 0.9);
  g2.fillCircle(21, 21, 3);
  g2.generateTexture('icon:core', 48, 48);
  g2.destroy();
}

function np(x: number, y: number): Phaser.Geom.Point {
  return new Phaser.Geom.Point(x, y);
}
