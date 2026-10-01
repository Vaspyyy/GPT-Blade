extends SceneTree
## A reproducible career playtest, not a claim that automation measures fun.
## A competent .86 launch, real unlocks/credits, and owned-part adaptations only.
const PATH := "user://campaign_test.json"
const SEEDS := [1, 7, 13, 29]
const STARTER_BUILDS := [
	{"blade": "fang", "disc": "halo", "driver": "rush", "core": "nova"},
	{"blade": "lotus", "disc": "halo", "driver": "needle", "core": "aegis"},
	{"blade": "comet", "disc": "anvil", "driver": "anchor", "core": "aegis"},
	{"blade": "fang", "disc": "feather", "driver": "orbit", "core": "nova"},
]
var failures := 0
var profile: Career
var adaptations := 0
var defeats := 0
var total_matches := 0
var campaign_time := 0.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_clean()
	profile = Career.new(PATH)
	for rung in range(12):
		_purchase_unlocked_parts()
		var rival := profile.current_rival()
		var sim := _match(profile.loadout, rival, 17 + rung * 19)
		if sim.result.winner != 0:
			var money_before := profile.credits
			profile.record_match(sim.result, false)
			defeats += 1
			check(profile.credits == money_before and profile.rung == rung, "a failed experiment never costs money or progress")
			var options := _available_builds()
			var best: Dictionary = {}
			var best_score := -1
			var best_time := 999.0
			for build in options:
				var performance := _evaluate(build, rival)
				if performance.wins > best_score or (performance.wins == best_score and performance.time < best_time):
					best = build
					best_score = performance.wins
					best_time = performance.time
			if best_score < 3:
				# Workshop compare permits one-part experiments without buying anything.
				for base in STARTER_BUILDS:
					for id in profile.owned:
						var build: Dictionary = base.duplicate(true)
						build[Catalog.part(id).category] = id
						var performance := _evaluate(build, rival)
						if performance.wins > best_score or (performance.wins == best_score and performance.time < best_time):
							best = build
							best_score = performance.wins
							best_time = performance.time
			check(best_score >= 3, "%s needs a reliable accessible build (found %d/4)" % [rival.name, best_score])
			if best.is_empty():
				break
			for id in best.values():
				check(id in profile.owned, "campaign cannot equip an unowned part")
				profile.equip(id)
			adaptations += 1
			sim = _match(profile.loadout, rival, 17 + rung * 19)
			# Independent footwork seeds validate the chosen build beyond its calibration samples.
			for retry in range(3):
				if sim.result.winner == 0:
					break
				profile.record_match(sim.result, false)
				defeats += 1
				sim = _match(profile.loadout, rival, 31 + rung * 23 + retry * 41)
		check(sim.result.winner == 0, "adaptation should beat " + str(rival.name) + " without a perfect launch")
		if sim.result.winner != 0:
			break
		var summary := profile.record_match(sim.result, false)
		campaign_time += sim.time
		print("CAMPAIGN %02d %s: %s / %.1fs / +%d CR / balance%d / %s" % [rung + 1, rival.name, sim.result.reason, sim.time, summary.reward, profile.credits, _build_name(profile.loadout)])
		check(profile.rung == rung + 1, "every real career win advances exactly one rung")
		check(profile.credits >= 0, "purchases never overdraw the wallet")
	check(profile.is_champion(), "honest play reaches the champion ending")
	check(adaptations >= 2, "campaign should reward changing builds instead of one universal solution")
	check(defeats >= 2, "campaign should expose meaningful weaknesses before adaptation")
	profile.store_build(0)
	var resumed := Career.new(PATH)
	check(resumed.is_champion() and resumed.saved_builds[0].loadout == profile.loadout, "completed career and winning custom build survive a restart")
	var rematch := profile.current_rival()
	check(rematch.get("endgame", false) and int(rematch.reward) > 0, "champion has a rewarding legend challenge")
	print("CAMPAIGN TEST: %s / %d adaptations / %d defeats without penalty / %.1f seconds winning battle time / %d simulated matches" % ["PASS" if failures == 0 else "FAIL", adaptations, defeats, campaign_time, total_matches])
	_clean()
	quit(1 if failures > 0 else 0)

func _purchase_unlocked_parts() -> void:
	var shopping: Array = []
	match profile.rung:
		3: shopping = ["gyre", "phoenix"]
		6: shopping = ["keel", "counter"]
		9: shopping = ["crown"]
		10: shopping = ["gyro"]
	for id in shopping:
		check(profile.buy(id), "first-win credits afford the planned unlocked experiment: " + str(id))

func _available_builds() -> Array[Dictionary]:
	var out: Array[Dictionary] = [Catalog.default_loadout()]
	for build in STARTER_BUILDS:
		out.append(build.duplicate(true))
	var special := [
		{"blade": "lotus", "disc": "gyre", "driver": "needle", "core": "phoenix"},
		{"blade": "comet", "disc": "keel", "driver": "anchor", "core": "aegis"},
		{"blade": "fang", "disc": "gyre", "driver": "counter", "core": "aegis"},
		{"blade": "lotus", "disc": "crown", "driver": "needle", "core": "phoenix"},
		{"blade": "lotus", "disc": "crown", "driver": "gyro", "core": "phoenix"},
	]
	for build in special:
		var owned := true
		for id in build.values():
			if id not in profile.owned:
				owned = false
		if owned:
			out.append(build)
	return out

func _evaluate(build: Dictionary, rival: Dictionary) -> Dictionary:
	var won := 0
	var time := 0.0
	for seed in SEEDS:
		var sim := _match(build, rival, seed)
		won += 1 if sim.result.winner == 0 else 0
		time += sim.time
	return {"wins": won, "time": time / SEEDS.size()}

func _match(build: Dictionary, rival: Dictionary, seed: int) -> BattleSim:
	var arena: Dictionary = Catalog.arenas()[0]
	for item in Catalog.arenas():
		if item.id == rival.arena:
			arena = item
	var sim := BattleSim.new()
	sim.setup(build, rival.loadout, {"quality": 0.86, "power": 0.86, "timing": 0.86, "angle": 0.12, "tilt": 0.35}, arena, seed)
	var frames := 0
	while not sim.finished and frames < 3600:
		sim.step(1.0 / 60.0)
		frames += 1
	check(sim.finished, "every tested battle is finite")
	total_matches += 1
	return sim

func _build_name(build: Dictionary) -> String:
	return "/".join([str(build.blade), str(build.disc), str(build.driver), str(build.core)])

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _clean() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
