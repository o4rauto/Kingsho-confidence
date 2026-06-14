/* ============================================================================
 * Teste de fumaça do motor (sem navegador).
 * Carrega data.js + engine.js num sandbox (vm) e simula ações reais para
 * garantir que a economia, filas, tropas, heróis e combate calculam valores
 * coerentes.  Rode com:  node test/smoke.test.js
 * ==========================================================================*/

const fs = require('fs');
const vm = require('vm');
const path = require('path');

function fakeLocalStorage() {
  const m = {};
  return {
    getItem: (k) => (k in m ? m[k] : null),
    setItem: (k, v) => { m[k] = String(v); },
    removeItem: (k) => { delete m[k]; },
  };
}

const sandbox = {
  console, Date, Math, JSON,
  localStorage: fakeLocalStorage(),
};
vm.createContext(sandbox);

const read = (f) => fs.readFileSync(path.join(__dirname, '..', f), 'utf8');
// `const DATA`/`const Game` ficam no escopo léxico do script (não viram globais),
// então expomos explicitamente no globalThis do sandbox para o teste acessar.
const code = read('js/data.js') + '\n' + read('js/engine.js') +
             '\nglobalThis.DATA = DATA; globalThis.Game = Game;';
vm.runInContext(code, sandbox, { filename: 'engine-bundle.js' });

/* ----- mini framework de asserções ----- */
let passed = 0, failed = 0;
function check(name, cond) {
  if (cond) { passed++; console.log('  ✓ ' + name); }
  else { failed++; console.error('  ✗ ' + name); }
}
function approx(a, b, tol) { return Math.abs(a - b) <= (tol || 1e-6); }

const { DATA, Game } = sandbox;

console.log('\n[1] Estado inicial');
Game.load();
check('estado criado', !!Game.state);
check('recursos iniciais de madeira = 200', Game.state.resources.wood === 200);
check('Centro de Comando começa no nível 1', Game.state.buildings.central === 1);
check('nenhuma tropa inicial', Game.troopCount() === 0);

console.log('\n[2] Produção');
const woodRate = Game.production('wood');
check('serraria produz madeira (>0)', woodRate > 0);
const before = Game.state.resources.wood;
Game.produce(10);
check('produzir 10s aumenta a madeira', Game.state.resources.wood > before);
check('produção respeita ~taxa esperada', approx(Game.state.resources.wood, Math.min(Game.storageCap(), before + woodRate * 10), 1));

console.log('\n[3] Multiplicador de produção');
const baseMult = Game.productionMultiplier();
Game.state.buildings.academia = 5;            // +20%
check('academia aumenta o multiplicador', Game.productionMultiplier() > baseMult);

console.log('\n[4] Construção (fila + conclusão)');
Game.state.resources.wood = 1e6; Game.state.resources.stone = 1e6;
check('upgrade do Centro permitido', Game.upgradeBlockReason('central') === null);
const before4 = Game.state.buildings.central;
Game.startUpgrade('central');
check('fila de construção criada', !!Game.state.buildQueue);
check('segundo upgrade é bloqueado (uma fila só)', Game.upgradeBlockReason('serraria') !== null);
Game.state.buildQueue.endsAt = Date.now() - 1;  // força conclusão
Game.processQueues();
check('nível subiu após concluir', Game.state.buildings.central === before4 + 1);
check('fila liberada', Game.state.buildQueue === null);

console.log('\n[5] Gating pelo Centro de Comando');
Game.state.buildings.central = 3;
check('serraria limitada ao nível do Centro', Game.maxLevelFor('serraria') === 3);

console.log('\n[6] Tropas');
check('treino bloqueado sem quartel', Game.trainBlockReason('infantry', 1) === 'Construa o Quartel primeiro.');
Game.state.buildings.quartel = 3;             // capacidade 120
Game.state.resources.food = 1e6; Game.state.resources.wood = 1e6; Game.state.resources.gold = 1e6;
check('capacidade de tropas = 120', Game.troopCap() === 120);
check('treino agora permitido', Game.trainBlockReason('infantry', 5) === null);
Game.startTraining('infantry', 5);
check('fila de treino criada', !!Game.state.trainQueue);
Game.state.trainQueue.endsAt = Date.now() - 1;
Game.processQueues();
check('5 infantarias adicionadas', Game.state.troops.infantry === 5);
check('treino acima da capacidade é bloqueado', Game.trainBlockReason('infantry', 999) === 'Capacidade de tropas excedida.');

console.log('\n[7] Heróis');
Game.state.resources.gems = 5000; Game.state.resources.gold = 50000;
const pBefore = Game.power();
check('recrutar Aurora', Game.recruitHero('aurora') === true);
check('não recruta duas vezes', Game.recruitHero('aurora') === false);
check('poder aumentou após recrutar', Game.power() > pBefore);
const defBonusBefore = Game.heroBonus('defense');
check('Aurora concede bônus de defesa', defBonusBefore > 0);
check('promover Aurora', Game.promoteHero('aurora') === true);
check('bônus de defesa escala com nível', Game.heroBonus('defense') > defBonusBefore);

console.log('\n[8] Combate (valores derivados)');
check('HP da muralha > 0', Game.wallMaxHp() > 0);
const wallNoInf = Game.wallMaxHp();
Game.state.troops.infantry += 20;
check('infantaria reforça a muralha', Game.wallMaxHp() > wallNoInf);
check('dano de tiro > 0', Game.shotDamage() > 0);
Game.state.troops.archer = 10;
check('arqueiros geram DPS', Game.archerDps() > 0);
Game.state.troops.cavalry = 8;
check('cavalaria aumenta a carga', Game.chargeDamage() > 200);

console.log('\n[9] Persistência e offline');
Game.save();
const json = sandbox.localStorage.getItem(Game.SAVE_KEY);
check('save gravado no localStorage', !!json && json.length > 10);
// Simula 1h de ausência.
Game.state.lastTick = Date.now() - 3600 * 1000;
Game.state.resources.wood = 0;
const report = Game.applyOffline();
check('relatório offline retornado', !!report && report.seconds >= 3600);
check('produção offline gerou madeira', (report.gained.wood || 0) > 0);

console.log('\n[10] Formatação');
check('fmt 1500 -> 1.5K', Game.fmt(1500) === '1.5K');
check('fmt 2_000_000 -> 2.0M', Game.fmt(2000000) === '2.0M');
check('fmt 25_000_000 -> 25M', Game.fmt(25000000) === '25M');
check('fmtTime 90 -> 1m 30s', Game.fmtTime(90) === '1m 30s');

console.log('\n[11] Pesquisa');
Game.state.buildings.academia = 5;
Game.state.research = {};
Game.state.researchQueue = null;
Game.state.resources.wood = 1e7; Game.state.resources.food = 1e7; Game.state.resources.stone = 1e7; Game.state.resources.gold = 1e7;
check('pesquisa exige Academia', (function () {
  const a = Game.state.buildings.academia; Game.state.buildings.academia = 0;
  const r = Game.researchBlockReason('mil_weapons'); Game.state.buildings.academia = a;
  return /Academia/.test(r);
})());
const prodMultBefore = Game.productionMultiplier();
check('iniciar Silvicultura', Game.startResearch('eco_forestry') === true);
check('fila de pesquisa criada', !!Game.state.researchQueue);
check('2ª pesquisa bloqueada (fila única)', Game.researchBlockReason('mil_weapons') !== null);
Game.state.researchQueue.endsAt = Date.now() - 1;
Game.processQueues();
check('nível de pesquisa aplicado', (Game.state.research.eco_forestry || 0) === 1);
check('bônus de produção da pesquisa ativo', Game.researchBonus('prod') > 0);
check('multiplicador de produção subiu', Game.productionMultiplier() > prodMultBefore);

console.log('\n[12] Expedições');
Game.state.expeditions = [];
Game.state.research.eco_cartography = 0;
Game.state.troops = { infantry: 100, archer: 0, cavalry: 0 };
check('1 slot de marcha por padrão', Game.marchSlots() === 1);
const avail0 = Game.availableTroops();
check('iniciar Coleta na Mata', Game.startExpedition('forage') === true);
check('tropas ocupadas = need', Game.busyTroops() === DATA.expeditions.forage.need);
check('tropas livres reduzem', Game.availableTroops() === avail0 - DATA.expeditions.forage.need);
check('2ª expedição bloqueada (sem slot)', Game.expeditionBlockReason('scavenge') === 'Sem slots de marcha livres.');
Game.state.research.eco_cartography = 1;
check('cartografia adiciona slot de marcha', Game.marchSlots() === 2);
Game.state.resources.wood = 0; Game.state.resources.food = 0;
const expDoneBefore = Game.state.stats.expeditionsDone;
Game.state.expeditions[0].endsAt = Date.now() - 1;
Game.processQueues();
check('expedição concluída libera o slot', Game.busyTroops() === 0);
check('recompensa de expedição creditada', Game.state.resources.wood === DATA.expeditions.forage.reward.wood);
check('expedição contabilizada', Game.state.stats.expeditionsDone === expDoneBefore + 1);

console.log('\n[13] Missões');
Game.state.missionsClaimed = {};
Game.state.stats.battlesWon = 5;
const mBattle = DATA.missions.find(m => m.id === 'm_battle1');
check('progresso reflete os stats', Game.missionProgress(mBattle) === 5);
check('missão atingida é resgatável', Game.missionClaimable(mBattle) === true);
const gemsBeforeM = Game.state.resources.gems;
check('resgatar missão', Game.claimMission('m_battle1') === true);
check('recompensa da missão creditada', Game.state.resources.gems === gemsBeforeM + mBattle.reward.gems);
check('missão não resgata 2x', Game.claimMission('m_battle1') === false);

console.log('\n[14] Recompensa diária');
Game.state.dailyClaim = null;
check('pode resgatar diária', Game.canClaimDaily() === true);
const gemsBeforeD = Game.state.resources.gems;
check('resgatar diária', Game.claimDaily() === true);
check('gemas da diária creditadas', Game.state.resources.gems === gemsBeforeD + DATA.daily.reward.gems);
check('não resgata diária 2x', Game.canClaimDaily() === false && Game.claimDaily() === false);
check('claimableCount é numérico', typeof Game.claimableCount() === 'number');

console.log(`\nResultado: ${passed} passou(aram), ${failed} falhou(aram).`);
process.exit(failed ? 1 : 0);
