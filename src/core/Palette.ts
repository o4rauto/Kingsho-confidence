/**
 * Palette — the art direction of Bastion Rush in one place.
 *
 * Warm ember gold against cold twilight blues: a besieged fortress glowing in
 * the dark. Every scene and generated texture pulls from this so the game reads
 * as one cohesive world.
 */
export const Palette = {
  // Backdrop / twilight
  night0: 0x05070f,
  night1: 0x0b1020,
  night2: 0x131c33,
  night3: 0x1e2b49,

  // Ink & panels
  panel: 0x111a30,
  panelHi: 0x1b2745,
  stroke: 0x2c3c63,
  strokeHi: 0x40598f,

  // Text
  text: 0xeaf0ff,
  textDim: 0x94a3c8,
  textFaint: 0x5d6d95,

  // Ember (the hero / player identity)
  ember0: 0xffe6a6,
  ember1: 0xffbf5e,
  ember2: 0xff8a3d,
  ember3: 0xf25a2a,

  // Aether (energy / magic)
  aether0: 0x8fe9ff,
  aether1: 0x37b6ff,
  aether2: 0x4d6bff,

  // Faction / states
  good: 0x54e08a,
  warn: 0xffcf4d,
  danger: 0xff5470,
  poison: 0x9be24d,

  // The Rush (enemies)
  rush0: 0x8a1f4a,
  rush1: 0xc0286a,
  rush2: 0xff4d7d,
  rushDark: 0x3a0f24,

  white: 0xffffff,
  black: 0x000000,
} as const;

/** Convert a 0xRRGGBB int to a CSS hex string. */
export function cssHex(n: number): string {
  return '#' + n.toString(16).padStart(6, '0');
}

/** Convert a 0xRRGGBB int + alpha to an rgba() string. */
export function rgba(n: number, a = 1): string {
  const r = (n >> 16) & 0xff;
  const g = (n >> 8) & 0xff;
  const b = n & 0xff;
  return `rgba(${r},${g},${b},${a})`;
}

/** Linear blend between two 0xRRGGBB colors. t in [0,1]. */
export function mix(a: number, b: number, t: number): number {
  const ar = (a >> 16) & 0xff;
  const ag = (a >> 8) & 0xff;
  const ab = a & 0xff;
  const br = (b >> 16) & 0xff;
  const bg = (b >> 8) & 0xff;
  const bb = b & 0xff;
  const r = Math.round(ar + (br - ar) * t);
  const g = Math.round(ag + (bg - ag) * t);
  const bl = Math.round(ab + (bb - ab) * t);
  return (r << 16) | (g << 8) | bl;
}

/** Darken a color toward black. */
export function shade(n: number, amt: number): number {
  return mix(n, 0x000000, amt);
}

/** Lighten a color toward white. */
export function tint(n: number, amt: number): number {
  return mix(n, 0xffffff, amt);
}
