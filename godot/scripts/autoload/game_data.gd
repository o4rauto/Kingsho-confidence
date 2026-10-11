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

const AETHER_MAX := 10.0
const AETHER_START := 5.0
const AETHER_REGEN := 0.62
const AETHER_WAVE_BONUS := 2.0
const BASTION_MAX := 100.0
const MAX_LEVEL := 12
const EVOLVE_LEVEL := 8
const GROWTH_PER_LEVEL := 0.14
const EVOLVE_BONUS := 0.35
const DECK_SIZE := 4

const WARDEN := {
	"speed": 6.5, "max_hp": 120.0, "fire_cd": 0.52, "proj_speed": 18.0,
	"damage": 14.0, "range": 9.0, "ult_max": 100.0,
}

# role: melee | ranged | tower | support
var champions: Array[Dictionary] = [
	{"id": "pyre_knight", "name": "Pyre Knight", "title": "Ember Vanguard", "role": "melee", "rarity": "common", "cost": 3,
	 "hp": 220.0, "damage": 22.0, "atk_speed": 1.0, "range": 1.6, "count": 1, "color": Color("ff8a3d"),
	 "lore": "Sworn to burn twice as bright so the Bastion never goes dark.", "ability": "Frontliner: blocks and slows the lane."},
	{"id": "thistle_archer", "name": "Thistle Archer", "title": "Wildwood Marksman", "role": "ranged", "rarity": "common", "cost": 2,
	 "hp": 70.0, "damage": 16.0, "atk_speed": 1.35, "range": 6.5, "count": 1, "color": Color("54e08a"),
	 "lore": "Loosed her first arrow at the rift the night the Sunspire fell.", "ability": "Cheap, fast ranged damage."},
	{"id": "runestone", "name": "Runestone", "title": "Arcane Sentinel", "role": "tower", "rarity": "common", "cost": 4,
	 "hp": 260.0, "damage": 20.0, "atk_speed": 1.1, "range": 7.5, "count": 1, "color": Color("37b6ff"),
	 "lore": "An old ward-glyph, woken to fire lances of light.", "ability": "Immobile turret with long range."},
	{"id": "sister_vale", "name": "Sister Vale", "title": "Keeper of the Flame", "role": "support", "rarity": "rare", "cost": 4,
	 "hp": 120.0, "damage": 6.0, "atk_speed": 0.8, "range": 5.5, "count": 1, "color": Color("ffe6a6"),
	 "lore": "Her hymns knit torn flesh.", "ability": "Heals the most wounded ally nearby."},
	{"id": "wolf_pack", "name": "Wolf Pack", "title": "Hollow Hunters", "role": "melee", "rarity": "rare", "cost": 4,
	 "hp": 60.0, "damage": 12.0, "atk_speed": 1.6, "range": 1.4, "count": 3, "color": Color("94a3c8"),
	 "lore": "Three shadows with teeth.", "ability": "Deploys three fast wolves."},
	{"id": "frost_warden", "name": "Frost Warden", "title": "The Long Winter", "role": "tower", "rarity": "rare", "cost": 5,
	 "hp": 200.0, "damage": 14.0, "atk_speed": 0.9, "range": 7.0, "count": 1, "color": Color("8fe9ff"),
	 "lore": "Where she breathes, the Rush slows.", "ability": "Hits slow enemies."},
	{"id": "boulder_golem", "name": "Boulder Golem", "title": "The Unmoved", "role": "melee", "rarity": "epic", "cost": 6,
	 "hp": 620.0, "damage": 30.0, "atk_speed": 0.7, "range": 1.8, "count": 1, "color": Color("8a94a8"),
	 "lore": "Carved from the Bastion wall itself.", "ability": "Huge health. The anchor of any line."},
	{"id": "stormcaller", "name": "Stormcaller", "title": "Voice of Thunder", "role": "tower", "rarity": "epic", "cost": 6,
	 "hp": 180.0, "damage": 26.0, "atk_speed": 0.85, "range": 8.0, "count": 1, "color": Color("4d6bff"),
	 "lore": "Calls down the storm.", "ability": "Bolts chain to 2 more enemies."},
	{"id": "sunspear_lancer", "name": "Sunspear Lancer", "title": "First Light", "role": "melee", "rarity": "epic", "cost": 5,
	 "hp": 240.0, "damage": 46.0, "atk_speed": 1.1, "range": 2.0, "count": 1, "color": Color("ffbf5e"),
	 "lore": "Rides down the lane trailing dawn.", "ability": "Heavy striker."},
	{"id": "ashen_queen", "name": "The Ashen Queen", "title": "Last of the Sunspire", "role": "support", "rarity": "legendary", "cost": 7,
	 "hp": 300.0, "damage": 40.0, "atk_speed": 0.7, "range": 6.0, "count": 1, "color": Color("f25a2a"),
	 "lore": "She wore the crown when it burned.", "ability": "Fire nova scorches every nearby enemy."},
]

# kind (behaviour + placeholder archetype): runner | brute | flyer | caster | boss
# Optional traits: armor (0..1 dmg reduction), shield (absorb hp), regen (hp/s),
# split [id, n] (on death), heal (caster heals allies), burn_touch (hurts champions),
# ability (bosses): summon | charge | shield | slam | split
var enemies: Dictionary = {
	# ── Ruins (Broken Gate) ──
	"wisp": {"name": "Rift Wisp", "kind": "runner", "hp": 36.0, "damage": 6.0, "speed": 2.4, "radius": 0.45, "bounty": 4, "breach": 4, "color": Color("ff4d7d")},
	"husk": {"name": "Ashen Husk", "kind": "runner", "hp": 70.0, "damage": 10.0, "speed": 1.8, "radius": 0.55, "bounty": 6, "breach": 7, "color": Color("c0286a")},
	"ravager": {"name": "Ravager", "kind": "brute", "hp": 220.0, "damage": 20.0, "speed": 1.35, "radius": 0.75, "bounty": 14, "breach": 12, "color": Color("8a1f4a")},
	"the_maw": {"name": "The Maw", "kind": "boss", "hp": 1320.0, "damage": 40.0, "speed": 0.95, "radius": 1.4, "bounty": 160, "breach": 60, "color": Color("8a1f4a"), "ability": "charge"},
	# ── Forest (Emberfall Wood) ──
	"ember_imp": {"name": "Ember Imp", "kind": "runner", "hp": 50.0, "damage": 9.0, "speed": 3.0, "radius": 0.42, "bounty": 6, "breach": 5, "color": Color("ff7a2a"), "burn_touch": 8.0},
	"sapling": {"name": "Burning Sapling", "kind": "brute", "hp": 240.0, "damage": 18.0, "speed": 1.2, "radius": 0.8, "bounty": 15, "breach": 12, "color": Color("6b4a22"), "regen": 6.0},
	"gloombat": {"name": "Gloombat", "kind": "flyer", "hp": 44.0, "damage": 8.0, "speed": 3.2, "radius": 0.5, "bounty": 8, "breach": 6, "color": Color("a267d6")},
	"cinder_treant": {"name": "Cinder Treant", "kind": "boss", "hp": 1870.0, "damage": 45.0, "speed": 0.8, "radius": 1.5, "bounty": 200, "breach": 60, "color": Color("4a2e14"), "ability": "summon", "summon": "ember_imp", "regen": 15.0},
	# ── Swamp (Sunken March) ──
	"drowned": {"name": "Drowned Soldier", "kind": "runner", "hp": 90.0, "damage": 12.0, "speed": 1.6, "radius": 0.55, "bounty": 8, "breach": 8, "color": Color("4f7a7a"), "shield": 40.0},
	"bog_lurker": {"name": "Bog Lurker", "kind": "brute", "hp": 300.0, "damage": 22.0, "speed": 1.1, "radius": 0.85, "bounty": 18, "breach": 14, "color": Color("2f4a3a"), "armor": 0.25},
	"hexmage": {"name": "Hexmage", "kind": "caster", "hp": 120.0, "damage": 16.0, "speed": 1.5, "radius": 0.6, "bounty": 16, "breach": 14, "color": Color("d14bff")},
	"drowned_king": {"name": "The Drowned King", "kind": "boss", "hp": 2310.0, "damage": 50.0, "speed": 0.85, "radius": 1.5, "bounty": 240, "breach": 60, "color": Color("2a5a6a"), "ability": "shield", "shield": 600.0},
	# ── Keep (Hollow Keep) ──
	"sentry": {"name": "Hollow Sentry", "kind": "caster", "hp": 150.0, "damage": 18.0, "speed": 1.3, "radius": 0.6, "bounty": 18, "breach": 14, "color": Color("7a7f9a"), "armor": 0.35},
	"knight": {"name": "Hollow Knight", "kind": "brute", "hp": 380.0, "damage": 26.0, "speed": 1.25, "radius": 0.8, "bounty": 22, "breach": 16, "color": Color("3a3f5a"), "armor": 0.3},
	"siege_titan": {"name": "Siege Titan", "kind": "boss", "hp": 2860.0, "damage": 55.0, "speed": 0.75, "radius": 1.7, "bounty": 280, "breach": 60, "color": Color("5a1730"), "ability": "slam", "armor": 0.3},
	# ── Rift (Rift Throne) ──
	"void_spawn": {"name": "Void Spawn", "kind": "runner", "hp": 80.0, "damage": 10.0, "speed": 2.2, "radius": 0.5, "bounty": 7, "breach": 7, "color": Color("6a2aa8"), "split": ["void_mite", 2]},
	"void_mite": {"name": "Void Mite", "kind": "runner", "hp": 24.0, "damage": 5.0, "speed": 3.0, "radius": 0.3, "bounty": 2, "breach": 3, "color": Color("a46aff")},
	"ogre": {"name": "Rift Ogre", "kind": "brute", "hp": 520.0, "damage": 34.0, "speed": 1.1, "radius": 0.95, "bounty": 30, "breach": 22, "color": Color("7a2140")},
	"rift_sovereign": {"name": "Rift Sovereign", "kind": "boss", "hp": 3850.0, "damage": 65.0, "speed": 0.9, "radius": 1.7, "bounty": 380, "breach": 60, "color": Color("2a0f3a"), "ability": "summon", "summon": "void_spawn"},
	# ── Ice (Frostpeak Pass) ──
	"ice_wisp": {"name": "Ice Wisp", "kind": "flyer", "hp": 60.0, "damage": 8.0, "speed": 3.0, "radius": 0.45, "bounty": 8, "breach": 6, "color": Color("bdf2ff")},
	"yeti": {"name": "Yeti", "kind": "brute", "hp": 480.0, "damage": 36.0, "speed": 1.15, "radius": 1.0, "bounty": 32, "breach": 22, "color": Color("e8f2ff"), "regen": 8.0},
	"frost_wyrm": {"name": "Frost Wyrm", "kind": "boss", "hp": 4400.0, "damage": 60.0, "speed": 1.0, "radius": 1.7, "bounty": 420, "breach": 60, "color": Color("5ab0d8"), "ability": "charge"},
	# ── Desert (Sunscar Dunes) ──
	"scorpion": {"name": "Dune Scorpion", "kind": "runner", "hp": 80.0, "damage": 14.0, "speed": 2.6, "radius": 0.55, "bounty": 10, "breach": 9, "color": Color("c98a3a"), "armor": 0.2},
	"sand_wraith": {"name": "Sand Wraith", "kind": "flyer", "hp": 70.0, "damage": 12.0, "speed": 2.8, "radius": 0.55, "bounty": 11, "breach": 8, "color": Color("e8c88a")},
	"sand_colossus": {"name": "Sand Colossus", "kind": "boss", "hp": 5220.0, "damage": 70.0, "speed": 0.7, "radius": 1.9, "bounty": 480, "breach": 60, "color": Color("a8803a"), "ability": "split", "split": ["scorpion", 6]},
	# ── Volcano (Ashen Caldera) ──
	"magma_slime": {"name": "Magma Slime", "kind": "brute", "hp": 260.0, "damage": 20.0, "speed": 1.4, "radius": 0.8, "bounty": 16, "breach": 12, "color": Color("ff5a1a"), "split": ["fire_imp", 2], "burn_touch": 10.0},
	"fire_imp": {"name": "Fire Imp", "kind": "runner", "hp": 70.0, "damage": 10.0, "speed": 3.1, "radius": 0.4, "bounty": 6, "breach": 6, "color": Color("ffb03a"), "burn_touch": 8.0},
	"magma_tyrant": {"name": "Magma Tyrant", "kind": "boss", "hp": 6050.0, "damage": 75.0, "speed": 0.8, "radius": 1.9, "bounty": 540, "breach": 60, "color": Color("b8300f"), "ability": "slam", "burn_touch": 20.0},
	# ── Mire (Gloomroot) ──
	"spore_toad": {"name": "Spore Toad", "kind": "caster", "hp": 160.0, "damage": 14.0, "speed": 1.4, "radius": 0.65, "bounty": 16, "breach": 12, "color": Color("9be24d"), "heal": 30.0},
	"root_horror": {"name": "Root Horror", "kind": "brute", "hp": 700.0, "damage": 34.0, "speed": 1.0, "radius": 1.0, "bounty": 34, "breach": 22, "color": Color("3a5a1a"), "regen": 14.0},
	"bog_mother": {"name": "Bog Mother", "kind": "boss", "hp": 6880.0, "damage": 70.0, "speed": 0.75, "radius": 2.0, "bounty": 600, "breach": 60, "color": Color("4a6a2a"), "ability": "summon", "summon": "spore_toad", "regen": 30.0},
	# ── Sunspire (finale) ──
	"eclipse_knight": {"name": "Eclipse Knight", "kind": "brute", "hp": 760.0, "damage": 40.0, "speed": 1.2, "radius": 0.95, "bounty": 38, "breach": 24, "color": Color("2a2440"), "armor": 0.35, "shield": 150.0},
	"radiant_shade": {"name": "Radiant Shade", "kind": "flyer", "hp": 140.0, "damage": 16.0, "speed": 3.0, "radius": 0.55, "bounty": 14, "breach": 10, "color": Color("fff0b0")},
	"the_eclipse": {"name": "The Eclipse", "kind": "boss", "hp": 9900.0, "damage": 90.0, "speed": 0.85, "radius": 2.1, "bounty": 1000, "breach": 60, "color": Color("1a1428"), "ability": "shield", "shield": 2500.0},
}

# Each boon: id, name, desc, rarity, mods: {key: [op, value]}  op = "mul" | "add" | "max"
var boons: Array[Dictionary] = [
	{"id": "ember_rounds", "name": "Ember Rounds", "desc": "+22% Warden damage", "rarity": "common", "mods": {"warden_dmg": ["mul", 1.22]}},
	{"id": "quickdraw", "name": "Quickdraw", "desc": "+18% attack speed", "rarity": "common", "mods": {"warden_aspd": ["mul", 1.18]}},
	{"id": "swift_boots", "name": "Swift Boots", "desc": "+15% move speed", "rarity": "common", "mods": {"warden_speed": ["mul", 1.15]}},
	{"id": "ironheart", "name": "Ironheart", "desc": "+40 max health", "rarity": "common", "mods": {"warden_hp": ["add", 40.0]}},
	{"id": "long_sight", "name": "Long Sight", "desc": "+20% range", "rarity": "common", "mods": {"warden_range": ["mul", 1.2]}},
	{"id": "piercing_shot", "name": "Piercing Shot", "desc": "Arrows pierce +1 enemy", "rarity": "rare", "mods": {"pierce": ["add", 1.0]}},
	{"id": "twin_shot", "name": "Twin Shot", "desc": "Fire +1 extra arrow", "rarity": "rare", "mods": {"multishot": ["add", 1.0]}},
	{"id": "keen_eye", "name": "Keen Eye", "desc": "+12% crit chance", "rarity": "rare", "mods": {"crit": ["add", 0.12]}},
	{"id": "bloodpact", "name": "Bloodpact", "desc": "Heal 6% of damage dealt", "rarity": "epic", "mods": {"lifesteal": ["add", 0.06]}},
	{"id": "aether_well", "name": "Aether Well", "desc": "+30% Aether regen", "rarity": "rare", "mods": {"aether_regen": ["mul", 1.3]}},
	{"id": "warhorn", "name": "Warhorn", "desc": "Champions +25% damage", "rarity": "rare", "mods": {"champ_dmg": ["mul", 1.25]}},
	{"id": "oaken_ward", "name": "Oaken Ward", "desc": "Champions +30% health", "rarity": "rare", "mods": {"champ_hp": ["mul", 1.3]}},
	{"id": "masons_guild", "name": "Mason's Guild", "desc": "Repair Bastion +8 per wave", "rarity": "epic", "mods": {"repair": ["add", 8.0]}},
	{"id": "chain_lightning", "name": "Chain Lightning", "desc": "Hits arc to 2 enemies", "rarity": "epic", "mods": {"chain": ["add", 2.0]}},
	{"id": "wildfire", "name": "Wildfire", "desc": "Hits set enemies alight", "rarity": "epic", "mods": {"burn": ["add", 6.0]}},
	{"id": "hoarfrost", "name": "Hoarfrost", "desc": "Hits slow enemies", "rarity": "rare", "mods": {"slow": ["max", 0.4]}},
	{"id": "gilded_touch", "name": "Gilded Touch", "desc": "+35% gold this run", "rarity": "common", "mods": {"gold": ["mul", 1.35]}},
]

static func fresh_mods() -> Dictionary:
	return {
		"warden_dmg": 1.0, "warden_aspd": 1.0, "warden_speed": 1.0, "warden_hp": 0.0,
		"warden_range": 1.0, "pierce": 0.0, "multishot": 0.0, "crit": 0.05, "crit_mul": 1.8,
		"lifesteal": 0.0, "aether_regen": 1.0, "champ_dmg": 1.0, "champ_hp": 1.0,
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
		_realm({"id": "broken_gate", "name": "The Broken Gate", "subtitle": "Where the first rift tore open",
			"lanes": 2, "layout": "straight", "biome": "ruins", "hazard": "none", "weather": "dust", "tod": "dusk",
			"ground": Color("3a3550"), "ground2": Color("2a2840"), "lane": Color("6a5a4a"), "accent": Color("ff8a3d"),
			"sky": Color("2a1e3a"), "fog": Color("4a2e3a"), "sun": Color("ffb070"), "sun_angle": -25.0, "ambient": Color("8a7aa0"),
			"roster": ["wisp", "husk", "ravager"], "boss": "the_maw", "waves": 6,
			"music": {"root": 196.0, "mode": "minor", "tempo": 0.46, "wave": "sine"}, "gold": 120, "shards": 6}),
		_realm({"id": "emberfall_wood", "name": "Emberfall Wood", "subtitle": "The canopy is still burning",
			"lanes": 2, "layout": "zigzag", "biome": "forest", "hazard": "embers", "weather": "embers", "tod": "sunset",
			"ground": Color("2a4a24"), "ground2": Color("1c3418"), "lane": Color("5a3a1a"), "accent": Color("ff7a2a"),
			"sky": Color("6a2a14"), "fog": Color("8a3a1a"), "sun": Color("ff7a3a"), "sun_angle": -15.0, "ambient": Color("a06a4a"),
			"roster": ["ember_imp", "sapling", "gloombat"], "boss": "cinder_treant", "waves": 7,
			"music": {"root": 220.0, "mode": "dorian", "tempo": 0.36, "wave": "tri"}, "gold": 180, "shards": 8}),
		_realm({"id": "sunken_march", "name": "The Sunken March", "subtitle": "Drowned banners, drowned kings",
			"lanes": 3, "layout": "serpent", "biome": "swamp", "hazard": "mud_fog", "weather": "fireflies", "tod": "night",
			"ground": Color("1e3a3a"), "ground2": Color("142a2a"), "lane": Color("3a4a3a"), "accent": Color("37b6ff"),
			"sky": Color("0a1a22"), "fog": Color("2a4a4a"), "sun": Color("8ab0ff"), "sun_angle": -55.0, "ambient": Color("4a6a7a"),
			"roster": ["drowned", "bog_lurker", "hexmage"], "boss": "drowned_king", "waves": 7,
			"music": {"root": 174.6, "mode": "phrygian", "tempo": 0.6, "wave": "sine"}, "gold": 260, "shards": 10}),
		_realm({"id": "hollow_keep", "name": "Hollow Keep", "subtitle": "A fortress the Rush made its own",
			"lanes": 2, "layout": "cross", "biome": "keep", "hazard": "ballista", "weather": "rain", "tod": "storm",
			"ground": Color("3a3a44"), "ground2": Color("2a2a34"), "lane": Color("5a5a6a"), "accent": Color("ff4d7d"),
			"sky": Color("1a1a24"), "fog": Color("3a3a4a"), "sun": Color("b0b8ff"), "sun_angle": -60.0, "ambient": Color("5a5a7a"),
			"roster": ["sentry", "knight", "husk"], "boss": "siege_titan", "waves": 8,
			"music": {"root": 146.8, "mode": "minor", "tempo": 0.4, "wave": "saw"}, "gold": 340, "shards": 12}),
		_realm({"id": "rift_throne", "name": "The Rift Throne", "subtitle": "The Rush's throne, but not its source",
			"lanes": 3, "layout": "fork", "biome": "rift", "hazard": "portals", "weather": "void", "tod": "void",
			"ground": Color("1e1430"), "ground2": Color("140c22"), "lane": Color("4a2a6a"), "accent": Color("a46aff"),
			"sky": Color("0c0618"), "fog": Color("2a1440"), "sun": Color("c08aff"), "sun_angle": -70.0, "ambient": Color("6a4a9a"),
			"roster": ["void_spawn", "ogre", "gloombat"], "boss": "rift_sovereign", "waves": 8,
			"music": {"root": 155.6, "mode": "locrian", "tempo": 0.5, "wave": "square"}, "gold": 460, "shards": 14}),
		_realm({"id": "frostpeak_pass", "name": "Frostpeak Pass", "subtitle": "Where the wind itself turned",
			"lanes": 1, "layout": "serpent", "biome": "ice", "hazard": "blizzard", "weather": "snow", "tod": "day",
			"ground": Color("a8bccf"), "ground2": Color("7f97b0"), "lane": Color("4f7898"), "accent": Color("8fe9ff"),
			"sky": Color("6f8fae"), "fog": Color("8faac4"), "sun": Color("e8f4ff"), "sun_angle": -40.0, "ambient": Color("7f93b0"),
			"roster": ["ice_wisp", "yeti", "husk"], "boss": "frost_wyrm", "waves": 8,
			"music": {"root": 261.6, "mode": "lydian", "tempo": 0.55, "wave": "sine"}, "gold": 600, "shards": 20}),
		_realm({"id": "sunscar_dunes", "name": "Sunscar Dunes", "subtitle": "Sand that remembers every footstep",
			"lanes": 4, "layout": "converge", "biome": "desert", "hazard": "sandstorm", "weather": "sand", "tod": "noon",
			"ground": Color("c8a060"), "ground2": Color("a8803e"), "lane": Color("7a5426"), "accent": Color("ffcf4d"),
			"sky": Color("d8b070"), "fog": Color("d8b47a"), "sun": Color("fff0c0"), "sun_angle": -70.0, "ambient": Color("a88a5a"),
			"roster": ["scorpion", "sand_wraith", "ravager"], "boss": "sand_colossus", "waves": 8,
			"music": {"root": 233.1, "mode": "hijaz", "tempo": 0.32, "wave": "tri"}, "gold": 700, "shards": 22}),
		_realm({"id": "ashen_caldera", "name": "Ashen Caldera", "subtitle": "The Sunspire's fall still smoulders",
			"lanes": 3, "layout": "zigzag", "biome": "volcano", "hazard": "eruptions", "weather": "ash", "tod": "lava",
			"ground": Color("2a2020"), "ground2": Color("1a1414"), "lane": Color("4a3a34"), "accent": Color("ff5a2a"),
			"sky": Color("3a1008"), "fog": Color("5a2010"), "sun": Color("ff6a2a"), "sun_angle": -35.0, "ambient": Color("8a4a3a"),
			"roster": ["magma_slime", "fire_imp", "ogre"], "boss": "magma_tyrant", "waves": 9,
			"music": {"root": 130.8, "mode": "minor", "tempo": 0.3, "wave": "saw"}, "gold": 820, "shards": 24}),
		_realm({"id": "gloomroot_mire", "name": "Gloomroot Mire", "subtitle": "Roots that drink the light",
			"lanes": 3, "layout": "braid", "biome": "mire", "hazard": "snares", "weather": "spores", "tod": "toxic",
			"ground": Color("243a1a"), "ground2": Color("182a10"), "lane": Color("3a4a24"), "accent": Color("9be24d"),
			"sky": Color("10200a"), "fog": Color("2a4a14"), "sun": Color("c8ff8a"), "sun_angle": -50.0, "ambient": Color("5a8a3a"),
			"roster": ["spore_toad", "root_horror", "gloombat"], "boss": "bog_mother", "waves": 9,
			"music": {"root": 164.8, "mode": "phrygian", "tempo": 0.52, "wave": "square"}, "gold": 950, "shards": 26}),
		_realm({"id": "shattered_sunspire", "name": "The Shattered Sunspire", "subtitle": "Where the light first broke — mend it",
			"lanes": 3, "layout": "spiral", "biome": "sunspire", "hazard": "sunbeam", "weather": "motes", "tod": "dawn",
			"ground": Color("b89a68"), "ground2": Color("8f7448"), "lane": Color("e8cf8a"), "accent": Color("ffe6a6"),
			"sky": Color("c08a58"), "fog": Color("d0a070"), "sun": Color("ffe8c0"), "sun_angle": -30.0, "ambient": Color("a8845a"),
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
			var gap := clampf(0.6 - tier * 0.025 - w * 0.015, 0.18, 0.6) * (2.4 if heavy else 1.0)
			groups.append(g(enemy, maxi(1, amount), gi * 0.7 + rng.randf() * 0.4, gap, (gi + w) % lanes))
		if w == count - 1:
			groups.push_front(g(boss, 1, 0.3, 0, int(lanes / 2)))
		out.append(groups)
	return out

func realm(id: String) -> Dictionary:
	for r in realms:
		if r.id == id:
			return r
	return realms[0]
