class_name Catalog
extends RefCounted
## Parts add to shared chassis stats: every upgrade buys a tradeoff, not a larger number.

static var _parts: Array[Dictionary] = []

static func _add(id: String, category: String, name: String, title: String, description: String, cost: int, tier: int, color: String, values: Dictionary, behavior: String = "", ability: String = "") -> void:
	_parts.append({"id": id, "category": category, "name": name, "title": title,
		"description": description, "cost": cost, "tier": tier, "color": Color(color),
		"stats": values, "behavior": behavior, "ability": ability})

static func _ensure() -> void:
	if not _parts.is_empty(): return
	# Blades alter contact geometry. Attack takes speed, defense takes stamina.
	_add("comet", "blade", "Comet Six", "BALANCE", "Six rounded wings trade a little of everything for reliable clashes.", 0, 0, "58e8ff", {"attack": 8, "defense": 7, "stamina": 5})
	_add("fang", "blade", "Crimson Fang", "ATTACK", "Long hooked teeth bite burst locks. Low protection makes missed lunges costly.", 120, 0, "ff647f", {"attack": 24, "defense": -9, "speed": 5, "burst": -5})
	_add("talon", "blade", "Raptor Talon", "SPEED ATTACK", "Light asymmetrical wings hit hard at speed, but heavy opponents throw them away.", 250, 1, "ffab59", {"attack": 24, "speed": 14, "weight": -7, "stamina": -3})
	_add("bastion", "blade", "Iron Bastion", "DEFENSE", "A blunt fortress ring softens impacts and guards the lock. Sacrifices pursuit.", 270, 1, "9ca7ff", {"attack": -10, "defense": 25, "burst": 13, "speed": -9})
	_add("lotus", "blade", "Silent Lotus", "STAMINA", "A smooth, quiet ring sheds almost no spin. Vulnerable to explosive attacks.", 130, 0, "92ecc0", {"attack": -12, "stamina": 24, "control": 8, "burst": -6})
	_add("scythe", "blade", "Moon Scythe", "LOCK BREAKER", "Two offset hooks strip burst locks. Their drag burns spin on every contact.", 420, 2, "d996ff", {"attack": 29, "burst": -12, "stamina": -13, "defense": 3})
	_add("meteor", "blade", "Meteor Hammer", "RING ATTACK", "A heavy outer hammer creates powerful knockback. Slow to turn or accelerate.", 440, 2, "ffcc69", {"attack": 21, "weight": 18, "speed": -15, "control": -6})
	_add("mirror", "blade", "Mirror Shell", "COUNTER", "Polished facets absorb a rush, then return stored energy through spirit attacks.", 390, 2, "b9e3ff", {"defense": 19, "burst": 15, "attack": -5, "stamina": -9})
	_add("leviathan", "blade", "Leviathan Coil", "ENDURANCE", "An immense smooth ring resists shove attacks. Weight makes each orbit expensive.", 620, 3, "72baff", {"weight": 21, "stamina": 16, "defense": 12, "speed": -19, "attack": -10})
	_add("monarch", "blade", "Solar Monarch", "GLASS CANNON", "Four solar spears dominate direct contact. Precision launch and strong locks are vital.", 680, 3, "ffe18b", {"attack": 34, "speed": 8, "burst": -18, "defense": -12, "stamina": -7})
	# Discs move mass. Rim weight controls shove; central weight improves steering.
	_add("halo", "disc", "Halo 8", "BALANCED MASS", "Even mass distribution. A forgiving foundation for experiments.", 0, 0, "b4d7f8", {"weight": 8, "burst": 6, "control": 6})
	_add("feather", "disc", "Feather 2", "LIGHTWEIGHT", "Rapid acceleration and turning. Light tops lose ground when the clash lands.", 100, 0, "9af4ee", {"speed": 16, "control": 10, "weight": -11, "stamina": 4, "defense": -5})
	_add("anvil", "disc", "Anvil 12", "HEAVYWEIGHT", "Brutal mass resists ring pressure. More mass consumes more spin.", 140, 0, "8b99b0", {"weight": 24, "defense": 8, "speed": -10, "stamina": -12})
	_add("gyre", "disc", "Gyre 9", "OUTER WEIGHT", "A weight-loaded perimeter stores spin, but turns sluggishly.", 260, 1, "97e5ae", {"stamina": 18, "weight": 10, "control": -10, "speed": -5})
	_add("split", "disc", "Split 5", "OFF-CENTER", "Intentional imbalance increases attack and spirit gain. Costs stability and lock safety.", 300, 1, "fb86aa", {"attack": 15, "speed": 8, "control": -12, "burst": -10})
	_add("keel", "disc", "Keel 10", "LOCK SUPPORT", "Low center of gravity protects the lock and steadies ambitious tilted launches.", 410, 2, "a0aaff", {"burst": 24, "control": 13, "attack": -10, "speed": -8})
	_add("reactor", "disc", "Reactor 6", "AGGRESSIVE MASS", "A compact dense disc accelerates into clashes. Hot contact eats reserve spin.", 470, 2, "ffb76d", {"attack": 18, "speed": 10, "weight": 8, "stamina": -20})
	_add("crown", "disc", "Crown 11", "PERIMETER MASS", "Royal outer weights preserve spin and resist shoves, sacrificing burst protection.", 600, 3, "ffda75", {"stamina": 22, "weight": 16, "burst": -15, "control": -8})
	# Driver steering is an explicit simulation behavior, not just a stat modifier.
	_add("rush", "driver", "Rush Flat", "HUNTER", "Pursues the rival with diving attacks. Fast contacts drain spin and punish poor launches.", 0, 0, "ff816f", {"speed": 15, "attack": 8, "stamina": -12, "control": -4}, "hunter")
	_add("orbit", "driver", "Orbit Rubber", "FLANKER", "Wide circling sweeps build impact speed, then cut across the rival's path.", 110, 0, "61dbff", {"speed": 17, "control": 6, "stamina": -8}, "orbit")
	_add("anchor", "driver", "Anchor Ball", "CENTER GUARD", "Holds the bowl's center. Dense stable footing absorbs attacks but rarely starts them.", 110, 0, "a2b2ff", {"defense": 16, "control": 16, "speed": -14, "attack": -4}, "anchor")
	_add("needle", "driver", "Needle Point", "SPIN SURVIVOR", "Conserves spin near the center. A thin contact point makes hard shoves dangerous.", 120, 0, "8febc6", {"stamina": 24, "speed": -16, "defense": -10, "control": 8}, "needle")
	_add("counter", "driver", "Counter Pivot", "AMBUSH", "Waits at mid-bowl, then lunges as the rival approaches. Strong against reckless hunters.", 300, 1, "dcafff", {"defense": 12, "attack": 8, "control": 10, "stamina": -9}, "counter")
	_add("rebound", "driver", "Ricochet Claw", "WALL RIDER", "Bounces off the rim into the rival. Spectacular on a high wall; risky in open bowls.", 360, 1, "ffbc72", {"attack": 14, "speed": 16, "control": -10, "burst": -5}, "rebound")
	_add("surge", "driver", "Surge Metal", "BERSERKER", "Relentless straight charges. Great ring pressure; exhausts itself if it cannot connect.", 470, 2, "ff6374", {"attack": 18, "speed": 22, "stamina": -24, "defense": -7}, "surge")
	_add("drift", "driver", "Drift Bearing", "EVASIVE ORBIT", "Changes orbit radius to dodge direct charges. Conserves spin but lacks bite.", 460, 2, "7adbc8", {"stamina": 15, "control": 18, "attack": -13, "speed": 8}, "drift")
	_add("pivot", "driver", "Gyro Fortress", "REFLECTOR", "Holds center until a close rival triggers a brief countercharge. High grip can waste spin.", 650, 3, "b2a6ff", {"defense": 24, "burst": 10, "control": 18, "speed": -17, "stamina": -10}, "pivot")
	_add("gyro", "driver", "Eternal Gyro", "LAST SPIN", "Near-motionless endurance. Strong finish potential but shoves become dangerous late in a match.", 660, 3, "8df3cc", {"stamina": 31, "control": 12, "attack": -19, "defense": -12, "speed": -10}, "gyro")
	# Spirits charge visibly. New spirits unlock play styles rather than flat upgrades.
	_add("nova", "core", "Nova Lion", "NOVA BREAK", "Telegraphs a straight explosive dash. A moving target can evade the strike; a heavy target may absorb it.", 0, 0, "ffad67", {"attack": 7, "burst": 7}, "", "nova")
	_add("aegis", "core", "Aegis Tortoise", "AEGIS GUARD", "Plants a glowing shield. Reduces damage and reflects incoming force for a short window.", 140, 0, "9ea9ff", {"defense": 10, "burst": 10, "speed": -5}, "", "aegis")
	_add("vortex", "core", "Vortex Dragon", "VORTEX PULL", "Draws the rival into a close-range spiral. Attack blades exploit it; guards can survive inside it.", 280, 1, "61dcff", {"control": 10, "attack": 7, "stamina": -6}, "", "vortex")
	_add("phoenix", "core", "Ember Phoenix", "ASHEN REBIRTH", "Saves charge until spin is low, then recovers a small reserve. The vulnerable revival can be interrupted.", 350, 1, "ff8b72", {"stamina": 10, "burst": -5}, "", "phoenix")
	_add("thunder", "core", "Thunder Kirin", "THUNDER RING", "A telegraphed radial shock shoves nearby rivals. Distance, mass, and control reduce its impact.", 480, 2, "ffe47e", {"attack": 6, "weight": 8, "stamina": -8}, "", "thunder")
	_add("eclipse", "core", "Eclipse Raven", "ECLIPSE FEINT", "Slip sideways, then dive from a new angle. Creates flanking hits but weakens the burst lock.", 510, 2, "d29dff", {"speed": 12, "control": 10, "burst": -10}, "", "eclipse")
	_add("pulse", "core", "Pulse Lion", "QUICK NOVA", "A lighter Nova vessel. Rapid movement fuels frequent dashes, at the cost of impact defense.", 630, 3, "ffbc8f", {"speed": 15, "attack": 6, "defense": -13}, "", "nova")
	_add("zenith", "core", "Zenith Tortoise", "DEEP AEGIS", "A dense Aegis vessel built for survival. Guard windows reward center-holding builds.", 690, 3, "bfc4ff", {"defense": 15, "burst": 15, "attack": -12, "speed": -7}, "", "aegis")

static func parts(category: String) -> Array[Dictionary]:
	_ensure()
	var out: Array[Dictionary] = []
	for entry in _parts:
		if entry.category == category: out.append(entry.duplicate(true))
	return out

static func part(id: String) -> Dictionary:
	_ensure()
	for entry in _parts:
		if entry.id == id: return entry.duplicate(true)
	return {}

static func default_loadout() -> Dictionary:
	return {"blade": "comet", "disc": "halo", "driver": "rush", "core": "nova"}

static func stats(loadout: Dictionary) -> Dictionary:
	var out := {"attack": 39.0, "defense": 42.0, "stamina": 44.0, "speed": 43.0, "weight": 45.0, "burst": 46.0, "control": 43.0, "behavior": "hunter", "ability": "nova", "color": Color("58e8ff"), "name": "Comet Six"}
	for category in ["blade", "disc", "driver", "core"]:
		var entry := part(str(loadout.get(category, default_loadout()[category])))
		if entry.is_empty(): entry = part(default_loadout()[category])
		for stat in entry.stats:
			out[stat] = float(out[stat]) + float(entry.stats[stat])
		if category == "driver": out.behavior = entry.behavior
		if category == "core": out.ability = entry.ability
		if category == "blade":
			out.color = entry.color
			out.name = entry.name
	for stat in ["attack", "defense", "stamina", "speed", "weight", "burst", "control"]:
		out[stat] = clampf(float(out[stat]), 8.0, 96.0)
	return out

static func arenas() -> Array[Dictionary]:
	return [
		{"id": "skyline", "name": "Skyline Bowl", "subtitle": "ROOFTOP CIRCUIT", "description": "A balanced bowl with generous rim guards. Learn your build and strike with confidence.", "color": Color("58e8ff"), "grip": 1.0, "radius": 1.0, "hazard": "none", "wall": 0.94},
		{"id": "volcano", "name": "Ember Crucible", "subtitle": "HEAT RISES", "description": "The outer ring heats every six seconds. Staying central saves spin; walls offer less protection.", "color": Color("ff9468"), "grip": 1.12, "radius": 0.96, "hazard": "heat", "wall": 0.75},
		{"id": "glacier", "name": "Glass Glacier", "subtitle": "SLIPSTREAM", "description": "A slippery wide bowl amplifies launch angles and long sweeps. Heavy discs tame slides.", "color": Color("a6ddff"), "grip": 0.63, "radius": 1.08, "hazard": "ice", "wall": 0.82},
		{"id": "stormwell", "name": "Stormwell", "subtitle": "PULSE CHAMBER", "description": "The center sends an outward pulse every seven seconds. Time aggression between visible storm rings.", "color": Color("ce9cff"), "grip": 0.94, "radius": 0.94, "hazard": "pulse", "wall": 0.88}
	]
