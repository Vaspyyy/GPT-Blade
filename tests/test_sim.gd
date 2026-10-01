extends SceneTree

const Cat = preload("res://scripts/catalog.gd")
const Sim = preload("res://scripts/battle_sim.gd")
var failures := 0
var total_matches := 0
var total_time := 0.0
var finish_counts: Dictionary = {}
var builds := {
	"balanced": {"blade": "comet", "disc": "halo", "driver": "rush", "core": "nova"},
	"attacker": {"blade": "fang", "disc": "reactor", "driver": "surge", "core": "thunder"},
	"guard": {"blade": "bastion", "disc": "keel", "driver": "counter", "core": "aegis"},
	"survivor": {"blade": "lotus", "disc": "gyre", "driver": "needle", "core": "phoenix"},
	"flanker": {"blade": "talon", "disc": "feather", "driver": "orbit", "core": "eclipse"},
	"control": {"blade": "meteor", "disc": "anvil", "driver": "rebound", "core": "vortex"}
}

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_match(a: Dictionary, b: Dictionary, quality: float, seed_value: int, arena_id: int = 0, frame_dt: float = 1.0 / 60.0) -> RefCounted:
	var sim = Sim.new()
	sim.setup(a, b, {"quality": quality, "power": 0.84, "timing": quality, "angle": 0.12, "tilt": 0.48}, Cat.arenas()[arena_id], seed_value)
	var frames := 0
	while not sim.finished and frames < int(62.0 / frame_dt):
		sim.step(frame_dt)
		frames += 1
	check(sim.finished, "Every battle must end within sixty seconds")
	check(sim.time <= 60.0, "Hard match duration bound")
	for top in sim.tops:
		check(is_finite(float(top.spin)) and is_finite(float(top.hp)), "Finite spin and lock")
		check(Vector2(top.pos).is_finite() and Vector2(top.vel).is_finite(), "Finite momentum and position")
		check(float(top.spin) >= 0.0 and float(top.hp) >= 0.0, "No negative status meters")
	return sim

func _run() -> void:
	for category in ["blade", "disc", "driver", "core"]:
		check(Cat.parts(category).size() >= 8, "At least eight parts per category")
		for p in Cat.parts(category):
			check(Cat.part(p.id).category == category, "Catalog round trip")
	check(Cat.arenas().size() == 4, "Four distinct arenas")
	var weak_lock = Sim.new()
	var clean_lock = Sim.new()
	weak_lock.setup(builds.balanced, builds.guard, {"quality": 0.25}, Cat.arenas()[0])
	clean_lock.setup(builds.balanced, builds.guard, {"quality": 0.96}, Cat.arenas()[0])
	check(float(clean_lock.tops[0].hp) > float(weak_lock.tops[0].hp) + 10.0, "A precise launch starts with a stronger burst lock")
	check(float(clean_lock.tops[0].hp) <= 100.0 and float(weak_lock.tops[0].hp) >= 0.0, "Launch lock bonus stays bounded")
	check(clean_lock.tops[1].hp == weak_lock.tops[1].hp, "Player timing does not alter the rival's lock")
	var first = run_match(builds.balanced, builds.guard, 0.88, 33)
	var replay = run_match(builds.balanced, builds.guard, 0.88, 33)
	check(first.result == replay.result, "Same inputs produce exactly the same result")
	check(first.history == replay.history, "Same inputs produce exactly the same history")
	var fine = run_match(builds.balanced, builds.guard, 0.88, 33, 0, 1.0 / 120.0)
	check(first.result == fine.result, "Render frame rate does not change simulation result")
	var coarse = run_match(builds.balanced, builds.guard, 0.88, 33, 0, 1.0 / 30.0)
	check(first.result == coarse.result, "30 Hz and 120 Hz integration are identical")
	var quality_wins := [0, 0]
	var quality_duration := [0.0, 0.0]
	for seed_value in range(1, 13):
		for q in range(2):
			var sim = run_match(builds.balanced, builds.balanced, 0.25 if q == 0 else 0.96, seed_value)
			if sim.result.winner == 0: quality_wins[q] += 1
			quality_duration[q] += sim.time
	check(quality_wins[1] > quality_wins[0], "Good launches must improve the same matchup")
	print("LAUNCH: low=%d/12, high=%d/12 wins" % [quality_wins[0], quality_wins[1]])
	# Aegis must actually mitigate both lock damage and spin loss.
	var exposed = Sim.new()
	var shielded = Sim.new()
	for sim in [exposed, shielded]:
		sim.setup(builds.attacker, builds.guard, {"quality": 0.86}, Cat.arenas()[0])
	var full_hp := float(exposed.tops[1].hp)
	shielded.tops[1].shield_until = 3.0
	exposed._hit(0, 1, 20.0, Vector2.RIGHT, true)
	shielded._hit(0, 1, 20.0, Vector2.RIGHT, true)
	check(full_hp - float(shielded.tops[1].hp) < (full_hp - float(exposed.tops[1].hp)) * 0.5, "Aegis gives observable lock protection")
	check(float(shielded.tops[1].spin) > float(exposed.tops[1].spin), "Aegis conserves spin on guarded contact")
	# The UI slider means stable at zero and aggressive at one.
	var stable = Sim.new()
	var aggressive = Sim.new()
	stable.setup(builds.flanker, builds.guard, {"quality": 0.86, "tilt": 0.0}, Cat.arenas()[0])
	aggressive.setup(builds.flanker, builds.guard, {"quality": 0.86, "tilt": 1.0}, Cat.arenas()[0])
	check(aggressive._contact_force(aggressive.tops[0], 1.0) > stable._contact_force(stable.tops[0], 1.0) * 1.2, "Aggressive tilt buys contact power")
	for frame in range(120):
		stable.step(1.0 / 120.0)
		aggressive.step(1.0 / 120.0)
	check(float(stable.tops[0].spin) > float(aggressive.tops[0].spin), "Stable tilt conserves spin")
	# Equal outward momentum can clear a light build while a heavy build recovers.
	var light = Sim.new()
	var heavy = Sim.new()
	var heavy_loadout := {"blade": "leviathan", "disc": "anvil", "driver": "pivot", "core": "zenith"}
	light.setup(builds.flanker, builds.guard, {"quality": 0.86, "tilt": 0.35}, Cat.arenas()[0])
	heavy.setup(heavy_loadout, builds.guard, {"quality": 0.86, "tilt": 0.35}, Cat.arenas()[0])
	for sim in [light, heavy]:
		sim.tops[0].pos = Vector2(0.94, 0.0)
		sim.tops[0].vel = Vector2(1.975, 0.0)
		sim.tops[0].pressure = 2.0
		sim._rim(0)
	check(light.finished and not heavy.finished, "Mass and control change ring-out resistance")
	# Weak phoenix revival can be stopped by real pressure, not a dice roll.
	var interrupted = Sim.new()
	interrupted.setup(builds.attacker, builds.survivor, {"quality": 0.86}, Cat.arenas()[0])
	interrupted.tops[1].charging = true
	interrupted._hit(0, 1, 11.0, Vector2.RIGHT, true)
	check(not interrupted.tops[1].charging and float(interrupted.tops[1].energy) < 70.0 and interrupted.history[0].type == "interrupt", "Strong contact interrupts Phoenix revival")
	# Each spirit must telegraph before it activates, including defensive ones.
	for spirit in ["nova", "aegis", "vortex", "phoenix", "thunder", "eclipse"]:
		var loadout: Dictionary = builds.survivor.duplicate()
		loadout.core = spirit
		var sim = run_match(loadout, builds.guard, 0.92, 2)
		var has_charge := false
		var has_attack := false
		for event in sim.history:
			if event.type == "charge" and event.actor == 0: has_charge = true
			if event.type == "ability" and event.actor == 0:
				check(has_charge, "Ability must follow an anticipation event")
				has_attack = true
		check(has_attack, "%s must activate in a normal battle" % spirit)
	# High attack, defense, stamina, mobility, and control archetypes play every other one.
	var names: Array = builds.keys()
	var matrix: Dictionary = {}
	var matchups: Dictionary = {}
	for name in names: matrix[name] = {"wins": 0, "games": 0, "distance": 0.0, "hits": 0, "abilities": 0}
	for arena_id in range(4):
		for a in range(names.size()):
			for b in range(a + 1, names.size()):
				var pair := "%s / %s" % [names[a], names[b]]
				if not matchups.has(pair): matchups[pair] = 0
				for seed_value in range(1, 5):
					var sim = run_match(builds[names[a]], builds[names[b]], 0.80, seed_value, arena_id)
					total_matches += 1
					total_time += sim.time
					finish_counts[sim.result.reason] = int(finish_counts.get(sim.result.reason, 0)) + 1
					if sim.result.winner == 0: matchups[pair] += 1
					for actor in range(2):
						var name: String = names[a] if actor == 0 else names[b]
						matrix[name].games += 1
						if sim.result.winner == actor: matrix[name].wins += 1
						matrix[name].distance += sim.tops[actor].diagnostics.distance
						matrix[name].hits += sim.tops[actor].diagnostics.hits
						matrix[name].abilities += sim.tops[actor].diagnostics.abilities
	print("BALANCE: %d matches, mean %.2fs, finishes %s" % [total_matches, total_time / total_matches, finish_counts])
	for name in names:
		var row: Dictionary = matrix[name]
		print("  %s: %d/%d wins, %.1f distance, %.1f contacts, %.1f spirits" % [name, row.wins, row.games, float(row.distance) / int(row.games), float(row.hits) / int(row.games), float(row.abilities) / int(row.games)])
	print("MATCHUPS (first build wins / 16): %s" % matchups)
	check(float(matrix.flanker.distance) > float(matrix.survivor.distance) * 2.0, "Drivers must create different observable movement")
	check(total_time / total_matches >= 15.0 and total_time / total_matches <= 35.0, "Typical match should last 15–35 seconds")
	check(finish_counts.get("Burst finish", 0) > 0, "Attack should sometimes break locks")
	print("SIM TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
