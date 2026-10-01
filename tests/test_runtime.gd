extends SceneTree
## Exercise the actual scene and its button/input connections, not a UI facsimile.
## Uses a unique profile path: no player career is written or deleted.
## Run after import: godot --headless --audio-driver Dummy --path . --script tests/test_runtime.gd

var failures := 0
var checks := 0
var game: Control
var test_path := ""


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	test_path = "user://runtime_test_%d.json" % Time.get_ticks_usec()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.profile = Career.new(test_path)
	game.sound.set_volume(0.0)
	game._show_title()
	await settle()
	check(game.screen == "title", "actual main scene opens on title")
	click("HOW TO PLAY")
	await settle()
	check(game.screen == "help", "help button opens the three-part guide")
	click("← BACK")
	await settle()
	click("ENTER THE WORKSHOP")
	await settle()
	check(game.screen == "workshop", "title enters real workshop")
	var workshop = find_workshop()
	check(workshop != null, "workshop initializes in main scene")
	await key(KEY_ENTER, true)
	await key(KEY_ENTER, false)
	check(game.screen == "launch" and not game.practice, "workshop Enter transitions safely before its node leaves the viewport")
	click("← WORKSHOP")
	await settle()
	await key(KEY_P, true)
	await key(KEY_P, false)
	check(game.screen == "launch" and game.practice, "workshop P transitions safely to practice")
	click("← WORKSHOP")
	await settle()
	workshop = find_workshop()
	click("COMPARE")
	await settle()
	check(not workshop.comparison.is_empty(), "part comparison displays a candidate")
	click("CLEAR")
	await settle()
	check(workshop.comparison.is_empty(), "comparison clears without equipping")
	workshop._acquire("lotus")
	await settle()
	check(game.profile.loadout.blade == "lotus", "owned part equips through workshop acquisition flow")
	click("CAREER")
	await settle()
	check(workshop.tab == "CAREER", "career tab opens ladder")
	click("LAB")
	await settle()
	check(workshop.tab == "LAB", "lab tab opens presets and practice arenas")
	click("FIT THIS BUILD")
	await settle()
	check(game.profile.loadout.driver == "rush" and game.profile.loadout.blade == "fang", "lab fits first complete preset")
	click("SELECT ARENA")
	await settle()
	check(workshop.practice_arena != "skyline", "lab arena selection changes practice stadium")
	click("SETTINGS")
	await settle()
	check(game.screen == "settings", "workshop settings signal opens main options")
	var volume = find_type(game.page, "HSlider")
	volume.value = 0.23
	var flashes = find_button(game.page, "REDUCED FLASHES")
	flashes.button_pressed = true
	var shake = find_button(game.page, "IMPACT CAMERA SHAKE")
	shake.button_pressed = false
	click("SAVE & RETURN")
	await settle()
	check(game.screen == "workshop", "saved settings return to workshop")
	check(game.profile.settings.reduced_flashes and not game.profile.settings.shake, "accessibility settings change through real controls")
	var restored := Career.new(test_path)
	check(is_equal_approx(float(restored.settings.volume), 0.23) and restored.settings.reduced_flashes, "options persist in isolated test profile")
	var initial_rung: int = game.profile.rung
	var initial_credits: int = game.profile.credits
	click("PRACTICE")
	await settle()
	check(game.screen == "launch" and game.practice, "practice button reaches launch as practice")
	game.angle_slider.value = 20
	game.tilt_slider.value = 0.15
	check(is_equal_approx(game.launch_angle, deg_to_rad(20)) and is_equal_approx(game.launch_tilt, 0.15), "aim controls update launch parameters")
	await wind_and_snap()
	check(game.screen == "battle", "real SPACE press/release/tap completes the launch")
	check(game.match_sim.launch_quality > 0.90, "gold-zone wind and centered snap reward precision")
	check(not game.arena_view.shake_enabled and game.arena_view.reduced_flashes, "battle applies accessibility settings")
	await key(KEY_ESCAPE, true)
	check(game.paused, "ESC pauses battle")
	var pause_time: float = game.match_sim.time
	game._process(0.25)
	check(is_equal_approx(game.match_sim.time, pause_time), "paused battle advances no simulation ticks")
	await key(KEY_ESCAPE, false)
	await key(KEY_ESCAPE, true)
	check(not game.paused, "ESC resumes battle")
	await key(KEY_ESCAPE, false)
	# A mouse click leaves buttons focused. SPACE must still have exactly one
	# gameplay meaning, rather than also activating the focused pause button.
	find_button(game.page, "PAUSE").grab_focus()
	await key(KEY_SPACE, true)
	await key(KEY_SPACE, false)
	check(is_equal_approx(game.speed, 2.0), "SPACE toggles autonomous match speed")
	check(not game.paused, "SPACE does not also activate a focused pause button")
	if game.paused:
		game._toggle_pause()
	await finish_match()
	check(game.screen == "results", "automatic battle reaches actual match report screen")
	check(game.pending_result.time <= 58.1 and int(game.pending_result.winner) in [0, 1], "full runtime simulation produces a finite valid result")
	check(game.profile.rung == initial_rung and game.profile.credits == initial_credits and game.profile.wins == 0 and game.profile.losses == 0, "practice report changes no ladder, money or career record")
	click("REMATCH THIS RIVAL")
	await settle()
	check(game.screen == "launch" and game.practice, "practice rematch stays practice")
	click("← WORKSHOP")
	await settle()
	click("LAUNCH MATCH")
	await settle()
	check(game.screen == "launch" and not game.practice, "career launch has career stakes")
	await wind_and_snap()
	await finish_match()
	check(game.screen == "results", "second real battle completes into career report")
	check(game.profile.wins + game.profile.losses == 1, "career result records exactly once")
	var won: bool = int(game.pending_result.winner) == 0
	check(game.profile.rung == (1 if won else 0), "only a career victory advances one rival")
	click("REMATCH THIS RIVAL")
	await settle()
	check(game.practice == won, "victory rematch cannot advance unrelated next rival")
	click("← WORKSHOP")
	await settle()
	var before_abandon_wins: int = game.profile.wins
	var before_abandon_losses: int = game.profile.losses
	click("LAUNCH MATCH")
	await settle()
	await wind_and_snap()
	click("PAUSE")
	await settle()
	click("RETURN TO WORKSHOP")
	await settle()
	check(game.screen == "workshop" and not game.paused, "pause overlay returns safely to workshop")
	check(game.profile.wins == before_abandon_wins and game.profile.losses == before_abandon_losses, "abandoning a match has no record penalty")
	var preserved_settings: Dictionary = game.profile.settings.duplicate()
	var preserved_progress: int = game.profile.rung
	click("SETTINGS")
	await settle()
	click("START A NEW CAREER")
	await settle()
	check(game.profile.rung == preserved_progress, "opening reset confirmation changes no career state")
	click("KEEP MY CAREER")
	await settle()
	check(game.profile.rung == preserved_progress, "canceling reset preserves career")
	click("START A NEW CAREER")
	await settle()
	click("RESET CAREER")
	await settle()
	check(game.screen == "workshop" and game.profile.rung == 0 and game.profile.wins == 0 and game.profile.losses == 0 and game.profile.credits == 180, "confirmed reset restores a real beginner workshop")
	check(game.profile.settings == preserved_settings, "career reset preserves accessibility and audio options")
	var reset_saved := Career.new(test_path)
	check(reset_saved.rung == 0 and reset_saved.settings == preserved_settings, "confirmed reset persists without affecting actual player profile")
	game.sound.stop()
	# AudioServer releases playback references on its mixer thread. Give the
	# native mixer a flush interval before destroying this accelerated fixture.
	await create_timer(0.15).timeout
	game.free()
	await settle()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(test_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + suffix))
	print("RUNTIME TESTS: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)


func wind_and_snap() -> void:
	game.launch_button.grab_focus()
	await key(KEY_SPACE, true)
	check(game.holding and game.launch_phase == 1, "SPACE begins wind phase")
	game._process(1.35)
	await key(KEY_SPACE, false)
	check(not game.holding and game.launch_phase == 2, "SPACE release locks power and enters snap")
	game.phase_clock = PI / 3.6
	await key(KEY_SPACE, true)
	await key(KEY_SPACE, false)


func finish_match() -> void:
	var iterations := 0
	while game.screen == "battle" and iterations < 800:
		game._process(0.1)
		iterations += 1
		if iterations % 30 == 0:
			await process_frame
	await settle()
	check(iterations < 800, "match loop and finish presentation terminate")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func settle() -> void:
	await process_frame
	await process_frame


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event)
	await settle()


func click(fragment: String) -> void:
	var button = find_button(game.page, fragment)
	check(button != null, "button exists: " + fragment)
	if button != null:
		button.pressed.emit()


func find_button(node: Node, fragment: String) -> BaseButton:
	if node is BaseButton and fragment in node.text and not node.disabled:
		return node
	for child in node.get_children():
		var found = find_button(child, fragment)
		if found != null:
			return found
	return null


func find_type(node: Node, type: String) -> Node:
	if node.is_class(type):
		return node
	for child in node.get_children():
		var found = find_type(child, type)
		if found != null:
			return found
	return null


func find_workshop() -> Workshop:
	for child in game.page.get_children():
		if child is Workshop:
			return child
	return null
