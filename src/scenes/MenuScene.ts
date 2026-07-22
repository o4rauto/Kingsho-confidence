import Phaser from 'phaser';
import { Palette } from '../core/Palette';
import { Backdrop } from '../core/Backdrop';
import { Save } from '../core/Save';
import { button, label, currencyChip, fadeIn, fadeTo } from '../core/UI';
import { DEPTH, SAFE } from '../config';
import { Audio } from '../core/Audio';

/**
 * MenuScene — the front door.
 *
 * Title, currencies, and the primary navigation: Play (choose a realm),
 * Champions (collection), and Settings. Built on the shared living Backdrop.
 */
export class MenuScene extends Phaser.Scene {
  constructor() {
    super('Menu');
  }

  create() {
    const { width, height } = this.scale;
    fadeIn(this);
    new Backdrop(this, { accent: Palette.ember2 });

    // Currency bar.
    const bar = this.add.container(0, SAFE.top).setDepth(DEPTH.hud);
    bar.add(currencyChip(this, width / 2 - 122, 0, 'icon:coin', Save.data.gold, 116));
    bar.add(currencyChip(this, width / 2, 0, 'icon:shard', Save.data.shards, 108));
    bar.add(currencyChip(this, width / 2 + 120, 0, 'icon:core', Save.data.cores, 96));

    // Title lockup.
    const titleY = height * 0.26;
    label(this, width / 2, titleY - 40, 'AETHELGARD', {
      size: 18,
      weight: '700',
      color: Palette.textFaint,
      align: 'center',
      letter: 8,
    }).setDepth(DEPTH.hud);

    const title = label(this, width / 2, titleY, 'BASTION', {
      size: 74,
      weight: '900',
      color: Palette.ember0,
      align: 'center',
      letter: 2,
    }).setDepth(DEPTH.hud);
    const title2 = label(this, width / 2, titleY + 66, 'RUSH', {
      size: 74,
      weight: '900',
      color: Palette.ember2,
      align: 'center',
      letter: 10,
    }).setDepth(DEPTH.hud);
    title.setShadow(0, 4, 'rgba(0,0,0,0.5)', 8);
    title2.setShadow(0, 4, 'rgba(0,0,0,0.5)', 8);
    this.tweens.add({ targets: [title, title2], y: '+=6', duration: 2600, yoyo: true, repeat: -1, ease: 'Sine.inOut' });

    label(this, width / 2, titleY + 156, 'Hold the last light against the Rush', {
      size: 17,
      weight: '600',
      color: Palette.textDim,
      align: 'center',
    }).setDepth(DEPTH.hud);

    // Primary buttons.
    const cx = width / 2;
    let by = height * 0.62;
    const gap = 78;

    button(this, cx, by, 'PLAY', () => this.go('RealmSelect'), {
      width: 300,
      height: 70,
      variant: 'ember',
      size: 30,
    }).setDepth(DEPTH.hud);

    by += gap;
    button(this, cx, by, 'CHAMPIONS', () => this.go('Collection'), {
      width: 300,
      height: 64,
      variant: 'solid',
      color: Palette.panelHi,
      textColor: Palette.text,
      size: 24,
      icon: 'icon:shield',
    }).setDepth(DEPTH.hud);

    by += gap;
    button(this, cx, by, 'SETTINGS', () => this.go('Settings'), {
      width: 300,
      height: 64,
      variant: 'ghost',
      size: 24,
      icon: 'icon:gem',
    }).setDepth(DEPTH.hud);

    // Version + progress footer.
    const cleared = Save.data.clearedRealms.length;
    label(this, width / 2, height - SAFE.bottom - 8, `Realms cleared: ${cleared}/5   ·   v0.1`, {
      size: 15,
      weight: '600',
      color: Palette.textFaint,
      align: 'center',
    }).setDepth(DEPTH.hud);

    // Continue hint if there is progress.
    if (Save.data.stats.runs === 0) {
      const hint = label(this, width / 2, by + 74, '▲  Tap PLAY to begin the last stand', {
        size: 16,
        weight: '700',
        color: Palette.ember1,
        align: 'center',
      }).setDepth(DEPTH.hud);
      this.tweens.add({ targets: hint, alpha: 0.3, duration: 900, yoyo: true, repeat: -1 });
    }
  }

  private go(scene: string) {
    Audio.uiClick();
    fadeTo(this, 260, () => this.scene.start(scene));
  }
}
