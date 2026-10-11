extends Node
## GameData — all data-driven content for Bastion Rush.
##
## Every champion / enemy has an `id` that is also its ASSET SLOT:
## drop `res://assets/models/<id>.glb` (built with the AI → Blender → Mixamo
## pipeline in /pipeline) and the game uses it instead of the placeholder.

const RARITY_COLOR := {
	"common": Color("9fb0d0"),
	"rare": Color("4ea3ff"),
	"epic": Color("c06bff"),
	"legendary": Color("ffb033"),
}

const BASTION_MAX := 100.0
const MAX_LEVEL := 10
const EVOLVE_LEVELS := [5, 10]     # ★ at 5, ★★ at 10 — automatic, no extra currency
const GROWTH_PER_LEVEL := 0.08
const EVOLVE_BONUS := 0.15
const DECK_SIZE := 4
const BUILD_GOLD_PER_COST := 30     # in-battle build price = cost × this
const TIER_MUL := [1.0, 1.5, 2.1]   # in-battle upgrades on a build spot
const SELL_REFUND := 0.6
const HERO_MAX_LEVEL := 20

## The hero you control. Name and cape are editable on the Hero screen.
const HERO := {
	"speed": 6.0, "max_hp": 140.0, "fire_cd": 0.55, "proj_speed": 18.0,
	"damage": 15.0, "range": 8.5, "ult_max": 100.0,
	"name": "Kael", "title": "O Último Guardião da Chama",
	"lore": "Kael era só o aprendiz do faroleiro da Torre do Sol. Quando a Torre se partiu e a Debandada jorrou da fenda, a última brasa da Chama caiu nas mãos dele — e não queimou. Desde então, onde Kael pisa, a luz resiste. Ele não é rei nem soldado: é o guardião que sobrou. Cada reino retomado reacende um pedaço da Torre.",
	"ult_name": "Chuva de Brasas", "ult_desc": "Dispara 16 flechas em círculo e atordoa quem estiver perto.",
}
const CAPES := [
	["Brasa", Color("e8452c")], ["Real", Color("3d6bff")], ["Bosque", Color("3fae4f")],
	["Noite", Color("6a3ab8")], ["Ouro", Color("f2b632")], ["Neve", Color("e8f0ff")],
]
const ROLE_NAME := {"melee": "Especialista de Quartel", "ranged": "Especialista de Arqueiros", "tower": "Especialista", "support": "Especialista Arcana"}

## The four tower families you can build on any stone spot (Kingdom-Rush
## structure). Tiers 1-3 are upgrades; at tier 3 you can SPECIALIZE into one
## of the family's champions (unlocked by conquering realms).
const TOWER_ORDER := ["archer", "barracks", "mage", "artillery"]
const TOWERS := {
	"archer": {"name": "Torre de Arqueiros", "icon": "bow", "color": Color("54d06a"),
		"cost": [70, 110, 160], "damage": [11.0, 19.0, 29.0], "rate": [0.8, 0.7, 0.6], "range": [6.5, 7.0, 7.6],
		"desc": "Flechas rápidas. Acerta voadores."},
	"barracks": {"name": "Quartel", "icon": "helmet", "color": Color("ff7a2a"),
		"cost": [70, 110, 160], "damage": [8.0, 13.0, 20.0], "hp": [110.0, 170.0, 250.0], "rate": [1.0, 1.0, 1.0], "range": [4.0, 4.0, 4.0],
		"desc": "Três soldados SEGURAM os inimigos na estrada."},
	"mage": {"name": "Torre Arcana", "icon": "orb", "color": Color("a46aff"),
		"cost": [100, 140, 200], "damage": [22.0, 40.0, 62.0], "rate": [1.5, 1.5, 1.4], "range": [6.0, 6.4, 6.8],
		"desc": "Raios mágicos que ignoram armadura."},
	"artillery": {"name": "Bombarda", "icon": "bomb", "color": Color("c8a070"),
		"cost": [125, 170, 240], "damage": [18.0, 33.0, 52.0], "rate": [3.0, 3.0, 2.8], "range": [7.5, 8.0, 8.5], "splash": [1.6, 1.8, 2.0],
		"desc": "Bombas que explodem em área. Não acertam voadores."},
}
const SPEC_MUL := 2.1

func spec_cost(def: Dictionary) -> int:
	return 150 + int(def.cost) * 20

func family_specs(fam: String) -> Array:
	var out: Array = []
	for c in champions:
		if c.family == fam: out.append(c)
	return out

## Star upgrade tree: 6 columns × 4 tiers; costs grow per tier.
const UPGRADE_COSTS := [1, 2, 3, 4]
const UPGRADES := [
	{"id": "archer", "name": "Arqueiros", "icon": "bow", "color": Color("54d06a"), "tiers": [
		{"name": "Flechas Afiadas", "desc": "+10% dano dos arqueiros", "mods": {"archer_dmg": 0.10}},
		{"name": "Olho de Águia", "desc": "+10% alcance dos arqueiros", "mods": {"archer_range": 0.10}},
		{"name": "Penas de Grifo", "desc": "+15% dano dos arqueiros", "mods": {"archer_dmg": 0.15}},
		{"name": "Ponta Perfurante", "desc": "Flechas atravessam 1 inimigo", "mods": {"archer_pierce": 1.0}}]},
	{"id": "barracks", "name": "Quartel", "icon": "helmet", "color": Color("ff7a2a"), "tiers": [
		{"name": "Cota de Malha", "desc": "+20% vida dos soldados", "mods": {"barracks_hp": 0.20}},
		{"name": "Treino Pesado", "desc": "+15% dano dos soldados", "mods": {"barracks_dmg": 0.15}},
		{"name": "Reforços", "desc": "Soldados voltam 40% mais rápido", "mods": {"barracks_respawn": 0.40}},
		{"name": "Escudo Torre", "desc": "Soldados recebem 25% menos dano", "mods": {"barracks_armor": 0.25}}]},
	{"id": "mage", "name": "Magos", "icon": "orb", "color": Color("a46aff"), "tiers": [
		{"name": "Foco Arcano", "desc": "+10% dano mágico", "mods": {"mage_dmg": 0.10}},
		{"name": "Runas Velozes", "desc": "+15% velocidade de ataque", "mods": {"mage_rate": 0.15}},
		{"name": "Visão Astral", "desc": "+10% alcance mágico", "mods": {"mage_range": 0.10}},
		{"name": "Feitiço Lento", "desc": "Magia deixa inimigos lentos", "mods": {"mage_slow": 0.3}}]},
	{"id": "artillery", "name": "Bombarda", "icon": "bomb", "color": Color("c8a070"), "tiers": [
		{"name": "Pólvora Fina", "desc": "+12% dano das bombas", "mods": {"artillery_dmg": 0.12}},
		{"name": "Estilhaços", "desc": "+20% área de explosão", "mods": {"artillery_splash": 0.20}},
		{"name": "Mira Longa", "desc": "+10% alcance das bombas", "mods": {"artillery_range": 0.10}},
		{"name": "Napalm", "desc": "Bombas deixam inimigos em chamas", "mods": {"artillery_burn": 10.0}}]},
	{"id": "hero", "name": "Herói", "icon": "helmet_hero", "color": Color("e8452c"), "tiers": [
		{"name": "Treino I", "desc": "Herói +10% vida e dano", "mods": {"hero_power": 0.10}},
		{"name": "Treino II", "desc": "Herói +10% vida e dano", "mods": {"hero_power": 0.10}},
		{"name": "Botas Aladas", "desc": "Herói +15% velocidade", "mods": {"hero_speed": 0.15}},
		{"name": "Brasa Viva", "desc": "Especial carrega 40% mais rápido", "mods": {"hero_ult": 0.40}}]},
	{"id": "bastion", "name": "Bastião", "icon": "shield", "color": Color("9aa4b8"), "tiers": [
		{"name": "Muralhas", "desc": "+20 vida do Bastião", "mods": {"bastion_hp": 20.0}},
		{"name": "Cofre", "desc": "+50 ouro inicial", "mods": {"start_gold": 50.0}},
		{"name": "Pedreiros", "desc": "Bastião recupera 5 por onda", "mods": {"repair": 5.0}},
		{"name": "Tesouro Real", "desc": "+60 ouro inicial", "mods": {"start_gold": 60.0}}]},
]

const STORY := [
	"Por mil anos a Torre do Sol guardou a Chama que mantinha o mundo aceso.",
	"Uma noite ela se partiu. Da rachadura saiu a DEBANDADA: monstros que correm sem parar em direção a qualquer luz.",
	"Restou um Bastião. Restou um guardião. Restou você.",
	"Construa defesas nas plataformas, comande seu herói e retome os 10 reinos até a Torre partida.",
]

# role: melee (barracks: soldiers hold the road) | ranged | tower | support — all act on their own
# unlock_after: realms you must conquer before it joins your collection.
var champions: Array[Dictionary] = [
	{"id": "pyre_knight", "family": "barracks", "name": "Cavaleiro da Pira", "title": "Vanguarda de Brasa", "role": "melee", "rarity": "common", "cost": 3,
	 "hp": 190.0, "damage": 14.0, "atk_speed": 1.0, "range": 1.4, "count": 2, "color": Color("ff7a2a"), "unlock_after": 0,
	 "lore": "Juraram queimar em dobro para que o Bastião nunca apague.", "ability": "Dois cavaleiros SEGURAM os inimigos na estrada e queimam quem luta com eles. Renascem se caírem.",
	 "evo": ["Armadura em brasa: queima mais forte", "Três cavaleiros em vez de dois"]},
	{"id": "thistle_archer", "family": "archer", "name": "Arqueira do Cardo", "title": "Atiradora do Bosque", "role": "ranged", "rarity": "common", "cost": 2,
	 "hp": 70.0, "damage": 13.0, "atk_speed": 1.4, "range": 6.5, "count": 1, "color": Color("54d06a"), "unlock_after": 0,
	 "lore": "Disparou a primeira flecha contra a fenda na noite em que a Torre caiu.", "ability": "Barata e rápida. Acerta voadores.",
	 "evo": ["Flechas duplas", "Alcance +25%"]},
	{"id": "runestone", "family": "artillery", "name": "Pedra Rúnica", "title": "Catapulta Arcana", "role": "tower", "rarity": "common", "cost": 4,
	 "hp": 260.0, "damage": 30.0, "atk_speed": 0.5, "range": 8.0, "count": 1, "color": Color("37b6ff"), "unlock_after": 0,
	 "lore": "Um glifo antigo acordado para arremessar pedras rúnicas.", "ability": "Pedras rúnicas explodem em área e ignoram armadura.",
	 "evo": ["Explosão maior", "Dano +30%"]},
	{"id": "sister_vale", "family": "mage", "name": "Irmã Vale", "title": "Guardiã do Santuário", "role": "support", "rarity": "common", "cost": 4,
	 "hp": 120.0, "damage": 10.0, "atk_speed": 0.8, "range": 5.5, "count": 1, "color": Color("ffe08a"), "unlock_after": 0,
	 "lore": "Seus hinos costuram carne rasgada.", "ability": "Cura soldados e o herói por perto. Sem feridos, castiga inimigos com luz.",
	 "evo": ["Cura em área", "Luz sagrada deixa lento"]},
	{"id": "wolf_pack", "family": "barracks", "name": "Matilha Oca", "title": "Caçadores da Sombra", "role": "melee", "rarity": "rare", "cost": 4,
	 "hp": 90.0, "damage": 11.0, "atk_speed": 1.7, "range": 1.3, "count": 3, "color": Color("94a3c8"), "unlock_after": 1,
	 "lore": "Três sombras com dentes.", "ability": "Três lobos rápidos seguram a estrada. Renascem depressa.",
	 "evo": ["Mordida sangra", "Quatro lobos"]},
	{"id": "frost_warden", "family": "archer", "name": "Guardiã do Gelo", "title": "O Longo Inverno", "role": "tower", "rarity": "rare", "cost": 5,
	 "hp": 200.0, "damage": 14.0, "atk_speed": 0.9, "range": 7.0, "count": 1, "color": Color("8fe9ff"), "unlock_after": 2,
	 "lore": "Onde ela respira, a Debandada desacelera.", "ability": "Tiros deixam os inimigos lentos.",
	 "evo": ["Lentidão mais forte", "Congela por um instante"]},
	{"id": "boulder_golem", "family": "barracks", "name": "Golem de Pedra", "title": "O Inabalável", "role": "melee", "rarity": "epic", "cost": 6,
	 "hp": 900.0, "damage": 30.0, "atk_speed": 0.7, "range": 1.8, "count": 1, "color": Color("8a8478"), "unlock_after": 3,
	 "lore": "Esculpido da própria muralha do Bastião.", "ability": "Um gigante que segura até 3 inimigos de uma vez.",
	 "evo": ["Pancada atordoa", "Vida +40%"]},
	{"id": "stormcaller", "family": "mage", "name": "Invocadora da Tempestade", "title": "Voz do Trovão", "role": "tower", "rarity": "epic", "cost": 6,
	 "hp": 180.0, "damage": 26.0, "atk_speed": 0.85, "range": 8.0, "count": 1, "color": Color("6b7bff"), "unlock_after": 4,
	 "lore": "Ela chama a tempestade e a tempestade obedece.", "ability": "Raios saltam para mais 2 inimigos.",
	 "evo": ["Salta para 3", "Salta para 4"]},
	{"id": "sunspear_lancer", "family": "barracks", "name": "Lanceiro do Sol", "title": "Primeira Luz", "role": "melee", "rarity": "epic", "cost": 5,
	 "hp": 260.0, "damage": 34.0, "atk_speed": 1.1, "range": 2.0, "count": 2, "color": Color("ffbf5e"), "unlock_after": 5,
	 "lore": "Cavalga pela estrada deixando o amanhecer para trás.", "ability": "Dois lanceiros de dano altíssimo seguram a estrada.",
	 "evo": ["Golpe crítico", "Dano +30%"]},
	{"id": "ashen_queen", "family": "artillery", "name": "A Rainha das Cinzas", "title": "Última da Torre do Sol", "role": "support", "rarity": "legendary", "cost": 7,
	 "hp": 300.0, "damage": 40.0, "atk_speed": 0.7, "range": 6.0, "count": 1, "color": Color("f25a2a"), "unlock_after": 7,
	 "lore": "Ela usava a coroa quando a Torre queimou.", "ability": "Explosão de fogo atinge TODOS os inimigos em volta.",
	 "evo": ["Explosão maior", "Deixa o chão em chamas"]},
]

## Achievements: stat → target → gold reward.
const ACHIEVEMENTS := [
	{"id": "first_blood", "name": "Primeiro Sangue", "desc": "Derrote 1 inimigo", "stat": "kills", "target": 1, "gold": 50},
	{"id": "slayer", "name": "Caçador", "desc": "Derrote 300 inimigos", "stat": "kills", "target": 300, "gold": 150},
	{"id": "legend", "name": "Lenda da Chama", "desc": "Derrote 3000 inimigos", "stat": "kills", "target": 3000, "gold": 600},
	{"id": "builder", "name": "Mestre de Obras", "desc": "Construa 40 defesas", "stat": "builds", "target": 40, "gold": 150},
	{"id": "bosses", "name": "Matador de Chefes", "desc": "Derrote 5 chefes", "stat": "bosses", "target": 5, "gold": 300},
	{"id": "realm1", "name": "A Primeira Luz", "desc": "Conquiste 1 reino", "stat": "cleared", "target": 1, "gold": 100},
	{"id": "realm5", "name": "Meio Caminho", "desc": "Conquiste 5 reinos", "stat": "cleared", "target": 5, "gold": 400},
	{"id": "realm10", "name": "A Torre Reacesa", "desc": "Conquiste os 10 reinos", "stat": "cleared", "target": 10, "gold": 1500},
	{"id": "stars15", "name": "Constelação", "desc": "Junte 15 estrelas", "stat": "stars", "target": 15, "gold": 250},
	{"id": "stars30", "name": "Céu Completo", "desc": "Junte as 30 estrelas", "stat": "stars", "target": 30, "gold": 1000},
	{"id": "hero10", "name": "Veterano", "desc": "Herói no nível 10", "stat": "hero_level", "target": 10, "gold": 300},
	{"id": "evolve", "name": "Evolução", "desc": "Evolua um campeão (nível 5)", "stat": "max_champ_level", "target": 5, "gold": 200},
]

# kind (behaviour + placeholder archetype): runner | brute | flyer | caster | boss
# Optional traits: armor (0..1 dmg reduction), shield (absorb hp), regen (hp/s),
# split [id, n] (on death), heal (caster heals allies), burn_touch (hurts champions),
# ability (bosses): summon | charge | shield | slam | split
var enemies: Dictionary = {
	# ── Ruins (Broken Gate) ──
	"wisp": {"name": "Fagulha da Fenda", "kind": "runner", "hp": 36.0, "damage": 6.0, "speed": 2.4, "radius": 0.45, "bounty": 4, "breach": 4, "color": Color("ff4d7d")},
	"husk": {"name": "Casca Cinzenta", "kind": "runner", "hp": 70.0, "damage": 10.0, "speed": 1.8, "radius": 0.55, "bounty": 6, "breach": 7, "color": Color("c0286a")},
	"ravager": {"name": "Devastador", "kind": "brute", "hp": 220.0, "damage": 20.0, "speed": 1.35, "radius": 0.75, "bounty": 14, "breach": 12, "color": Color("8a1f4a")},
	"the_maw": {"name": "A Bocarra", "kind": "boss", "hp": 1320.0, "damage": 40.0, "speed": 0.95, "radius": 1.4, "bounty": 160, "breach": 30, "color": Color("8a1f4a"), "ability": "charge"},
	# ── Forest (Emberfall Wood) ──
	"ember_imp": {"name": "Diabrete de Brasa", "kind": "runner", "hp": 50.0, "damage": 9.0, "speed": 3.0, "radius": 0.42, "bounty": 6, "breach": 5, "color": Color("ff7a2a"), "burn_touch": 8.0},
	"sapling": {"name": "Muda em Chamas", "kind": "brute", "hp": 240.0, "damage": 18.0, "speed": 1.2, "radius": 0.8, "bounty": 15, "breach": 12, "color": Color("6b4a22"), "regen": 6.0},
	"gloombat": {"name": "Morcego Sombrio", "kind": "flyer", "hp": 44.0, "damage": 8.0, "speed": 3.2, "radius": 0.5, "bounty": 8, "breach": 6, "color": Color("a267d6")},
	"cinder_treant": {"name": "Ent de Cinzas", "kind": "boss", "hp": 1870.0, "damage": 45.0, "speed": 0.8, "radius": 1.5, "bounty": 200, "breach": 30, "color": Color("4a2e14"), "ability": "summon", "summon": "ember_imp", "regen": 15.0},
	# ── Swamp (Sunken March) ──
	"drowned": {"name": "Soldado Afogado", "kind": "runner", "hp": 90.0, "damage": 12.0, "speed": 1.6, "radius": 0.55, "bounty": 8, "breach": 8, "color": Color("4f7a7a"), "shield": 40.0},
	"bog_lurker": {"name": "Espreitador do Brejo", "kind": "brute", "hp": 300.0, "damage": 22.0, "speed": 1.1, "radius": 0.85, "bounty": 18, "breach": 14, "color": Color("2f4a3a"), "armor": 0.25},
	"hexmage": {"name": "Mago do Feitiço", "kind": "caster", "hp": 120.0, "damage": 16.0, "speed": 1.5, "radius": 0.6, "bounty": 16, "breach": 14, "color": Color("d14bff")},
	"drowned_king": {"name": "O Rei Afogado", "kind": "boss", "hp": 2310.0, "damage": 50.0, "speed": 0.85, "radius": 1.5, "bounty": 240, "breach": 30, "color": Color("2a5a6a"), "ability": "shield", "shield": 600.0},
	# ── Keep (Hollow Keep) ──
	"sentry": {"name": "Sentinela Oca", "kind": "caster", "hp": 120.0, "damage": 18.0, "speed": 1.3, "radius": 0.6, "bounty": 18, "breach": 14, "color": Color("7a7f9a"), "armor": 0.35},
	"knight": {"name": "Cavaleiro Oco", "kind": "brute", "hp": 300.0, "damage": 26.0, "speed": 1.25, "radius": 0.8, "bounty": 22, "breach": 16, "color": Color("3a3f5a"), "armor": 0.3},
	"siege_titan": {"name": "Titã de Cerco", "kind": "boss", "hp": 2860.0, "damage": 55.0, "speed": 0.75, "radius": 1.7, "bounty": 280, "breach": 30, "color": Color("5a1730"), "ability": "slam", "armor": 0.3},
	# ── Rift (Rift Throne) ──
	"void_spawn": {"name": "Cria do Vazio", "kind": "runner", "hp": 80.0, "damage": 10.0, "speed": 2.2, "radius": 0.5, "bounty": 7, "breach": 7, "color": Color("6a2aa8"), "split": ["void_mite", 2]},
	"void_mite": {"name": "Ácaro do Vazio", "kind": "runner", "hp": 24.0, "damage": 5.0, "speed": 3.0, "radius": 0.3, "bounty": 2, "breach": 3, "color": Color("a46aff")},
	"ogre": {"name": "Ogro da Fenda", "kind": "brute", "hp": 520.0, "damage": 34.0, "speed": 1.1, "radius": 0.95, "bounty": 30, "breach": 22, "color": Color("7a2140")},
	"rift_sovereign": {"name": "Soberano da Fenda", "kind": "boss", "hp": 3850.0, "damage": 65.0, "speed": 0.9, "radius": 1.7, "bounty": 380, "breach": 30, "color": Color("2a0f3a"), "ability": "summon", "summon": "void_spawn"},
	# ── Ice (Frostpeak Pass) ──
	"ice_wisp": {"name": "Fagulha de Gelo", "kind": "flyer", "hp": 60.0, "damage": 8.0, "speed": 3.0, "radius": 0.45, "bounty": 8, "breach": 6, "color": Color("bdf2ff")},
	"yeti": {"name": "Yeti", "kind": "brute", "hp": 480.0, "damage": 36.0, "speed": 1.15, "radius": 1.0, "bounty": 32, "breach": 22, "color": Color("e8f2ff"), "regen": 8.0},
	"frost_wyrm": {"name": "Serpe Gélida", "kind": "boss", "hp": 4400.0, "damage": 60.0, "speed": 1.0, "radius": 1.7, "bounty": 420, "breach": 30, "color": Color("5ab0d8"), "ability": "charge"},
	# ── Desert (Sunscar Dunes) ──
	"scorpion": {"name": "Escorpião das Dunas", "kind": "runner", "hp": 80.0, "damage": 14.0, "speed": 2.6, "radius": 0.55, "bounty": 10, "breach": 9, "color": Color("c98a3a"), "armor": 0.2},
	"sand_wraith": {"name": "Espectro de Areia", "kind": "flyer", "hp": 70.0, "damage": 12.0, "speed": 2.8, "radius": 0.55, "bounty": 11, "breach": 8, "color": Color("e8c88a")},
	"sand_colossus": {"name": "Colosso de Areia", "kind": "boss", "hp": 5220.0, "damage": 70.0, "speed": 0.7, "radius": 1.9, "bounty": 480, "breach": 30, "color": Color("a8803a"), "ability": "split", "split": ["scorpion", 6]},
	# ── Volcano (Ashen Caldera) ──
	"magma_slime": {"name": "Gosma de Magma", "kind": "brute", "hp": 260.0, "damage": 20.0, "speed": 1.4, "radius": 0.8, "bounty": 16, "breach": 12, "color": Color("ff5a1a"), "split": ["fire_imp", 2], "burn_touch": 10.0},
	"fire_imp": {"name": "Diabrete de Fogo", "kind": "runner", "hp": 70.0, "damage": 10.0, "speed": 3.1, "radius": 0.4, "bounty": 6, "breach": 6, "color": Color("ffb03a"), "burn_touch": 8.0},
	"magma_tyrant": {"name": "Tirano de Magma", "kind": "boss", "hp": 6050.0, "damage": 75.0, "speed": 0.8, "radius": 1.9, "bounty": 540, "breach": 30, "color": Color("b8300f"), "ability": "slam", "burn_touch": 20.0},
	# ── Mire (Gloomroot) ──
	"spore_toad": {"name": "Sapo de Esporos", "kind": "caster", "hp": 160.0, "damage": 14.0, "speed": 1.4, "radius": 0.65, "bounty": 16, "breach": 12, "color": Color("9be24d"), "heal": 30.0},
	"root_horror": {"name": "Horror de Raízes", "kind": "brute", "hp": 700.0, "damage": 34.0, "speed": 1.0, "radius": 1.0, "bounty": 34, "breach": 22, "color": Color("3a5a1a"), "regen": 14.0},
	"bog_mother": {"name": "Mãe do Pântano", "kind": "boss", "hp": 6880.0, "damage": 70.0, "speed": 0.75, "radius": 2.0, "bounty": 600, "breach": 30, "color": Color("4a6a2a"), "ability": "summon", "summon": "spore_toad", "regen": 30.0},
	# ── Sunspire (finale) ──
	"eclipse_knight": {"name": "Cavaleiro do Eclipse", "kind": "brute", "hp": 760.0, "damage": 40.0, "speed": 1.2, "radius": 0.95, "bounty": 38, "breach": 24, "color": Color("2a2440"), "armor": 0.35, "shield": 150.0},
	"radiant_shade": {"name": "Sombra Radiante", "kind": "flyer", "hp": 140.0, "damage": 16.0, "speed": 3.0, "radius": 0.55, "bounty": 14, "breach": 10, "color": Color("fff0b0")},
	"the_eclipse": {"name": "O Eclipse", "kind": "boss", "hp": 9900.0, "damage": 90.0, "speed": 0.85, "radius": 2.1, "bounty": 1000, "breach": 30, "color": Color("1a1428"), "ability": "shield", "shield": 2500.0},
}

# Each boon: id, name, desc, rarity, mods: {key: [op, value]}  op = "mul" | "add" | "max"
var boons: Array[Dictionary] = [
	{"id": "ember_rounds", "name": "Flechas de Brasa", "desc": "+22% dano do herói", "rarity": "common", "mods": {"warden_dmg": ["mul", 1.22]}},
	{"id": "quickdraw", "name": "Saque Rápido", "desc": "+18% velocidade de ataque do herói", "rarity": "common", "mods": {"warden_aspd": ["mul", 1.18]}},
	{"id": "swift_boots", "name": "Botas Ligeiras", "desc": "+15% velocidade do herói", "rarity": "common", "mods": {"warden_speed": ["mul", 1.15]}},
	{"id": "ironheart", "name": "Coração de Ferro", "desc": "+40 vida do herói", "rarity": "common", "mods": {"warden_hp": ["add", 40.0]}},
	{"id": "long_sight", "name": "Olhar Distante", "desc": "+20% alcance do herói", "rarity": "common", "mods": {"warden_range": ["mul", 1.2]}},
	{"id": "piercing_shot", "name": "Tiro Perfurante", "desc": "Flechas atravessam +1 inimigo", "rarity": "rare", "mods": {"pierce": ["add", 1.0]}},
	{"id": "twin_shot", "name": "Tiro Duplo", "desc": "+1 flecha por disparo", "rarity": "rare", "mods": {"multishot": ["add", 1.0]}},
	{"id": "keen_eye", "name": "Olho Certeiro", "desc": "+12% chance de crítico", "rarity": "rare", "mods": {"crit": ["add", 0.12]}},
	{"id": "bloodpact", "name": "Pacto de Sangue", "desc": "Herói cura 6% do dano causado", "rarity": "epic", "mods": {"lifesteal": ["add", 0.06]}},
	{"id": "aether_well", "name": "Bolsa Cheia", "desc": "+60 ouro agora", "rarity": "rare", "mods": {"bonus_gold": ["add", 60.0]}},
	{"id": "warhorn", "name": "Trompa de Guerra", "desc": "Campeões +25% dano", "rarity": "rare", "mods": {"champ_dmg": ["mul", 1.25]}},
	{"id": "oaken_ward", "name": "Escudo de Carvalho", "desc": "Campeões +30% vida", "rarity": "rare", "mods": {"champ_hp": ["mul", 1.3]}},
	{"id": "masons_guild", "name": "Guilda dos Pedreiros", "desc": "Bastião +8 de vida por onda", "rarity": "epic", "mods": {"repair": ["add", 8.0]}},
	{"id": "chain_lightning", "name": "Corrente Elétrica", "desc": "Tiros do herói saltam p/ 2 inimigos", "rarity": "epic", "mods": {"chain": ["add", 2.0]}},
	{"id": "wildfire", "name": "Fogo Selvagem", "desc": "Tiros do herói incendeiam", "rarity": "epic", "mods": {"burn": ["add", 6.0]}},
	{"id": "hoarfrost", "name": "Geada", "desc": "Tiros do herói deixam lentos", "rarity": "rare", "mods": {"slow": ["max", 0.4]}},
	{"id": "gilded_touch", "name": "Toque Dourado", "desc": "+35% ouro por abate", "rarity": "common", "mods": {"gold": ["mul", 1.35]}},
]

static func fresh_mods() -> Dictionary:
	return {
		"warden_dmg": 1.0, "warden_aspd": 1.0, "warden_speed": 1.0, "warden_hp": 0.0,
		"warden_range": 1.0, "pierce": 0.0, "multishot": 0.0, "crit": 0.05, "crit_mul": 1.8,
		"lifesteal": 0.0, "bonus_gold": 0.0, "champ_dmg": 1.0, "champ_hp": 1.0,
		"repair": 0.0, "chain": 0.0, "burn": 0.0, "slow": 0.0, "gold": 1.0,
	}

static func apply_boon(mods: Dictionary, boon: Dictionary) -> void:
	for key in boon.mods:
		var op: String = boon.mods[key][0]
		var v: float = boon.mods[key][1]
		match op:
			"mul": mods[key] *= v
			"add": mods[key] += v
			"max": mods[key] = maxf(mods[key], v)

func champion(id: String) -> Dictionary:
	for c in champions:
		if c.id == id:
			return c
	push_error("Unknown champion " + id)
	return champions[0]

# ── Realms ──────────────────────────────────────────────────
static func g(enemy: String, count: int, at: float, gap: float = 0.7, lane: int = 0) -> Dictionary:
	return {"enemy": enemy, "count": count, "at": at, "gap": gap, "lane": lane}

## Each realm is different in EVERYTHING: lane count/shape, palette, sky,
## lighting, weather, props, enemy roster, boss, hazard and music.
var realms: Array[Dictionary] = []

func _init() -> void:
	realms = [
		_realm({"id": "broken_gate", "desc": "Ruínas cercadas de campos verdes. Duas estradas retas — o lugar ideal para aprender a construir.", "map": Vector2(0.22, 0.86), "name": "O Portão Partido", "subtitle": "Onde a primeira fenda se abriu",
			"lanes": 2, "layout": "straight", "biome": "ruins", "hazard": "none", "weather": "dust", "tod": "dusk",
			"ground": Color("74b843"), "ground2": Color("5e9c34"), "lane": Color("d6a866"), "accent": Color("ff8a3d"),
			"sky": Color("8fd3ff"), "fog": Color("cfe8ff"), "sun": Color("fff1d6"), "sun_angle": -25.0, "ambient": Color("c8d4f0"),
			"roster": ["wisp", "husk", "ravager"], "boss": "the_maw", "waves": 6,
			"music": {"root": 196.0, "mode": "minor", "tempo": 0.46, "wave": "sine"}, "gold": 120, "shards": 6}),
		_realm({"id": "emberfall_wood", "desc": "Floresta em chamas. As estradas fazem zigue-zague e brasas caem do céu.", "map": Vector2(0.55, 0.8), "name": "Bosque das Brasas", "subtitle": "As copas ainda estão queimando",
			"lanes": 2, "layout": "zigzag", "biome": "forest", "hazard": "embers", "weather": "embers", "tod": "sunset",
			"ground": Color("4f9a3a"), "ground2": Color("3e8030"), "lane": Color("b27a40"), "accent": Color("ff7a2a"),
			"sky": Color("ffb36b"), "fog": Color("ffd8a8"), "sun": Color("ffe0b0"), "sun_angle": -15.0, "ambient": Color("e8c0a0"),
			"roster": ["ember_imp", "sapling", "gloombat"], "boss": "cinder_treant", "waves": 7,
			"music": {"root": 220.0, "mode": "dorian", "tempo": 0.36, "wave": "tri"}, "gold": 180, "shards": 8}),
		_realm({"id": "sunken_march", "desc": "Pântano de três estradas em serpente. Lama atrasa e a neblina encurta o alcance.", "map": Vector2(0.8, 0.7), "name": "O Brejo Afundado", "subtitle": "Estandartes e reis afogados",
			"lanes": 3, "layout": "serpent", "biome": "swamp", "hazard": "mud_fog", "weather": "fireflies", "tod": "night",
			"ground": Color("4fa088"), "ground2": Color("3d8470"), "lane": Color("8f7a4c"), "accent": Color("37b6ff"),
			"sky": Color("5a86c0"), "fog": Color("a0c8e0"), "sun": Color("dceaff"), "sun_angle": -55.0, "ambient": Color("9ec0dc"),
			"roster": ["drowned", "bog_lurker", "hexmage"], "boss": "drowned_king", "waves": 7,
			"music": {"root": 174.6, "mode": "phrygian", "tempo": 0.6, "wave": "sine"}, "gold": 260, "shards": 10}),
		_realm({"id": "hollow_keep", "desc": "Fortaleza tomada pelo inimigo. Estradas cruzadas e uma balista que mira no seu herói.", "map": Vector2(0.62, 0.58), "name": "Fortaleza Oca", "subtitle": "Um forte que a Debandada tomou",
			"lanes": 2, "layout": "cross", "biome": "keep", "hazard": "ballista", "weather": "rain", "tod": "storm",
			"ground": Color("8d93a6"), "ground2": Color("737a8e"), "lane": Color("cdbb94"), "accent": Color("ff4d7d"),
			"sky": Color("6a7898"), "fog": Color("b0b8d0"), "sun": Color("eef2ff"), "sun_angle": -60.0, "ambient": Color("b0b8d4"),
			"roster": ["sentry", "knight", "husk"], "boss": "siege_titan", "waves": 8,
			"music": {"root": 146.8, "mode": "minor", "tempo": 0.4, "wave": "saw"}, "gold": 340, "shards": 12}),
		_realm({"id": "rift_throne", "desc": "O trono roxo da fenda. Portais abrem no meio das estradas e soltam crias do vazio.", "map": Vector2(0.3, 0.56), "name": "O Trono da Fenda", "subtitle": "O trono da Debandada, mas não sua origem",
			"lanes": 3, "layout": "fork", "biome": "rift", "hazard": "portals", "weather": "void", "tod": "void",
			"ground": Color("7656b8"), "ground2": Color("5f4298"), "lane": Color("c69cf0"), "accent": Color("a46aff"),
			"sky": Color("2e1c52"), "fog": Color("8a6ac0"), "sun": Color("f0dcff"), "sun_angle": -70.0, "ambient": Color("b8a0e0"),
			"roster": ["void_spawn", "ogre", "gloombat"], "boss": "rift_sovereign", "waves": 8,
			"music": {"root": 155.6, "mode": "locrian", "tempo": 0.5, "wave": "square"}, "gold": 460, "shards": 14}),
		_realm({"id": "frostpeak_pass", "desc": "Uma única estrada sinuosa na neve. Gelo escorrega e nevascas congelam tudo.", "map": Vector2(0.14, 0.4), "name": "Passo do Pico Gelado", "subtitle": "Onde até o vento virou inimigo",
			"lanes": 1, "layout": "serpent", "biome": "ice", "hazard": "blizzard", "weather": "snow", "tod": "day",
			"ground": Color("e2f0fc"), "ground2": Color("c4dcf0"), "lane": Color("78aedb"), "accent": Color("8fe9ff"),
			"sky": Color("a8d8ff"), "fog": Color("e0f0ff"), "sun": Color("ffffff"), "sun_angle": -40.0, "ambient": Color("a8c0dc"),
			"roster": ["ice_wisp", "yeti", "husk"], "boss": "frost_wyrm", "waves": 8,
			"music": {"root": 261.6, "mode": "lydian", "tempo": 0.55, "wave": "sine"}, "gold": 600, "shards": 20}),
		_realm({"id": "sunscar_dunes", "desc": "Quatro estradas convergem no deserto. Tempestades de areia cortam o alcance.", "map": Vector2(0.48, 0.38), "name": "Dunas Queimadas", "subtitle": "Areia que lembra cada passo",
			"lanes": 4, "layout": "converge", "biome": "desert", "hazard": "sandstorm", "weather": "sand", "tod": "noon",
			"ground": Color("f2c46a"), "ground2": Color("dfa84e"), "lane": Color("c27a3a"), "accent": Color("ffcf4d"),
			"sky": Color("ffd98a"), "fog": Color("fff0c8"), "sun": Color("fff4dc"), "sun_angle": -70.0, "ambient": Color("dcc090"),
			"roster": ["scorpion", "sand_wraith", "ravager"], "boss": "sand_colossus", "waves": 8,
			"music": {"root": 233.1, "mode": "hijaz", "tempo": 0.32, "wave": "tri"}, "gold": 700, "shards": 22}),
		_realm({"id": "ashen_caldera", "desc": "Rocha vulcânica e rios de lava. Erupções atingem todos — use-as a seu favor.", "map": Vector2(0.82, 0.32), "name": "Caldeira de Cinzas", "subtitle": "A queda da Torre do Sol ainda fumega",
			"lanes": 3, "layout": "zigzag", "biome": "volcano", "hazard": "eruptions", "weather": "ash", "tod": "lava",
			"ground": Color("6a5650"), "ground2": Color("54423e"), "lane": Color("a07858"), "accent": Color("ff5a2a"),
			"sky": Color("d0562a"), "fog": Color("ffa070"), "sun": Color("ffd0a0"), "sun_angle": -35.0, "ambient": Color("d09080"),
			"roster": ["magma_slime", "fire_imp", "ogre"], "boss": "magma_tyrant", "waves": 9,
			"music": {"root": 130.8, "mode": "minor", "tempo": 0.3, "wave": "saw"}, "gold": 820, "shards": 24}),
		_realm({"id": "gloomroot_mire", "desc": "Raízes tóxicas e três estradas trançadas. Raízes prendem quem fica parado.", "map": Vector2(0.66, 0.18), "name": "Pântano Raiz-Sombria", "subtitle": "Raízes que bebem a luz",
			"lanes": 3, "layout": "braid", "biome": "mire", "hazard": "snares", "weather": "spores", "tod": "toxic",
			"ground": Color("68a83c"), "ground2": Color("52902e"), "lane": Color("8a6aa8"), "accent": Color("9be24d"),
			"sky": Color("4a7a3a"), "fog": Color("b8e090"), "sun": Color("f0ffd0"), "sun_angle": -50.0, "ambient": Color("b0d090"),
			"roster": ["spore_toad", "root_horror", "gloombat"], "boss": "bog_mother", "waves": 9,
			"music": {"root": 164.8, "mode": "phrygian", "tempo": 0.52, "wave": "square"}, "gold": 950, "shards": 26}),
		_realm({"id": "shattered_sunspire", "desc": "A Torre partida, em espiral. Um raio de sol gira: fortalece aliados e queima inimigos.", "map": Vector2(0.36, 0.14), "name": "A Torre do Sol Partida", "subtitle": "Onde a luz quebrou — conserte-a",
			"lanes": 3, "layout": "spiral", "biome": "sunspire", "hazard": "sunbeam", "weather": "motes", "tod": "dawn",
			"ground": Color("f0e2c0"), "ground2": Color("dccaa0"), "lane": Color("ffcf6b"), "accent": Color("ffe6a6"),
			"sky": Color("ffcf9a"), "fog": Color("fff0d8"), "sun": Color("fff0d0"), "sun_angle": -30.0, "ambient": Color("e8d4b4"),
			"roster": ["eclipse_knight", "radiant_shade", "void_spawn"], "boss": "the_eclipse", "waves": 10,
			"music": {"root": 293.7, "mode": "major", "tempo": 0.42, "wave": "tri"}, "gold": 1400, "shards": 40}),
	]
	for i in realms.size():
		realms[i]["unlock_after"] = i
		realms[i]["index"] = i
		if i == 0:
			realms[i]["wave_list"] = [
				[g("wisp", 5, 0, 0.62)],
				[g("wisp", 5, 0, 0.52), g("husk", 3, 0.9, 0.8, 1)],
				[g("husk", 6, 0, 0.62), g("wisp", 6, 0.4, 0.38, 1)],
				[g("husk", 5, 0, 0.56), g("ravager", 1, 1.2, 0, 1), g("wisp", 6, 1.6, 0.32)],
				[g("wisp", 10, 0, 0.3), g("husk", 6, 0.8, 0.5, 1), g("ravager", 2, 2.6, 1.4)],
				[g("the_maw", 1, 0.4, 0), g("wisp", 8, 1.2, 0.5, 1)],
			]
		else:
			realms[i]["wave_list"] = gen_waves(i, realms[i].waves, realms[i].roster, realms[i].boss, realms[i].lanes)

func _realm(d: Dictionary) -> Dictionary:
	return d

## Deterministic wave generator: `tier` scales size/density; last wave is the boss.
func gen_waves(tier: int, count: int, roster: Array, boss: String, lanes: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(boss + str(tier))
	var out: Array = []
	for w in count:
		var groups: Array = []
		var n_groups := 1 + mini(3, 1 + int(w / 2))
		for gi in n_groups:
			var enemy: String = roster[(w + gi) % roster.size()]
			var heavy: bool = enemies[enemy].kind == "brute"
			var amount := int((2 + tier * 0.3 + w * 0.95) * (0.3 if heavy else 1.0))
			var gap := clampf(0.95 - tier * 0.03 - w * 0.02, 0.38, 0.95) * (2.2 if heavy else 1.0)
			groups.append(g(enemy, maxi(1, amount), gi * 3.5 + rng.randf() * 1.0, gap, (gi + w) % lanes))
		if w == count - 1:
			groups.push_front(g(boss, 1, 0.3, 0, int(lanes / 2)))
		out.append(groups)
	return out

func realm(id: String) -> Dictionary:
	for r in realms:
		if r.id == id:
			return r
	return realms[0]

## Human-readable traits for the Encyclopedia.
func enemy_traits(id: String) -> String:
	var e: Dictionary = enemies[id]
	var t: Array = []
	t.append({"runner": "Corredor", "brute": "Brutamonte", "flyer": "Voador (ignora soldados)", "caster": "Conjurador", "boss": "CHEFE"}.get(e.kind, e.kind))
	if e.has("armor"): t.append("Armadura %d%%" % int(e.armor * 100))
	if e.has("shield") and e.kind != "boss": t.append("Escudo %d" % int(e.shield))
	if e.has("regen"): t.append("Regenera")
	if e.has("split"): t.append("Divide-se ao morrer")
	if e.has("heal"): t.append("Cura aliados")
	if e.has("burn_touch"): t.append("Queima quem encosta")
	match e.get("ability", ""):
		"charge": t.append("Investida")
		"summon": t.append("Invoca lacaios")
		"shield": t.append("Escudo mágico")
		"slam": t.append("Pancada que atordoa")
		"split": t.append("Explode em escorpiões")
	return " · ".join(t)

func enemy_realm(id: String) -> Dictionary:
	for r in realms:
		if r.roster.has(id) or r.boss == id:
			return r
	return realms[0]
