import { Save } from './Save';

/**
 * Audio — a tiny procedural sound engine.
 *
 * Every sound is synthesized with the WebAudio API at play time: no audio files
 * to ship or license. A soft ambient music bed loops under the menus and runs,
 * and short synth "blips" cover the SFX. Respects the player's sfx/music
 * settings and only starts after a user gesture (mobile autoplay rules).
 */
class AudioEngine {
  private ctx: AudioContext | null = null;
  private master: GainNode | null = null;
  private musicGain: GainNode | null = null;
  private sfxGain: GainNode | null = null;
  private musicTimer: number | null = null;
  private musicStep = 0;
  private started = false;

  /** Call from the first user gesture to satisfy autoplay policies. */
  unlock() {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') void this.ctx.resume();
      return;
    }
    const Ctor =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctor) return;
    this.ctx = new Ctor();
    this.master = this.ctx.createGain();
    this.master.gain.value = 0.9;
    this.master.connect(this.ctx.destination);

    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = 0.0;
    this.musicGain.connect(this.master);

    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.value = 0.6;
    this.sfxGain.connect(this.master);
  }

  private now(): number {
    return this.ctx ? this.ctx.currentTime : 0;
  }

  /** Core one-shot oscillator voice. */
  private blip(
    freq: number,
    dur: number,
    type: OscillatorType = 'sine',
    gain = 0.5,
    slideTo?: number,
    dest?: GainNode,
  ) {
    if (!this.ctx || !this.sfxGain) return;
    if (!Save.data.settings.sfx && dest !== this.musicGain) return;
    const t = this.now();
    const osc = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t);
    if (slideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(1, slideTo), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g);
    g.connect(dest ?? this.sfxGain);
    osc.start(t);
    osc.stop(t + dur + 0.02);
  }

  private noise(dur: number, gain = 0.4, hp = 800) {
    if (!this.ctx || !this.sfxGain) return;
    if (!Save.data.settings.sfx) return;
    const t = this.now();
    const len = Math.floor(this.ctx.sampleRate * dur);
    const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / len);
    const src = this.ctx.createBufferSource();
    src.buffer = buf;
    const filter = this.ctx.createBiquadFilter();
    filter.type = 'highpass';
    filter.frequency.value = hp;
    const g = this.ctx.createGain();
    g.gain.value = gain;
    src.connect(filter);
    filter.connect(g);
    g.connect(this.sfxGain);
    src.start(t);
  }

  // ── Named SFX ────────────────────────────────────────────
  shoot() {
    this.blip(720, 0.12, 'triangle', 0.28, 320);
  }
  hit() {
    this.noise(0.06, 0.16, 1400);
    this.blip(220, 0.06, 'square', 0.14, 140);
  }
  enemyDie() {
    this.blip(180, 0.2, 'sawtooth', 0.24, 60);
    this.noise(0.12, 0.18, 500);
  }
  deploy() {
    this.blip(320, 0.18, 'sine', 0.3, 620);
    this.blip(480, 0.2, 'sine', 0.2, 720);
  }
  coin() {
    this.blip(880, 0.08, 'square', 0.18, 1180);
    this.blip(1180, 0.1, 'square', 0.14);
  }
  uiClick() {
    this.blip(520, 0.06, 'square', 0.16, 700);
  }
  uiBack() {
    this.blip(400, 0.08, 'square', 0.14, 280);
  }
  boon() {
    this.blip(523, 0.14, 'triangle', 0.24);
    this.blip(784, 0.18, 'triangle', 0.22);
    this.blip(1046, 0.22, 'triangle', 0.2);
  }
  ultimate() {
    this.blip(120, 0.5, 'sawtooth', 0.35, 900);
    this.noise(0.4, 0.3, 300);
  }
  boss() {
    this.blip(70, 0.8, 'sawtooth', 0.4, 48);
    this.noise(0.6, 0.3, 160);
  }
  hurt() {
    this.blip(160, 0.16, 'square', 0.3, 70);
    this.noise(0.1, 0.2, 400);
  }
  victory() {
    const notes = [523, 659, 784, 1046];
    notes.forEach((n, i) => setTimeout(() => this.blip(n, 0.3, 'triangle', 0.3), i * 130));
  }
  defeat() {
    const notes = [440, 349, 262];
    notes.forEach((n, i) => setTimeout(() => this.blip(n, 0.5, 'sawtooth', 0.28, n * 0.8), i * 200));
  }

  // ── Ambient music ────────────────────────────────────────
  startMusic() {
    if (!this.ctx || !this.musicGain) return;
    if (this.started) return;
    this.started = true;
    this.setMusicEnabled(Save.data.settings.music);
    // A slow minor arpeggio pad — evocative, unobtrusive.
    const scale = [196, 233, 261.63, 293.66, 349.23, 392, 466.16];
    const pattern = [0, 2, 4, 2, 5, 4, 2, 0, 3, 4, 6, 4];
    const stepMs = 460;
    this.musicTimer = window.setInterval(() => {
      if (!Save.data.settings.music) return;
      const idx = pattern[this.musicStep % pattern.length];
      const base = scale[idx];
      this.blip(base, 0.9, 'sine', 0.16, undefined, this.musicGain!);
      if (this.musicStep % 4 === 0) this.blip(base / 2, 1.4, 'triangle', 0.1, undefined, this.musicGain!);
      if (this.musicStep % 8 === 0) this.blip(base * 1.5, 0.7, 'sine', 0.06, undefined, this.musicGain!);
      this.musicStep++;
    }, stepMs);
  }

  setMusicEnabled(on: boolean) {
    if (!this.musicGain || !this.ctx) return;
    this.musicGain.gain.linearRampToValueAtTime(on ? 0.5 : 0.0001, this.now() + 0.4);
  }

  stopMusic() {
    if (this.musicTimer !== null) {
      clearInterval(this.musicTimer);
      this.musicTimer = null;
      this.started = false;
    }
  }
}

export const Audio = new AudioEngine();
