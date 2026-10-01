class_name Career
extends RefCounted
## Career deliberately keeps purchases and defeats forgiving: the ladder is a puzzle,
## not a currency treadmill. Opponent data is immutable and saves contain IDs only.

const SAVE_VERSION := 1
const LEAGUES := ["UNDERPASS", "NEON CIRCUIT", "SKYLINE MASTERS", "ASCEND FINALS"]
const CATEGORIES := ["blade", "disc", "driver", "core"]
const STARTER_PARTS := ["comet", "halo", "rush", "nova", "fang", "lotus", "feather", "anvil", "orbit", "anchor", "needle", "aegis"]
var loadout: Dictionary = {}
var owned: Array = []
var credits: int = 180
var rung: int = 0
var wins: int = 0
var losses: int = 0
var endgame_wins: int = 0
var settings: Dictionary = {"volume": 0.65, "fullscreen": false, "shake": true, "reduced_flashes": false}
var last_report: Dictionary = {}
var saved_builds: Array = [{}, {}, {}]
var save_path: String = "user://career.json"
var save_error: String = ""

func _init(path_override: String = "") -> void:
	if not path_override.is_empty():
		save_path = path_override
	_defaults()
	_load_profile()

func _defaults() -> void:
	loadout = Catalog.default_loadout().duplicate(true)
	owned = []
	for id in STARTER_PARTS:
		if not Catalog.part(id).is_empty():
			owned.append(id)
	for id in loadout.values():
		if id not in owned:
			owned.append(id)
	credits = 180
	rung = 0
	wins = 0
	losses = 0
	endgame_wins = 0
	settings = {"volume": 0.65, "fullscreen": false, "shake": true, "reduced_flashes": false}
	last_report = {}
	saved_builds = [{}, {}, {}]

func rivals() -> Array[Dictionary]:
	return [
		_rival("mika", "MIKA SPARK", "The neighborhood comet", "A clean launch. An honest clash. That's all we need.", ["comet", "halo", "rush", "nova"], "skyline", 150, 0, Color("ffb56b"), "Start with timing. A well-centered launch keeps your spin and burst lock healthy."),
		_rival("rook", "ROOK IRON", "The immovable wall", "Try harder. The floor is still mine.", ["bastion", "anvil", "anchor", "aegis"], "skyline", 180, 0, Color("9cafc4"), "Rook plants in the center. Let Lotus + Needle outlast the wall, or strike hard with Fang + Rush."),
		_rival("iona", "IONA WISP", "The quiet survivor", "You can have the sparks. I'll keep the last rotation.", ["lotus", "feather", "needle", "nova"], "skyline", 220, 0, Color("bcb5ff"), "Iona rewards endurance. Match her with Lotus + Needle and a precise launch, or hunt an early burst with Fang + Rush."),
		_rival("jax", "JAX RICOCHET", "Rail-riding trouble", "Walls aren't boundaries. They're launchpads.", ["talon", "split", "rebound", "thunder"], "skyline", 210, 1, Color("ff785d"), "Jax charges from the rails. Weight and defense blunt those impacts; a stable tilt prevents ring outs."),
		_rival("sera", "SERA TIDE", "Dancer of the outer ring", "Catch me before the music ends.", ["mirror", "gyre", "orbit", "vortex"], "glacier", 230, 1, Color("67e0cf"), "Sera keeps distance. A fast hunter closes the gap, while a stamina build can win the empty seconds."),
		_rival("nox", "NOX REVERSAL", "The patient counter", "The hit you remember will be your own.", ["bastion", "keel", "counter", "aegis"], "volcano", 270, 1, Color("8298ff"), "Nox punishes reckless contact. Orbit and stamina let you save energy, then meet him late."),
		_rival("emi", "EMI FIREBIRD", "The comeback kid", "Count me out. I dare you.", ["meteor", "reactor", "surge", "phoenix"], "volcano", 260, 2, Color("ff905b"), "Emi punishes light burst locks. Anvil + Aegis blunts her rushes; secure a burst before Phoenix's comeback window."),
		_rival("vale", "VALE NULL", "Keeper of the eclipse", "Every spotlight casts a shadow.", ["scythe", "split", "drift", "eclipse"], "stormwell", 290, 2, Color("ce94ff"), "Vale circles and steals momentum. Defense protects burst lock; center control avoids dangerous outer clashes."),
		_rival("kira", "KIRA VOLT", "One hundred storms", "Let's make enough noise to wake the sky.", ["fang", "reactor", "surge", "thunder"], "volcano", 330, 2, Color("ffe274"), "Kira commits to violent rushes. Anchor + Anvil can absorb them; Counter turns that aggression against her."),
		_rival("orin", "ORIN MERIDIAN", "The flawless orbit", "There is a place for every star. Find yours.", ["leviathan", "gyre", "gyro", "vortex"], "glacier", 320, 3, Color("73d9ef"), "Orin's spin economy is exceptional. A decisive attack build needs a powerful launch and early contact."),
		_rival("rena", "RENA SOVEREIGN", "The crown's guardian", "A champion protects more than a title.", ["monarch", "crown", "pivot", "pulse"], "skyline", 360, 3, Color("f4baea"), "Rena switches stance as danger grows. Compare your stamina and defense, then specialize instead of matching everything."),
		_rival("atlas", "ATLAS ZERO", "Champion of the skyline", "Don't imitate my legend. Build the one that beats it.", ["monarch", "crown", "gyro", "zenith"], "stormwell", 500, 3, Color("ffd17d"), "Atlas is balanced and relentless. Your launch and a coherent specialty matter more than an expensive mixed build."),
	]

func _rival(id: String, name_value: String, title: String, quote: String, ids: Array, arena: String, reward: int, tier: int, color: Color, advice: String) -> Dictionary:
	var arena_ids: Array = []
	for item in Catalog.arenas():
		arena_ids.append(item.id)
	if arena not in arena_ids:
		arena = str(arena_ids[mini(tier, arena_ids.size() - 1)]) if not arena_ids.is_empty() else "dish"
	return {"id": id, "name": name_value, "title": title, "quote": quote, "loadout": {"blade": ids[0], "disc": ids[1], "driver": ids[2], "core": ids[3]}, "arena": arena, "reward": reward, "tier": tier, "color": color, "advice": advice}

func current_rival() -> Dictionary:
	var ladder := rivals()
	if rung < ladder.size():
		return ladder[rung].duplicate(true)
	var rival: Dictionary = ladder[(endgame_wins * 5 + 11) % ladder.size()].duplicate(true)
	rival.title = "LEGEND REMATCH · " + str(endgame_wins + 1)
	rival.reward = 220
	rival.quote = "The title is yours. Now show us how far a legend can go."
	var behavior := str(Catalog.stats(rival.loadout).behavior)
	var legend_ids: Array
	match behavior:
		"hunter", "surge": legend_ids = ["monarch", "reactor", "surge", "thunder"]
		"anchor", "counter", "pivot": legend_ids = ["bastion", "keel", "pivot", "zenith"]
		"needle", "gyro": legend_ids = ["leviathan", "crown", "gyro", "phoenix"]
		"orbit", "drift": legend_ids = ["scythe", "split", "drift", "eclipse"]
		_: legend_ids = ["meteor", "anvil", "rebound", "vortex"]
	for index in range(CATEGORIES.size()):
		rival.loadout[CATEGORIES[index]] = legend_ids[index]
	rival.advice = "A familiar rival, a rebuilt legend. Their upgraded " + str(Catalog.part(rival.loadout.driver).title).to_lower() + " style needs a fresh answer."
	rival["endgame"] = true
	return rival

func unlocked_tier() -> int:
	return mini(3, int(rung / 3))

func is_champion() -> bool:
	return rung >= rivals().size()

func league_name() -> String:
	return "SKYLINE CHAMPION" if is_champion() else LEAGUES[unlocked_tier()]

func buy(id: String) -> bool:
	var item := Catalog.part(id)
	if item.is_empty():
		return false
	if id in owned:
		return true
	if int(item.tier) > unlocked_tier() or int(item.cost) > credits:
		return false
	credits -= int(item.cost)
	owned.append(id)
	save_profile()
	return true

func equip(id: String) -> void:
	var item := Catalog.part(id)
	if item.is_empty() or id not in owned:
		return
	loadout[item.category] = id
	save_profile()

func store_build(slot: int) -> bool:
	if slot < 0 or slot >= 3:
		return false
	var name_value := str(Catalog.part(loadout.blade).name) + " / " + str(Catalog.part(loadout.driver).name)
	saved_builds[slot] = {"name": name_value, "loadout": loadout.duplicate(true)}
	save_profile()
	return true

func recall_build(slot: int) -> bool:
	if slot < 0 or slot >= 3 or saved_builds[slot].is_empty():
		return false
	for family in CATEGORIES:
		var id: String = str(saved_builds[slot].loadout.get(family, ""))
		if id not in owned or Catalog.part(id).get("category", "") != family:
			return false
	loadout = saved_builds[slot].loadout.duplicate(true)
	save_profile()
	return true

func record_match(result: Dictionary, practice: bool) -> Dictionary:
	var opponent := current_rival()
	if result.get("rival_name") is String:
		opponent.name = str(result.rival_name).left(100)
	if result.get("rival_advice") is String:
		opponent.advice = str(result.rival_advice).left(500)
	var won: bool = int(result.get("winner", 1)) == 0
	var old_tier := unlocked_tier()
	var reward := 0
	var newly_champion := false
	if not practice:
		if won:
			wins += 1
			reward = int(opponent.reward)
			credits += reward
			if is_champion():
				endgame_wins += 1
			else:
				rung += 1
				newly_champion = is_champion()
		else:
			losses += 1
	var promoted := unlocked_tier() > old_tier
	var report := {
		"won": won, "reason": str(result.get("reason", "Spin finish")),
		"time": clampf(float(result.get("time", 0)), 0, 120),
		"launch_quality": clampf(float(result.get("launch_quality", 0.5)), 0, 1),
		"reward": reward, "practice": practice, "promoted": promoted,
		"rival_name": str(opponent.name), "ending": newly_champion,
		"league": league_name(), "lesson": _lesson(result, won, opponent),
	}
	last_report = report
	save_profile()
	return report.duplicate(true)

func _lesson(result: Dictionary, won: bool, opponent: Dictionary) -> String:
	var quality := float(result.get("launch_quality", 0.5))
	var reason := str(result.get("reason", "Spin finish"))
	if quality < 0.48:
		return "Your launch left spin on the table. Release near the timing ring's center, keep tilt stable, and try the same build again."
	if won:
		if reason == "Burst finish":
			return "Your impacts overwhelmed the opponent's burst lock. Keep this attack setup as a preset; test it against a heavier defender."
		if reason == "Ring out":
			return "Your pressure claimed the edge. Weight and speed converted contact into distance; a center-holding rival will pose a different puzzle."
		return "Your build kept the final rotation. Try changing one part at a time in the Lab to learn which piece carried the win."
	if reason == "Burst finish":
		return "Your burst lock broke under impact. Try Aegis, a defensive blade, or more weight; an accurate launch also strengthens your opening."
	if reason == "Ring out":
		return "The arena edge ended the match. Anchor holds the center; Anvil adds weight. Reduce launch tilt before sacrificing your entire attack plan."
	var own_stats: Dictionary = result.get("player_stats", {})
	var enemy_stats: Dictionary = result.get("opponent_stats", {})
	if float(own_stats.get("stamina", 50)) < float(enemy_stats.get("stamina", 50)):
		return "You lost the spin duel. Hunt earlier with Rush + Fang, or challenge their endurance with Lotus + Needle. " + str(opponent.advice)
	return "You had the stamina on paper. Contact, movement and launch quality decide how efficiently it lasts. " + str(opponent.advice)

func save_profile() -> void:
	var payload := {"version": SAVE_VERSION, "loadout": loadout, "owned": owned, "credits": credits, "rung": rung, "wins": wins, "losses": losses, "endgame_wins": endgame_wins, "settings": settings, "last_report": last_report, "saved_builds": saved_builds}
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "Could not open save file (" + str(FileAccess.get_open_error()) + ")."
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	var absolute := ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(absolute, absolute + ".bak")
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), absolute)
	save_error = "" if error == OK else "Could not replace save file (" + str(error) + ")."

func _load_profile() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var raw: Variant = _parse_save(save_path)
	if not raw is Dictionary or _integer(raw.get("version", 0), 0, 0, 999999) != SAVE_VERSION:
		if FileAccess.file_exists(save_path + ".bak"):
			raw = _parse_save(save_path + ".bak")
		if not raw is Dictionary or _integer(raw.get("version", 0), 0, 0, 999999) != SAVE_VERSION:
			save_error = "Unreadable profile. Your backup is preserved; a fresh workshop is available."
			return
	var saved: Dictionary = raw
	credits = _integer(saved.get("credits", 180), 180, 0, 999999)
	rung = _integer(saved.get("rung", 0), 0, 0, 12)
	wins = _integer(saved.get("wins", 0), 0, 0, 999999)
	losses = _integer(saved.get("losses", 0), 0, 0, 999999)
	endgame_wins = _integer(saved.get("endgame_wins", 0), 0, 0, 999999)
	var loaded_owned: Variant = saved.get("owned", [])
	if loaded_owned is Array:
		for id in loaded_owned:
			if id is String and not Catalog.part(id).is_empty() and id not in owned:
				owned.append(id)
	var loaded_loadout: Variant = saved.get("loadout", {})
	if loaded_loadout is Dictionary:
		for category in CATEGORIES:
			var id: Variant = loaded_loadout.get(category, loadout[category])
			if id is String and id in owned and not Catalog.part(id).is_empty() and Catalog.part(id).category == category:
				loadout[category] = id
	var loaded_builds: Variant = saved.get("saved_builds", [])
	if loaded_builds is Array:
		for slot in range(mini(3, loaded_builds.size())):
			var build: Variant = loaded_builds[slot]
			if not build is Dictionary or not build.get("loadout") is Dictionary:
				continue
			var valid := true
			var clean_loadout := {}
			for family in CATEGORIES:
				var id: Variant = build.loadout.get(family)
				if not id is String or id not in owned or Catalog.part(id).get("category", "") != family:
					valid = false
					break
				clean_loadout[family] = id
			if valid:
				var label: Variant = build.get("name", "Saved build " + str(slot + 1))
				saved_builds[slot] = {"name": label.left(70) if label is String else "Saved build " + str(slot + 1), "loadout": clean_loadout}
	var loaded_settings: Variant = saved.get("settings", {})
	if loaded_settings is Dictionary:
		var volume: Variant = loaded_settings.get("volume", settings.volume)
		if volume is float or volume is int:
			settings.volume = clampf(float(volume), 0, 1)
		for key in ["fullscreen", "shake", "reduced_flashes"]:
			if loaded_settings.get(key) is bool:
				settings[key] = loaded_settings[key]
	var loaded_report: Variant = saved.get("last_report", {})
	if loaded_report is Dictionary:
		# Read only known small fields; never trust arbitrarily large serialized objects.
		for key in ["won", "reason", "time", "launch_quality", "reward", "practice", "promoted", "rival_name", "ending", "league", "lesson"]:
			var value: Variant = loaded_report.get(key)
			if value is String:
				last_report[key] = value.left(1000)
			elif value is bool or value is int or value is float:
				last_report[key] = value

func _parse_save(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data

func _integer(value: Variant, fallback: int, lower: int, upper: int) -> int:
	if value is int or value is float:
		return clampi(int(value), lower, upper)
	return fallback

func reset_profile() -> void:
	_defaults()
	save_profile()
