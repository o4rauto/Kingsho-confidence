import Phaser from 'phaser';
import { Palette, mix } from './Palette';
import { DEPTH } from '../config';

/**
 * Backdrop — the shared living twilight behind every menu.
 *
 * A vertical night gradient, a drift of stars, distant hills, the Bastion
 * silhouette, and a slow rise of embers. Gives the menus depth and motion so
 * the game feels alive before you even press Play.
 */
export class Backdrop {
  private scene: Phaser.Scene;
  private embers: Phaser.GameObjects.Particles.ParticleEmitter | null = null;

  constructor(scene: Phaser.Scene, opts: { accent?: number; hills?: boolean } = {}) {
    this.scene = scene;
    const { width, height } = scene.scale;
    const accent = opts.accent ?? Palette.ember2;

    // Sky gradient via stacked bands (cheap, no shader).
    const g = scene.add.graphics().setDepth(DEPTH.ground);
    const bands = 24;
    for (let i = 0; i < bands; i++) {
      const t = i / (bands - 1);
      const col = mix(Palette.night0, Palette.night2, Math.pow(1 - t, 1.4));
      g.fillStyle(col, 1);
      g.fillRect(0, (height / bands) * i, width, height / bands + 1);
    }
    // Warm horizon glow.
    const glow = scene.add
      .image(width / 2, height * 0.72, 'fx:glow-ember')
      .setDisplaySize(width * 1.6, height * 0.9)
      .setAlpha(0.16)
      .setTint(accent)
      .setDepth(DEPTH.ground);
    scene.tweens.add({
      targets: glow,
      alpha: 0.24,
      duration: 3600,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.inOut',
    });

    // Stars.
    const stars = scene.add.graphics().setDepth(DEPTH.ground);
    for (let i = 0; i < 70; i++) {
      const x = Math.random() * width;
      const y = Math.random() * height * 0.6;
      const a = Math.random() * 0.6 + 0.2;
      stars.fillStyle(Palette.white, a);
      stars.fillCircle(x, y, Math.random() < 0.85 ? 1 : 2);
    }
    scene.tweens.add({ targets: stars, alpha: 0.5, duration: 2200, yoyo: true, repeat: -1 });

    if (opts.hills !== false) {
      this.drawHills(width, height, accent);
    }

    // Rising embers.
    this.embers = scene.add.particles(0, 0, 'fx:soft', {
      x: { min: 0, max: width },
      y: height + 10,
      lifespan: 6000,
      speedY: { min: -40, max: -80 },
      speedX: { min: -12, max: 12 },
      scale: { start: 0.12, end: 0 },
      alpha: { start: 0.5, end: 0 },
      tint: [Palette.ember1, Palette.ember2, accent],
      frequency: 260,
      blendMode: 'ADD',
    });
    this.embers.setDepth(DEPTH.decal);
  }

  private drawHills(width: number, height: number, accent: number) {
    const scene = this.scene;
    const layers = [
      { y: height * 0.62, color: mix(Palette.night2, accent, 0.08), amp: 40, depth: DEPTH.ground },
      { y: height * 0.72, color: Palette.night1, amp: 60, depth: DEPTH.path },
      { y: height * 0.82, color: Palette.night0, amp: 34, depth: DEPTH.decal },
    ];
    for (const L of layers) {
      const g = scene.add.graphics().setDepth(L.depth);
      g.fillStyle(L.color, 1);
      g.beginPath();
      g.moveTo(0, height);
      g.lineTo(0, L.y);
      const steps = 8;
      for (let i = 0; i <= steps; i++) {
        const x = (width / steps) * i;
        const y = L.y + Math.sin(i * 1.3 + L.amp) * L.amp * 0.5 - (i % 2) * L.amp * 0.3;
        g.lineTo(x, y);
      }
      g.lineTo(width, height);
      g.closePath();
      g.fillPath();
    }

    // Distant Bastion on the middle hill.
    const b = scene.add
      .image(width * 0.5, height * 0.74, 'bastion')
      .setScale(0.7)
      .setDepth(DEPTH.path)
      .setTint(mix(Palette.night1, accent, 0.25));
    const beacon = scene.add
      .image(width * 0.5, height * 0.62, 'bastion:glow')
      .setDisplaySize(220, 220)
      .setAlpha(0.18)
      .setBlendMode(Phaser.BlendModes.ADD)
      .setDepth(DEPTH.path)
      .setTint(accent);
    scene.tweens.add({ targets: beacon, alpha: 0.32, scale: 1.1, duration: 2400, yoyo: true, repeat: -1 });
    scene.tweens.add({ targets: b, y: height * 0.735, duration: 3000, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
  }

  destroy() {
    this.embers?.destroy();
  }
}
