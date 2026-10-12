import Phaser from 'phaser';
import { Save } from '../core/Save';
import { Audio } from '../core/Audio';
import { buildAllTextures } from '../core/Art';
import { snapshotUnlocks } from '../core/Meta';

/**
 * BootScene — one-time init.
 *
 * Loads the save profile, forges every procedural texture, wires the first
 * user-gesture audio unlock, then hands off to the main menu. Hides the HTML
 * pre-loader once the first real frame is ready.
 */
export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  create() {
    Save.load();
    snapshotUnlocks();
    buildAllTextures(this);

    // Unlock audio on the first interaction anywhere.
    const unlock = () => {
      Audio.unlock();
      Audio.startMusic();
    };
    this.input.once('pointerdown', unlock);
    window.addEventListener('keydown', unlock, { once: true });

    // Dismiss the HTML boot loader.
    const boot = document.getElementById('boot');
    if (boot) {
      boot.classList.add('hide');
      window.setTimeout(() => boot.remove(), 600);
    }

    this.scene.start('Menu');
  }
}
