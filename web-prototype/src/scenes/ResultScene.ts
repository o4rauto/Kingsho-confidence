import Phaser from 'phaser';
import { Palette, mix } from '../core/Palette';
import { Backdrop } from '../core/Backdrop';
import { getRealm, REALM_BY_ID } from '../data/realms';
import type { RunRewards } from '../core/Meta';
import { button, label, drawPanel, fadeIn, fadeTo } from '../core/UI';
import { DEPTH } from '../config';
import { Audio } from '../core/Audio';

interface ResultData {
  realmId: string;
  victory: boolean;
  wavesCleared: number;
  totalWaves: number;
  kills: number;
  rewards: RunRewards;
}

/**
 * ResultScene — the after-action report.
 *
 * Victory or defeat banner, animated reward tally, any newly-unlocked realm,
 * and the choices to retry, pick another realm, or return to the menu.
 */
export class ResultScene extends Phaser.Scene {
  constructor() {
    super('Result');
  }

  create(data: ResultData) {
    const { width, height } = this.scale;
    fadeIn(this);
    const realm = getRealm(data.realmId);
    const accent = data.victory ? Palette.ember1 : Palette.rush2;
    new Backdrop(this, { accent, hills: false });

    if (data.victory) Audio.victory();
    else Audio.defeat();

    // Banner.
    const banner = label(this, width / 2, height * 0.2, data.victory ? 'REALM CLEARED' : 'THE BASTION FELL', {
      size: 42,
      weight: '900',
      color: data.victory ? Palette.ember0 : Palette.danger,
      align: 'center',
      letter: 2,
    }).setDepth(DEPTH.hud).setOrigin(0.5);
    banner.setScale(0.6).setAlpha(0);
    this.tweens.add({ targets: banner, scale: 1, alpha: 1, duration: 500, ease: 'Back.out' });

    label(this, width / 2, height * 0.2 + 44, realm.name, {
      size: 18,
      weight: '700',
      color: Palette.textDim,
      align: 'center',
    }).setDepth(DEPTH.hud).setOrigin(0.5);

    // Reward panel.
    const pw = width - 80;
    const ph = 300;
    const px = 40;
    const py = height * 0.32;
    const g = this.add.graphics().setDepth(DEPTH.hud);
    drawPanel(g, pw, ph, { fill: Palette.panel, stroke: mix(Palette.stroke, accent, 0.4), strokeWidth: 2, radius: 22, highlight: true });
    g.x = px;
    g.y = py;

    label(this, width / 2, py + 30, data.victory ? '★ SPOILS OF WAR ★' : 'SALVAGE', {
      size: 18,
      weight: '900',
      color: accent,
      align: 'center',
    }).setDepth(DEPTH.hud).setOrigin(0.5);

    const rows: [string, string, number][] = [
      ['icon:coin', 'Gold', data.rewards.gold],
      ['icon:shard', 'Shards', data.rewards.shards],
      ['icon:core', 'Cores', data.rewards.cores],
    ];
    rows.forEach(([icon, name, val], i) => {
      const ry = py + 78 + i * 52;
      this.add.image(px + 40, ry, icon).setDisplaySize(34, 34).setDepth(DEPTH.hud);
      label(this, px + 70, ry, name, { size: 20, weight: '700', color: Palette.text }).setDepth(DEPTH.hud).setOrigin(0, 0.5);
      const valText = label(this, px + pw - 30, ry, '+0', { size: 24, weight: '900', color: Palette.warn }).setDepth(DEPTH.hud).setOrigin(1, 0.5);
      // Count-up animation.
      const obj = { v: 0 };
      this.tweens.add({
        targets: obj,
        v: val,
        duration: 700,
        delay: 300 + i * 150,
        onUpdate: () => valText.setText(`+${Math.floor(obj.v)}`),
        onComplete: () => {
          valText.setText(`+${val}`);
          if (val > 0) Audio.coin();
        },
      });
    });

    // Waves + kills line.
    label(this, width / 2, py + ph - 26, `Reached wave ${data.wavesCleared}/${data.totalWaves}   ·   ${data.kills} kills`, {
      size: 15,
      weight: '700',
      color: Palette.textDim,
      align: 'center',
    }).setDepth(DEPTH.hud).setOrigin(0.5);

    // Unlock banner.
    let yBtn = height * 0.72;
    if (data.rewards.unlockedRealm && REALM_BY_ID[data.rewards.unlockedRealm]) {
      const nr = REALM_BY_ID[data.rewards.unlockedRealm];
      const ub = this.add.container(width / 2, yBtn - 6).setDepth(DEPTH.hud);
      const ug = this.add.graphics();
      drawPanel(ug, pw, 56, { fill: mix(Palette.panel, Palette.aether1, 0.2), stroke: Palette.aether1, strokeWidth: 2, radius: 16 });
      ug.x = -pw / 2;
      ub.add(ug);
      ub.add(label(this, 0, 28, `🗝  New realm unlocked: ${nr.name}`, { size: 17, weight: '800', color: Palette.aether0, align: 'center' }).setOrigin(0.5));
      this.tweens.add({ targets: ub, scale: 1.03, duration: 800, yoyo: true, repeat: -1 });
      yBtn += 78;
    }

    // Buttons.
    button(this, width / 2, yBtn + 30, data.victory ? 'PLAY AGAIN' : 'RETRY', () => this.retry(data.realmId), {
      width: pw,
      height: 64,
      variant: 'ember',
      size: 24,
    }).setDepth(DEPTH.hud);
    button(this, width / 2 - pw / 4 - 6, yBtn + 106, 'REALMS', () => this.go('RealmSelect'), {
      width: pw / 2 - 12,
      height: 56,
      variant: 'ghost',
      size: 20,
    }).setDepth(DEPTH.hud);
    button(this, width / 2 + pw / 4 + 6, yBtn + 106, 'MENU', () => this.go('Menu'), {
      width: pw / 2 - 12,
      height: 56,
      variant: 'ghost',
      size: 20,
    }).setDepth(DEPTH.hud);
  }

  private retry(realmId: string) {
    Audio.uiClick();
    fadeTo(this, 260, () => this.scene.start('Loadout', { realmId }));
  }

  private go(scene: string) {
    Audio.uiClick();
    fadeTo(this, 260, () => this.scene.start(scene));
  }
}
