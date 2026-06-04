/* ============================================================================
 * Frontier Bastion — Combate de defesa (Canvas)
 * ----------------------------------------------------------------------------
 * A fortaleza fica à esquerda; as hordas avançam pela direita. O jogador mira
 * e atira (clique/toque) na torre da muralha. Arqueiros disparam sozinhos e a
 * Cavalaria potencializa a "Carga" (especial em área). Limpar todas as ondas
 * concede recompensas e avança o estágio da campanha.
 * ==========================================================================*/

const Combat = {
  canvas: null, ctx: null, running: false, raf: null,
  W: 0, H: 0, wallX: 96,
  stage: 1, wave: 0, totalWaves: 5,
  wallHp: 0, wallMax: 0,
  enemies: [], bullets: [], particles: [],
  spawnQueue: [], spawnTimer: 0,
  archerCooldown: 0, chargeCooldown: 0, chargeMax: 9,
  lastTs: 0, ended: false, onEnd: null, score: 0,

  /* ----- Ciclo de vida -------------------------------------------------- */
  mount(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this._onClick = (e) => this.handleAim(e);
    canvas.addEventListener('pointerdown', this._onClick);
  },

  resize() {
    if (!this.canvas) return;
    const rect = this.canvas.parentElement.getBoundingClientRect();
    const w = Math.max(320, Math.floor(rect.width));
    const h = Math.max(280, Math.min(520, Math.floor(rect.width * 0.52)));
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = w * dpr;
    this.canvas.height = h * dpr;
    this.canvas.style.width = w + 'px';
    this.canvas.style.height = h + 'px';
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.W = w; this.H = h;
    this.wallX = Math.max(70, Math.floor(w * 0.12));
  },

  start(stage, onEnd) {
    this.stage = stage;
    this.onEnd = onEnd;
    this.totalWaves = DATA.combat.wavesPerStage;
    this.wave = 0;
    this.wallMax = Game.wallMaxHp();
    this.wallHp = this.wallMax;
    this.enemies = []; this.bullets = []; this.particles = [];
    this.spawnQueue = []; this.spawnTimer = 0;
    this.archerCooldown = 0; this.chargeCooldown = 0; this.shake = 0; this.shield = 0;
    this.chargeMax = DATA.combat.cavalryChargeCooldown;
    this.heroSkills = {};
    for (const id in Game.state.heroes) {
      const def = Game.heroDef(id);
      if (def && def.skill) this.heroSkills[id] = { def: def.skill, cd: 0 };
    }
    this.score = 0; this.ended = false; this.running = true;
    this.resize();
    this.nextWave();
    this.lastTs = performance.now();
    cancelAnimationFrame(this.raf);
    const loop = (ts) => {
      if (!this.running) return;
      const dt = Math.min(0.05, (ts - this.lastTs) / 1000);
      this.lastTs = ts;
      this.update(dt);
      this.render();
      this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  },

  stop() {
    this.running = false;
    cancelAnimationFrame(this.raf);
  },

  destroy() {
    this.stop();
    if (this.canvas && this._onClick) this.canvas.removeEventListener('pointerdown', this._onClick);
  },

  /* ----- Geração de ondas ---------------------------------------------- */
  nextWave() {
    this.wave += 1;
    const s = this.stage, w = this.wave;
    const hpMul  = 1 + (s - 1) * 0.45 + (w - 1) * 0.12;
    const isBoss = (w === this.totalWaves) && (s % 3 === 0);

    const queue = [];
    const count = 4 + s + w;                       // nº de inimigos da onda
    for (let i = 0; i < count; i++) {
      let type = 'raider';
      const roll = Math.random();
      if (roll > 0.82) type = 'brute';
      else if (roll > 0.5) type = 'runner';
      queue.push({ type, hpMul });
    }
    if (isBoss) queue.push({ type: 'boss', hpMul: hpMul * 1.2 });

    this.spawnQueue = queue;
    this.spawnTimer = 0.4;
  },

  spawnEnemy(spec) {
    const def = DATA.combat.enemyTypes[spec.type];
    const hp = Math.floor(def.hp * spec.hpMul);
    this.enemies.push({
      type: spec.type,
      x: this.W + 30 + Math.random() * 60,
      y: 60 + Math.random() * (this.H - 120),
      r: def.r, hp, maxHp: hp,
      speed: def.speed * (0.85 + Math.random() * 0.3),
      dmg: def.dmg, gold: def.gold, color: def.color,
      hitFlash: 0,
    });
  },

  /* ----- Entrada do jogador -------------------------------------------- */
  handleAim(e) {
    if (!this.running || this.ended) return;
    const rect = this.canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    this.fireBullet(x, y, Game.shotDamage(), '#ffd45e', 520, true);
  },

  useCharge() {
    if (this.chargeCooldown > 0 || !this.running || this.ended) return false;
    const dmg = Game.chargeDamage();
    let hit = 0;
    for (const en of this.enemies) {
      en.hp -= dmg;
      en.hitFlash = 0.15;
      hit++;
      this.burst(en.x, en.y, '#ff7a3c', 10);
    }
    this.chargeCooldown = this.chargeMax;
    this.shake = 0.25;
    return hit > 0;
  },

  // Aplica dano à muralha, consumindo o escudo (se houver) antes do HP.
  damageWall(d) {
    if (this.shield > 0) {
      const absorbed = Math.min(this.shield, d);
      this.shield -= absorbed;
      d -= absorbed;
    }
    if (d > 0) this.wallHp -= d;
  },

  skillCooldown(id) {
    return this.heroSkills && this.heroSkills[id] ? this.heroSkills[id].cd : 0;
  },

  // Aciona a habilidade ativa de um herói recrutado.
  useHeroSkill(id) {
    const s = this.heroSkills && this.heroSkills[id];
    if (!s || s.cd > 0 || !this.running || this.ended) return false;
    const sk = s.def;
    if (sk.type === 'heal') {
      this.wallHp = Math.min(this.wallMax, this.wallHp + sk.value * this.wallMax);
      this.burst(this.wallX, this.H * 0.5, '#5fcf6b', 18);
    } else if (sk.type === 'shield') {
      this.shield = Math.min(this.wallMax, this.shield + sk.value * this.wallMax);
      this.burst(this.wallX, this.H * 0.5, '#7fd4ff', 18);
    } else if (sk.type === 'volley') {
      const live = this.enemies.filter(e => e.hp > 0);
      for (let i = 0; i < sk.value; i++) {
        const t = live[i % Math.max(1, live.length)];
        if (t) this.fireBullet(t.x, t.y, Game.shotDamage() * 1.6, '#ffd45e', 640, true);
      }
    } else if (sk.type === 'nuke') {
      const dmg = Math.floor(sk.value * Game.chargeDamage());
      for (const en of this.enemies) { en.hp -= dmg; en.hitFlash = 0.15; this.burst(en.x, en.y, '#ff7a3c', 8); }
      this.shake = 0.3;
    }
    s.cd = sk.cooldown;
    return true;
  },

  fireBullet(tx, ty, dmg, color, speed, manual) {
    const sx = this.wallX, sy = this.H * 0.5;
    const ang = Math.atan2(ty - sy, tx - sx);
    this.bullets.push({
      x: sx, y: sy,
      vx: Math.cos(ang) * speed, vy: Math.sin(ang) * speed,
      dmg, color, r: manual ? 5 : 3, life: 2.2,
    });
  },

  /* ----- Atualização ---------------------------------------------------- */
  update(dt) {
    if (this.ended) return;

    // Spawns escalonados.
    if (this.spawnQueue.length) {
      this.spawnTimer -= dt;
      if (this.spawnTimer <= 0) {
        this.spawnEnemy(this.spawnQueue.shift());
        this.spawnTimer = 0.55;
      }
    }

    // Tiro automático dos arqueiros.
    const adps = Game.archerDps();
    if (adps > 0) {
      this.archerCooldown -= dt;
      if (this.archerCooldown <= 0 && this.enemies.length) {
        const target = this.nearestEnemy();
        if (target) this.fireBullet(target.x, target.y, Math.max(4, adps * 0.5), '#7fd4ff', 460, false);
        this.archerCooldown = 0.5;   // 2 disparos/s; dano por disparo = dps*0.5
      }
    }

    if (this.chargeCooldown > 0) this.chargeCooldown = Math.max(0, this.chargeCooldown - dt);
    if (this.shake > 0) this.shake = Math.max(0, this.shake - dt);
    for (const id in this.heroSkills) { const s = this.heroSkills[id]; if (s.cd > 0) s.cd = Math.max(0, s.cd - dt); }

    // Move projéteis e checa colisão.
    for (const b of this.bullets) {
      b.x += b.vx * dt; b.y += b.vy * dt; b.life -= dt;
      for (const en of this.enemies) {
        if (en.hp <= 0) continue;
        const dx = en.x - b.x, dy = en.y - b.y;
        if (dx * dx + dy * dy <= (en.r + b.r) * (en.r + b.r)) {
          en.hp -= b.dmg; en.hitFlash = 0.12; b.life = 0;
          this.burst(b.x, b.y, b.color, 4);
          break;
        }
      }
    }
    this.bullets = this.bullets.filter(b => b.life > 0 && b.x > -20 && b.x < this.W + 40 && b.y > -20 && b.y < this.H + 20);

    // Move inimigos; dano na muralha ao alcançá-la.
    for (const en of this.enemies) {
      if (en.hp <= 0) continue;
      en.x -= en.speed * dt;
      if (en.hitFlash > 0) en.hitFlash -= dt;
      if (en.x - en.r <= this.wallX) {
        this.damageWall(en.dmg);
        en.hp = 0;
        this.burst(this.wallX, en.y, '#ff5050', 12);
        this.shake = 0.18;
      }
    }

    // Remove mortos e concede recompensa.
    const alive = [];
    for (const en of this.enemies) {
      if (en.hp <= 0) {
        if (en.x - en.r > this.wallX) {           // morreu lutando (não bateu na muralha)
          this.score += en.gold;
          Game.state.stats.enemiesDefeated++;
        }
        this.burst(en.x, en.y, en.color, 8);
      } else alive.push(en);
    }
    this.enemies = alive;

    // Partículas.
    for (const p of this.particles) {
      p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt; p.vy += 60 * dt;
    }
    this.particles = this.particles.filter(p => p.life > 0);

    // Condições de fim.
    if (this.wallHp <= 0) return this.finish(false);
    if (!this.enemies.length && !this.spawnQueue.length) {
      if (this.wave >= this.totalWaves) return this.finish(true);
      this.nextWave();
    }
  },

  nearestEnemy() {
    let best = null, bd = Infinity;
    for (const en of this.enemies) {
      if (en.hp <= 0) continue;
      const d = en.x;                 // mais à esquerda = mais perto da muralha
      if (d < bd) { bd = d; best = en; }
    }
    return best;
  },

  burst(x, y, color, n) {
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2, sp = 40 + Math.random() * 120;
      this.particles.push({ x, y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, life: 0.4 + Math.random() * 0.3, color, r: 1 + Math.random() * 2 });
    }
  },

  finish(victory) {
    if (this.ended) return;
    this.ended = true;
    this.running = false;
    cancelAnimationFrame(this.raf);

    let rewards = null;
    if (victory) {
      const s = this.stage;
      rewards = {
        gold:  120 + s * 60 + this.score,
        wood:  200 + s * 90,
        food:  200 + s * 90,
        stone: 120 + s * 60,
      };
      if (Math.random() < 0.35 + Math.min(0.4, s * 0.03)) rewards.gems = 8 + s * 2;
      Game.add(rewards);
      Game.state.stats.battlesWon++;
      if (s >= Game.state.stage) Game.state.stage = s + 1;   // desbloqueia o próximo
      Game.save();
    }
    if (this.onEnd) this.onEnd({ victory, rewards, stage: this.stage, score: this.score });
  },

  /* ----- Renderização --------------------------------------------------- */
  render() {
    const ctx = this.ctx;
    if (!ctx) return;
    const sx = this.shake > 0 ? (Math.random() - 0.5) * 8 * this.shake : 0;
    const sy = this.shake > 0 ? (Math.random() - 0.5) * 8 * this.shake : 0;
    ctx.save();
    ctx.translate(sx, sy);

    // Fundo (céu -> terra).
    const g = ctx.createLinearGradient(0, 0, 0, this.H);
    g.addColorStop(0, '#2a3550'); g.addColorStop(0.6, '#3a4a3a'); g.addColorStop(1, '#26331f');
    ctx.fillStyle = g;
    ctx.fillRect(-10, -10, this.W + 20, this.H + 20);

    // Muralha.
    ctx.fillStyle = '#5a4632';
    ctx.fillRect(0, 0, this.wallX, this.H);
    ctx.fillStyle = '#6b5640';
    for (let y = 0; y < this.H; y += 28) ctx.fillRect(this.wallX - 10, y + 3, 10, 22);
    // Torre/atirador.
    ctx.fillStyle = '#caa46a';
    ctx.beginPath(); ctx.arc(this.wallX, this.H * 0.5, 12, 0, Math.PI * 2); ctx.fill();

    // Barra de HP da muralha.
    const hpW = this.wallX - 8, hpFrac = Math.max(0, this.wallHp / this.wallMax);
    ctx.fillStyle = 'rgba(0,0,0,.4)'; ctx.fillRect(4, 8, hpW, 8);
    ctx.fillStyle = hpFrac > 0.35 ? '#5fcf6b' : '#e05050';
    ctx.fillRect(4, 8, hpW * hpFrac, 8);
    // Escudo (Égide) sobre a barra de HP.
    if (this.shield > 0) {
      const shFrac = Math.min(1, this.shield / this.wallMax);
      ctx.fillStyle = 'rgba(0,0,0,.4)'; ctx.fillRect(4, 18, hpW, 4);
      ctx.fillStyle = '#7fd4ff'; ctx.fillRect(4, 18, hpW * shFrac, 4);
    }

    // Inimigos.
    for (const en of this.enemies) {
      ctx.fillStyle = en.hitFlash > 0 ? '#ffffff' : en.color;
      ctx.beginPath(); ctx.arc(en.x, en.y, en.r, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgba(0,0,0,.35)';
      ctx.beginPath(); ctx.arc(en.x - en.r * 0.3, en.y - en.r * 0.25, en.r * 0.5, 0, Math.PI * 2); ctx.fill();
      if (en.hp < en.maxHp) {
        const bw = en.r * 2;
        ctx.fillStyle = 'rgba(0,0,0,.5)'; ctx.fillRect(en.x - en.r, en.y - en.r - 8, bw, 4);
        ctx.fillStyle = '#ffd45e'; ctx.fillRect(en.x - en.r, en.y - en.r - 8, bw * (en.hp / en.maxHp), 4);
      }
    }

    // Projéteis.
    for (const b of this.bullets) {
      ctx.fillStyle = b.color;
      ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2); ctx.fill();
    }

    // Partículas.
    for (const p of this.particles) {
      ctx.globalAlpha = Math.max(0, p.life * 2);
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x, p.y, p.r, p.r);
    }
    ctx.globalAlpha = 1;

    ctx.restore();

    // HUD (texto da onda) — fora do shake.
    ctx.fillStyle = 'rgba(255,255,255,.92)';
    ctx.font = '600 14px system-ui, sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText(`Estágio ${this.stage} · Onda ${this.wave}/${this.totalWaves}`, this.W - 10, 22);
    ctx.textAlign = 'left';
  },
};
