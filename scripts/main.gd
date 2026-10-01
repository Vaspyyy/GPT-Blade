extends Control

var profile: Career
var sound: Sound
var page: Control
var screen: String = "title"
var arena_view: ArenaView
var match_sim: BattleSim
var rival: Dictionary = {}
var stadium: Dictionary = {}
var practice: bool = false
var launch_angle: float = 0.0
var launch_tilt: float = 0.35
var launch_power: float = 0.0
var launch_timing: float = 0.0
var launch_phase: int = 0
var holding: bool = false
var phase_clock: float = 0.0
var gauge: Control
var launch_hint: Label
var launch_caption: Label
var launch_button: Button
var angle_slider: HSlider
var tilt_slider: HSlider
var hud: Array = []
var clock_label: Label
var status_label: Label
var attack_label: Label
var attack_timer: float = 0.0
var accumulator: float = 0.0
var hit_pause: float = 0.0
var finish_delay: float = -1.0
var paused: bool = false
var speed: float = 1.0
var pause_layer: Control
var speed_button: Button
var time_elapsed: float = 0.0
var pending_result: Dictionary = {}
var qa_auto: bool = false
var qa_started: bool = false
var previous_screen: String = "title"
var battle_countdown: float = 0.0
var countdown_digit: int = -1

func _ready() -> void:
	theme = UI.theme()
	RenderingServer.set_default_clear_color(UI.INK)
	profile = Career.new()
	sound = Sound.new()
	add_child(sound)
	sound.set_volume(float(profile.settings.get("volume", 0.65)))
	if profile.settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_tree().auto_accept_quit = false
	qa_auto = "--qa-auto" in OS.get_cmdline_user_args()
	_show_title()
	get_viewport().size_changed.connect(_on_resize)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_quit()

func _request_quit() -> void:
	if profile != null: profile.save_profile()
	if sound != null: sound.stop()
	set_process(false)
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_resize() -> void:
	if is_instance_valid(gauge): gauge.queue_redraw()

func _new_page(name_value: String) -> Control:
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	screen = name_value
	page = Control.new()
	page.name = name_value.capitalize()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	arena_view = null
	gauge = null
	pause_layer = null
	return page

func _bg(color: Color = UI.INK) -> void:
	var bg = ColorRect.new()
	bg.color = color
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(bg)

func _frame() -> VBoxContainer:
	var margin = UI.margin(page, 28)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return UI.vbox(margin, 16)

func _header(parent: Node, title: String, sub: String = "") -> HBoxContainer:
	var row = UI.hbox(parent, 14)
	var stack = UI.vbox(row, 0)
	stack.add_child(UI.label(title, 32, UI.WHITE))
	if not sub.is_empty(): stack.add_child(UI.label(sub, 13, UI.MUTED))
	UI.spacer(row)
	return row

func _card(parent: Node, width: float = 0) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = width
	parent.add_child(panel)
	return UI.vbox(panel, 14)

func _show_title() -> void:
	_new_page("title")
	_bg()
	arena_view = ArenaView.new()
	arena_view.arena = Catalog.arenas()[0]
	arena_view.preview_loadout = profile.loadout
	arena_view.opponent_loadout = {"blade": "monarch", "disc": "crown", "driver": "gyro", "core": "zenith"}
	arena_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(arena_view)
	var shade = ColorRect.new()
	shade.color = Color(UI.INK, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(shade)
	var margin = UI.margin(page, 64)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer = UI.vbox(margin, 0)
	var top = UI.hbox(outer)
	top.add_child(UI.label("A NEW LEGEND IS BUILT. NEVER GIVEN.", 15, UI.CYAN))
	UI.spacer(top)
	top.add_child(UI.label("01 / THE SKYLINE CIRCUIT", 14, UI.MUTED))
	UI.spacer(outer)
	var row = UI.hbox(outer, 50)
	var left = UI.vbox(row, 16)
	left.custom_minimum_size.x = 530
	left.add_child(UI.label("SPIN //", 106, UI.WHITE))
	var second = UI.label("ASCEND", 106, UI.CYAN)
	second.add_theme_constant_override("outline_size", 1)
	left.add_child(second)
	left.add_child(UI.label("BUILD YOUR TOP. BREAK THE SKY.", 26, UI.GOLD))
	left.add_child(UI.paragraph("Choose every piece. Master the launch.\nWatch your creation fight its way from the underpass to the championship.", 18, UI.WHITE))
	var buttons = UI.hbox(left, 12)
	var play = UI.button("ENTER THE WORKSHOP  →", _show_workshop, true)
	play.custom_minimum_size = Vector2(295, 56)
	buttons.add_child(play)
	buttons.add_child(UI.button("HOW TO PLAY", _show_help))
	var little = UI.hbox(left, 18)
	little.add_child(UI.button("OPTIONS", func(): _show_settings("title")))
	little.add_child(UI.button("QUIT", _request_quit))
	var hero_box = UI.vbox(row, 8)
	hero_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top_view = TopView.new()
	top_view.custom_minimum_size = Vector2(380, 380)
	top_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_view.set_loadout(profile.loadout)
	hero_box.add_child(top_view)
	var intro = UI.label("FOUR PARTS. YOUR SIGNATURE.", 24, UI.GOLD)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_box.add_child(intro)
	UI.spacer(outer)
	var footer = UI.hbox(outer)
	footer.add_child(UI.label("12 RIVALS  /  4 ARENAS  /  THOUSANDS OF BUILDS", 14, UI.MUTED))
	UI.spacer(footer)
	footer.add_child(UI.label("MOUSE + KEYBOARD     •     ESC TO PAUSE", 13, UI.MUTED))
	sound.music("menu")
	play.grab_focus()

func _show_workshop() -> void:
	_new_page("workshop")
	var workshop = Workshop.new()
	workshop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(workshop)
	workshop.battle_requested.connect(_prepare_match)
	workshop.settings_requested.connect(func(): _show_settings("workshop"))
	if workshop.has_signal("title_requested"):
		workshop.connect("title_requested", _show_title)
	workshop.initialize(profile)
	sound.music("menu")
	sound.play("click")
	if not profile.save_error.is_empty():
		var warning = UI.label("SAVE WARNING: " + profile.save_error, 13, UI.PINK)
		warning.position = Vector2(28, size.y - 28)
		page.add_child(warning)

func _arena_by_id(id: String) -> Dictionary:
	for a in Catalog.arenas():
		if str(a.id) == id: return a
	return Catalog.arenas()[0]

func _prepare_match(selected: Dictionary, is_practice: bool = false) -> void:
	rival = selected.duplicate(true)
	practice = is_practice
	stadium = _arena_by_id(str(rival.get("arena", "skyline")))
	launch_angle = 0.0
	launch_tilt = 0.35
	launch_phase = 0
	launch_power = 0
	launch_timing = 0
	phase_clock = 0
	holding = false
	_show_launch()

func _show_launch() -> void:
	_new_page("launch")
	_bg()
	var frame = _frame()
	var header = _header(frame, "READY. AIM. ASCEND.", "PRACTICE • No ladder progress" if practice else "CAREER / " + profile.league_name())
	header.add_child(UI.button("← WORKSHOP", _show_workshop))
	var content = UI.hbox(frame, 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var side = _card(content, 350)
	side.add_child(UI.label("NEXT UP", 13, UI.PINK))
	side.add_child(UI.label(str(rival.name), 37, UI.WHITE))
	side.add_child(UI.label(str(rival.title), 17, UI.GOLD))
	side.add_child(UI.paragraph('“' + str(rival.quote) + '”', 16, UI.MUTED))
	var portrait = RivalPortrait.new()
	portrait.custom_minimum_size = Vector2(310, 180)
	portrait.initialize(rival)
	side.add_child(portrait)
	var their_stats = Catalog.stats(rival.loadout)
	side.add_child(UI.label(str(their_stats.behavior).to_upper() + "  /  " + str(their_stats.ability).to_upper(), 17, UI.PINK))
	side.add_child(UI.paragraph(str(rival.get("advice", "Watch the paths. Every driver fights differently.")), 14))
	UI.spacer(side)
	side.add_child(UI.label(str(stadium.name).to_upper(), 22, stadium.color))
	side.add_child(UI.paragraph(str(stadium.description), 14))
	var right = UI.vbox(content, 14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_view = ArenaView.new()
	arena_view.arena = stadium
	arena_view.preview_loadout = profile.loadout
	arena_view.opponent_loadout = rival.loadout
	arena_view.show_launch = true
	arena_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_view.custom_minimum_size.y = 320
	right.add_child(arena_view)
	var sliders = UI.hbox(right, 20)
	var aim_box = UI.vbox(sliders, 5)
	aim_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aim_box.add_child(UI.label("ENTRY ANGLE   ← / →", 14, UI.CYAN))
	angle_slider = HSlider.new()
	angle_slider.min_value = -55
	angle_slider.max_value = 55
	angle_slider.value = 0
	angle_slider.step = 1
	aim_box.add_child(angle_slider)
	angle_slider.value_changed.connect(func(v): launch_angle = deg_to_rad(v))
	var tilt_box = UI.vbox(sliders, 5)
	tilt_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tilt_box.add_child(UI.label("TILT: STABLE / AGGRESSIVE   ↑ / ↓", 14, UI.GOLD))
	tilt_slider = HSlider.new()
	tilt_slider.min_value = 0
	tilt_slider.max_value = 1
	tilt_slider.step = 0.01
	tilt_slider.value = 0.35
	tilt_box.add_child(tilt_slider)
	tilt_slider.value_changed.connect(func(v): launch_tilt = v)
	var controls = _card(right)
	launch_caption = UI.label("01 / WIND THE RIPCORD", 29, UI.CYAN)
	controls.add_child(launch_caption)
	launch_hint = UI.paragraph("Set your entry angle and tilt. Hold SPACE to build power; release in the gold zone. Then tap SPACE when the snap marker meets the center.", 15, UI.WHITE)
	controls.add_child(launch_hint)
	gauge = Control.new()
	gauge.custom_minimum_size.y = 58
	gauge.draw.connect(_draw_launch_gauge)
	controls.add_child(gauge)
	launch_button = UI.button("HOLD SPACE OR HOLD HERE", Callable(), true)
	launch_button.custom_minimum_size.y = 48
	launch_button.button_down.connect(_wind_start)
	launch_button.button_up.connect(_wind_release)
	launch_button.pressed.connect(func():
		if launch_phase == 2 and phase_clock > 0.18: _snap_launch())
	controls.add_child(launch_button)
	sound.play("click")
	sound.music("menu")

func _wind_start() -> void:
	if screen != "launch" or launch_phase == 2: return
	holding = true
	launch_phase = 1
	phase_clock = 0
	angle_slider.editable = false
	tilt_slider.editable = false
	sound.play("charge")

func _wind_release() -> void:
	if screen != "launch" or not holding: return
	holding = false
	launch_power = clampf(0.45 + 0.55 * (1 - absf(fmod(phase_clock * 0.68, 2.0) - 1)), 0, 1)
	launch_phase = 2
	phase_clock = 0
	launch_caption.text = "02 / SNAP THE RELEASE"
	launch_caption.add_theme_color_override("font_color", UI.GOLD)
	launch_hint.text = "Power locked: %d%%. Tap SPACE or click SNAP when the moving marker touches the center. Precision protects spin and burst lock." % roundi(launch_power * 100)
	launch_button.text = "SNAP!  /  TAP SPACE"
	sound.play("click")

func _snap_launch() -> void:
	if screen != "launch" or launch_phase != 2: return
	launch_timing = clampf(1.0 - absf(sin(phase_clock * 3.6)) * 1.3, 0.0, 1.0)
	_start_battle()

func _draw_launch_gauge() -> void:
	if not is_instance_valid(gauge): return
	var width = gauge.size.x
	var y = 25.0
	gauge.draw_style_box(UI.panel(Color("070d18"), UI.EDGE, 7), Rect2(0, 8, width, 36))
	if launch_phase < 2:
		gauge.draw_rect(Rect2(width * 0.81, 10, width * 0.16, 32), Color(UI.GOLD, 0.17))
		var power = 0.45 if not holding else clampf(0.45 + 0.55 * (1 - absf(fmod(phase_clock * 0.68, 2.0) - 1)), 0, 1)
		gauge.draw_style_box(UI.panel(UI.CYAN, UI.CYAN, 5), Rect2(4, 13, maxf(1, (width - 8) * power), 26))
		gauge.draw_line(Vector2(width * 0.89, 9), Vector2(width * 0.89, 43), UI.GOLD, 2)
		gauge.draw_string(UI.font_title(), Vector2(12, 32), "%02d%%" % roundi(power * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.INK)
	else:
		gauge.draw_rect(Rect2(width * 0.44, 10, width * 0.12, 32), Color(UI.GOLD, 0.24))
		gauge.draw_line(Vector2(width * 0.5, 6), Vector2(width * 0.5, 48), UI.GOLD, 2)
		var x = width * (0.5 + sin(phase_clock * 3.6) * 0.46)
		gauge.draw_circle(Vector2(x, y), 9, UI.CYAN)
		gauge.draw_circle(Vector2(x, y), 4, UI.WHITE)

func _start_battle(quality_override: float = -1.0) -> void:
	var launch = {"power": launch_power, "timing": launch_timing, "angle": launch_angle, "tilt": launch_tilt, "quality": launch_power * 0.45 + launch_timing * 0.55}
	if quality_override >= 0:
		launch.power = quality_override
		launch.timing = quality_override
		launch.quality = quality_override
	match_sim = BattleSim.new()
	match_sim.setup(profile.loadout, rival.loadout, launch, stadium, int(Time.get_ticks_msec()))
	paused = false
	speed = 1
	accumulator = 0
	hit_pause = 0
	finish_delay = -1
	pending_result = {}
	battle_countdown = 1.8
	countdown_digit = -1
	_new_page("battle")
	_bg()
	var frame = _frame()
	var header = _header(frame, "THE SKYLINE CIRCUIT", "PRACTICE" if practice else profile.league_name())
	speed_button = UI.button("SPEED ×1  [SPACE]", _toggle_speed)
	header.add_child(speed_button)
	header.add_child(UI.button("PAUSE  [ESC]", _toggle_pause))
	var topbar = UI.hbox(frame, 24)
	hud = []
	for i in range(2):
		if i == 1:
			var center = UI.vbox(topbar, 0)
			center.custom_minimum_size.x = 105
			clock_label = UI.label("00.0", 38, UI.GOLD)
			clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(clock_label)
			var vs = UI.label("VS", 17, UI.MUTED)
			vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(vs)
		var stack = UI.vbox(topbar, 4)
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stats = Catalog.stats(profile.loadout if i == 0 else rival.loadout)
		stack.add_child(UI.label("YOU / " + str(stats.name) if i == 0 else str(rival.name), 25, UI.CYAN if i == 0 else UI.PINK))
		var spin_row = UI.hbox(stack, 8)
		spin_row.add_child(UI.label("SPIN", 12, UI.MUTED))
		var spin_bar = _bar(spin_row, UI.CYAN if i == 0 else UI.PINK)
		var spin_value = UI.label("100", 14)
		spin_value.custom_minimum_size.x = 30
		spin_row.add_child(spin_value)
		var row = UI.hbox(stack, 8)
		row.add_child(UI.label("LOCK", 12, UI.MUTED))
		var hp_bar = _bar(row, UI.GOLD)
		row.add_child(UI.label("SPIRIT", 12, UI.MUTED))
		var energy_bar = _bar(row, Color("bca4ff"))
		spin_bar.value = match_sim.tops[i].spin
		spin_value.text = str(roundi(match_sim.tops[i].spin))
		hp_bar.value = match_sim.tops[i].hp
		energy_bar.value = match_sim.tops[i].energy
		hud.append({"spin": spin_bar, "hp": hp_bar, "energy": energy_bar, "value": spin_value})
	arena_view = ArenaView.new()
	arena_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_view.custom_minimum_size.y = 410
	arena_view.shake_enabled = profile.settings.get("shake", true)
	arena_view.reduced_flashes = profile.settings.get("reduced_flashes", false)
	arena_view.set_match(match_sim, stadium)
	frame.add_child(arena_view)
	attack_label = UI.label("", 38, UI.GOLD)
	attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	attack_label.position = Vector2(-350, 82)
	attack_label.size = Vector2(700, 50)
	arena_view.add_child(attack_label)
	status_label = UI.label("%s LAUNCH  /  %d%% POWER  /  %d%% SNAP   —   YOUR BUILD TAKES OVER." % ["PERFECT" if launch.quality > 0.88 else "SOLID" if launch.quality > 0.6 else "SHAKY", roundi(launch.power * 100), roundi(launch.timing * 100)], 19, UI.CYAN)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(status_label)
	var bottom = UI.hbox(frame)
	bottom.add_child(UI.label("SPIN = stamina  •  LOCK = burst resistance  •  SPIRIT = automatic attack", 13, UI.MUTED))
	UI.spacer(bottom)
	bottom.add_child(UI.label("WATCH. LEARN. REBUILD.", 15, UI.GOLD))
	sound.music("battle")
	sound.play("launch")

func _bar(parent: Node, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(60, 10)
	bar.show_percentage = false
	bar.value = 100
	var background = UI.panel(Color("050a14"), UI.EDGE, 3)
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background)
	var fill = UI.panel(color, color, 3)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _process(delta: float) -> void:
	time_elapsed += delta
	if qa_auto and not qa_started and time_elapsed > 0.7:
		qa_started = true
		practice = true
		rival = profile.current_rival()
		stadium = Catalog.arenas()[0]
		_start_battle(0.92)
	if screen == "launch":
		phase_clock += delta
		if launch_phase == 0:
			if Input.is_key_pressed(KEY_LEFT): angle_slider.value -= delta * 48
			if Input.is_key_pressed(KEY_RIGHT): angle_slider.value += delta * 48
			if Input.is_key_pressed(KEY_UP): tilt_slider.value += delta * 0.45
			if Input.is_key_pressed(KEY_DOWN): tilt_slider.value -= delta * 0.45
		if is_instance_valid(arena_view):
			arena_view.launch_angle = launch_angle
			arena_view.launch_tilt = launch_tilt
		if is_instance_valid(gauge): gauge.queue_redraw()
	if screen != "battle": return
	if paused: return
	if battle_countdown > 0:
		battle_countdown -= delta
		var digit = ceili(battle_countdown / 0.6)
		if digit != countdown_digit:
			countdown_digit = digit
			attack_label.text = str(digit) if digit > 0 else "LET IT RIP!"
			attack_label.add_theme_font_size_override("font_size", 76 if digit > 0 else 60)
			attack_timer = 0.55 if digit > 0 else 0.95
			sound.play("countdown" if digit > 0 else "launch")
		attack_label.modulate.a = minf(1, maxf(0.4, attack_timer * 2))
		return
	if hit_pause > 0:
		hit_pause -= delta
		accumulator += delta * 0.17
	else:
		accumulator += delta * speed
	var iterations = 0
	while accumulator >= 1.0 / 120.0 and not match_sim.finished and iterations < 32:
		var events = match_sim.step(1.0 / 120.0)
		arena_view.add_events(events)
		_handle_events(events)
		accumulator -= 1.0 / 120.0
		iterations += 1
	if iterations >= 32: accumulator = 0
	for i in range(2):
		var top = match_sim.tops[i]
		hud[i].spin.value = top.spin
		hud[i].hp.value = top.hp
		hud[i].energy.value = top.energy
		hud[i].value.text = str(maxi(0, roundi(top.spin)))
	clock_label.text = "%04.1f" % match_sim.time
	attack_timer = maxf(0, attack_timer - delta)
	attack_label.modulate.a = minf(1, attack_timer * 2)
	if match_sim.finished:
		if finish_delay < 0:
			finish_delay = 2.0
			status_label.text = str(match_sim.result.get("reason", "Finish")).to_upper() + "!"
			status_label.add_theme_color_override("font_color", UI.GOLD)
			sound.play("win" if int(match_sim.result.winner) == 0 else "lose")
		else:
			finish_delay -= delta
			if finish_delay <= 0: _show_results()

func _handle_events(events: Array) -> void:
	for ev in events:
		var kind = str(ev.get("type", ""))
		var actor = "YOUR" if int(ev.get("actor", 0)) == 0 else str(rival.name).split(" ")[0] + "'S"
		if kind == "clash":
			sound.play("clash", float(ev.get("intensity", 0.7)))
			if float(ev.get("intensity", 0)) > 0.65: hit_pause = maxf(hit_pause, 0.065)
			if float(ev.get("intensity", 0)) > 0.95:
				status_label.text = "HEAVY CLASH  /  " + ("YOUR PRESSURE" if int(ev.get("actor", 0)) == 0 else "RIVAL PRESSURE")
		elif kind == "charge":
			sound.play("telegraph", 0.7)
			status_label.text = actor + " SPIRIT IS CHARGING…"
		elif kind == "ability":
			sound.play("ability")
			hit_pause = 0.22
			attack_label.text = str(ev.get("name", "SPIRIT BREAK")).to_upper()
			attack_label.add_theme_font_size_override("font_size", 38)
			attack_label.add_theme_color_override("font_color", UI.CYAN if int(ev.get("actor", 0)) == 0 else UI.PINK)
			attack_timer = 1.7
			status_label.text = actor + " " + attack_label.text
		elif kind in ["burst", "ringout"]:
			sound.play("burst")
			hit_pause = 0.32
		elif kind == "hazard":
			status_label.text = str(ev.get("name", "ARENA PULSE")).to_upper()
		elif kind == "interrupt":
			status_label.text = "REBIRTH INTERRUPTED!  /  " + actor + " PRESSURE BROKE CONCENTRATION"
			sound.play("clash", 1.1)

func _toggle_speed() -> void:
	if screen != "battle": return
	speed = 2.0 if speed < 1.5 else 1.0
	if is_instance_valid(speed_button): speed_button.text = "SPEED ×%d  [SPACE]" % int(speed)
	sound.play("click")

func _toggle_pause() -> void:
	if screen != "battle": return
	paused = not paused
	if not paused:
		if is_instance_valid(pause_layer): pause_layer.queue_free()
		pause_layer = null
		return
	pause_layer = ColorRect.new()
	pause_layer.color = Color(UI.INK, 0.88)
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(pause_layer)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)
	var card = _card(center, 430)
	card.add_child(UI.label("TIME OUT", 56, UI.CYAN))
	card.add_child(UI.paragraph("Your build will pick up exactly where it left off.", 17))
	card.add_child(UI.button("RESUME  /  ESC", _toggle_pause, true))
	card.add_child(UI.button("RETURN TO WORKSHOP", func():
		paused = false
		_show_workshop()))
	card.add_child(UI.label("Leaving a battle has no penalty.", 13, UI.MUTED))

func _show_results() -> void:
	pending_result = match_sim.result.duplicate(true)
	pending_result.rival_name = str(rival.name)
	pending_result.rival_advice = str(rival.get("advice", ""))
	var report = profile.record_match(pending_result, practice)
	_new_page("results")
	_bg()
	var margin = UI.margin(page, 50)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame = UI.vbox(margin, 16)
	var header = UI.hbox(frame)
	header.add_child(UI.label("MATCH REPORT / " + str(stadium.name).to_upper(), 16, UI.MUTED))
	UI.spacer(header)
	header.add_child(UI.label("PRACTICE" if practice else "CAREER", 15, UI.GOLD))
	var row = UI.hbox(frame, 32)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left = UI.vbox(row, 15)
	left.custom_minimum_size.x = 400
	left.add_child(UI.label("CHAMPION" if report.ending else "VICTORY" if report.won else "NEXT TIME", 78, UI.GOLD if report.ending else UI.CYAN if report.won else UI.PINK))
	left.add_child(UI.label(str(report.reason).to_upper(), 33, UI.WHITE))
	left.add_child(UI.label("%.1fs  /  %d%% LAUNCH" % [report.time, roundi(report.launch_quality * 100)], 20, UI.MUTED))
	var top = TopView.new()
	top.custom_minimum_size = Vector2(370, 290)
	top.set_loadout(profile.loadout)
	left.add_child(top)
	if report.ending:
		left.add_child(UI.paragraph("From the underpass to the skyline. Every part, every launch, every comeback was yours. The crown is only the beginning: legend rematches await.", 19, UI.GOLD))
	elif report.promoted:
		left.add_child(UI.label("PROMOTED / " + str(report.league), 25, UI.GOLD))
		left.add_child(UI.paragraph("A new tier of parts is open in the workshop. New rivals demand new ideas.", 16))
	elif report.won:
		left.add_child(UI.label("+%d CR   /   THE LADDER MOVES ON" % report.reward, 21, UI.GOLD))
	else:
		left.add_child(UI.label("NO PARTS LOST. NO CREDITS LOST.", 20, UI.GOLD))
	UI.spacer(left)
	var right = UI.vbox(row, 18)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lesson_box = _card(right)
	lesson_box.add_child(UI.label("WHAT THE ARENA TAUGHT YOU", 26, UI.CYAN))
	lesson_box.add_child(UI.paragraph(str(report.lesson), 18, UI.WHITE))
	var reason = str(pending_result.get("explanation", ""))
	if not reason.is_empty(): lesson_box.add_child(UI.paragraph(reason, 15))
	var stat_box = _card(right)
	stat_box.add_child(UI.label("YOUR BUILD VS THEIR BUILD", 25, UI.WHITE))
	var your_stats = Catalog.stats(profile.loadout)
	var their_stats = Catalog.stats(rival.loadout)
	for key in ["attack", "defense", "stamina", "speed", "weight", "burst"]:
		var stat_row = UI.hbox(stat_box, 12)
		var name_label = UI.label(str(key).to_upper(), 13, UI.MUTED)
		name_label.custom_minimum_size.x = 100
		stat_row.add_child(name_label)
		var own = _bar(stat_row, UI.CYAN)
		own.value = float(your_stats[key])
		stat_row.add_child(UI.label("%02d : %02d" % [roundi(your_stats[key]), roundi(their_stats[key])], 15, UI.WHITE))
		var enemy = _bar(stat_row, UI.PINK)
		enemy.value = float(their_stats[key])
	var diagnostics: Array = pending_result.get("diagnostics", [])
	if diagnostics.size() >= 2:
		var d = diagnostics[0]
		right.add_child(UI.label("%d HITS  /  %d SPIRIT ATTACKS  /  %.0f IMPACT DAMAGE" % [int(d.get("hits", 0)), int(d.get("abilities", 0)), float(d.get("damage_dealt", 0))], 17, UI.GOLD))
	right.add_child(UI.paragraph("Change one part, see a different fight. Drivers decide the path; blades decide the clash; discs decide the mass; spirits decide the reversal.", 16))
	UI.spacer(right)
	var actions = UI.hbox(frame, 16)
	var next = UI.button("TO THE WORKSHOP  →", _show_workshop, true)
	next.custom_minimum_size = Vector2(330, 58)
	actions.add_child(next)
	actions.add_child(UI.button("REMATCH THIS RIVAL", func():
		# Replaying a defeated rival is practice, so it cannot advance the next rung.
		_prepare_match(rival, practice or report.won)))
	UI.spacer(actions)
	actions.add_child(UI.label("Your career saves automatically.", 14, UI.MUTED))
	sound.music("menu")
	next.grab_focus()

func _show_help() -> void:
	previous_screen = "title"
	_new_page("help")
	_bg()
	var frame = _frame()
	var header = _header(frame, "THE ART OF THE LAUNCH", "A four-part build. A two-stage launch. A career of discoveries.")
	header.add_child(UI.button("← BACK", _show_title))
	var row = UI.hbox(frame, 20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var guides = [
		["01 / BUILD", "Your workshop is your strategy.", "BLADE\nAttack, defense and contact geometry.\n\nDISC\nMass, steering, and stored spin.\n\nDRIVER\nAutonomous movement: hunt, orbit, guard, evade.\n\nSPIRIT\nAn automatic attack with a visible charge.\n\nThere is no best part. Follow a coherent idea, then change one piece at a time."],
		["02 / LAUNCH", "Precision turns potential into power.", "AIM\nLeft/right sets entry angle. Up/down sets tilt. Stable tilt holds the bowl; aggressive tilt buys attack at a cost.\n\nWIND\nHold SPACE or the button. Release when power enters the gold zone.\n\nSNAP\nTap SPACE or click when the moving marker crosses the center. Good timing protects spin and burst lock.\n\nBoth steps reward practice. You can retry every loss without losing credits."],
		["03 / ASCEND", "Let the fight tell you what to change.", "SPIN FINISH\nThe last top rotating wins. Movement and clashes spend stamina.\n\nBURST FINISH\nStrong impacts break a rival's lock. Defense and burst resistance help it survive.\n\nRING OUT\nContact and arena pulses can throw a top outside. Mass, control and stable tilt keep it safe.\n\nSPACE switches match speed. ESC pauses. Victory unlocks tougher rivals and new parts; the Lab lets you experiment freely."],
	]
	for guide in guides:
		var card = _card(row)
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(UI.label(guide[0], 32, UI.CYAN))
		card.add_child(UI.paragraph(guide[1], 19, UI.GOLD))
		card.add_child(UI.paragraph(guide[2], 17, UI.WHITE))
	frame.add_child(UI.button("I'M READY  /  ENTER WORKSHOP", _show_workshop, true))

func _show_settings(back: String) -> void:
	previous_screen = back
	_new_page("settings")
	_bg()
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(center)
	var card = _card(center, 560)
	card.add_child(UI.label("SET YOUR STAGE", 49, UI.CYAN))
	card.add_child(UI.label("MASTER VOLUME", 16, UI.MUTED))
	var volume = HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.01
	volume.value = float(profile.settings.get("volume", 0.65))
	card.add_child(volume)
	volume.value_changed.connect(func(v):
		profile.settings.volume = v
		sound.set_volume(v))
	for setting in [["fullscreen", "FULLSCREEN"], ["shake", "IMPACT CAMERA SHAKE"], ["reduced_flashes", "REDUCED FLASHES"]]:
		var toggle = CheckButton.new()
		toggle.text = setting[1]
		toggle.button_pressed = bool(profile.settings.get(setting[0], false))
		card.add_child(toggle)
		var key: String = setting[0]
		toggle.toggled.connect(func(v):
			profile.settings[key] = v
			if key == "fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED))
	card.add_child(UI.paragraph("Window resizing keeps the arena and controls together. F11 toggles fullscreen anywhere. Career progress is stored locally in your user data folder.", 15))
	card.add_child(UI.button("START A NEW CAREER…", func(): _confirm_reset(card)))
	card.add_child(UI.button("SAVE & RETURN", func():
		profile.save_profile()
		if back == "workshop": _show_workshop()
		else: _show_title(), true))

func _confirm_reset(parent: Node) -> void:
	if parent.has_node("ResetPrompt"): return
	var box = PanelContainer.new()
	box.name = "ResetPrompt"
	box.add_theme_stylebox_override("panel", UI.panel(Color("23172b"), UI.PINK))
	parent.add_child(box)
	var stack = UI.vbox(box, 9)
	stack.add_child(UI.paragraph("Start from the underpass again? This resets your career, credits, parts, and saved builds. Your settings stay as they are.", 15, UI.WHITE))
	var row = UI.hbox(stack)
	row.add_child(UI.button("KEEP MY CAREER", func(): box.queue_free(), true))
	row.add_child(UI.button("RESET CAREER", func():
		var prefs = profile.settings.duplicate()
		profile.reset_profile()
		profile.settings = prefs
		profile.save_profile()
		_show_workshop()))

func _input(event: InputEvent) -> void:
	# Gameplay bindings take precedence over a focused button's ui_accept event.
	# Handle both edges so one press cannot wind/launch and click a menu button.
	if not event is InputEventKey or event.echo: return
	if event.keycode == KEY_SPACE and screen in ["launch", "battle"]:
		_unhandled_key_input(event)
		get_viewport().set_input_as_handled()
	elif event.pressed and event.keycode in [KEY_ESCAPE, KEY_F11]:
		_unhandled_key_input(event)
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	if event.keycode == KEY_F11 and event.pressed:
		var full = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)
		profile.settings.fullscreen = full
		profile.save_profile()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and event.pressed:
		if screen == "battle": _toggle_pause()
		elif screen in ["launch", "help", "settings"]:
			if screen == "launch" or previous_screen == "workshop": _show_workshop()
			else: _show_title()
		elif screen == "workshop": _show_title()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_SPACE:
		if screen == "launch":
			if event.pressed:
				if launch_phase == 2: _snap_launch()
				else: _wind_start()
			else: _wind_release()
			get_viewport().set_input_as_handled()
		elif screen == "battle" and event.pressed:
			_toggle_speed()
			get_viewport().set_input_as_handled()
