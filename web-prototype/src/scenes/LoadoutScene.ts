import Phaser from 'phaser';
import { Palette, mix } from '../core/Palette';
import { Backdrop } from '../core/Backdrop';
import { CHAMPIONS, getChampion } from '../data/champions';
import { getRealm } from '../data/realms';
import { effectiveStats } from '../core/Meta';
import { Save } from '../core/Save';
import { button, label, drawPanel, fadeIn, fadeTo } from '../core/UI';
import { DEPTH, SAFE, DECK_SIZE, RARITY_COLOR } from '../config';
import { Audio } from '../core/Audio';

/**
 * LoadoutScene — assemble your deck of four champions, then descend.
 *
 * Tap a deck slot to open the roster tray and swap in any unlocked champion.
 * The Warden (your piloted hero) is always present. START launches the run.
 */
export class LoadoutScene extends Phaser.Scene {
  private realmId = 'broken-gate';
  private slots: Phaser.GameObjects.Container[] = [];
  private trayOpen = false;
  private selectedSlot = -1;
  private tray?: Phaser.GameObjects.Container;

  constructor() {
    super('Loadout');
  }

  create(data: { realmId?: string }) {
    this.realmId = data?.realmId ?? 'broken-gate';
    this.slots = [];
    this.trayOpen = false;
    const { width, height } = this.scale;
    fadeIn(this);
    new Backdrop(this, { accent: Palette.ember2, hills: false });

    const realm = getRealm(this.realmId);
    label(this, width / 2, SAFE.top + 20, 'YOUR WARBAND', {
      size: 26,
      weight: '900',
      align: 'center',
      letter: 2,
    }).setDepth(DEPTH.hud);
    label(this, width / 2, SAFE.top + 50, `Deploying to ${realm.name}`, {
      size: 16,
      weight: '700',
      color: mix(Palette.textDim, realm.accent, 0.4),
      align: 'center',
    }).setDepth(DEPTH.hud);

    // Warden card.
    this.buildWardenCard(width / 2, SAFE.top + 150);

    // Deck slots (2x2).
    const gridY = SAFE.top + 300;
    const slotW = 156;
    const slotH = 190;
    const gx = width / 2 - slotW / 2 - 12;
    const gy = gridY;
    for (let i = 0; i < DECK_SIZE; i++) {
      const col = i % 2;
      const row = Math.floor(i / 2);
      const x = gx + col * (slotW + 24);
      const y = gy + row * (slotH + 20);
      this.buildSlot(i, x, y, slotW, slotH);
    }

    label(this, width / 2, gridY + 2 * (slotH + 20) - 6, 'Tap a slot to swap champion', {
      size: 14,
      weight: '600',
      color: Palette.textFaint,
      align: 'center',
    }).setDepth(DEPTH.hud);

    // Start / back.
    button(this, width / 2, height - SAFE.bottom - 44, 'START THE STAND', () => this.start(), {
      width: 320,
      height: 68,
      variant: 'ember',
      size: 26,
    }).setDepth(DEPTH.hud);
    button(this, 64, SAFE.top + 16, '‹', () => this.back(), {
      width: 56,
      height: 48,
      variant: 'ghost',
      size: 30,
    }).setDepth(DEPTH.hud);
  }

  private buildWardenCard(cx: number, cy: number) {
    const c = this.add.container(cx, cy).setDepth(DEPTH.hud);
    const w = 340;
    const h = 96;
    const g = this.add.graphics();
    drawPanel(g, w, h, {
      fill: mix(Palette.panel, Palette.ember2, 0.16),
      stroke: Palette.ember2,
      strokeWidth: 2,
      radius: 18,
      highlight: true,
    });
    g.x = -w / 2;
    c.add(g);
    const portrait = this.add.image(-w / 2 + 52, 4, 'warden').setDisplaySize(76, 86);
    c.add(portrait);
    c.add(label(this, -w / 2 + 100, -26, 'THE WARDEN', { size: 22, weight: '900', color: Palette.ember0 }));
    c.add(
      label(this, -w / 2 + 100, 2, `You — move, aim, and unleash the ultimate`, {
        size: 14,
        weight: '600',
        color: Palette.textDim,
      }),
    );
    c.add(
      label(this, -w / 2 + 100, 26, `Level ${Save.data.wardenLevel}`, {
        size: 15,
        weight: '800',
        color: Palette.ember1,
      }),
    );
  }

  private buildSlot(index: number, x: number, y: number, w: number, h: number) {
    const c = this.add.container(x, y).setDepth(DEPTH.hud);
    this.slots[index] = c;
    this.renderSlot(index, w, h);
    // Interactivity is attached inside renderSlot via a hit rect.
    c.setSize(w, h);
    c.setInteractive(new Phaser.Geom.Rectangle(0, 0, w, h), Phaser.Geom.Rectangle.Contains);
    c.on('pointerup', () => this.openTray(index));
    c.on('pointerdown', () => c.setScale(0.97));
    c.on('pointerout', () => c.setScale(1));
  }

  private renderSlot(index: number, w: number, h: number) {
    const c = this.slots[index];
    c.removeAll(true);
    const id = Save.data.deck[index];
    const def = id ? getChampion(id) : null;
    const g = this.add.graphics();
    const rc = def ? RARITY_COLOR[def.rarity] : Palette.stroke;
    drawPanel(g, w, h, {
      fill: def ? mix(Palette.panel, rc, 0.1) : Palette.night1,
      stroke: rc,
      strokeWidth: 2,
      radius: 16,
      highlight: !!def,
    });
    c.add(g);

    if (!def) {
      c.add(label(this, w / 2, h / 2, '+', { size: 44, weight: '900', color: Palette.textFaint, align: 'center' }).setOrigin(0.5));
      return;
    }

    const st = Save.champion(id);
    const key = st.evolved ? `champ:${id}:evo` : `champ:${id}`;
    const img = this.add.image(w / 2, 70, key).setDisplaySize(96, 110);
    c.add(img);
    // Rarity tab.
    const tab = this.add.graphics();
    tab.fillStyle(rc, 1);
    tab.fillRoundedRect(w / 2 - 40, 8, 80, 22, 8);
    c.add(tab);
    c.add(label(this, w / 2, 19, def.name.toUpperCase(), { size: 11, weight: '900', color: Palette.night0, align: 'center' }).setOrigin(0.5));
    // Name + level + cost.
    c.add(label(this, w / 2, h - 44, def.name, { size: 15, weight: '800', align: 'center' }).setOrigin(0.5));
    const stats = effectiveStats(def);
    c.add(
      label(this, w / 2, h - 24, `Lv.${st.level}${st.evolved ? ' ★' : ''} · PWR ${stats.power}`, {
        size: 12,
        weight: '700',
        color: Palette.textDim,
        align: 'center',
      }).setOrigin(0.5),
    );
    // Cost pip.
    const cost = this.add.graphics();
    cost.fillStyle(Palette.aether1, 1);
    cost.fillCircle(w - 20, 20, 15);
    c.add(cost);
    c.add(label(this, w - 20, 20, `${def.cost}`, { size: 16, weight: '900', color: Palette.night0, align: 'center' }).setOrigin(0.5));
  }

  private openTray(slot: number) {
    if (this.trayOpen) this.closeTray();
    this.trayOpen = true;
    this.selectedSlot = slot;
    Audio.uiClick();

    const { width, height } = this.scale;
    const tray = this.add.container(0, 0).setDepth(DEPTH.overlay);
    this.tray = tray;
    const dim = this.add.graphics();
    dim.fillStyle(Palette.night0, 0.72);
    dim.fillRect(0, 0, width, height);
    dim.setInteractive(new Phaser.Geom.Rectangle(0, 0, width, height), Phaser.Geom.Rectangle.Contains);
    dim.on('pointerup', () => this.closeTray());
    tray.add(dim);

    const panelH = height * 0.5;
    const py = height - panelH;
    const pg = this.add.graphics();
    drawPanel(pg, width, panelH + 30, { fill: Palette.panel, stroke: Palette.strokeHi, radius: 26 });
    pg.y = py;
    tray.add(pg);
    tray.add(label(this, width / 2, py + 28, 'CHOOSE A CHAMPION', { size: 20, weight: '900', align: 'center' }).setOrigin(0.5));

    // Grid of unlocked champions.
    const owned = CHAMPIONS.filter((d) => Save.champion(d.id).unlocked);
    const cols = 3;
    const cw = 150;
    const ch = 150;
    const startX = width / 2 - ((cols - 1) * (cw + 12)) / 2;
    const startY = py + 78;
    const grid = this.add.container(0, 0);
    tray.add(grid);

    owned.forEach((def, i) => {
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x = startX + col * (cw + 12);
      const y = startY + row * (ch + 12);
      const cell = this.buildTrayCell(def.id, x, y, cw, ch);
      grid.add(cell);
    });

    // Scroll the grid if it overflows.
    const rows = Math.ceil(owned.length / cols);
    const gridBottom = startY + rows * (ch + 12);
    const overflow = Math.max(0, gridBottom - (height - 20));
    if (overflow > 0) {
      let scroll = 0;
      let dragStart = 0;
      let base = 0;
      let dragging = false;
      dim.on('pointerdown', () => (dragging = false));
      grid.setInteractive(new Phaser.Geom.Rectangle(0, startY, width, gridBottom - startY), Phaser.Geom.Rectangle.Contains);
      grid.on('pointerdown', (p: Phaser.Input.Pointer) => {
        dragging = true;
        dragStart = p.y;
        base = scroll;
      });
      this.input.on('pointermove', (p: Phaser.Input.Pointer) => {
        if (!dragging || !p.isDown || !this.trayOpen) return;
        scroll = Phaser.Math.Clamp(base - (p.y - dragStart), 0, overflow);
        grid.y = -scroll;
      });
    }

    tray.setAlpha(0);
    this.tweens.add({ targets: tray, alpha: 1, duration: 180 });
  }

  private buildTrayCell(id: string, x: number, y: number, w: number, h: number): Phaser.GameObjects.Container {
    const def = getChampion(id);
    const st = Save.champion(id);
    const c = this.add.container(x, y);
    const rc = RARITY_COLOR[def.rarity];
    const inDeck = Save.data.deck.includes(id);
    const g = this.add.graphics();
    drawPanel(g, w, h, {
      fill: mix(Palette.panelHi, rc, 0.12),
      stroke: rc,
      strokeWidth: inDeck ? 3 : 2,
      radius: 14,
    });
    c.add(g);
    const key = st.evolved ? `champ:${id}:evo` : `champ:${id}`;
    c.add(this.add.image(w / 2, 62, key).setDisplaySize(84, 96));
    c.add(label(this, w / 2, h - 40, def.name, { size: 13, weight: '800', align: 'center' }).setOrigin(0.5));
    c.add(label(this, w / 2, h - 20, `Lv.${st.level} · ${def.cost}⬡`, { size: 12, weight: '700', color: Palette.textDim, align: 'center' }).setOrigin(0.5));
    if (inDeck) {
      c.add(label(this, w - 16, 14, '✓', { size: 18, weight: '900', color: rc, align: 'center' }).setOrigin(0.5));
    }
    g.setInteractive(new Phaser.Geom.Rectangle(0, 0, w, h), Phaser.Geom.Rectangle.Contains);
    g.on('pointerup', () => this.assign(id));
    g.on('pointerdown', () => c.setScale(0.95));
    g.on('pointerout', () => c.setScale(1));
    return c;
  }

  private assign(id: string) {
    // If already elsewhere in the deck, swap positions.
    const existing = Save.data.deck.indexOf(id);
    const target = this.selectedSlot;
    if (existing >= 0) {
      const tmp = Save.data.deck[target];
      Save.data.deck[target] = id;
      Save.data.deck[existing] = tmp;
    } else {
      Save.data.deck[target] = id;
    }
    Save.flush();
    Audio.deploy();
    // Re-render all slots (positions may have swapped).
    this.slots.forEach((_, i) => this.renderSlot(i, 156, 190));
    this.closeTray();
  }

  private closeTray() {
    this.trayOpen = false;
    if (this.tray) {
      const t = this.tray;
      this.tween(t);
      this.tray = undefined;
    }
  }

  private tween(t: Phaser.GameObjects.Container) {
    this.tweens.add({ targets: t, alpha: 0, duration: 140, onComplete: () => t.destroy() });
  }

  private start() {
    Audio.deploy();
    fadeTo(this, 320, () => this.scene.start('Game', { realmId: this.realmId, deck: Save.data.deck.slice() }));
  }

  private back() {
    Audio.uiBack();
    fadeTo(this, 240, () => this.scene.start('RealmSelect'));
  }
}
