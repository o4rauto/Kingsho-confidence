/* ============================================================================
 * Frontier Bastion — Orquestração principal
 * ----------------------------------------------------------------------------
 * Inicialização, barra de recursos, navegação entre telas, delegação de
 * eventos, toasts, loop do jogo e integração com o combate.
 * ==========================================================================*/

(function () {
  'use strict';

  const NAV = [
    { id: 'cidade',  icon: '🏰', label: 'Fortaleza' },
    { id: 'quartel', icon: '⚔️', label: 'Quartel' },
    { id: 'herois',  icon: '🦸', label: 'Heróis' },
    { id: 'batalha', icon: '🎯', label: 'Defesa' },
  ];

  let battleStageView = 1;   // estágio sendo visualizado no saguão
  let toastTimer = null;

  /* ----- Toast --------------------------------------------------------- */
  function toast(msg, type) {
    const box = document.getElementById('toast');
    box.textContent = msg;
    box.className = 'toast show' + (type ? ' toast-' + type : '');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { box.className = 'toast'; }, 2600);
  }

  /* ----- Barra de recursos --------------------------------------------- */
  function buildTopbar() {
    const bar = document.getElementById('resbar');
    const order = ['wood', 'food', 'stone', 'gold', 'gems'];
    bar.innerHTML = order.map(r => {
      const def = DATA.resources[r];
      return `<div class="res" data-res="${r}">
                <span class="res-ico">${def.icon}</span>
                <span class="res-amt" id="amt-${r}">0</span>
                ${def.capped ? `<span class="res-rate" id="rate-${r}"></span>` : ''}
              </div>`;
    }).join('');
  }

  function refreshTopbar() {
    const cap = Game.storageCap();
    for (const r in DATA.resources) {
      const amtEl = document.getElementById('amt-' + r);
      if (!amtEl) continue;
      const val = Game.state.resources[r] || 0;
      amtEl.textContent = Game.fmt(val);
      const def = DATA.resources[r];
      if (def.capped) {
        amtEl.classList.toggle('full', val >= cap);
        const rateEl = document.getElementById('rate-' + r);
        if (rateEl) {
          const rate = Game.production(r);
          rateEl.textContent = rate > 0 ? '+' + Game.fmt(rate) + '/s' : '';
        }
      }
    }
    const pw = document.getElementById('power-val');
    if (pw) pw.textContent = Game.fmt(Game.power());
  }

  /* ----- Navegação ----------------------------------------------------- */
  function buildNav() {
    const nav = document.getElementById('navbar');
    nav.innerHTML = NAV.map(n =>
      `<button class="nav-btn" data-nav="${n.id}">
         <span class="nav-ico">${n.icon}</span><span class="nav-lbl">${n.label}</span>
       </button>`).join('');
  }

  function navigate(id) {
    if (Combat.running) Combat.stop();
    const screen = document.getElementById('screen');
    const samePage = (Screens.current === id);
    const keepScroll = samePage ? screen.scrollTop : 0;   // preserva scroll em refresh
    Screens.current = id;

    if (id === 'cidade')       screen.innerHTML = Screens.renderCidade();
    else if (id === 'quartel') screen.innerHTML = Screens.renderQuartel();
    else if (id === 'herois')  screen.innerHTML = Screens.renderHerois();
    else if (id === 'batalha') {
      if (!samePage) battleStageView = Game.state.stage;          // ao entrar, mostra o estágio mais avançado
      battleStageView = Math.max(1, Math.min(battleStageView, Game.state.stage));
      screen.innerHTML = Screens.renderBatalha(battleStageView);
      setupBattle();
    }

    document.querySelectorAll('.nav-btn').forEach(b =>
      b.classList.toggle('active', b.getAttribute('data-nav') === id));
    screen.scrollTop = keepScroll;
    refreshTopbar();
  }

  /* ----- Delegação de eventos (cliques) -------------------------------- */
  function onClick(e) {
    const t = e.target.closest('[data-nav],[data-upgrade],[data-train],[data-trainmax],[data-recruit],[data-promote],[data-rush]');
    if (!t) return;

    if (t.dataset.nav) return navigate(t.dataset.nav);

    if (t.dataset.rush) {
      const ok = t.dataset.rush === 'build' ? Game.rushBuild() : Game.rushTraining();
      if (!ok) return toast('Gemas insuficientes para acelerar.', 'warn');
      Game.save();
      refreshScreen();
      return toast('Concluído instantaneamente!', 'ok');
    }

    if (t.dataset.upgrade) {
      const key = t.dataset.upgrade;
      const reason = Game.upgradeBlockReason(key);
      if (reason) return toast(reason, 'warn');
      Game.startUpgrade(key);
      Game.save();
      refreshScreen();
      toast(`${DATA.buildings[key].name}: construção iniciada.`, 'ok');
    }

    if (t.dataset.train || t.dataset.trainmax) {
      const type = t.dataset.train || t.dataset.trainmax;
      let qty;
      if (t.dataset.trainmax) {
        qty = Math.min(Game.maxTrainable(type), affordableQty(type));
        if (qty < 1) return toast('Sem capacidade ou recursos para treinar.', 'warn');
      } else {
        const input = document.querySelector(`input[data-qty="${type}"]`);
        qty = Math.max(1, parseInt(input && input.value, 10) || 1);
      }
      const reason = Game.trainBlockReason(type, qty);
      if (reason) return toast(reason, 'warn');
      Game.startTraining(type, qty);
      Game.save();
      refreshScreen();
      toast(`Treinando ${qty} ${DATA.troops[type].name}.`, 'ok');
    }

    if (t.dataset.recruit) {
      const id = t.dataset.recruit;
      if (!Game.recruitHero(id)) return toast('Recursos insuficientes.', 'warn');
      Game.save();
      refreshScreen();
      toast(`${Game.heroDef(id).name} recrutado!`, 'ok');
    }

    if (t.dataset.promote) {
      const id = t.dataset.promote;
      if (!Game.promoteHero(id)) return toast('Recursos insuficientes.', 'warn');
      Game.save();
      refreshScreen();
      toast(`${Game.heroDef(id).name} promovido!`, 'ok');
    }
  }

  // Quantidade de uma tropa que o jogador consegue pagar (1 lote contínuo).
  function affordableQty(type) {
    const cost = DATA.troops[type].cost;
    let max = Infinity;
    for (const r in cost) max = Math.min(max, Math.floor((Game.state.resources[r] || 0) / cost[r]));
    return isFinite(max) ? max : 0;
  }

  function refreshScreen() {
    navigate(Screens.current);
  }

  /* ----- Combate ------------------------------------------------------- */
  function setupBattle() {
    const canvas = document.getElementById('battle-canvas');
    if (!canvas) return;
    Combat.mount(canvas);
    Combat.resize();

    const startBtn = document.getElementById('battle-start');
    const overlay = document.getElementById('battle-overlay');
    const chargeBtn = document.getElementById('charge-btn');

    document.getElementById('stage-prev').onclick = () => {
      battleStageView = Math.max(1, battleStageView - 1);
      updateStageLabel();
    };
    document.getElementById('stage-next').onclick = () => {
      battleStageView = Math.min(Game.state.stage, battleStageView + 1);
      updateStageLabel();
    };

    startBtn.onclick = () => {
      overlay.classList.add('hidden');
      chargeBtn.hidden = false;
      Combat.start(battleStageView, onBattleEnd);
    };

    chargeBtn.onclick = () => {
      if (Combat.chargeCooldown > 0) return;
      if (!Combat.useCharge()) return;
    };

    // Atualiza o cooldown visual da carga.
    if (window.__chargeRaf) cancelAnimationFrame(window.__chargeRaf);
    const tickCharge = () => {
      if (Screens.current !== 'batalha') return;
      const btn = document.getElementById('charge-btn');
      if (btn && !btn.hidden) {
        if (Combat.chargeCooldown > 0) {
          btn.classList.add('cooling');
          btn.textContent = '🐎 ' + Math.ceil(Combat.chargeCooldown) + 's';
        } else {
          btn.classList.remove('cooling');
          btn.textContent = '🐎 Carga';
        }
      }
      window.__chargeRaf = requestAnimationFrame(tickCharge);
    };
    tickCharge();
  }

  function updateStageLabel() {
    const n = document.getElementById('stage-num');
    const s = document.getElementById('start-stage');
    if (n) n.textContent = battleStageView;
    if (s) s.textContent = battleStageView;
  }

  function onBattleEnd(result) {
    const overlay = document.getElementById('battle-overlay');
    const chargeBtn = document.getElementById('charge-btn');
    if (chargeBtn) chargeBtn.hidden = true;
    if (!overlay) return;

    let rewardsHtml = '';
    if (result.victory && result.rewards) {
      rewardsHtml = '<div class="reward-row">' + Object.keys(result.rewards).map(r =>
        `<span class="chip">${DATA.resources[r].icon} +${Game.fmt(result.rewards[r])}</span>`).join('') + '</div>';
    }
    overlay.querySelector('.overlay-card').innerHTML = `
      <h3>${result.victory ? '🎉 Vitória!' : '💥 A muralha caiu'}</h3>
      <p>${result.victory
            ? `Você defendeu o estágio ${result.stage}!`
            : 'As hordas romperam suas defesas. Treine mais tropas e tente de novo.'}</p>
      ${rewardsHtml}
      <div class="overlay-actions">
        <button class="btn btn-big" id="battle-again">${result.victory ? 'Continuar' : 'Tentar de novo'}</button>
      </div>`;
    overlay.classList.remove('hidden');

    document.getElementById('battle-again').onclick = () => {
      // Vitória: avança para o próximo estágio desbloqueado. Derrota: repete o mesmo.
      battleStageView = result.victory
        ? Math.min(Game.state.stage, result.stage + 1)
        : result.stage;
      navigate('batalha');
    };
    refreshTopbar();
  }

  /* ----- Progresso offline (modal de boas-vindas) ---------------------- */
  function showOfflineReport(report) {
    if (!report || !Object.keys(report.gained).length) return;
    const chips = Object.keys(report.gained).map(r =>
      `<span class="chip">${DATA.resources[r].icon} +${Game.fmt(report.gained[r])}</span>`).join('');
    const modal = document.getElementById('modal');
    modal.innerHTML = `
      <div class="modal-card">
        <h3>👋 Bem-vindo de volta!</h3>
        <p>Sua fortaleza produziu durante <b>${Game.fmtTime(report.seconds)}</b> de ausência:</p>
        <div class="reward-row">${chips}</div>
        <button class="btn btn-big" id="modal-close">Coletar</button>
      </div>`;
    modal.classList.add('show');
    document.getElementById('modal-close').onclick = () => modal.classList.remove('show');
  }

  /* ----- Loop principal ------------------------------------------------ */
  let lastLoop = performance.now();
  function loop() {
    const now = performance.now();
    let dt = (now - lastLoop) / 1000;
    lastLoop = now;
    if (dt > 2) dt = 2;                          // catch-up de períodos longos é feito por applyOffline

    const bq = Game.state.buildQueue;
    const tq = Game.state.trainQueue;
    Game.tick(dt);
    const buildDone = bq && !Game.state.buildQueue;
    const trainDone = tq && !Game.state.trainQueue;
    if (buildDone) toast(`${DATA.buildings[bq.key].name} concluído (Nv ${bq.toLevel}).`, 'ok');
    if (trainDone) toast(`${tq.qty} ${DATA.troops[tq.type].name} prontos para a batalha.`, 'ok');

    refreshTopbar();
    if (Screens.current === 'batalha') {
      /* o combate gerencia o próprio canvas */
    } else if (buildDone || trainDone) {
      navigate(Screens.current);                 // re-render para refletir a conclusão
    } else {
      Screens.refresh();
    }
    requestAnimationFrame(loop);
  }

  /* ----- Inicialização ------------------------------------------------- */
  function init() {
    Game.load();
    const offline = Game.applyOffline();

    buildTopbar();
    buildNav();
    navigate('cidade');

    document.body.addEventListener('click', onClick);

    // Reset (botão no rodapé do menu).
    const resetBtn = document.getElementById('reset-btn');
    if (resetBtn) resetBtn.onclick = () => {
      if (confirm('Reiniciar todo o progresso? Esta ação não pode ser desfeita.')) {
        Game.reset(); Game.save(); navigate('cidade');
        toast('Jogo reiniciado.', 'ok');
      }
    };

    // Salva ao sair; ao voltar, recupera a produção do tempo ausente.
    window.addEventListener('beforeunload', () => Game.save());
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        Game.save();
      } else {
        const r = Game.applyOffline();           // recupera produção e atualiza lastTick
        lastLoop = performance.now();            // evita contar o intervalo duas vezes no loop
        refreshTopbar();
        // Não re-renderiza durante a batalha (resetaria o combate em andamento).
        if (r && Object.keys(r.gained).length && Screens.current !== 'batalha') navigate(Screens.current);
      }
    });
    window.addEventListener('resize', () => { if (Screens.current === 'batalha') Combat.resize(); });

    // Autosave periódico.
    setInterval(() => Game.save(), 10000);

    if (offline) showOfflineReport(offline);

    requestAnimationFrame(loop);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
