import Phaser from 'phaser';
import { Palette, mix, cssHex } from '../core/Palette';
import { Backdrop } from '../core/Backdrop';
import { REALMS } from '../data/realms';
import { realmUnlocked, realmCleared } from '../core/Meta';
import { Save } from '../core/Save';
import { button, label, drawPanel, fadeIn, fadeTo, FONT } from '../core/UI';
import { DEPTH, SAFE } from '../config';
import { Audio } from '../core/Audio';

/**
 * RealmSelectScene — pick where to make your stand.
 *
 * A scrollable column of realm cards. Locked realms show their unlock
 * requirement; cleared realms show a star and your best wave.
 */
export class RealmSelectScene extends Phaser.Scene {
  constructor() {
    super('RealmSelect');
  }

  create() {
    const { width, height } = this.scale;
    fadeIn(this);
    new Backdrop(this, { accent: Palette.aether1, hills: false });

    // Header.
    this.header('CHOOSE A REALM');

    // Scrollable list.
    const cardH = 148;
    const cardGap = 18;
    const startY = SAFE.top + 78;
    const listW = width - SAFE.left - SAFE.right;
    const content = this.add.container(0, 0);

    REALMS.forEach((realm, i) => {
      const y = startY + i * (cardH + cardGap);
      const unlocked = realmUnlocked(realm.id);
      const cleared = realmCleared(realm.id);
      const card = this.buildCard(realm.id, SAFE.left, y, listW, cardH, unlocked, cleared);
      content.add(card);
    });

    const totalH = startY + REALMS.length * (cardH + cardGap);
    this.enableScroll(content, totalH, height);

    // Back.
    button(this, 64, SAFE.top + 20, '‹', () => this.back(), {
      width: 56,
      height: 48,
      variant: 'ghost',
      size: 30,
    }).setDepth(DEPTH.hud);
  }

  private header(text: string) {
    const { width } = this.scale;
    label(this, width / 2, SAFE.top + 24, text, {
      size: 26,
      weight: '900',
      color: Palette.text,
      align: 'center',
      letter: 2,
    }).setDepth(DEPTH.hud);
  }

  private buildCard(
    realmId: string,
    x: number,
    y: number,
    w: number,
    h: number,
    unlocked: boolean,
    cleared: boolean,
  ): Phaser.GameObjects.Container {
    const realm = REALMS.find((r) => r.id === realmId)!;
    const c = this.add.container(x, y);
    const g = this.add.graphics();
    const baseFill = unlocked ? mix(Palette.panel, realm.accent, 0.14) : Palette.night1;
    drawPanel(g, w, h, {
      fill: baseFill,
      stroke: unlocked ? mix(Palette.stroke, realm.accent, 0.4) : Palette.stroke,
      strokeWidth: 2,
      radius: 20,
      highlight: unlocked,
    });
    c.add(g);

    // Left "biome" swatch.
    const swatch = this.add.graphics();
    swatch.fillStyle(realm.ground, 1);
    swatch.fillRoundedRect(14, 14, 108, h - 28, 14);
    swatch.fillStyle(realm.ground2, 1);
    swatch.fillRoundedRect(14, 14 + (h - 28) * 0.5, 108, (h - 28) * 0.5, 14);
    swatch.lineStyle(2, mix(realm.accent, Palette.night0, 0.3), 1);
    swatch.strokeRoundedRect(14, 14, 108, h - 28, 14);
    // A little path motif on the swatch.
    swatch.lineStyle(6, mix(realm.accent, Palette.white, 0.1), 0.5);
    swatch.beginPath();
    swatch.moveTo(30, h - 24);
    swatch.lineTo(60, h * 0.5);
    swatch.lineTo(100, 30);
    swatch.strokePath();
    c.add(swatch);

    // Realm number badge.
    const idx = REALMS.indexOf(realm) + 1;
    const badge = label(this, 68, h / 2 - 8, `${idx}`, {
      size: 40,
      weight: '900',
      color: unlocked ? Palette.white : Palette.textFaint,
      align: 'center',
    });
    badge.setOrigin(0.5).setAlpha(0.9);
    c.add(badge);

    // Texts.
    const tx = 140;
    c.add(
      label(this, tx, 26, realm.name, {
        size: 24,
        weight: '800',
        color: unlocked ? Palette.text : Palette.textDim,
      }),
    );
    c.add(
      label(this, tx, 58, realm.subtitle, {
        size: 15,
        weight: '600',
        color: Palette.textDim,
      }),
    );

    if (unlocked) {
      const best = Save.data.bestWave[realm.id] ?? 0;
      const info = cleared
        ? `★ Cleared · Best wave ${best}/${realm.waves.length}`
        : best > 0
          ? `Best wave ${best}/${realm.waves.length}`
          : `${realm.waves.length} waves · ${realm.lanes} lanes`;
      c.add(
        label(this, tx, 92, info, {
          size: 15,
          weight: '700',
          color: cleared ? Palette.ember1 : Palette.textDim,
        }),
      );
      c.add(
        this.rewardRow(tx, 118, realm.goldReward, realm.shardReward),
      );

      // Whole card is tappable.
      g.setInteractive(
        new Phaser.Geom.Rectangle(0, 0, w, h),
        Phaser.Geom.Rectangle.Contains,
      );
      g.on('pointerup', () => this.pick(realm.id));
      g.on('pointerdown', () => c.setScale(0.985));
      g.on('pointerout', () => c.setScale(1));
    } else {
      // Lock overlay.
      const lock = this.add.graphics();
      lock.fillStyle(Palette.night0, 0.5);
      lock.fillRoundedRect(0, 0, w, h, 20);
      c.add(lock);
      c.add(
        label(this, w / 2, h / 2, `🔒  Clear ${realm.unlockAfter} realm${realm.unlockAfter > 1 ? 's' : ''} to unlock`, {
          size: 17,
          weight: '800',
          color: Palette.textDim,
          align: 'center',
        }).setOrigin(0.5),
      );
    }

    c.setDepth(DEPTH.hud);
    return c;
  }

  private rewardRow(x: number, y: number, gold: number, shards: number): Phaser.GameObjects.Container {
    const c = this.add.container(x, y);
    const coin = this.add.image(8, 8, 'icon:coin').setDisplaySize(22, 22);
    const gt = this.add.text(24, 8, `${gold}`, {
      fontFamily: FONT,
      fontSize: '16px',
      color: cssHex(Palette.warn),
      fontStyle: 'bold',
    }).setOrigin(0, 0.5);
    const shard = this.add.image(78, 8, 'icon:shard').setDisplaySize(22, 22);
    const st = this.add.text(94, 8, `${shards}`, {
      fontFamily: FONT,
      fontSize: '16px',
      color: cssHex(Palette.aether0),
      fontStyle: 'bold',
    }).setOrigin(0, 0.5);
    c.add([coin, gt, shard, st]);
    return c;
  }

  /** Simple drag-to-scroll for a vertical content container. */
  private enableScroll(content: Phaser.GameObjects.Container, totalH: number, viewH: number) {
    const maxScroll = Math.max(0, totalH - viewH + SAFE.bottom + 20);
    if (maxScroll <= 0) return;
    let dragging = false;
    let startY = 0;
    let startScroll = 0;
    let scroll = 0;

    this.input.on('pointerdown', (p: Phaser.Input.Pointer) => {
      dragging = true;
      startY = p.y;
      startScroll = scroll;
    });
    this.input.on('pointermove', (p: Phaser.Input.Pointer) => {
      if (!dragging || !p.isDown) return;
      scroll = Phaser.Math.Clamp(startScroll - (p.y - startY), 0, maxScroll);
      content.y = -scroll;
    });
    this.input.on('pointerup', () => (dragging = false));
    this.input.on('wheel', (_p: unknown, _o: unknown, _dx: number, dy: number) => {
      scroll = Phaser.Math.Clamp(scroll + dy * 0.5, 0, maxScroll);
      content.y = -scroll;
    });
  }

  private pick(realmId: string) {
    Audio.uiClick();
    fadeTo(this, 240, () => this.scene.start('Loadout', { realmId }));
  }

  private back() {
    Audio.uiBack();
    fadeTo(this, 240, () => this.scene.start('Menu'));
  }
}
