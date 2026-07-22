import Phaser from 'phaser';
import { Palette } from '../core/Palette';
import { Backdrop } from '../core/Backdrop';
import { Save } from '../core/Save';
import { Audio } from '../core/Audio';
import { button, label, drawPanel, fadeIn, fadeTo, toast } from '../core/UI';
import { DEPTH, SAFE } from '../config';

/**
 * SettingsScene — audio, feedback, and data controls.
 */
export class SettingsScene extends Phaser.Scene {
  constructor() {
    super('Settings');
  }

  create() {
    const { width, height } = this.scale;
    fadeIn(this);
    new Backdrop(this, { accent: Palette.aether1, hills: false });

    label(this, width / 2, SAFE.top + 24, 'SETTINGS', {
      size: 26,
      weight: '900',
      align: 'center',
      letter: 3,
    }).setDepth(DEPTH.hud);

    button(this, 64, SAFE.top + 20, '‹', () => this.back(), {
      width: 56,
      height: 48,
      variant: 'ghost',
      size: 30,
    }).setDepth(DEPTH.hud);

    const s = Save.data.settings;
    let y = SAFE.top + 110;
    const gap = 82;
    this.toggle('Sound Effects', y, s.sfx, (v) => {
      s.sfx = v;
      Save.flush();
      if (v) Audio.uiClick();
    });
    y += gap;
    this.toggle('Music', y, s.music, (v) => {
      s.music = v;
      Save.flush();
      Audio.setMusicEnabled(v);
    });
    y += gap;
    this.toggle('Haptics', y, s.haptics, (v) => {
      s.haptics = v;
      Save.flush();
      if (v && navigator.vibrate) navigator.vibrate(20);
    });
    y += gap;
    this.toggle('Screen Shake', y, s.screenShake, (v) => {
      s.screenShake = v;
      Save.flush();
    });

    // Stats panel.
    y += gap + 10;
    const pw = width - 2 * SAFE.left;
    const pg = this.add.graphics().setDepth(DEPTH.hud);
    drawPanel(pg, pw, 132, { fill: Palette.panel, stroke: Palette.stroke, radius: 18 });
    pg.x = SAFE.left;
    pg.y = y;
    label(this, SAFE.left + 20, y + 18, 'CAMPAIGN RECORD', { size: 15, weight: '800', color: Palette.textDim }).setDepth(DEPTH.hud);
    const st = Save.data.stats;
    const lines = [
      `Runs played:  ${st.runs}`,
      `Enemies felled:  ${st.kills}`,
      `Realms cleared:  ${Save.data.clearedRealms.length}/5   ·   Victories:  ${st.victories}`,
    ];
    lines.forEach((l, i) =>
      label(this, SAFE.left + 20, y + 48 + i * 24, l, { size: 16, weight: '700' }).setDepth(DEPTH.hud),
    );

    // Danger zone.
    y += 132 + 24;
    button(this, width / 2, y + 20, 'RESET ALL PROGRESS', () => this.confirmWipe(), {
      width: pw,
      height: 56,
      variant: 'solid',
      color: Palette.danger,
      textColor: Palette.night0,
      size: 18,
    }).setDepth(DEPTH.hud);

    label(this, width / 2, height - SAFE.bottom - 6, 'Bastion Rush · a procedural roguelite · made with Phaser', {
      size: 13,
      weight: '600',
      color: Palette.textFaint,
      align: 'center',
    }).setDepth(DEPTH.hud);
  }

  private toggle(name: string, y: number, value: boolean, onChange: (v: boolean) => void) {
    const { width } = this.scale;
    const pw = width - 2 * SAFE.left;
    const c = this.add.container(SAFE.left, y).setDepth(DEPTH.hud);
    const g = this.add.graphics();
    drawPanel(g, pw, 62, { fill: Palette.panel, stroke: Palette.stroke, radius: 16 });
    c.add(g);
    c.add(label(this, 22, 31, name, { size: 20, weight: '800' }).setOrigin(0, 0.5));

    const knobX = pw - 74;
    const track = this.add.graphics();
    const knob = this.add.graphics();
    let state = value;
    const paint = () => {
      track.clear();
      track.fillStyle(state ? Palette.good : Palette.night0, 1);
      track.fillRoundedRect(knobX, 20, 52, 24, 12);
      knob.clear();
      knob.fillStyle(Palette.white, 1);
      knob.fillCircle(knobX + (state ? 40 : 12), 32, 10);
    };
    paint();
    c.add(track);
    c.add(knob);

    g.setInteractive(new Phaser.Geom.Rectangle(0, 0, pw, 62), Phaser.Geom.Rectangle.Contains);
    g.on('pointerup', () => {
      state = !state;
      paint();
      onChange(state);
    });
  }

  private confirmWipe() {
    Audio.uiBack();
    const { width, height } = this.scale;
    const c = this.add.container(0, 0).setDepth(DEPTH.overlay);
    const dim = this.add.graphics();
    dim.fillStyle(Palette.night0, 0.8);
    dim.fillRect(0, 0, width, height);
    dim.setInteractive(new Phaser.Geom.Rectangle(0, 0, width, height), Phaser.Geom.Rectangle.Contains);
    c.add(dim);
    const pw = width - 80;
    const g = this.add.graphics();
    drawPanel(g, pw, 240, { fill: Palette.panel, stroke: Palette.danger, strokeWidth: 3, radius: 22 });
    g.x = 40;
    g.y = height / 2 - 120;
    c.add(g);
    c.add(label(this, width / 2, height / 2 - 78, 'Reset everything?', { size: 24, weight: '900', color: Palette.danger, align: 'center' }).setOrigin(0.5));
    c.add(label(this, width / 2, height / 2 - 40, 'All champions, gold, and progress\nwill be permanently lost.', { size: 16, weight: '600', color: Palette.textDim, align: 'center' }).setOrigin(0.5));
    const cancel = button(this, width / 2 - 90, height / 2 + 50, 'Cancel', () => c.destroy(), { width: 150, height: 54, variant: 'ghost', size: 20 });
    const confirm = button(this, width / 2 + 90, height / 2 + 50, 'Reset', () => {
      Save.wipe();
      c.destroy();
      toast(this, 'Progress reset', Palette.danger);
      this.scene.restart();
    }, { width: 150, height: 54, variant: 'solid', color: Palette.danger, textColor: Palette.night0, size: 20 });
    c.add([cancel, confirm]);
  }

  private back() {
    Audio.uiBack();
    fadeTo(this, 240, () => this.scene.start('Menu'));
  }
}
