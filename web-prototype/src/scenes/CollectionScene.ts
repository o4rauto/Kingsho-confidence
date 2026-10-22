import Phaser from 'phaser';
import { Palette, mix } from '../core/Palette';
import { Backdrop } from '../core/Backdrop';
import { CHAMPIONS, getChampion } from '../data/champions';
import {
  effectiveStats,
  canLevelUp,
  levelUp,
  levelUpShardCost,
  levelUpGoldCost,
  canEvolve,
  evolve,
  EVOLVE_CORE_COST,
  EVOLVE_GOLD_COST,
  canUnlock,
  unlockChampion,
  unlockShardCost,
} from '../core/Meta';
import { Save } from '../core/Save';
import { button, label, drawPanel, currencyChip, fadeIn, fadeTo, toast } from '../core/UI';
import { DEPTH, SAFE, RARITY_COLOR, RARITY_LABEL, CHAMPION } from '../config';
import { Audio } from '../core/Audio';

/**
 * CollectionScene — the champion armory.
 *
 * Grid of every champion with lock/level state. Tap one to open a detail modal
 * where you spend shards + gold to level up, and cores to evolve at max tier.
 */
export class CollectionScene extends Phaser.Scene {
  private modal?: Phaser.GameObjects.Container;
  private currencyBar?: Phaser.GameObjects.Container;

  constructor() {
    super('Collection');
  }

  create() {
    const { width } = this.scale;
    fadeIn(this);
    new Backdrop(this, { accent: Palette.aether1, hills: false });

    label(this, width / 2, SAFE.top + 24, 'CHAMPIONS', {
      size: 26,
      weight: '900',
      align: 'center',
      letter: 3,
    }).setDepth(DEPTH.hud);

    this.buildCurrencyBar();

    button(this, 64, SAFE.top + 20, '‹', () => this.back(), {
      width: 56,
      height: 48,
      variant: 'ghost',
      size: 30,
    }).setDepth(DEPTH.hud);

    this.buildGrid();
  }

  private buildCurrencyBar() {
    const { width } = this.scale;
    this.currencyBar?.destroy();
    const bar = this.add.container(0, SAFE.top + 62).setDepth(DEPTH.hud);
    bar.add(currencyChip(this, width / 2 - 122, 0, 'icon:coin', Save.data.gold, 116));
    bar.add(currencyChip(this, width / 2, 0, 'icon:shard', Save.data.shards, 108));
    bar.add(currencyChip(this, width / 2 + 120, 0, 'icon:core', Save.data.cores, 96));
    this.currencyBar = bar;
  }

  private buildGrid() {
    const { width, height } = this.scale;
    const cols = 3;
    const cw = 210;
    const chh = 232;
    const gapX = 12;
    const gapY = 14;
    const totalW = cols * cw + (cols - 1) * gapX;
    const startX = width / 2 - totalW / 2 + cw / 2;
    const startY = SAFE.top + 128;

    const content = this.add.container(0, 0).setDepth(DEPTH.hud);

    CHAMPIONS.forEach((def, i) => {
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x = startX + col * (cw + gapX);
      const y = startY + row * (chh + gapY);
      content.add(this.buildCell(def.id, x, y, cw, chh));
    });

    const rows = Math.ceil(CHAMPIONS.length / cols);
    const totalH = startY + rows * (chh + gapY);
    this.enableScroll(content, totalH, height);
  }

  private buildCell(id: string, cx: number, cy: number, w: number, h: number): Phaser.GameObjects.Container {
    const def = getChampion(id);
    const st = Save.champion(id);
    const c = this.add.container(cx, cy);
    const rc = RARITY_COLOR[def.rarity];
    const locked = !st.unlocked;
    const g = this.add.graphics();
    drawPanel(g, w, h, {
      fill: locked ? Palette.night1 : mix(Palette.panel, rc, 0.12),
      stroke: rc,
      strokeWidth: 2,
      radius: 16,
      highlight: !locked,
    });
    g.x = -w / 2;
    c.add(g);

    // Portrait.
    const key = st.evolved ? `champ:${id}:evo` : `champ:${id}`;
    const img = this.add.image(0, -14, key).setDisplaySize(112, 128);
    if (locked) img.setTint(Palette.night0).setAlpha(0.6);
    c.add(img);

    // Rarity ribbon.
    const rib = this.add.graphics();
    rib.fillStyle(rc, 1);
    rib.fillRoundedRect(-w / 2 + 10, -h / 2 + 10, 76, 20, 6);
    c.add(rib);
    c.add(label(this, -w / 2 + 48, -h / 2 + 20, RARITY_LABEL[def.rarity].toUpperCase(), { size: 10, weight: '900', color: Palette.night0, align: 'center' }).setOrigin(0.5));

    // Name.
    c.add(label(this, 0, h / 2 - 62, def.name, { size: 17, weight: '800', color: locked ? Palette.textDim : Palette.text, align: 'center' }).setOrigin(0.5));

    if (locked) {
      const affordable = canUnlock(def);
      c.add(label(this, 0, h / 2 - 34, `🔒 ${st.shards}/${unlockShardCost(def.rarity)} shards`, {
        size: 13,
        weight: '800',
        color: affordable ? Palette.good : Palette.textDim,
        align: 'center',
      }).setOrigin(0.5));
    } else {
      const stats = effectiveStats(def);
      c.add(label(this, 0, h / 2 - 36, `Lv.${st.level}${st.evolved ? '  ★' : ''}`, {
        size: 14,
        weight: '800',
        color: st.evolved ? Palette.ember1 : Palette.text,
        align: 'center',
      }).setOrigin(0.5));
      // Shard progress bar.
      const need = levelUpShardCost(st.level);
      const frac = st.level >= CHAMPION.maxLevel ? 1 : Phaser.Math.Clamp(st.shards / need, 0, 1);
      const bar = this.add.graphics();
      bar.fillStyle(Palette.night0, 1);
      bar.fillRoundedRect(-w / 2 + 20, h / 2 - 20, w - 40, 8, 4);
      bar.fillStyle(canLevelUp(id) ? Palette.good : rc, 1);
      bar.fillRoundedRect(-w / 2 + 20, h / 2 - 20, (w - 40) * frac, 8, 4);
      c.add(bar);
      c.add(label(this, 0, h / 2 - 4, `PWR ${stats.power}`, { size: 11, weight: '700', color: Palette.textFaint, align: 'center' }).setOrigin(0.5));
      // Upgrade-ready pip.
      if (canLevelUp(id) || canEvolve(id)) {
        const pip = this.add.graphics();
        pip.fillStyle(Palette.good, 1);
        pip.fillCircle(w / 2 - 16, -h / 2 + 16, 9);
        c.add(pip);
        c.add(label(this, w / 2 - 16, -h / 2 + 16, '!', { size: 14, weight: '900', color: Palette.night0, align: 'center' }).setOrigin(0.5));
      }
    }

    g.setInteractive(new Phaser.Geom.Rectangle(0, 0, w, h), Phaser.Geom.Rectangle.Contains);
    g.on('pointerup', () => this.openDetail(id));
    g.on('pointerdown', () => c.setScale(0.97));
    g.on('pointerout', () => c.setScale(1));
    return c;
  }

  private openDetail(id: string) {
    Audio.uiClick();
    this.modal?.destroy();
    const def = getChampion(id);
    const st = Save.champion(id);
    const { width, height } = this.scale;

    const modal = this.add.container(0, 0).setDepth(DEPTH.overlay);
    this.modal = modal;
    const dim = this.add.graphics();
    dim.fillStyle(Palette.night0, 0.78);
    dim.fillRect(0, 0, width, height);
    dim.setInteractive(new Phaser.Geom.Rectangle(0, 0, width, height), Phaser.Geom.Rectangle.Contains);
    dim.on('pointerup', () => this.closeDetail());
    modal.add(dim);

    const pw = width - 60;
    const ph = 620;
    const px = 30;
    const py = (height - ph) / 2;
    const card = this.add.container(px, py);
    modal.add(card);
    const rc = RARITY_COLOR[def.rarity];
    const g = this.add.graphics();
    drawPanel(g, pw, ph, { fill: mix(Palette.panel, rc, 0.1), stroke: rc, strokeWidth: 3, radius: 24, highlight: true });
    card.add(g);
    // Swallow taps on the card so they don't close the modal.
    g.setInteractive(new Phaser.Geom.Rectangle(0, 0, pw, ph), Phaser.Geom.Rectangle.Contains);

    // Portrait + glow.
    const glow = this.add.image(pw / 2, 150, st.evolved ? 'fx:glow-ember' : 'fx:glow-aether').setDisplaySize(260, 260).setAlpha(0.4).setBlendMode(Phaser.BlendModes.ADD);
    card.add(glow);
    this.tweens.add({ targets: glow, scale: 1.1, alpha: 0.55, duration: 1600, yoyo: true, repeat: -1 });
    const key = st.evolved ? `champ:${id}:evo` : `champ:${id}`;
    const portrait = this.add.image(pw / 2, 154, key).setDisplaySize(150, 172);
    card.add(portrait);
    this.tweens.add({ targets: portrait, y: 148, duration: 1800, yoyo: true, repeat: -1, ease: 'Sine.inOut' });

    card.add(label(this, pw / 2, 250, def.name, { size: 30, weight: '900', align: 'center' }).setOrigin(0.5));
    card.add(label(this, pw / 2, 282, `${def.title} · ${RARITY_LABEL[def.rarity]}`, { size: 15, weight: '700', color: rc, align: 'center' }).setOrigin(0.5));
    card.add(label(this, pw / 2, 316, `"${def.lore}"`, { size: 14, weight: '600', color: Palette.textDim, align: 'center' }).setOrigin(0.5));
    const abilityText = label(this, pw / 2, 344, def.ability, { size: 14, weight: '700', color: Palette.text, align: 'center' }).setOrigin(0.5);
    abilityText.setWordWrapWidth(pw - 60);
    card.add(abilityText);

    // Stats row.
    const stats = effectiveStats(def);
    this.statChips(card, pw, 392, [
      ['HP', `${stats.hp}`],
      ['DMG', `${stats.damage}`],
      ['SPD', `${def.attackSpeed.toFixed(1)}/s`],
      ['COST', `${def.cost}⬡`],
    ], rc);

    // Level line.
    if (st.unlocked) {
      card.add(label(this, pw / 2, 452, `Level ${st.level} / ${CHAMPION.maxLevel}${st.evolved ? '   ★ Evolved' : ''}`, {
        size: 18,
        weight: '800',
        color: st.evolved ? Palette.ember1 : Palette.text,
        align: 'center',
      }).setOrigin(0.5));
    }

    // Action buttons.
    this.buildActions(card, id, pw, ph);

    // Close X.
    const x = button(this, pw - 26, 26, '✕', () => this.closeDetail(), { width: 44, height: 44, variant: 'ghost', size: 22 });
    card.add(x);

    modal.setAlpha(0).setScale(0.96);
    this.tweens.add({ targets: modal, alpha: 1, scale: 1, duration: 180, ease: 'Back.out' });
  }

  private statChips(parent: Phaser.GameObjects.Container, pw: number, y: number, chips: [string, string][], rc: number) {
    const cw = 118;
    const total = chips.length * cw + (chips.length - 1) * 8;
    const startX = pw / 2 - total / 2 + cw / 2;
    chips.forEach(([k, v], i) => {
      const x = startX + i * (cw + 8);
      const g = this.add.graphics();
      drawPanel(g, cw, 46, { fill: Palette.night1, stroke: mix(Palette.stroke, rc, 0.3), radius: 12 });
      g.x = x - cw / 2;
      g.y = y - 23;
      parent.add(g);
      parent.add(label(this, x, y - 12, k, { size: 11, weight: '700', color: Palette.textFaint, align: 'center' }).setOrigin(0.5));
      parent.add(label(this, x, y + 8, v, { size: 17, weight: '900', align: 'center' }).setOrigin(0.5));
    });
  }

  private buildActions(card: Phaser.GameObjects.Container, id: string, pw: number, ph: number) {
    const def = getChampion(id);
    const st = Save.champion(id);
    const y1 = ph - 130;

    if (!st.unlocked) {
      const cost = unlockShardCost(def.rarity);
      const b = button(this, pw / 2, y1 + 20, `UNLOCK · ${cost} shards`, () => {
        if (unlockChampion(def)) {
          Audio.boon();
          toast(this, `${def.name} unlocked!`, Palette.good);
          this.refresh(id);
        } else {
          Audio.uiBack();
          toast(this, 'Not enough shards', Palette.danger);
        }
      }, { width: pw - 80, height: 64, variant: 'ember', size: 22 });
      b.setEnabled(canUnlock(def));
      card.add(b);
      return;
    }

    // Level up button.
    if (st.level < CHAMPION.maxLevel) {
      const sc = levelUpShardCost(st.level);
      const gc = levelUpGoldCost(st.level);
      const lb = button(this, pw / 2, y1, `LEVEL UP · ${sc}◆  ${gc}◉`, () => {
        if (levelUp(id)) {
          Audio.boon();
          this.buildCurrencyBar();
          this.refresh(id);
        } else {
          Audio.uiBack();
          toast(this, 'Need more shards or gold', Palette.danger);
        }
      }, { width: pw - 80, height: 60, variant: 'solid', color: Palette.good, size: 20 });
      lb.setEnabled(canLevelUp(id));
      card.add(lb);
    } else {
      card.add(label(this, pw / 2, y1, 'MAX LEVEL', { size: 20, weight: '900', color: Palette.ember1, align: 'center' }).setOrigin(0.5));
    }

    // Evolve button.
    if (!st.evolved) {
      const evb = button(this, pw / 2, y1 + 66, st.level >= CHAMPION.evolveLevel ? `EVOLVE · ${EVOLVE_CORE_COST}✦  ${EVOLVE_GOLD_COST}◉` : `Evolve at Lv.${CHAMPION.evolveLevel}`, () => {
        if (evolve(id)) {
          Audio.victory();
          toast(this, `${def.name} evolved! ★`, Palette.ember1);
          this.buildCurrencyBar();
          this.refresh(id);
        } else {
          Audio.uiBack();
          toast(this, st.level < CHAMPION.evolveLevel ? `Reach level ${CHAMPION.evolveLevel} first` : 'Need cores & gold', Palette.danger);
        }
      }, { width: pw - 80, height: 58, variant: 'ember', size: 20 });
      evb.setEnabled(canEvolve(id));
      card.add(evb);
    }
  }

  private refresh(id: string) {
    // Rebuild the modal in place and the underlying grid.
    this.closeDetail();
    this.scene.restart();
    // Re-open detail after restart on next tick.
    this.time.delayedCall(60, () => this.openDetail(id));
  }

  private closeDetail() {
    if (this.modal) {
      const m = this.modal;
      this.modal = undefined;
      this.tweens.add({ targets: m, alpha: 0, duration: 140, onComplete: () => m.destroy() });
    }
  }

  private enableScroll(content: Phaser.GameObjects.Container, totalH: number, viewH: number) {
    const maxScroll = Math.max(0, totalH - viewH + SAFE.bottom + 20);
    if (maxScroll <= 0) return;
    let scroll = 0;
    let startY = 0;
    let base = 0;
    let dragging = false;
    this.input.on('pointerdown', (p: Phaser.Input.Pointer) => {
      if (this.modal) return;
      dragging = true;
      startY = p.y;
      base = scroll;
    });
    this.input.on('pointermove', (p: Phaser.Input.Pointer) => {
      if (!dragging || !p.isDown || this.modal) return;
      scroll = Phaser.Math.Clamp(base - (p.y - startY), 0, maxScroll);
      content.y = -scroll;
    });
    this.input.on('pointerup', () => (dragging = false));
    this.input.on('wheel', (_p: unknown, _o: unknown, _dx: number, dy: number) => {
      if (this.modal) return;
      scroll = Phaser.Math.Clamp(scroll + dy * 0.5, 0, maxScroll);
      content.y = -scroll;
    });
  }

  private back() {
    Audio.uiBack();
    fadeTo(this, 240, () => this.scene.start('Menu'));
  }
}
