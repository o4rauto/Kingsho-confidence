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
      desc: 'Estuda técnicas que elevam a produção global de recursos (+4% por nível).',
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
      desc: 'Aumenta o dano da Carga de Cavalaria, seu especial em batalha.',
    },
  },

  /* ------------------------------------------------------------------------
   * Heróis. Recrutados uma vez (pagando o custo) e podem ser promovidos com
   * Ouro para ganhar poder e reforçar o bônus. `bonus` aceita:
   *   production -> +% produção global
   *   atk        -> +% dano em combate
   *   defense    -> +% HP da muralha
   * ----------------------------------------------------------------------*/
  heroes: [
    {
      id: 'bramble', name: 'Bramble', icon: '🌲', role: 'Provedor', rarity: 'Raro',
      cost: { gold: 4000 }, bonus: { production: 0.10 }, power: 80,
      bonusText: '+10% de produção de recursos',
      lore: 'Guarda-florestal que conhece cada trilha. Mantém os celeiros sempre cheios.',
    },
    {
      id: 'aurora', name: 'Aurora', icon: '🛡️', role: 'Guardiã', rarity: 'Épico',
      cost: { gems: 280 }, bonus: { defense: 0.18 }, power: 130,
      bonusText: '+18% de HP da muralha',
      lore: 'Comandante da guarda. Sua presença faz a muralha resistir ao impossível.',
    },
    {
      id: 'corvus', name: 'Corvus', icon: '🎯', role: 'Atirador', rarity: 'Épico',
      cost: { gems: 280 }, bonus: { atk: 0.18 }, power: 130,
      bonusText: '+18% de dano em combate',
      lore: 'Franco-atirador silencioso. Nenhum invasor passa do seu campo de visão.',
    },
    {
      id: 'vex', name: 'Vex', icon: '⚡', role: 'Estrategista', rarity: 'Lendário',
      cost: { gems: 750 }, bonus: { atk: 0.12, defense: 0.12, production: 0.06 }, power: 240,
      bonusText: '+12% dano, +12% muralha e +6% produção',
      lore: 'Mente brilhante por trás de cada vitória. Transforma recursos escassos em poder.',
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
};
