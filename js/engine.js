/* ============================================================================
 * Frontier Bastion — Motor do jogo
 * ----------------------------------------------------------------------------
 * Estado, persistência (localStorage), produção em tempo real, progresso
 * offline, filas de construção/treino, heróis e cálculo de poder.
 * ==========================================================================*/

const Game = {
  SAVE_KEY: 'frontier-bastion-save-v1',
  state: null,

  /* ----- Estado inicial ------------------------------------------------- */
  defaultState() {
    const buildings = {};
    for (const key in DATA.buildings) buildings[key] = 0;       // 0 = ainda não construído
    buildings.central = 1;                                       // começa com o Centro nível 1
    buildings.serraria = 1;
    buildings.fazenda = 1;

    return {
      createdAt: Date.now(),
      lastTick: Date.now(),
      resources: { wood: 200, food: 200, stone: 120, gold: 60, gems: 120 },
      buildings,
      troops: { infantry: 0, archer: 0, cavalry: 0 },
      heroes: {},               // id -> { level }
      buildQueue: null,         // { key, startedAt, endsAt, toLevel }
      trainQueue: null,         // { type, qty, startedAt, endsAt }
      stage: 1,                 // estágio de campanha desbloqueado
      stats: { battlesWon: 0, enemiesDefeated: 0 },
    };
  },

  /* ----- Persistência --------------------------------------------------- */
  load() {
    try {
      const raw = localStorage.getItem(this.SAVE_KEY);
      if (!raw) { this.state = this.defaultState(); return false; }
      const data = JSON.parse(raw);
      // Mescla com o padrão para tolerar saves antigos / campos novos.
      this.state = Object.assign(this.defaultState(), data);
      this.state.resources = Object.assign(this.defaultState().resources, data.resources || {});
      this.state.buildings = Object.assign(this.defaultState().buildings, data.buildings || {});
      this.state.troops    = Object.assign({ infantry: 0, archer: 0, cavalry: 0 }, data.troops || {});
      this.state.heroes    = data.heroes || {};
      return true;
    } catch (e) {
      console.warn('Falha ao carregar save, iniciando novo jogo.', e);
      this.state = this.defaultState();
      return false;
    }
  },

  save() {
    try {
      this.state.lastTick = Date.now();
      localStorage.setItem(this.SAVE_KEY, JSON.stringify(this.state));
    } catch (e) {
      console.warn('Falha ao salvar.', e);
    }
  },

  reset() {
    localStorage.removeItem(this.SAVE_KEY);
    this.state = this.defaultState();
  },

  /* ----- Utilidades ----------------------------------------------------- */
  fmt(n) {
    n = Math.floor(n);
    if (n < 1000) return '' + n;
    if (n < 1e6)  return (n / 1e3).toFixed(n < 1e4 ? 1 : 0) + 'K';
    if (n < 1e9)  return (n / 1e6).toFixed(n < 1e7 ? 1 : 0) + 'M';
    return (n / 1e9).toFixed(1) + 'B';
  },

  fmtTime(sec) {
    sec = Math.max(0, Math.ceil(sec));
    if (sec < 60) return sec + 's';
    const m = Math.floor(sec / 60), s = sec % 60;
    if (m < 60) return m + 'm' + (s ? ' ' + s + 's' : '');
    const h = Math.floor(m / 60);
    return h + 'h ' + (m % 60) + 'm';
  },

  /* ----- Economia: bônus e produção ------------------------------------ */
  population() {
    const b = DATA.buildings.casas;
    return (this.state.buildings.casas || 0) * b.population;
  },

  // Multiplicador global de produção (academia + população + heróis).
  productionMultiplier() {
    const acad = (this.state.buildings.academia || 0) * DATA.buildings.academia.prodBonus;
    const pop  = this.population() * 0.0009;
    const hero = this.heroBonus('production');
    return 1 + acad + pop + hero;
  },

  // Produção por segundo de um recurso, somando todos os edifícios.
  production(type) {
    let base = 0;
    for (const key in DATA.buildings) {
      const def = DATA.buildings[key];
      const lvl = this.state.buildings[key] || 0;
      if (lvl > 0 && def.produces && def.produces.type === type) {
        base += def.produces.base * lvl;
      }
    }
    return base * this.productionMultiplier();
  },

  storageCap() {
    const base = 1000;
    const wh = (this.state.buildings.armazem || 0) * DATA.buildings.armazem.storage;
    return base + wh;
  },

  // Soma de um tipo de bônus entre os heróis recrutados (escala leve com nível).
  heroBonus(type) {
    let sum = 0;
    for (const def of DATA.heroes) {
      const owned = this.state.heroes[def.id];
      if (owned && def.bonus[type]) {
        sum += def.bonus[type] * (1 + (owned.level - 1) * 0.06);
      }
    }
    return sum;
  },

  /* ----- Custos / afford ------------------------------------------------ */
  scaleCost(baseCost, factor, level) {
    const out = {};
    const mult = Math.pow(factor, level);
    for (const r in baseCost) out[r] = Math.ceil(baseCost[r] * mult);
    return out;
  },

  canAfford(cost) {
    for (const r in cost) if ((this.state.resources[r] || 0) < cost[r]) return false;
    return true;
  },

  spend(cost) {
    if (!this.canAfford(cost)) return false;
    for (const r in cost) this.state.resources[r] -= cost[r];
    return true;
  },

  add(map) {
    const cap = this.storageCap();
    for (const r in map) {
      const def = DATA.resources[r];
      let v = (this.state.resources[r] || 0) + map[r];
      if (def && def.capped) v = Math.min(v, cap);
      this.state.resources[r] = v;
    }
  },

  /* ----- Edifícios ------------------------------------------------------ */
  buildingCost(key) {
    const def = DATA.buildings[key];
    const lvl = this.state.buildings[key] || 0;     // próximo nível = lvl (custo do nível atual->seguinte)
    return this.scaleCost(def.baseCost, def.costFactor, lvl);
  },

  buildingTime(key) {
    const def = DATA.buildings[key];
    const lvl = this.state.buildings[key] || 0;
    return def.baseTime * Math.pow(def.timeFactor, lvl);
  },

  // Nível máximo que um edifício pode atingir (limitado pelo Centro de Comando).
  maxLevelFor(key) {
    const def = DATA.buildings[key];
    if (key === 'central') return def.max;
    return Math.min(def.max, this.state.buildings.central || 1);
  },

  upgradeBlockReason(key) {
    if (this.state.buildQueue) return 'Já há uma construção em andamento.';
    const lvl = this.state.buildings[key] || 0;
    if (lvl >= this.maxLevelFor(key)) {
      return key === 'central'
        ? 'Nível máximo atingido.'
        : 'Eleve o Centro de Comando primeiro.';
    }
    if (!this.canAfford(this.buildingCost(key))) return 'Recursos insuficientes.';
    return null;
  },

  startUpgrade(key) {
    if (this.upgradeBlockReason(key)) return false;
    const cost = this.buildingCost(key);
    this.spend(cost);
    const dur = this.buildingTime(key) * 1000;
    const now = Date.now();
    this.state.buildQueue = {
      key, startedAt: now, endsAt: now + dur,
      toLevel: (this.state.buildings[key] || 0) + 1,
    };
    return true;
  },

  // Custo em gemas para concluir instantaneamente (proporcional ao tempo restante).
  rushCost(endsAt) {
    const remMin = Math.max(0, (endsAt - Date.now()) / 60000);
    return Math.max(1, Math.ceil(remMin * 12 + 1));
  },

  rushBuild() {
    const q = this.state.buildQueue;
    if (!q) return false;
    const cost = this.rushCost(q.endsAt);
    if ((this.state.resources.gems || 0) < cost) return false;
    this.state.resources.gems -= cost;
    q.endsAt = Date.now();
    this.processQueues();
    return true;
  },

  /* ----- Tropas --------------------------------------------------------- */
  troopCount() {
    const t = this.state.troops;
    return t.infantry + t.archer + t.cavalry;
  },

  troopCap() {
    return (this.state.buildings.quartel || 0) * DATA.buildings.quartel.troopCap;
  },

  trainCost(type, qty) {
    const base = DATA.troops[type].cost;
    const out = {};
    for (const r in base) out[r] = base[r] * qty;
    return out;
  },

  trainTime(type, qty) {
    return DATA.troops[type].time * qty;
  },

  maxTrainable(type) {
    // Limite por capacidade restante de tropas.
    return Math.max(0, this.troopCap() - this.troopCount());
  },

  trainBlockReason(type, qty) {
    if ((this.state.buildings.quartel || 0) < 1) return 'Construa o Quartel primeiro.';
    if (this.state.trainQueue) return 'Já há um treinamento em andamento.';
    if (qty < 1) return 'Quantidade inválida.';
    if (this.troopCount() + qty > this.troopCap()) return 'Capacidade de tropas excedida.';
    if (!this.canAfford(this.trainCost(type, qty))) return 'Recursos insuficientes.';
    return null;
  },

  startTraining(type, qty) {
    if (this.trainBlockReason(type, qty)) return false;
    this.spend(this.trainCost(type, qty));
    const dur = this.trainTime(type, qty) * 1000;
    const now = Date.now();
    this.state.trainQueue = { type, qty, startedAt: now, endsAt: now + dur };
    return true;
  },

  rushTraining() {
    const q = this.state.trainQueue;
    if (!q) return false;
    const cost = this.rushCost(q.endsAt);
    if ((this.state.resources.gems || 0) < cost) return false;
    this.state.resources.gems -= cost;
    q.endsAt = Date.now();
    this.processQueues();
    return true;
  },

  /* ----- Heróis --------------------------------------------------------- */
  heroDef(id) { return DATA.heroes.find(h => h.id === id); },

  recruitHero(id) {
    if (this.state.heroes[id]) return false;
    const def = this.heroDef(id);
    if (!def || !this.canAfford(def.cost)) return false;
    this.spend(def.cost);
    this.state.heroes[id] = { level: 1 };
    return true;
  },

  heroPromoteCost(id) {
    const owned = this.state.heroes[id];
    if (!owned) return null;
    return { gold: Math.ceil(1200 * Math.pow(1.5, owned.level - 1)) };
  },

  promoteHero(id) {
    const owned = this.state.heroes[id];
    if (!owned || owned.level >= 10) return false;
    const cost = this.heroPromoteCost(id);
    if (!this.canAfford(cost)) return false;
    this.spend(cost);
    owned.level += 1;
    return true;
  },

  /* ----- Combate (consultado por combat.js) ----------------------------- */
  wallMaxHp() {
    const wall = (this.state.buildings.muralha || 0) * DATA.buildings.muralha.wallHp;
    const inf  = this.state.troops.infantry * DATA.troops.infantry.wallHp;
    return Math.floor((wall + inf + 150) * (1 + this.heroBonus('defense')));
  },

  shotDamage() {
    return Math.floor(DATA.combat.baseShotDamage * (1 + this.heroBonus('atk')));
  },

  archerDps() {
    return Math.floor(this.state.troops.archer * DATA.troops.archer.dps * (1 + this.heroBonus('atk')));
  },

  chargeDamage() {
    return Math.floor((200 + this.state.troops.cavalry * DATA.troops.cavalry.charge) * (1 + this.heroBonus('atk')));
  },

  /* ----- Poder ---------------------------------------------------------- */
  power() {
    let p = 0;
    for (const key in this.state.buildings) p += (this.state.buildings[key] || 0) * 10;
    for (const t in this.state.troops) p += this.state.troops[t] * DATA.troops[t].power;
    for (const id in this.state.heroes) {
      const def = this.heroDef(id);
      if (def) p += def.power * this.state.heroes[id].level;
    }
    return Math.floor(p);
  },

  /* ----- Loop: filas e produção ---------------------------------------- */
  // Conclui construções/treinos cujo tempo já passou.
  processQueues() {
    const now = Date.now();
    if (this.state.buildQueue && now >= this.state.buildQueue.endsAt) {
      const q = this.state.buildQueue;
      this.state.buildings[q.key] = q.toLevel;
      this.state.buildQueue = null;
    }
    if (this.state.trainQueue && now >= this.state.trainQueue.endsAt) {
      const q = this.state.trainQueue;
      this.state.troops[q.type] = (this.state.troops[q.type] || 0) + q.qty;
      this.state.trainQueue = null;
    }
  },

  // Avança a produção `dtSeconds` segundos (respeitando o teto de estoque).
  produce(dtSeconds) {
    if (dtSeconds <= 0) return;
    const gains = {};
    for (const type in DATA.resources) {
      if (!DATA.resources[type].capped && type === 'gems') continue; // gemas não são produzidas
      const rate = this.production(type);
      if (rate > 0) gains[type] = rate * dtSeconds;
    }
    this.add(gains);
  },

  tick(dtSeconds) {
    this.produce(dtSeconds);
    this.processQueues();
  },

  // Calcula ganhos enquanto o jogador esteve ausente. Retorna o resumo.
  applyOffline() {
    const now = Date.now();
    const elapsed = Math.max(0, (now - (this.state.lastTick || now)) / 1000);
    if (elapsed < 5) { this.state.lastTick = now; return null; }

    const capped = Math.min(elapsed, 60 * 60 * 12); // teto de 12h de produção offline
    const before = Object.assign({}, this.state.resources);
    this.produce(capped);
    this.processQueues();
    this.state.lastTick = now;

    const gained = {};
    for (const r in this.state.resources) {
      const d = Math.floor(this.state.resources[r] - (before[r] || 0));
      if (d > 0) gained[r] = d;
    }
    return { seconds: Math.floor(elapsed), gained };
  },
};
