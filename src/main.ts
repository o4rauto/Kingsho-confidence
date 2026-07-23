import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from './config';
import { Palette } from './core/Palette';
import { BootScene } from './scenes/BootScene';
import { MenuScene } from './scenes/MenuScene';
import { RealmSelectScene } from './scenes/RealmSelectScene';
import { LoadoutScene } from './scenes/LoadoutScene';
import { CollectionScene } from './scenes/CollectionScene';
import { GameScene } from './scenes/GameScene';
import { ResultScene } from './scenes/ResultScene';
import { SettingsScene } from './scenes/SettingsScene';

/**
 * Bastion Rush — entry point.
 *
 * A last-stand roguelite tower-brawler: Kingdom Rush lanes, Clash Royale
 * collection & deploy energy, Archero hero action. Portrait, mobile-first,
 * packaged for Android with Capacitor.
 */
const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  parent: 'game',
  backgroundColor: Palette.night0,
  roundPixels: false,
  antialias: true,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: GAME_WIDTH,
    height: GAME_HEIGHT,
  },
  input: {
    activePointers: 3,
  },
  render: {
    powerPreference: 'high-performance',
  },
  fps: {
    // A low `min` stops Phaser from clamping the frame delta on slow/software-
    // rendered devices, so timers (wave spawns) keep real-time pace. The
    // GameScene sub-steps its own simulation with a hard cap, so this can't
    // trigger a death spiral.
    target: 60,
    min: 5,
  },
  scene: [
    BootScene,
    MenuScene,
    RealmSelectScene,
    LoadoutScene,
    CollectionScene,
    GameScene,
    ResultScene,
    SettingsScene,
  ],
};

const game = new Phaser.Game(config);
// Expose the game instance for debugging tools & automated smoke tests.
(window as unknown as { game?: Phaser.Game }).game = game;
