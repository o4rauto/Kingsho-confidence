/* ============================================================================
 * Frontier Bastion — Dados e balanceamento
 * ----------------------------------------------------------------------------
 * Jogo original de estratégia de sobrevivência. Toda a nomenclatura, balanço
 * e arte (emoji/CSS) são originais. Inspirado no gênero, sem copiar nenhum
 * conteúdo de jogos existentes.
 * ==========================================================================*/

const DATA = {
  /* Recursos do jogo. `gems` é a moeda premium e não tem teto de estoque. */
  resources: {
    wood:  { name: 'Madeira', icon: '🪵', capped: true  },
    food:  { name: 'Comida',  icon: '🍞', capped: true  },
    stone: { name: 'Pedra',   icon: '🪨', capped: true  },
    gold:  { name: 'Ouro',    icon: '🪙', capped: true  },
    gems:  { name: 'Gemas',   icon: '💎', capped: false },
  },

  /* ------------------------------------------------------------------------
   * Edifícios.
   *   produces   -> { type, base }  produção/segundo no nível 1 (escala c/ nível)
   *   storage    -> capacidade extra de estoque por nível
   *   population -> habitantes por nível (aumenta produção global)
   *   troopCap   -> capacidade de tropas por nível
   *   wallHp     -> HP base da muralha por nível (usado no combate)
   *   prodBonus  -> bônus percentual de produção global por nível
   * baseCost/costFactor e baseTime/timeFactor definem custo e tempo de upgrade.
   * ----------------------------------------------------------------------*/
  buildings: {
    central: {
      name: 'Centro de Comando', icon: '🏰', max: 30,
      desc: 'O coração da fortaleza. Define o nível máximo dos demais edifícios e concentra grande parte do seu poder.',
      baseCost: { wood: 60, stone: 40 }, costFactor: 1.65,
      baseTime: 4, timeFactor: 1.32,
    },
    serraria: {
      name: 'Serraria', icon: '🪚', max: 30,
      desc: 'Derruba e processa toras, gerando Madeira continuamente.',
      produces: { type: 'wood', base: 6 },
      baseCost: { wood: 40, stone: 20 }, costFactor: 1.55,
      baseTime: 3, timeFactor: 1.28,
    },
    fazenda: {
      name: 'Fazenda', icon: '🌾', max: 30,
      desc: 'Cultiva grãos e cria animais, produzindo Comida para sua população e tropas.',
      produces: { type: 'food', base: 6 },
      baseCost: { wood: 35, stone: 25 }, costFactor: 1.55,
      baseTime: 3, timeFactor: 1.28,
    },
    pedreira: {
      name: 'Pedreira', icon: '⛏️', max: 30,
      desc: 'Extrai Pedra das encostas, essencial para construções avançadas.',
      produces: { type: 'stone', base: 4 },
      baseCost: { wood: 50, stone: 20 }, costFactor: 1.58,
      baseTime: 4, timeFactor: 1.29,
    },
    casa_moeda: {
      name: 'Casa da Moeda', icon: '🏦', max: 30,
      desc: 'Cunha moedas a partir do comércio, gerando Ouro com o tempo.',
      produces: { type: 'gold', base: 2 },
      baseCost: { wood: 80, stone: 90 }, costFactor: 1.62,
      baseTime: 6, timeFactor: 1.30,
    },
    armazem: {
      name: 'Armazém', icon: '📦', max: 30,
      desc: 'Aumenta a capacidade de estoque de todos os recursos. Sem espaço, a produção é desperdiçada.',
      storage: 1500,
      baseCost: { wood: 60, stone: 60 }, costFactor: 1.5,
      baseTime: 5, timeFactor: 1.27,
    },
    casas: {
      name: 'Casas', icon: '🏘️', max: 30,
      desc: 'Abriga sobreviventes. Cada habitante aumenta levemente toda a produção da fortaleza.',
      population: 18,
      baseCost: { wood: 45, stone: 30 }, costFactor: 1.5,
      baseTime: 4, timeFactor: 1.26,
    },
    quartel: {
      name: 'Quartel', icon: '⚔️', max: 30,
      desc: 'Treina e abriga tropas. Cada nível eleva sua capacidade militar.',
      troopCap: 40,
      baseCost: { wood: 70, stone: 50, food: 40 }, costFactor: 1.58,
      baseTime: 6, timeFactor: 1.30,
    },
    muralha: {
      name: 'Muralha', icon: '🧱', max: 30,
      desc: 'Protege a fortaleza durante os ataques. Aumenta muito o HP da muralha no combate.',
      wallHp: 220,
      baseCost: { wood: 50, stone: 110 }, costFactor: 1.6,
      baseTime: 6, timeFactor: 1.30,
    },
    academia: {
      name: 'Academia', icon: '📚', max: 30,
      desc: 'Centro de estudos. Eleva a produção global (+4%/nível) e destrava níveis da árvore de Pesquisa.',
      prodBonus: 0.04,
      baseCost: { wood: 90, stone: 80, gold: 30 }, costFactor: 1.62,
      baseTime: 8, timeFactor: 1.31,
    },
  },

  /* ------------------------------------------------------------------------
   * Tropas. Cada unidade custa recursos + tempo (por unidade) e ocupa 1 de
   * capacidade. Os atributos alimentam o combate de defesa:
   *   infantry -> reforça o HP da muralha
   *   archer   -> dispara automaticamente nos invasores
   *   cavalry  -> potencializa a "Carga de Cavalaria" (especial)
   * ----------------------------------------------------------------------*/
  troops: {
    infantry: {
      name: 'Infantaria', icon: '🛡️', power: 4,
      cost: { food: 45, wood: 30 }, time: 6, wallHp: 22,
      desc: 'Segura a linha de frente e reforça o HP da muralha no combate.',
    },
    archer: {
      name: 'Arqueiros', icon: '🏹', power: 5,
      cost: { food: 35, wood: 55 }, time: 8, dps: 7,
      desc: 'Disparam automaticamente contra os invasores mais próximos.',
    },
    cavalry: {
      name: 'Cavalaria', icon: '🐎', power: 8,
      cost: { food: 70, gold: 18 }, time: 11, charge: 60,
      desc: 'Aumenta o dano da Carga de Cavalaria e é essencial nas expedições.',
    },
  },

  /* ------------------------------------------------------------------------
   * Heróis. Recrutados uma vez e promovidos com Ouro. Além do bônus passivo,
   * cada herói concede uma HABILIDADE ATIVA usável no combate de defesa:
   *   heal   -> recupera HP da muralha
   *   shield -> escudo temporário que absorve dano antes da muralha
   *   volley -> rajada de disparos potentes nos inimigos mais próximos
   *   nuke   -> dano em área a todos os invasores na tela
   * ----------------------------------------------------------------------*/
  heroes: [
    {
      id: 'bramble', name: 'Bramble', icon: '🌲', role: 'Provedor', rarity: 'Raro',
      cost: { gold: 4000 }, bonus: { production: 0.10 }, power: 80,
      bonusText: '+10% de produção de recursos',
      lore: 'Guarda-florestal que conhece cada trilha. Mantém os celeiros sempre cheios.',
      skill: { name: 'Suprimentos', icon: '📦', cooldown: 14, type: 'heal', value: 0.12, text: 'Recupera 12% do HP da muralha.' },
    },
    {
      id: 'aurora', name: 'Aurora', icon: '🛡️', role: 'Guardiã', rarity: 'Épico',
      cost: { gems: 280 }, bonus: { defense: 0.18 }, power: 130,
      bonusText: '+18% de HP da muralha',
      lore: 'Comandante da guarda. Sua presença faz a muralha resistir ao impossível.',
      skill: { name: 'Égide', icon: '🛡️', cooldown: 16, type: 'shield', value: 0.30, text: 'Ergue um escudo que absorve dano (30% do HP da muralha).' },
    },
    {
      id: 'corvus', name: 'Corvus', icon: '🎯', role: 'Atirador', rarity: 'Épico',
      cost: { gems: 280 }, bonus: { atk: 0.18 }, power: 130,
      bonusText: '+18% de dano em combate',
      lore: 'Franco-atirador silencioso. Nenhum invasor passa do seu campo de visão.',
      skill: { name: 'Saraivada', icon: '🎯', cooldown: 12, type: 'volley', value: 10, text: 'Dispara 10 tiros certeiros instantâneos.' },
    },
    {
      id: 'vex', name: 'Vex', icon: '⚡', role: 'Estrategista', rarity: 'Lendário',
      cost: { gems: 750 }, bonus: { atk: 0.12, defense: 0.12, production: 0.06 }, power: 240,
      bonusText: '+12% dano, +12% muralha e +6% produção',
      lore: 'Mente brilhante por trás de cada vitória. Transforma recursos escassos em poder.',
      skill: { name: 'Investida Tática', icon: '⚡', cooldown: 18, type: 'nuke', value: 2.2, text: 'Detona uma onda que fere todos os invasores na tela.' },
    },
  ],

  /* ------------------------------------------------------------------------
   * Combate / campanha. Cada estágio tem `waves` ondas; a dificuldade escala
   * com o número do estágio. Recompensas crescem junto.
   * ----------------------------------------------------------------------*/
  combat: {
    wavesPerStage: 5,
    baseShotDamage: 26,       // dano do tiro manual no nível base
    cavalryChargeCooldown: 9, // segundos
    enemyTypes: {
      raider: { name: 'Saqueador', hp: 50,  speed: 34, dmg: 16, gold: 6,  color: '#c0563b', r: 15 },
      runner: { name: 'Batedor',   hp: 30,  speed: 64, dmg: 10, gold: 7,  color: '#3b9ac0', r: 12 },
      brute:  { name: 'Brutamonte', hp: 190, speed: 20, dmg: 42, gold: 16, color: '#7a4ca0', r: 22 },
      boss:   { name: 'Senhor da Horda', hp: 900, speed: 16, dmg: 90, gold: 80, color: '#b8323f', r: 34 },
    },
  },

  /* ------------------------------------------------------------------------
   * Pesquisa (árvore de tecnologia). Cada nó dá um efeito permanente por nível
   * e é destravado pelo nível da Academia (reqAcademy). Tem fila própria,
   * independente da fila de construção.
   *   effect: prod | storage | atk | archer | wall | shot (percentuais)
   *           march (inteiro: +slots de expedição)
   * ----------------------------------------------------------------------*/
  research: {
    eco_forestry: {
      branch: 'Economia', name: 'Silvicultura', icon: '🌲', max: 10, reqAcademy: 1,
      effect: { prod: 0.03 }, effectText: 'produção de recursos',
      baseCost: { wood: 300, food: 200 }, costFactor: 1.55, baseTime: 25, timeFactor: 1.28,
    },
    eco_storage: {
      branch: 'Economia', name: 'Logística', icon: '📦', max: 8, reqAcademy: 2,
      effect: { storage: 0.06 }, effectText: 'capacidade de estoque',
      baseCost: { wood: 350, stone: 250 }, costFactor: 1.55, baseTime: 30, timeFactor: 1.28,
    },
    eco_cartography: {
      branch: 'Economia', name: 'Cartografia', icon: '🗺️', max: 5, reqAcademy: 3,
      effect: { march: 1 }, effectText: 'slots de expedição',
      baseCost: { wood: 600, gold: 250 }, costFactor: 1.7, baseTime: 90, timeFactor: 1.35,
    },
    mil_weapons: {
      branch: 'Militar', name: 'Forja de Armas', icon: '⚔️', max: 10, reqAcademy: 2,
      effect: { atk: 0.04 }, effectText: 'dano em combate',
      baseCost: { stone: 300, gold: 150 }, costFactor: 1.58, baseTime: 35, timeFactor: 1.29,
    },
    mil_archery: {
      branch: 'Militar', name: 'Arquearia', icon: '🏹', max: 10, reqAcademy: 3,
      effect: { archer: 0.05 }, effectText: 'dano dos arqueiros',
      baseCost: { wood: 320, gold: 160 }, costFactor: 1.58, baseTime: 35, timeFactor: 1.29,
    },
    def_masonry: {
      branch: 'Defesa', name: 'Alvenaria', icon: '🧱', max: 10, reqAcademy: 2,
      effect: { wall: 0.04 }, effectText: 'HP da muralha',
      baseCost: { stone: 360, wood: 200 }, costFactor: 1.58, baseTime: 35, timeFactor: 1.29,
    },
    def_traps: {
      branch: 'Defesa', name: 'Armadilhas', icon: '🪤', max: 10, reqAcademy: 4,
      effect: { shot: 0.05 }, effectText: 'dano do seu tiro',
      baseCost: { wood: 280, stone: 280, gold: 120 }, costFactor: 1.6, baseTime: 45, timeFactor: 1.30,
    },
  },

  /* ------------------------------------------------------------------------
   * Expedições (mapa-múndi / PvE). Enviam tropas por um tempo; ao retornar,
   * concedem recompensas. As tropas ficam ocupadas durante a expedição.
   *   need -> tropas reservadas | dur -> segundos | reward -> recursos
   * ----------------------------------------------------------------------*/
  expeditions: {
    forage:   { name: 'Coleta na Mata',     icon: '🌲', dur: 45,  need: 10, reward: { wood: 700, food: 450 } },
    scavenge: { name: 'Saque nas Ruínas',   icon: '🏚️', dur: 90,  need: 20, reward: { stone: 600, gold: 180 } },
    hunt:     { name: 'Caçada à Matilha',   icon: '🐺', dur: 75,  need: 30, reward: { food: 650, gems: 6 } },
    convoy:   { name: 'Escolta de Comboio', icon: '🛒', dur: 150, need: 50, reward: { gold: 500, wood: 900, stone: 600 } },
    expedboss:{ name: 'Toca do Colosso',    icon: '🐲', dur: 240, need: 80, reward: { gold: 1200, gems: 20, stone: 800 } },
  },

  /* ------------------------------------------------------------------------
   * Missões. Objetivos permanentes com recompensa única ao atingir a meta.
   *   type -> power | troops | battles | buildLevels | expeditions | heroes | research
   * ----------------------------------------------------------------------*/
  missions: [
    { id: 'm_build1',  name: 'Erga a fortaleza',   icon: '🏗️', type: 'buildLevels', target: 15,   reward: { wood: 500, stone: 400 } },
    { id: 'm_troops1', name: 'Forme um exército',  icon: '⚔️', type: 'troops',      target: 50,   reward: { food: 600, gold: 150 } },
    { id: 'm_battle1', name: 'Primeira defesa',    icon: '🛡️', type: 'battles',     target: 1,    reward: { gems: 30 } },
    { id: 'm_battle5', name: 'Veterano de guerra', icon: '🎖️', type: 'battles',     target: 5,    reward: { gems: 60, gold: 500 } },
    { id: 'm_exped1',  name: 'Explore o mundo',    icon: '🗺️', type: 'expeditions', target: 3,    reward: { gold: 400, gems: 15 } },
    { id: 'm_hero1',   name: 'Recrute um herói',   icon: '🦸', type: 'heroes',      target: 1,    reward: { gold: 800 } },
    { id: 'm_res1',    name: 'Avanço tecnológico', icon: '🔬', type: 'research',    target: 5,    reward: { gems: 50, wood: 800 } },
    { id: 'm_power1',  name: 'Potência regional',  icon: '⚡', type: 'power',       target: 2000, reward: { gems: 100, gold: 1000 } },
  ],

  /* Recompensa diária (1x por dia real). */
  daily: {
    reward: { wood: 1000, food: 1000, stone: 600, gold: 300, gems: 25 },
  },
};
