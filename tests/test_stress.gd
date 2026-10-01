extends SceneTree
## Coverage beyond curated balance: 1,024 legal combinatorial builds, extreme
## launches, every arena, live bounds, endgame variants, and ability outcomes.
const Cat = preload("res://scripts/catalog.gd")
const Sim = preload("res://scripts/battle_sim.gd")
const CareerClass = preload("res://scripts/career.gd")
const GAMES := 1024
var failures := 0
var rng := RandomNumberGenerator.new()
var ticks := 0
var simulated_time := 0.0
var finishes: Dictionary = {}
var durations: Array[float] = []
var usage: Dictionary = {}
var spirit_rows: Dictionary = {}
var last_sample: Dictionary = {}
var categories := ["blade", "disc", "driver", "core"]
var part_lists: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message + " [sample " + str(last_sample) + "]")

func build() -> Dictionary:
	var result := {}
	for category in categories:
		var options: Array = part_lists[category]
		result[category] = options[rng.randi_range(0, options.size() - 1)].id
		usage[result[category]] = int(usage.get(result[category], 0)) + 1
	return result

func run_match(player: Dictionary, rival: Dictionary, launch: Dictionary, arena_data: Dictionary, seed_value: int) -> RefCounted:
	var sim = Sim.new()
	sim.setup(player, rival, launch, arena_data, seed_value)
	var activated_behind := [false, false]
	var prior_spin := [sim.tops[0].spin, sim.tops[1].spin]
	var chunks := 0
	while not sim.finished and chunks < 240:
		prior_spin = [sim.tops[0].spin, sim.tops[1].spin]
		var events: Array = sim.step(0.25)
		chunks += 1
		for event in events:
			if event.type == "ability":
				var actor := int(event.actor)
				if float(prior_spin[actor]) + 5.0 < float(prior_spin[1 - actor]): activated_behind[actor] = true
		for top in sim.tops:
			check(Vector2(top.pos).is_finite() and Vector2(top.vel).is_finite() and is_finite(float(top.rotation)), "Live finite vectors and orientation")
			check(is_finite(float(top.spin)) and is_finite(float(top.hp)) and is_finite(float(top.energy)), "Live finite status")
			check(float(top.spin) >= 0.0 and float(top.spin) <= 100.001 and float(top.hp) >= 0.0 and float(top.hp) <= 100.001, "Live health and spin bounds")
			check(float(top.energy) >= 0.0 and float(top.energy) <= 100.001 and Vector2(top.pos).length() < 1.3, "Live charge and bowl bounds")
	check(sim.finished and sim.time <= 58.01, "Every combinatorial match terminates within advertised bound")
	check(sim.result.has("explanation") and not str(sim.result.explanation).is_empty(), "Every outcome supplies a useful build explanation")
	for actor in range(2):
		var top: Dictionary = sim.tops[actor]
		var row: Dictionary = spirit_rows[top.ability]
		row.matches += 1
		if int(top.diagnostics.abilities) > 0:
			row.activations += int(top.diagnostics.abilities)
			if int(sim.result.winner) == actor: row.wins += 1
			else: row.losses += 1
			if int(sim.result.winner) == actor and activated_behind[actor]: row.behind_spin_wins += 1
			var no_contact_effect := false
			match str(top.ability):
				"nova", "eclipse", "thunder": no_contact_effect = int(top.diagnostics.ability_hits) == 0
				"aegis": no_contact_effect = float(top.diagnostics.guarded_damage) < 0.01
				"vortex": no_contact_effect = int(top.diagnostics.ability_hits) == 0
				"phoenix": no_contact_effect = float(top.diagnostics.revived_spin) < 0.01
			if no_contact_effect: row.no_direct_effect += 1
		else: row.no_activation += 1
		for event in sim.history:
			if event.type == "interrupt" and int(event.actor) != actor: row.interruptions += 1
	ticks += int(round(sim.time * 120.0))
	simulated_time += sim.time
	durations.append(sim.time)
	finishes[sim.result.reason] = int(finishes.get(sim.result.reason, 0)) + 1
	return sim

func _run() -> void:
	rng.seed = 20261001
	for category in categories: part_lists[category] = Cat.parts(category)
	for ability in ["nova", "aegis", "vortex", "phoenix", "thunder", "eclipse"]:
		spirit_rows[ability] = {"matches": 0, "activations": 0, "wins": 0, "losses": 0, "behind_spin_wins": 0, "no_direct_effect": 0, "no_activation": 0, "interruptions": 0}
	if "--controls-only" in OS.get_cmdline_user_args():
		_sensitivity()
		print("CONTROL TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
		quit(0 if failures == 0 else 1)
		return
	var start_usec := Time.get_ticks_usec()
	for game in range(GAMES):
		var player := build()
		var rival := build()
		var launch := {"quality": [0.0, 0.15, 0.5, 0.86, 1.0][game % 5], "power": [0.0, 0.5, 1.0][game % 3], "timing": 0.86,
			"angle": float(game % 24) * TAU / 24.0, "tilt": [0.0, 0.35, 0.75, 1.0][game % 4]}
		last_sample = {"game": game, "player": player, "rival": rival, "launch": launch}
		run_match(player, rival, launch, Cat.arenas()[game % 4], game * 19 + 1)
		if game % 128 == 127: print("STRESS progress %d/%d" % [game + 1, GAMES])
	# Champion rematches rebuild opponents by driver type. Test real authored endgame,
	# not only a copy of the regular ladder, with achievable quality and no free parts.
	var career = CareerClass.new("user://stress-campaign-do-not-save.json")
	career.rung = career.rivals().size()
	var legend_styles: Dictionary = {}
	var champion_candidates := [
		{"blade": "fang", "disc": "reactor", "driver": "surge", "core": "thunder"},
		{"blade": "bastion", "disc": "keel", "driver": "pivot", "core": "zenith"},
		{"blade": "lotus", "disc": "crown", "driver": "gyro", "core": "phoenix"},
		{"blade": "meteor", "disc": "anvil", "driver": "rebound", "core": "vortex"},
		{"blade": "comet", "disc": "anvil", "driver": "anchor", "core": "aegis"},
		{"blade": "comet", "disc": "halo", "driver": "rush", "core": "nova"},
	]
	for index in range(12):
		career.endgame_wins = index
		var rival: Dictionary = career.current_rival()
		var wins := 0
		var arena_data: Dictionary = Cat.arenas()[0]
		for data in Cat.arenas():
			if data.id == rival.arena: arena_data = data
		legend_styles[Cat.stats(rival.loadout).behavior] = true
		for candidate in champion_candidates:
			last_sample = {"legend": rival.name, "build": candidate}
			var sim = run_match(candidate, rival.loadout, {"quality": 0.86, "power": 0.86, "angle": 0.12, "tilt": 0.35}, arena_data, 7)
			if sim.result.winner == 0: wins += 1
		check(wins > 0, "Each rebuilt legend has at least one coherent counter at quality .86")
		print("LEGEND %s: %d/%d candidate answers" % [rival.name, wins, champion_candidates.size()])
	check(legend_styles.size() >= 4, "Rematches contain distinct upgraded behaviors")
	for category in categories:
		for part in part_lists[category]: check(usage.has(part.id), "Randomized suite covers every part")
	for ability in spirit_rows:
		var row: Dictionary = spirit_rows[ability]
		check(row.activations > 0 and row.wins > 0 and row.losses > 0, "Every spirit activates in both victories and defeats")
		print("SPIRIT %s: %s" % [ability, row])
	durations.sort()
	var wall_seconds := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	print("STRESS %d+72 matches: mean %.2fs, median %.2fs, min %.2fs, max %.2fs, %s" % [GAMES, simulated_time / durations.size(), durations[durations.size() / 2], durations[0], durations[-1], finishes])
	print("BENCHMARK: %d fixed ticks in %.2fs = %.2fus/tick; %.0fx faster than realtime (headless simulation only)" % [ticks, wall_seconds, wall_seconds * 1000000.0 / ticks, simulated_time / wall_seconds])
	_sensitivity()
	print("STRESS TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _sensitivity() -> void:
	# Paired complete matches isolate launch controls within the actual UI angle
	# limits. Same parts, quality, opponent, arena, and footwork phase in each pair.
	rng.seed = 19890317
	var angle_flips := 0
	var tilt_flips := 0
	var angle_delta := 0.0
	var tilt_delta := 0.0
	for sample in range(32):
		var player := build()
		var rival := build()
		var scenarios := [
			{"quality": 0.86, "power": 0.86, "angle": -0.95, "tilt": 0.35},
			{"quality": 0.86, "power": 0.86, "angle": 0.95, "tilt": 0.35},
			{"quality": 0.86, "power": 0.86, "angle": 0.0, "tilt": 0.0},
			{"quality": 0.86, "power": 0.86, "angle": 0.0, "tilt": 1.0}]
		var outcomes: Array = []
		for launch in scenarios:
			last_sample = {"control_sample": sample, "player": player, "rival": rival, "launch": launch}
			var sim = run_match(player, rival, launch, Cat.arenas()[sample % 4], sample * 17 + 3)
			outcomes.append(sim.result)
		if int(outcomes[0].winner) != int(outcomes[1].winner): angle_flips += 1
		if int(outcomes[2].winner) != int(outcomes[3].winner): tilt_flips += 1
		angle_delta += absf(float(outcomes[0].time) - float(outcomes[1].time))
		tilt_delta += absf(float(outcomes[2].time) - float(outcomes[3].time))
	check(angle_flips > 0, "Entry angle can change the winner at achievable quality within UI bounds")
	check(tilt_flips > 0, "Tilt can change the winner at achievable quality")
	print("CONTROLS (32 paired matchups): angle changes %d winners and %.2fs mean duration; tilt changes %d winners and %.2fs mean duration" % [angle_flips, angle_delta / 32.0, tilt_flips, tilt_delta / 32.0])
