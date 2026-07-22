import Phaser from 'phaser';
import { Palette, cssHex, shade, tint } from './Palette';
import { Audio } from './Audio';

/**
 * UI — reusable interface widgets built on Phaser primitives.
 *
 * Buttons, panels, labels, and currency chips with a consistent look, press
 * feedback, and touch-friendly hit areas. Keeps every menu on-brand.
 */

export const FONT = 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

export interface TextOpts {
  size?: number;
  color?: number;
  weight?: '400' | '600' | '700' | '800' | '900';
  align?: 'left' | 'center' | 'right';
  alpha?: number;
  letter?: number;
}

export function label(
  scene: Phaser.Scene,
  x: number,
  y: number,
  str: string,
  opts: TextOpts = {},
): Phaser.GameObjects.Text {
  const t = scene.add.text(x, y, str, {
    fontFamily: FONT,
    fontSize: `${opts.size ?? 22}px`,
    color: cssHex(opts.color ?? Palette.text),
    fontStyle: opts.weight === '400' ? 'normal' : 'bold',
    align: opts.align ?? 'left',
  });
  if (opts.weight) t.setFontStyle(weightToStyle(opts.weight));
  t.setAlpha(opts.alpha ?? 1);
  if (opts.letter) t.setLetterSpacing(opts.letter);
  if (opts.align === 'center') t.setOrigin(0.5, t.originY);
  else if (opts.align === 'right') t.setOrigin(1, t.originY);
  return t;
}

function weightToStyle(w: string): string {
  const n = parseInt(w, 10);
  return n >= 700 ? 'bold' : 'normal';
}

export interface PanelOpts {
  fill?: number;
  stroke?: number;
  strokeWidth?: number;
  radius?: number;
  alpha?: number;
  highlight?: boolean;
  glow?: number;
}

/** Draws a rounded panel into a Graphics object at local (0,0). */
export function drawPanel(
  g: Phaser.GameObjects.Graphics,
  w: number,
  h: number,
  opts: PanelOpts = {},
) {
  const r = opts.radius ?? 18;
  const fill = opts.fill ?? Palette.panel;
  const stroke = opts.stroke ?? Palette.stroke;
  g.fillStyle(fill, opts.alpha ?? 1);
  g.fillRoundedRect(0, 0, w, h, r);
  if (opts.highlight) {
    g.fillStyle(tint(fill, 0.12), 0.6);
    g.fillRoundedRect(2, 2, w - 4, h * 0.42, r - 2);
  }
  if (opts.strokeWidth !== 0) {
    g.lineStyle(opts.strokeWidth ?? 2, stroke, 1);
    g.strokeRoundedRect(1, 1, w - 2, h - 2, r);
  }
}

export function panel(
  scene: Phaser.Scene,
  x: number,
  y: number,
  w: number,
  h: number,
  opts: PanelOpts = {},
): Phaser.GameObjects.Graphics {
  const g = scene.add.graphics({ x, y });
  drawPanel(g, w, h, opts);
  return g;
}

export interface ButtonOpts {
  width?: number;
  height?: number;
  color?: number;
  textColor?: number;
  size?: number;
  icon?: string;
  radius?: number;
  variant?: 'solid' | 'ghost' | 'ember' | 'aether';
}

/** A touch-friendly button container with press feedback. */
export class Button extends Phaser.GameObjects.Container {
  private bg: Phaser.GameObjects.Graphics;
  private txt: Phaser.GameObjects.Text;
  private iconImg?: Phaser.GameObjects.Image;
  private bw: number;
  private bh: number;
  private opts: ButtonOpts;
  private baseColor: number;
  private enabled = true;
  private onTap: () => void;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    text: string,
    onTap: () => void,
    opts: ButtonOpts = {},
  ) {
    super(scene, x, y);
    this.opts = opts;
    this.onTap = onTap;
    this.bw = opts.width ?? 240;
    this.bh = opts.height ?? 62;

    const variant = opts.variant ?? 'solid';
    this.baseColor =
      opts.color ??
      (variant === 'ember'
        ? Palette.ember2
        : variant === 'aether'
          ? Palette.aether1
          : variant === 'ghost'
            ? Palette.panelHi
            : Palette.panelHi);

    this.bg = scene.add.graphics();
    this.add(this.bg);
    this.redraw(this.baseColor);

    this.txt = label(scene, 0, 0, text, {
      size: opts.size ?? 24,
      weight: '800',
      color: opts.textColor ?? (variant === 'ghost' ? Palette.text : Palette.night0),
      align: 'center',
    });
    this.txt.setOrigin(0.5);

    if (opts.icon) {
      this.iconImg = scene.add.image(0, 0, opts.icon).setDisplaySize(30, 30);
      this.add(this.iconImg);
      this.iconImg.x = -this.bw / 2 + 34;
      this.txt.x = 18;
    }
    this.add(this.txt);

    this.setSize(this.bw, this.bh);
    this.setInteractive(
      new Phaser.Geom.Rectangle(-this.bw / 2, -this.bh / 2, this.bw, this.bh),
      Phaser.Geom.Rectangle.Contains,
    );

    this.on('pointerdown', this.press, this);
    this.on('pointerup', this.release, this);
    this.on('pointerout', this.cancel, this);

    scene.add.existing(this);
  }

  private redraw(color: number) {
    const g = this.bg;
    g.clear();
    const r = this.opts.radius ?? 16;
    const variant = this.opts.variant ?? 'solid';
    // Drop shadow.
    g.fillStyle(Palette.night0, 0.35);
    g.fillRoundedRect(-this.bw / 2, -this.bh / 2 + 4, this.bw, this.bh, r);
    if (variant === 'ghost') {
      g.fillStyle(color, 1);
      g.fillRoundedRect(-this.bw / 2, -this.bh / 2, this.bw, this.bh, r);
      g.lineStyle(2, Palette.strokeHi, 1);
      g.strokeRoundedRect(-this.bw / 2 + 1, -this.bh / 2 + 1, this.bw - 2, this.bh - 2, r);
    } else {
      // Base.
      g.fillStyle(shade(color, 0.25), 1);
      g.fillRoundedRect(-this.bw / 2, -this.bh / 2, this.bw, this.bh, r);
      // Top face.
      g.fillStyle(color, 1);
      g.fillRoundedRect(-this.bw / 2, -this.bh / 2, this.bw, this.bh - 6, r);
      // Gloss.
      g.fillStyle(tint(color, 0.35), 0.55);
      g.fillRoundedRect(-this.bw / 2 + 4, -this.bh / 2 + 4, this.bw - 8, this.bh * 0.34, r - 4);
    }
  }

  private press() {
    if (!this.enabled) return;
    this.setScale(0.96);
    this.redraw(shade(this.baseColor, 0.12));
    Audio.uiClick();
  }
  private release() {
    if (!this.enabled) return;
    this.setScale(1);
    this.redraw(this.baseColor);
    this.onTap();
  }
  private cancel() {
    this.setScale(1);
    this.redraw(this.baseColor);
  }

  setEnabled(on: boolean): this {
    this.enabled = on;
    this.setAlpha(on ? 1 : 0.45);
    return this;
  }

  setText(s: string): this {
    this.txt.setText(s);
    return this;
  }
}

export function button(
  scene: Phaser.Scene,
  x: number,
  y: number,
  text: string,
  onTap: () => void,
  opts: ButtonOpts = {},
): Button {
  return new Button(scene, x, y, text, onTap, opts);
}

/** A small currency readout chip: [icon] 1,234 */
export function currencyChip(
  scene: Phaser.Scene,
  x: number,
  y: number,
  iconKey: string,
  value: number,
  width = 120,
): Phaser.GameObjects.Container {
  const c = scene.add.container(x, y);
  const g = scene.add.graphics();
  drawPanel(g, width, 40, { fill: Palette.night1, stroke: Palette.stroke, radius: 20 });
  g.x = -width / 2;
  const icon = scene.add.image(-width / 2 + 22, 20, iconKey).setDisplaySize(26, 26);
  const t = label(scene, -width / 2 + 42, 20, formatNum(value), { size: 20, weight: '800' });
  t.setOrigin(0, 0.5);
  c.add([g, icon, t]);
  c.setData('text', t);
  return c;
}

export function formatNum(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
  if (n >= 10_000) return (n / 1000).toFixed(1) + 'k';
  return Math.floor(n).toLocaleString('en-US');
}

/** Fade the camera in from black — used on every scene start. */
export function fadeIn(scene: Phaser.Scene, ms = 320) {
  scene.cameras.main.fadeIn(ms, 5, 7, 15);
}

/** Fade out to black then run a callback (scene transition). */
export function fadeTo(scene: Phaser.Scene, ms: number, cb: () => void) {
  scene.cameras.main.fadeOut(ms, 5, 7, 15);
  scene.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, cb);
}

/** A transient toast message near the top of the screen. */
export function toast(scene: Phaser.Scene, msg: string, color: number = Palette.text) {
  const { width } = scene.scale;
  const c = scene.add.container(width / 2, 120).setDepth(90);
  const g = scene.add.graphics();
  const w = Math.max(200, msg.length * 12 + 40);
  drawPanel(g, w, 46, { fill: Palette.panelHi, stroke: Palette.strokeHi, radius: 23 });
  g.x = -w / 2;
  const t = label(scene, 0, 23, msg, { size: 19, weight: '700', color, align: 'center' });
  t.setOrigin(0.5);
  c.add([g, t]);
  c.setAlpha(0);
  scene.tweens.add({ targets: c, alpha: 1, y: 140, duration: 200, ease: 'Back.out' });
  scene.tweens.add({
    targets: c,
    alpha: 0,
    y: 120,
    delay: 1400,
    duration: 300,
    onComplete: () => c.destroy(),
  });
}
