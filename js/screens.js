/* ============================================================================
 * Frontier Bastion — Telas (UI baseada em DOM)
 * ----------------------------------------------------------------------------
 * Cada tela expõe render() (monta o HTML) e, opcionalmente, refresh() (atualiza
 * números/timers sem reconstruir tudo). main.js cuida da navegação.
 * ==========================================================================*/

const Screens = {
  current: 'cidade',
  root: null,

  el(id) { return document.getElementById(id); },

  /* Cabeçalho reutilizável de uma seção. */
  header(title, subtitle) {
    return `<div class="section-head"><h2>${title}</h2>${subtitle ? `<p>${subtitle}</p>` : ''}</div>`;
  },

  /* Renderiza um conjunto de custos como chips. */
  costChips(cost, faded) {
    return Object.keys(cost).map(r => {
      const def = DATA.resources[r];
      const ok = (Game.state.resources[r] || 0) >= cost[r];
      return `<span class="chip ${!ok && !faded ? 'chip-lack' : ''}">${def.icon} ${Game.fmt(cost[r])}</span>`;
    }).join('');
  },

  /* ===================================================================== *
   * CIDADE
   * ===================================================================== */
  renderCidade() {
    const order = ['central', 'serraria', 'fazenda', 'pedreira', 'casa_moeda',
                   'casas', 'armazem', 'academia', 'quartel', 'muralha'];
    const cards = order.map(key => this.buildingCard(key)).join('');
    return `
      ${this.header('Fortaleza', 'Construa e melhore seus edifícios para crescer.')}
      <div class="grid buildings" id="buildings-grid">${cards}</div>
    `;
  },

  buildingCard(key) {
    const def = DATA.buildings[key];
    const lvl = Game.state.buildings[key] || 0;
    const q = Game.state.buildQueue && Game.state.buildQueue.key === key ? Game.state.buildQueue : null;
    const maxed = lvl >= Game.maxLevelFor(key);
    const cost = Game.buildingCost(key);
    const reason = Game.upgradeBlockReason(key);

    let prod = '';
    if (def.produces && lvl > 0) {
      prod = `<div class="b-prod">${DATA.resources[def.produces.type].icon} +${Game.fmt(Game.production(def.produces.type))}/s</div>`;
    } else if (def.storage && lvl > 0) {
      prod = `<div class="b-prod">📦 +${Game.fmt(lvl * def.storage)} estoque</div>`;
    } else if (def.population && lvl > 0) {
      prod = `<div class="b-prod">👥 ${Game.fmt(lvl * def.population)} habitantes</div>`;
    } else if (def.troopCap && lvl > 0) {
      prod = `<div class="b-prod">⚔️ ${Game.fmt(lvl * def.troopCap)} de capacidade</div>`;
    } else if (def.wallHp && lvl > 0) {
      prod = `<div class="b-prod">🧱 +${Game.fmt(lvl * def.wallHp)} HP de muralha</div>`;
    } else if (def.prodBonus && lvl > 0) {
      prod = `<div class="b-prod">📈 +${Math.round(lvl * def.prodBonus * 100)}% produção</div>`;
    }

    let footer;
    if (q) {
      footer = `<div class="b-building" data-bq="${key}">
                  <div class="bar"><div class="bar-fill" style="width:0%"></div></div>
                  <div class="b-build-row">
                    <span class="b-timer">…</span>
                    <button class="btn btn-rush" data-rush="build" title="Concluir agora com gemas">⚡<span class="rush-cost"></span></button>
                  </div>
                </div>`;
    } else if (maxed) {
      footer = `<div class="b-max">${key === 'central' ? 'Nível máximo' : 'Requer Centro de Comando'}</div>`;
    } else {
      footer = `<div class="b-cost">${this.costChips(cost)}</div>
                <button class="btn btn-up" data-upgrade="${key}" ${reason && reason !== 'Recursos insuficientes.' ? 'disabled' : ''}>
                  ${lvl === 0 ? 'Construir' : 'Melhorar'} · ${Game.fmtTime(Game.buildingTime(key))}
                </button>`;
    }

    return `
      <div class="card building" data-building="${key}">
        <div class="b-top">
          <div class="b-icon">${def.icon}</div>
          <div class="b-info">
            <div class="b-name">${def.name} <span class="b-level">Nv ${lvl}</span></div>
            <div class="b-desc">${def.desc}</div>
            ${prod}
          </div>
        </div>
        <div class="b-foot">${footer}</div>
      </div>`;
  },

  /* ===================================================================== *
   * QUARTEL (tropas)
   * ===================================================================== */
  renderQuartel() {
    if ((Game.state.buildings.quartel || 0) < 1) {
      return `${this.header('Quartel', 'Treine tropas para defender a fortaleza.')}
        <div class="empty">⚔️<p>Construa o <b>Quartel</b> na Fortaleza para treinar tropas.</p></div>`;
    }
    const cap = Game.troopCap(), used = Game.troopCount();
    const cards = Object.keys(DATA.troops).map(t => this.troopCard(t)).join('');
    return `
      ${this.header('Quartel', `Capacidade de tropas: <b id="troop-cap">${used}/${cap}</b>`)}
      <div class="grid troops" id="troops-grid">${cards}</div>
    `;
  },

  troopCard(type) {
    const def = DATA.troops[type];
    const have = Game.state.troops[type] || 0;
    const q = Game.state.trainQueue && Game.state.trainQueue.type === type ? Game.state.trainQueue : null;
    const cost = def.cost;
    return `
      <div class="card troop" data-troop="${type}">
        <div class="b-top">
          <div class="b-icon">${def.icon}</div>
          <div class="b-info">
            <div class="b-name">${def.name} <span class="b-level">${Game.fmt(have)} treinados</span></div>
            <div class="b-desc">${def.desc}</div>
            <div class="b-cost">${this.costChips(cost)} <span class="chip">⏱ ${Game.fmtTime(def.time)}/un</span></div>
          </div>
        </div>
        <div class="b-foot">
          ${q ? `<div class="b-building" data-tq="1">
                   <div class="bar"><div class="bar-fill" style="width:0%"></div></div>
                   <div class="b-build-row">
                     <span class="b-timer">Treinando ${q.qty} ${def.name}…</span>
                     <button class="btn btn-rush" data-rush="train" title="Concluir agora com gemas">⚡<span class="rush-cost"></span></button>
                   </div>
                 </div>`
              : `<div class="train-row">
                   <input class="qty" type="number" min="1" value="1" data-qty="${type}">
                   <button class="btn" data-train="${type}">Treinar</button>
                   <button class="btn btn-ghost" data-trainmax="${type}">Máx</button>
                 </div>`}
        </div>
      </div>`;
  },

  /* ===================================================================== *
   * HERÓIS
   * ===================================================================== */
  renderHerois() {
    const cards = DATA.heroes.map(h => this.heroCard(h)).join('');
    return `
      ${this.header('Heróis', 'Recrute e promova líderes que concedem bônus permanentes.')}
      <div class="grid heroes">${cards}</div>
    `;
  },

  heroCard(def) {
    const owned = Game.state.heroes[def.id];
    const rarityClass = 'r-' + def.rarity.toLowerCase().normalize('NFD').replace(/[^a-z]/g, '');
    let action;
    if (!owned) {
      const can = Game.canAfford(def.cost);
      action = `<div class="b-cost">${this.costChips(def.cost)}</div>
                <button class="btn" data-recruit="${def.id}" ${can ? '' : 'disabled'}>Recrutar</button>`;
    } else if (owned.level >= 10) {
      action = `<div class="b-max">Nível máximo (Nv 10)</div>`;
    } else {
      const pc = Game.heroPromoteCost(def.id);
      action = `<div class="b-cost">${this.costChips(pc)}</div>
                <button class="btn" data-promote="${def.id}" ${Game.canAfford(pc) ? '' : 'disabled'}>Promover → Nv ${owned.level + 1}</button>`;
    }
    return `
      <div class="card hero ${owned ? 'owned' : ''}">
        <div class="hero-banner ${rarityClass}">
          <span class="hero-icon">${def.icon}</span>
          <span class="hero-rarity">${def.rarity}</span>
          ${owned ? `<span class="hero-lvl">Nv ${owned.level}</span>` : ''}
        </div>
        <div class="hero-body">
          <div class="b-name">${def.name} <span class="hero-role">${def.role}</span></div>
          <div class="b-desc">${def.lore}</div>
          <div class="hero-bonus">✨ ${def.bonusText}</div>
        </div>
        <div class="b-foot">${action}</div>
      </div>`;
  },

  /* ===================================================================== *
   * BATALHA (saguão + canvas)
   * ===================================================================== */
  renderBatalha(selected) {
    const sel = Math.max(1, Math.min(selected || Game.state.stage, Game.state.stage));
    const max = Game.state.stage;
    return `
      ${this.header('Defesa', 'Repele as hordas. Mire e atire; vença todas as ondas para avançar.')}
      <div class="battle-meta">
        <div class="meta-box"><span>🧱 Muralha</span><b>${Game.fmt(Game.wallMaxHp())} HP</b></div>
        <div class="meta-box"><span>🎯 Dano/tiro</span><b>${Game.fmt(Game.shotDamage())}</b></div>
        <div class="meta-box"><span>🏹 Arqueiros</span><b>${Game.fmt(Game.archerDps())} dps</b></div>
        <div class="meta-box"><span>🐎 Carga</span><b>${Game.fmt(Game.chargeDamage())}</b></div>
      </div>
      <div class="stage-row">
        <button class="btn btn-ghost" id="stage-prev">‹</button>
        <div class="stage-label">Estágio <b id="stage-num">${sel}</b><small id="stage-best">máx desbloqueado: ${max}</small></div>
        <button class="btn btn-ghost" id="stage-next">›</button>
      </div>
      <div class="canvas-wrap" id="canvas-wrap">
        <canvas id="battle-canvas"></canvas>
        <div class="battle-overlay" id="battle-overlay">
          <div class="overlay-card">
            <h3>Pronto para defender?</h3>
            <p>Clique/toque para atirar nos invasores. Não deixe a muralha cair!</p>
            <button class="btn btn-big" id="battle-start">Iniciar Estágio <span id="start-stage">${sel}</span></button>
          </div>
        </div>
        <button class="charge-btn" id="charge-btn" hidden>🐎 Carga</button>
      </div>
    `;
  },

  /* ===================================================================== *
   * REFRESH (atualizações leves por tick)
   * ===================================================================== */
  refresh() {
    if (this.current === 'cidade') this.refreshCidade();
    else if (this.current === 'quartel') this.refreshQuartel();
  },

  refreshCidade() {
    const q = Game.state.buildQueue;
    document.querySelectorAll('[data-bq]').forEach(node => {
      if (!q || node.getAttribute('data-bq') !== q.key) return;
      const total = q.endsAt - q.startedAt;
      const done = Math.min(1, (Date.now() - q.startedAt) / total);
      const fill = node.querySelector('.bar-fill');
      const timer = node.querySelector('.b-timer');
      const rush = node.querySelector('.rush-cost');
      if (fill) fill.style.width = (done * 100).toFixed(1) + '%';
      if (timer) timer.textContent = Game.fmtTime((q.endsAt - Date.now()) / 1000) + ' restante';
      if (rush) rush.textContent = ' ' + Game.rushCost(q.endsAt) + '💎';
    });
  },

  refreshQuartel() {
    const capEl = this.el('troop-cap');
    if (capEl) capEl.textContent = `${Game.troopCount()}/${Game.troopCap()}`;
    const q = Game.state.trainQueue;
    if (q) {
      document.querySelectorAll('[data-tq]').forEach(node => {
        const total = q.endsAt - q.startedAt;
        const done = Math.min(1, (Date.now() - q.startedAt) / total);
        const fill = node.querySelector('.bar-fill');
        const timer = node.querySelector('.b-timer');
        const rush = node.querySelector('.rush-cost');
        if (fill) fill.style.width = (done * 100).toFixed(1) + '%';
        if (timer) timer.textContent = Game.fmtTime((q.endsAt - Date.now()) / 1000) + ' restante';
        if (rush) rush.textContent = ' ' + Game.rushCost(q.endsAt) + '💎';
      });
    }
  },
};
