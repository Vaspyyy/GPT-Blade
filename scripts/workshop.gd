class_name Workshop
extends Control

signal battle_requested(rival: Dictionary, practice: bool)
signal settings_requested
signal title_requested

const U = preload("res://scripts/ui.gd")
const TOP_VIEW = preload("res://scripts/top_view.gd")
const CATEGORIES := ["blade", "disc", "driver", "core"]
const FAMILY_LABELS := {"blade": "BLADE", "disc": "WEIGHT DISC", "driver": "DRIVER", "core": "SPIRIT CORE"}
const STAT_LABELS := {"attack": "ATTACK", "defense": "DEFENSE", "stamina": "STAMINA", "speed": "SPEED", "weight": "WEIGHT", "burst": "BURST LOCK", "control": "CONTROL"}
var profile: Career
var tab := "BUILD"
var category := "blade"
var comparison := ""
var practice_arena := "skyline"
var body: HBoxContainer
var sidebar: VBoxContainer
var content: VBoxContainer
var layout: VBoxContainer
var notification := ""

func initialize(value: Career) -> void:
	profile = value
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side != "bottom" else 16)
	add_child(margin)
	layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	_build_header()
	body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	layout.add_child(body)
	sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 340
	sidebar.add_theme_constant_override("separation", 11)
	body.add_child(sidebar)
	_build_sidebar()
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	body.add_child(content)
	if tab == "CAREER":
		_build_career()
	elif tab == "LAB":
		_build_lab()
	else:
		_build_parts()
	_build_rival_strip()
	var footer := HBoxContainer.new()
	layout.add_child(footer)
	var help := U.label("B  BUILD     C  CAREER     L  LAB     1–4  PART FAMILY     ENTER  NEXT MATCH     P  PRACTICE", 12, U.MUTED)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(help)
	footer.add_child(U.label("AUTOSAVED  ·  NATIVE LINUX", 12, U.CYAN))
	if not profile.save_error.is_empty():
		layout.add_child(_wrapped(profile.save_error, 14, U.PINK))

func _build_header() -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 58
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(U.label("SPIN//ASCEND", 34, U.CYAN))
	brand.add_child(U.label("BUILD YOUR TOP.  WRITE YOUR LEGEND.", 12, U.MUTED))
	for title in ["BUILD", "CAREER", "LAB"]:
		var button := U.button(title, func(): _select_tab(title), tab == title)
		button.custom_minimum_size = Vector2(106, 43)
		header.add_child(button)
	var purse := VBoxContainer.new()
	purse.custom_minimum_size.x = 150
	header.add_child(purse)
	purse.add_child(U.label(str(profile.credits) + "  CR", 24, U.GOLD))
	purse.add_child(U.label(profile.league_name(), 11, U.MUTED))
	header.add_child(U.button("SETTINGS", func(): settings_requested.emit()))

func _build_sidebar() -> void:
	for child in sidebar.get_children():
		sidebar.remove_child(child)
		child.queue_free()
	var equipped_stats := Catalog.stats(profile.loadout)
	var display_loadout := profile.loadout.duplicate(true)
	if not comparison.is_empty():
		var candidate := Catalog.part(comparison)
		if not candidate.is_empty():
			display_loadout[candidate.category] = comparison
	var shown_stats := Catalog.stats(display_loadout)
	var heading := HBoxContainer.new()
	sidebar.add_child(heading)
	heading.add_child(U.label("YOUR CREATION" if comparison.is_empty() else "PART COMPARISON", 15, U.CYAN))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	if not comparison.is_empty():
		heading.add_child(_compact_button("CLEAR", func(): comparison = ""; _build_sidebar()))
	var preview_panel := _panel(U.INK, U.CYAN.darkened(0.6))
	preview_panel.custom_minimum_size.y = 180
	sidebar.add_child(preview_panel)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 0)
	preview_panel.add_child(preview_box)
	var preview := TOP_VIEW.new()
	preview.custom_minimum_size = Vector2(300, 139)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.ready.connect(func(): preview.custom_minimum_size = Vector2(300, 139))
	preview_box.add_child(preview)
	preview.custom_minimum_size = Vector2(300, 139)
	preview.set_loadout(display_loadout)
	var name_label := U.label(str(shown_stats.name).to_upper(), 22, shown_stats.color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(name_label)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 4)
	sidebar.add_child(stats_box)
	for stat in STAT_LABELS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		stats_box.add_child(row)
		var text_label := U.label(STAT_LABELS[stat], 12, U.MUTED)
		text_label.custom_minimum_size.x = 91
		row.add_child(text_label)
		var bar := ProgressBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 8
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.value = float(shown_stats[stat])
		var bar_bg := U.panel(Color("14203a"), Color.TRANSPARENT, 4)
		var bar_fill := U.panel(U.CYAN if stat not in ["attack", "burst"] else U.GOLD, Color.TRANSPARENT, 4)
		for style in [bar_bg, bar_fill]:
			style.content_margin_top = 0
			style.content_margin_bottom = 0
			style.content_margin_left = 0
			style.content_margin_right = 0
		bar.add_theme_stylebox_override("background", bar_bg)
		bar.add_theme_stylebox_override("fill", bar_fill)
		row.add_child(bar)
		var delta: int = roundi(float(shown_stats[stat]) - float(equipped_stats[stat]))
		var number := U.label(str(roundi(shown_stats[stat])) + ((" %+d" % delta) if delta != 0 else ""), 13, U.GOLD if delta > 0 else (U.PINK if delta < 0 else Color.WHITE))
		number.custom_minimum_size.x = 56
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(number)
	var loadout_box := VBoxContainer.new()
	loadout_box.add_theme_constant_override("separation", 2)
	sidebar.add_child(loadout_box)
	for family in CATEGORIES:
		var item := Catalog.part(profile.loadout[family])
		var row := HBoxContainer.new()
		loadout_box.add_child(row)
		var title := U.label(FAMILY_LABELS[family], 11, U.MUTED)
		title.custom_minimum_size.x = 91
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(title)
		var slot := _compact_button(item.name, func(): category = family; comparison = ""; tab = "BUILD"; _rebuild())
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size.y = 28
		row.add_child(slot)
	var behavior := Catalog.part(display_loadout.driver)
	var spirit := Catalog.part(display_loadout.core)
	sidebar.add_child(_wrapped(str(behavior.title) + "  //  " + str(spirit.title), 14, U.CYAN))
	sidebar.add_child(_wrapped(str(behavior.description), 13, U.MUTED))
	if not profile.last_report.is_empty():
		var report_panel := _panel(Color("11192d"), U.GOLD.darkened(0.65))
		sidebar.add_child(report_panel)
		var report_box := VBoxContainer.new()
		report_box.add_theme_constant_override("separation", 6)
		report_panel.add_child(report_box)
		var report := profile.last_report
		report_box.add_child(U.label("LAST MATCH  ·  " + ("VICTORY" if report.get("won", false) else "LESSON LEARNED"), 12, U.GOLD))
		var full_lesson := str(report.get("lesson", "Change one part, then try again."))
		var lesson := _wrapped(full_lesson.left(120) + ("…" if full_lesson.length() > 120 else ""), 12, U.MUTED)
		lesson.max_lines_visible = 3
		lesson.tooltip_text = full_lesson
		report_box.add_child(lesson)
	else:
		sidebar.add_child(_wrapped("Twelve starter parts are already yours. Try a hunter, a center guard, or an endurance build before spending credits.", 13, U.MUTED))

func _build_parts() -> void:
	var intro := HBoxContainer.new()
	content.add_child(intro)
	var title := U.label("THE WORKSHOP", 30, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(title)
	intro.add_child(U.label("TIER " + str(profile.unlocked_tier()) + " AVAILABLE", 13, U.GOLD))
	content.add_child(_wrapped("Every part has a tradeoff. Compare the whole build, then change one piece and launch again.", 15, U.MUTED))
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 8)
	content.add_child(categories)
	for family in CATEGORIES:
		var button := U.button(FAMILY_LABELS[family], func(): category = family; comparison = ""; _rebuild(), category == family)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		categories.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 11)
	grid.add_theme_constant_override("v_separation", 11)
	scroll.add_child(grid)
	for item in Catalog.parts(category):
		grid.add_child(_part_card(item))
	if not notification.is_empty():
		content.add_child(U.label(notification, 14, U.GOLD))

func _part_card(item: Dictionary) -> PanelContainer:
	var equipped: bool = profile.loadout[item.category] == item.id
	var owned: bool = item.id in profile.owned
	var locked: bool = int(item.tier) > profile.unlocked_tier()
	var card := _panel(Color("101a2d"), item.color if equipped else Color("26344f"))
	card.custom_minimum_size = Vector2(240, 202)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := U.label(str(item.name).to_upper(), 19, item.color)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title)
	head.add_child(U.label("T" + str(item.tier), 11, U.MUTED))
	box.add_child(U.label(item.title, 11, U.GOLD))
	var description := _wrapped(item.description, 13, U.MUTED)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	var modifiers: Array[String] = []
	for stat in item.stats:
		modifiers.append(("%+d " % int(item.stats[stat])) + str(stat).to_upper().replace("DEFENSE", "DEF").replace("STAMINA", "STA").replace("CONTROL", "CTRL").replace("ATTACK", "ATK"))
	box.add_child(_wrapped("  ·  ".join(modifiers), 11, U.CYAN))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	box.add_child(actions)
	var compare := _compact_button("COMPARE", func(): comparison = item.id; _build_sidebar())
	compare.custom_minimum_size.y = 31
	actions.add_child(compare)
	var action_text := "EQUIPPED" if equipped else ("EQUIP" if owned else ("LEAGUE " + str(item.tier + 1) if locked else str(item.cost) + " CR"))
	var action := _compact_button(action_text, func(): _acquire(item.id), owned and not equipped)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.custom_minimum_size.y = 31
	action.disabled = equipped or locked or (not owned and profile.credits < int(item.cost))
	action.tooltip_text = "Advance to " + Career.LEAGUES[item.tier] + " to unlock this part." if locked else ("Already fitted to your top." if equipped else ("Buy and immediately equip. Permanent ownership." if not owned else "Equip this owned part."))
	actions.add_child(action)
	return card

func _acquire(id: String) -> void:
	var item := Catalog.part(id)
	var previously_owned: bool = id in profile.owned
	if profile.buy(id):
		profile.equip(id)
		comparison = ""
		notification = str(item.name) + (" equipped." if previously_owned else " unlocked and equipped. Yours permanently.")
		_rebuild()

func _build_career() -> void:
	content.add_child(U.label("ROAD TO THE SKYLINE", 30, Color.WHITE))
	var sub := "%d / 12 RIVALS DEFEATED  ·  %d WINS  ·  %d LESSONS" % [profile.rung, profile.wins, profile.losses]
	content.add_child(U.label(sub, 13, U.GOLD))
	if profile.is_champion():
		content.add_child(_wrapped("YOU ARE THE SKYLINE CHAMPION. The city knows your name. Legend rematches cycle old rivals, award credits, and leave every part open for experimentation.", 18, U.CYAN))
	else:
		content.add_child(_wrapped("Win three matches to reach the next league and open new parts. Defeats cost nothing. Change your build, practice your launch, and come back stronger.", 15, U.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var career_box := VBoxContainer.new()
	career_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	career_box.add_theme_constant_override("separation", 8)
	scroll.add_child(career_box)
	var ladder := profile.rivals()
	for league in range(4):
		career_box.add_child(U.label("0" + str(league + 1) + "  //  " + Career.LEAGUES[league], 18, U.GOLD if profile.unlocked_tier() >= league else U.MUTED))
		for index in range(league * 3, league * 3 + 3):
			var rival: Dictionary = ladder[index]
			var panel := _panel(Color("10192b"), U.CYAN.darkened(0.4) if index == profile.rung else Color("223049"))
			career_box.add_child(panel)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 14)
			panel.add_child(row)
			var status := U.label("✓" if index < profile.rung else ("▶" if index == profile.rung else "%02d" % (index + 1)), 24, U.CYAN if index <= profile.rung else U.MUTED)
			status.custom_minimum_size.x = 38
			row.add_child(status)
			var details := VBoxContainer.new()
			details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(details)
			details.add_child(U.label(rival.name + "  ·  " + rival.title, 17, rival.color))
			details.add_child(_wrapped("“" + str(rival.quote) + "”", 13, U.MUTED))
			if index == profile.rung:
				details.add_child(_wrapped(str(rival.advice), 13, U.CYAN))
			row.add_child(U.label("+" + str(rival.reward) + " CR", 15, U.GOLD))

func _build_lab() -> void:
	content.add_child(U.label("THE EXPERIMENT LAB", 30, Color.WHITE))
	content.add_child(_wrapped("Start with a purpose. Presets use owned parts, and practice matches never change the ladder. Try one change between launches.", 15, U.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 11)
	scroll.add_child(box)
	var memory_panel := _panel(Color("111c30"), U.CYAN.darkened(0.65))
	box.add_child(memory_panel)
	var memory := VBoxContainer.new()
	memory.add_theme_constant_override("separation", 7)
	memory_panel.add_child(memory)
	memory.add_child(U.label("YOUR SAVED BUILDS", 18, U.CYAN))
	for slot in range(3):
		var saved: Dictionary = profile.saved_builds[slot]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		memory.add_child(row)
		row.add_child(U.label("0" + str(slot + 1), 15, U.GOLD))
		var name_label := U.label(str(saved.get("name", "EMPTY SLOT  /  save your current creation")), 13, U.MUTED if saved.is_empty() else Color.WHITE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(name_label)
		var recall := _compact_button("RECALL", func(): _recall_build(slot))
		recall.disabled = saved.is_empty()
		row.add_child(recall)
		var store := _compact_button("SAVE CURRENT", func(): profile.store_build(slot); notification = "Build saved in slot " + str(slot + 1) + "."; _rebuild())
		store.tooltip_text = "Replace this slot with your current equipped top. Your owned parts are never consumed."
		row.add_child(store)
	var presets := [
		{"name": "CRIMSON HUNTER", "description": "Fang / Halo / Rush / Nova. Chase early burst finishes; attack costs endurance and lock safety.", "ids": ["fang", "halo", "rush", "nova"], "color": U.PINK},
		{"name": "SILENT MARATHON", "description": "Lotus / Halo / Needle / Aegis. Save every rotation at the center; powerful shoves are your enemy.", "ids": ["lotus", "halo", "needle", "aegis"], "color": Color("92ecc0")},
		{"name": "IRON SANCTUARY", "description": "Comet / Anvil / Anchor / Aegis. Hold the center and absorb rushes; patient opponents may outspin you.", "ids": ["comet", "anvil", "anchor", "aegis"], "color": Color("b7bfff")},
		{"name": "NEON SLINGSHOT", "description": "Fang / Feather / Orbit / Nova. Wide, fast arcs set up sweeping clashes. Lightweight mass risks the edge.", "ids": ["fang", "feather", "orbit", "nova"], "color": U.CYAN},
	]
	var preset_grid := GridContainer.new()
	preset_grid.columns = 2
	preset_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_grid.add_theme_constant_override("h_separation", 11)
	preset_grid.add_theme_constant_override("v_separation", 11)
	box.add_child(preset_grid)
	for preset in presets:
		var panel := _panel(Color("101a2d"), preset.color.darkened(0.6))
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size.y = 140
		preset_grid.add_child(panel)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 7)
		panel.add_child(inner)
		inner.add_child(U.label(preset.name, 20, preset.color))
		inner.add_child(_wrapped(preset.description, 14, U.MUTED))
		inner.add_child(_compact_button("FIT THIS BUILD", func(): _apply_preset(preset.ids)))
	box.add_child(U.label("PRACTICE ARENA", 18, U.GOLD))
	var arena_grid := GridContainer.new()
	arena_grid.columns = 2
	arena_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_grid.add_theme_constant_override("h_separation", 11)
	arena_grid.add_theme_constant_override("v_separation", 11)
	box.add_child(arena_grid)
	for arena in Catalog.arenas():
		var arena_panel := _panel(Color("10192a"), arena.color.darkened(0.45) if arena.id == practice_arena else Color("23314a"))
		arena_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arena_grid.add_child(arena_panel)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 7)
		arena_panel.add_child(inner)
		inner.add_child(U.label(arena.name.to_upper(), 19, arena.color))
		inner.add_child(_wrapped(arena.description, 13, U.MUTED))
		inner.add_child(_compact_button("SELECTED" if arena.id == practice_arena else "SELECT ARENA", func(): practice_arena = arena.id; _rebuild(), arena.id == practice_arena))
	if not notification.is_empty():
		content.add_child(U.label(notification, 14, U.GOLD))
	box.add_child(_wrapped("READ THE TRADEOFFS\nAttack breaks locks and pushes rivals. Defense softens contact. Stamina slows spin loss. Speed improves pursuit but spends spin. Weight resists ring outs. Burst protects the lock. Control steadies movement and your launch.", 14, U.MUTED))

func _recall_build(slot: int) -> void:
	if profile.recall_build(slot):
		comparison = ""
		notification = "Saved build recalled. Ready to launch."
		_rebuild()

func _apply_preset(ids: Array) -> void:
	for id in ids:
		profile.equip(id)
	comparison = ""
	notification = "Preset fitted. Launch it, then change one part and compare."
	_rebuild()

func _build_rival_strip() -> void:
	var rival := profile.current_rival()
	var panel := _panel(Color("16213a"), rival.color.darkened(0.6))
	panel.custom_minimum_size.y = 148
	content.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 5)
	row.add_child(details)
	details.add_child(U.label("LEGEND REMATCH" if profile.is_champion() else "NEXT RIVAL  ·  MATCH " + str(profile.rung + 1) + " / 12", 11, U.GOLD))
	details.add_child(U.label(rival.name + "  //  " + rival.title, 22, rival.color))
	var arena_name := str(rival.arena)
	for arena in Catalog.arenas():
		if arena.id == rival.arena:
			arena_name = arena.name
	details.add_child(U.label(arena_name.to_upper() + "   ·   WIN +" + str(rival.reward) + " CR", 12, U.MUTED))
	details.add_child(_wrapped(str(rival.advice), 13, U.CYAN))
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 196
	actions.add_theme_constant_override("separation", 8)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(actions)
	var launch := U.button("LAUNCH MATCH  ›", func(): _request_battle(false), true)
	launch.custom_minimum_size.y = 48
	actions.add_child(launch)
	var practice := U.button("PRACTICE  [P]", func(): _request_battle(true))
	practice.tooltip_text = "Your current rival, in the selected Lab arena. No ladder progress, no cost."
	actions.add_child(practice)

func _request_battle(practice: bool) -> void:
	var rival := profile.current_rival()
	if practice:
		rival.arena = practice_arena
	battle_requested.emit(rival, practice)

func _select_tab(value: String) -> void:
	tab = value
	comparison = ""
	notification = ""
	_rebuild()

func _compact_button(value: String, callback: Callable = Callable(), primary: bool = false) -> Button:
	var button := U.button(value, callback, primary)
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size.y = 31
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = button.get_theme_stylebox(state).duplicate()
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		style.content_margin_left = 8
		style.content_margin_right = 8
		button.add_theme_stylebox_override(state, style)
	return button

func _panel(bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := U.panel(bg, border, 12)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _wrapped(value: String, size: int = 15, color: Color = Color.WHITE) -> Label:
	var label := U.label(value, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_B: _select_tab("BUILD")
		KEY_C: _select_tab("CAREER")
		KEY_L: _select_tab("LAB")
		KEY_ENTER, KEY_KP_ENTER: _request_battle(false)
		KEY_P: _request_battle(true)
		KEY_1, KEY_2, KEY_3, KEY_4:
			category = CATEGORIES[event.keycode - KEY_1]
			tab = "BUILD"
			comparison = ""
			_rebuild()
		_: return
	get_viewport().set_input_as_handled()
