class_name ArenaView
extends Control

var sim: BattleSim
var arena: Dictionary = {}
var effects: Array = []
var trails: Array = [[], []]
var clock: float = 0.0
var shake: float = 0.0
var shake_enabled: bool = true
var reduced_flashes: bool = false
var offset = Vector2.ZERO
var launch_angle: float = 0.0
var launch_tilt: float = 0.35
var show_launch: bool = false
var preview_loadout: Dictionary = {}
var opponent_loadout: Dictionary = {}
var last_trace: float = 0.0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 2401

func set_match(value: BattleSim, stadium: Dictionary) -> void:
	sim = value
	arena = stadium
	effects.clear()
	trails = [[], []]
	show_launch = false

func add_events(events: Array) -> void:
	for ev in events:
		var event: Dictionary = ev.duplicate()
		event.age = 0.0
		var kind = str(event.get("type", "clash"))
		event.life = 0.55
		if kind == "ability": event.life = 1.9
		elif kind == "charge": event.life = 1.0
		elif kind in ["burst", "ringout", "finish"]: event.life = 2.1
		event.seed = rng.randi()
		effects.append(event)
		if kind in ["clash", "ability", "burst"]:
			shake = minf(17.0, maxf(shake, float(event.get("intensity", 0.5)) * 11.0))
	if effects.size() > 42:
		effects = effects.slice(-42)

func _process(delta: float) -> void:
	clock += delta
	shake = maxf(0, shake - delta * 40)
	offset = Vector2(sin(clock * 109), cos(clock * 93)) * shake if shake_enabled else Vector2.ZERO
	for ev in effects:
		ev.age += delta
	effects = effects.filter(func(ev): return ev.age < ev.life)
	if sim != null and sim.tops.size() == 2 and clock - last_trace > 0.024:
		last_trace = clock
		for i in range(2):
			trails[i].append(sim.tops[i].pos)
			if trails[i].size() > 22: trails[i].pop_front()
	queue_redraw()

func metrics() -> Dictionary:
	var radius = minf(size.x * 0.425, size.y * 0.64)
	return {"center": Vector2(size.x * 0.5, size.y * 0.52) + offset, "radius": radius}

func project(point: Vector2) -> Vector2:
	var m = metrics()
	return m.center + Vector2(point.x, point.y * 0.61) * m.radius

func _draw() -> void:
	var m = metrics()
	var at: Vector2 = m.center
	var radius: float = m.radius
	var accent: Color = arena.get("color", UI.CYAN)
	# Vast dark room, illuminated seating, and a sculpted dish.
	draw_rect(Rect2(Vector2.ZERO, size), Color("080e1c"))
	_draw_stadium_environment(accent)
	for i in range(7):
		TopView.ellipse(self, at, Vector2(radius * (1.22 + i * 0.025), radius * (0.74 + i * 0.015)), Color(accent, 0.016), false, 4)
	for i in range(96):
		var a = TAU * i / 96.0
		var dot = at + Vector2(cos(a) * radius * 1.21, sin(a) * radius * 0.78)
		draw_circle(dot, 1.7 if i % 4 != 0 else 2.5, Color(accent if i % 3 == 0 else UI.MUTED, 0.35))
	TopView.ellipse(self, at + Vector2(0, radius * 0.075), Vector2(radius * 1.073, radius * 0.66), Color("02050d"))
	for i in range(10):
		var y = radius * (0.065 - i * 0.008)
		TopView.ellipse(self, at + Vector2(0, y), Vector2(radius * 1.065, radius * 0.658), Color("26364f").darkened(0.42 - i * 0.025))
	TopView.ellipse(self, at, Vector2(radius * 1.065, radius * 0.658), Color("344964"), false, 3)
	TopView.ellipse(self, at, Vector2(radius * 1.035, radius * 0.635), Color(accent, 0.7), false, 2)
	TopView.ellipse(self, at, Vector2(radius, radius * 0.61), Color("101d31"))
	for i in range(8):
		var r = radius * (1.0 - i * 0.088)
		TopView.ellipse(self, at, Vector2(r, r * 0.61), Color("192940").lightened(i * 0.009))
		TopView.ellipse(self, at, Vector2(r, r * 0.61), Color(accent, 0.035), false, 1)
	# Fine stadium lanes. Radial white hash marks reveal spin paths.
	for i in range(48):
		var a = TAU * i / 48.0
		var v = Vector2(cos(a), sin(a))
		draw_line(project(v * 0.925), project(v * 0.97), Color(accent, 0.4 if i % 4 == 0 else 0.12), 2 if i % 4 == 0 else 1, true)
	for i in range(12):
		var a = TAU * i / 12.0
		var v = Vector2(cos(a), sin(a))
		draw_line(project(v * 0.25), project(v * 0.9), Color(UI.WHITE, 0.035), 1, true)
	TopView.ellipse(self, at, Vector2(radius * 0.25, radius * 0.152), Color(accent, 0.14), false, 1.6)
	TopView.ellipse(self, at, Vector2(radius * 0.08, radius * 0.049), Color(accent, 0.08))
	var hazard = str(arena.get("hazard", ""))
	if hazard == "heat":
		var active_heat = sim != null and sim.time > 5 and fposmod(sim.time - 5.0, 6.0) < 2.0
		var heat_color = Color(UI.PINK, 0.3 if active_heat else 0.065)
		TopView.ellipse(self, at, Vector2(radius * 0.72, radius * 0.439), heat_color, false, radius * 0.18)
		TopView.ellipse(self, at, Vector2(radius * 0.57, radius * 0.348), Color(UI.GOLD, 0.65 if active_heat else 0.2), false, 2)
		if active_heat:
			for i in range(24):
				var a = i * TAU / 24
				var q = project(Vector2.from_angle(a) * 0.85)
				draw_line(q, q + Vector2(0, -10 - 7 * sin(clock * 6 + i)), Color(UI.GOLD, 0.35), 2, true)
	elif hazard == "pulse":
		var until_pulse = 5.0 if sim == null or sim.time < 5 else 7.0 - fposmod(sim.time - 5, 7.0)
		var warning = clampf((2.0 - until_pulse) / 2, 0, 1)
		TopView.ellipse(self, at, Vector2(radius * 0.36, radius * 0.22), Color(accent, 0.09 + warning * 0.4), false, 3)
		for i in range(6):
			var a = TAU * i / 6 + clock * 0.2
			var r = radius * 0.24
			var q = at + Vector2(cos(a), sin(a) * 0.61) * r
			draw_circle(q, 3, Color(accent, 0.25 + warning * 0.5))
	elif hazard == "ice":
		for i in range(9):
			var a = TAU * i / 9 + 0.15
			var p = project(Vector2.from_angle(a) * 0.82)
			var edge = PackedVector2Array([p, p + Vector2(9, -10), p + Vector2(14, 5)])
			draw_polyline(edge, Color(accent, 0.19), 1, true)
	# Ring-out exits, alternating with raised rails.
	for i in range(4):
		var a = TAU * (i + 0.5) / 4
		var v = Vector2.from_angle(a)
		var p = project(v * 1.015)
		var tangent = Vector2(-v.y, v.x * 0.61).normalized()
		draw_line(p - tangent * 25, p + tangent * 25, Color(UI.PINK, 0.8), 5, true)
		draw_line(p - tangent * 20 + Vector2(0, 6), p + tangent * 20 + Vector2(0, 6), Color(UI.PINK, 0.17), 5, true)
	var font = UI.font_title()
	var title = str(arena.get("name", "NEON DOJO")).to_upper()
	draw_string(font, Vector2(32, 38), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(accent, 0.8))
	draw_string(UI.font_body(), Vector2(32, 62), str(arena.get("subtitle", "AUTONOMOUS COMBAT • BUILT BY YOU")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.MUTED)
	draw_string(font, Vector2(at.x - 88, at.y + radius * 0.49), "SPIN // ASCEND", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(UI.WHITE, 0.09))
	if sim != null and sim.tops.size() == 2:
		for i in range(2):
			_draw_trail(i)
		var order = [0, 1] if sim.tops[0].pos.y <= sim.tops[1].pos.y else [1, 0]
		for i in order:
			_draw_top(i, sim.tops[i])
	else:
		_draw_idle(0, Vector2(-0.39, -0.06), preview_loadout, UI.CYAN)
		_draw_idle(1, Vector2(0.39, 0.06), opponent_loadout, UI.PINK)
	if show_launch:
		var entry = Vector2(-0.43, 0.12)
		var aim = entry + Vector2.from_angle(launch_angle) * 0.75
		for i in range(12):
			var f = i / 12.0
			var a = entry.lerp(aim, f)
			var b = entry.lerp(aim, f + 0.035)
			draw_line(project(a), project(b), Color(UI.CYAN, 0.6), 3, true)
		var tip = project(aim)
		draw_circle(tip, 8, Color(UI.CYAN, 0.12))
		draw_circle(tip, 4, UI.CYAN)
		var from = project(entry)
		TopView.ellipse(self, from, Vector2(39, 24), Color(UI.CYAN, 0.35), false, 2)
	for ev in effects:
		_draw_effect(ev)

func _draw_idle(actor: int, pos: Vector2, loadout: Dictionary, fallback: Color) -> void:
	var col: Color = fallback
	var style = ""
	if not loadout.is_empty():
		style = str(loadout.get("blade", ""))
		col = Catalog.part(style).get("color", fallback)
	TopView.paint(self, project(pos), metrics().radius * 0.085, col, clock * (2.0 if actor == 0 else -1.8), style)

func _draw_top(actor: int, top: Dictionary) -> void:
	var col: Color = UI.CYAN if actor == 0 else UI.PINK
	var p = project(top.pos)
	var radius: float = metrics().radius * 0.085
	if top.get("active", true):
		var wobble = maxf(0, 20.0 - float(top.spin)) * 0.13
		p += Vector2(sin(clock * 30), cos(clock * 26)) * wobble
		TopView.ellipse(self, p, Vector2(radius * 1.23, radius * 0.75), Color(col, 0.2), false, 2)
		if sim.time < float(top.get("shield_until", -1)):
			TopView.ellipse(self, p - Vector2(0, 6), Vector2(radius * 1.55, radius * 1.1), Color(col, 0.13))
			TopView.ellipse(self, p - Vector2(0, 6), Vector2(radius * 1.55, radius * 1.1), Color(col, 0.72), false, 2)
			for j in range(6):
				var a = TAU * j / 6 + clock * 0.4
				var q = p + Vector2(cos(a), sin(a) * 0.75) * radius * 1.45
				draw_circle(q, 3, col)
		if sim.time < float(top.get("vortex_until", -1)):
			for j in range(2):
				var spiral = PackedVector2Array()
				for k in range(32):
					var a = k * 0.19 + clock * 6 + j * PI
					var r = radius * (0.7 + k * 0.07)
					spiral.append(p + Vector2(cos(a), sin(a) * 0.61) * r)
				draw_polyline(spiral, Color(col, 0.23), 2, true)
		if top.get("charging", false):
			var aim: Vector2 = top.get("aim", Vector2.RIGHT)
			var tip = project(Vector2(top.pos) + aim * 0.30)
			draw_line(p, tip, Color(col, 0.45 + 0.2 * sin(clock * 14)), 2, true)
			TopView.ellipse(self, p, Vector2(radius * 1.8, radius * 1.1), Color(col, 0.15), false, 2)
		var top_color: Color = top.get("color", col)
		TopView.paint(self, p, radius, top_color, float(top.get("rotation", clock * 20)), str(top.get("blade", top.get("name", ""))), float(top.get("energy", 0)))
		if float(top.get("energy", 0)) > 82:
			for j in range(3):
				var ang = clock * 3 + j * TAU / 3
				var ray = p + Vector2(cos(ang), sin(ang) * 0.62) * radius * 1.5
				draw_line(ray, ray + Vector2(0, -20 - sin(clock * 5) * 7), Color(col, 0.5), 2, true)
	else:
		TopView.ellipse(self, p + Vector2(0, 8), Vector2(radius, radius * 0.62), Color(col, 0.14))
		TopView.paint(self, p, radius * 0.9, top.get("color", col).darkened(0.4), float(top.get("rotation", 0)), "", 0)
	# Position markers retain identity even if both builds share a blade color.
	var marker = p + Vector2(0, -radius * 0.9 - 16)
	draw_colored_polygon(PackedVector2Array([marker + Vector2(-4, -4), marker + Vector2(4, -4), marker + Vector2(0, 2)]), col)
	draw_string(UI.font_title(), marker + Vector2(-12, -8), "YOU" if actor == 0 else "RIVAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

func _draw_trail(actor: int) -> void:
	var col = UI.CYAN if actor == 0 else UI.PINK
	var trace: Array = trails[actor]
	for i in range(1, trace.size()):
		var a = project(trace[i - 1])
		var b = project(trace[i])
		var f = float(i) / trace.size()
		draw_line(a, b, Color(col, f * 0.14), 10 * f, true)
		draw_line(a, b, Color(col.lightened(0.5), f * 0.5), 2 * f, true)

func _draw_effect(ev: Dictionary) -> void:
	var age: float = ev.age
	var life: float = ev.life
	var f = age / life
	var fade = maxf(0, 1 - f)
	var actor: int = int(ev.get("actor", 0))
	var col = UI.CYAN if actor == 0 else UI.PINK
	var p = project(ev.get("pos", Vector2.ZERO))
	var kind = str(ev.get("type", "clash"))
	var intensity = clampf(float(ev.get("intensity", 1)), 0.25, 2)
	var radius: float = metrics().radius
	if kind == "hazard":
		if str(ev.get("name", "")).contains("PULSE"):
			TopView.ellipse(self, p, Vector2(radius * f * 1.5, radius * f * 0.91), Color(UI.PINK, fade * 0.35), false, 6 * fade)
			TopView.ellipse(self, p, Vector2(radius * f * 1.2, radius * f * 0.73), Color(UI.WHITE, fade * 0.25), false, 2)
		else:
			TopView.ellipse(self, p, Vector2(radius * 0.77, radius * 0.47), Color(UI.GOLD, fade * 0.22), false, 5)
	elif kind == "charge":
		var r = 25 + age * 30
		TopView.ellipse(self, p, Vector2(r, r * 0.62), Color(col, fade * 0.7), false, 3)
		for i in range(8):
			var a = i * TAU / 8 - age * 6
			var point = p + Vector2(cos(a) * r, sin(a) * r * 0.62)
			draw_line(point, point + Vector2(0, -40 * f), Color(col, fade * 0.6), 2, true)
	elif kind == "ability":
		var r = (35 + radius * 0.38 * sin(minf(f * 2, 1) * PI * 0.5))
		TopView.ellipse(self, p, Vector2(r, r * 0.61), Color(col, fade * 0.25), false, 2 + fade * 4)
		_draw_spirit(p, col, str(ev.get("name", "")), f, radius * 0.34)
		for i in range(12):
			var a = i * TAU / 12 + float(ev.get("seed", 0) % 20)
			var va = Vector2(cos(a), sin(a) * 0.65)
			draw_line(p + va * (30 + f * 100), p + va * (50 + f * radius * 0.7), Color(col, fade * 0.6), fade * 2.5, true)
		if not reduced_flashes and f < 0.1:
			draw_rect(Rect2(Vector2.ZERO, size), Color(col, (0.1 - f) * 0.7))
	elif kind in ["clash", "burst", "ringout"]:
		var boost = 2.0 if kind != "clash" else intensity
		TopView.ellipse(self, p, Vector2((10 + age * 140) * boost, (6 + age * 85) * boost), Color(UI.GOLD if kind == "clash" else col, fade * 0.8), false, fade * 4)
		for i in range(18 if kind != "clash" else 10):
			var a = i * 2.399 + float(ev.get("seed", 0) % 10)
			var v = Vector2(cos(a), sin(a))
			var speed = 70 + (i % 5) * 45
			var spark = p + v * speed * age * boost + Vector2(0, age * age * 80)
			if kind == "burst":
				var poly = PackedVector2Array([spark, spark + v.rotated(0.8) * 15 * fade, spark + v * 26 * fade])
				draw_colored_polygon(poly, Color(col, fade))
			else:
				draw_line(spark, spark - v * 12 * fade, Color(UI.GOLD, fade), 2.3 * fade, true)
		if kind == "clash" and age < 0.14:
			var r = (8 + age * 110) * intensity
			draw_line(p - Vector2(r, r), p + Vector2(r, r), Color(UI.WHITE, fade), 2, true)
			draw_line(p - Vector2(r, -r), p + Vector2(r, -r), Color(UI.WHITE, fade), 2, true)

func _draw_spirit(p: Vector2, col: Color, ability: String, f: float, radius: float) -> void:
	# A stylized guardian silhouette emerges at discharge: wings, crown, and energy eye.
	var alpha = sin(minf(f * 1.4, 1) * PI) * 0.35
	if alpha <= 0: return
	var s = radius * (0.7 + f * 0.3)
	var center = p + Vector2(0, -s * 0.45)
	if ability.contains("AEGIS"):
		var shield = PackedVector2Array()
		for i in range(7):
			var a = TAU * i / 6 - PI * 0.5
			shield.append(center + Vector2(cos(a), sin(a)) * s * 0.74)
		draw_colored_polygon(shield, Color(col, alpha * 0.25))
		draw_polyline(shield, Color(col, alpha * 1.8), 4, true)
		for i in range(6):
			draw_line(center, shield[i], Color(col, alpha * 0.55), 2, true)
		TopView.ellipse(self, center, Vector2(s * 0.33, s * 0.4), Color(col, alpha * 0.6), false, 3)
		draw_circle(center, s * 0.08, Color(UI.WHITE, alpha * 1.5))
		return
	if ability.contains("VORTEX"):
		var body = PackedVector2Array()
		for i in range(49):
			var a = i * 0.21 + f * 3
			var r = s * (0.9 - i * 0.014)
			body.append(center + Vector2(cos(a), sin(a) * 0.8) * r)
		draw_polyline(body, Color(col, alpha * 0.4), 19, true)
		draw_polyline(body, Color(col, alpha * 1.5), 2.5, true)
		var head_pos: Vector2 = body[0]
		var dragon = PackedVector2Array([head_pos + Vector2(-20, 8), head_pos + Vector2(-12, -24), head_pos + Vector2(0, -8), head_pos + Vector2(28, -16), head_pos + Vector2(14, 6)])
		draw_colored_polygon(dragon, Color(col, alpha))
		draw_line(head_pos + Vector2(0, -3), head_pos + Vector2(9, -6), Color(UI.WHITE, alpha * 1.8), 3, true)
		return
	if ability.contains("THUNDER"):
		for j in range(5):
			var a = j * TAU / 5 - PI * 0.5
			var dir = Vector2.from_angle(a)
			var side = dir.orthogonal()
			var bolt = PackedVector2Array([center + dir * s * 0.18, center + dir * s * 0.7 + side * s * 0.12, center + dir * s * 0.54 - side * s * 0.1, center + dir * s * 1.1])
			draw_polyline(bolt, Color(UI.GOLD, alpha * 1.5), 5, true)
			draw_polyline(bolt, Color(UI.WHITE, alpha), 1.5, true)
	if ability.contains("NOVA"):
		var mane = PackedVector2Array()
		for i in range(24):
			var a = TAU * i / 24 - PI * 0.5
			mane.append(center + Vector2(cos(a), sin(a)) * s * (0.7 if i % 2 == 0 else 0.48))
		draw_colored_polygon(mane, Color(col, alpha * 0.24))
		mane.append(mane[0])
		draw_polyline(mane, Color(col, alpha), 3, true)
	if ability.contains("REBIRTH"):
		for j in range(9):
			var a = j * PI / 8 - PI
			var point = center + Vector2(cos(a), sin(a)) * s
			draw_line(center, point, Color(UI.GOLD, alpha * 0.65), 3, true)
	if ability.contains("ECLIPSE"):
		draw_circle(center, s * 0.62, Color("020411", alpha * 1.8))
		draw_arc(center, s * 0.65, -PI * 0.7, PI * 0.7, 40, Color(col, alpha * 1.7), 3, true)
	for sign_value in [-1, 1]:
		var wing = PackedVector2Array()
		for point in [Vector2(0.12, 0.3), Vector2(0.32, -0.35), Vector2(0.9, -0.96), Vector2(0.7, -0.25), Vector2(1.15, -0.48), Vector2(0.85, 0.14), Vector2(1.07, 0.18), Vector2(0.38, 0.45)]:
			wing.append(center + Vector2(point.x * sign_value, point.y) * s)
		draw_colored_polygon(wing, Color(col, alpha * 0.55))
		draw_polyline(wing, Color(col.lightened(0.3), alpha), 2, true)
	var head = PackedVector2Array()
	for point in [Vector2(-0.2, 0.2), Vector2(-0.24, -0.22), Vector2(-0.12, -0.5), Vector2(0, -0.26), Vector2(0.12, -0.5), Vector2(0.24, -0.22), Vector2(0.2, 0.2), Vector2(0, 0.38)]:
		head.append(center + point * s)
	draw_colored_polygon(head, Color(col, alpha))
	draw_line(center + Vector2(-s * 0.1, -s * 0.07), center + Vector2(s * 0.1, -s * 0.07), Color(UI.WHITE, alpha * 2), 3, true)

func _draw_stadium_environment(accent: Color) -> void:
	var id = str(arena.get("id", "skyline"))
	if id == "skyline":
		# Rooftops recede into the night beyond the bowl.
		for i in range(32):
			var x = float(i) * size.x / 32
			var h = 26 + ((i * 47 + 29) % 55)
			draw_rect(Rect2(x, 65, size.x / 34, h), Color("0d182b"))
			for j in range(3):
				draw_rect(Rect2(x + 6 + j * 6, 80 + (i % 3) * 6, 2, 3), Color(accent, 0.12))
	elif id == "volcano":
		for side in [-1, 1]:
			var points = PackedVector2Array()
			var x = size.x * 0.5 + side * size.x * 0.48
			for i in range(8):
				points.append(Vector2(x + side * sin(i * 7.1) * 16, 110 + i * size.y / 10))
			draw_polyline(points, Color(UI.PINK, 0.17), 2, true)
	elif id == "glacier":
		for i in range(8):
			var x = size.x * (i + 0.5) / 8
			var crystal = PackedVector2Array([Vector2(x - 10, 112), Vector2(x + 8, 65), Vector2(x + 22, 125)])
			draw_colored_polygon(crystal, Color(accent, 0.05))
			draw_polyline(crystal, Color(accent, 0.09), 1, true)
	elif id == "stormwell":
		for i in range(6):
			var p = Vector2((i + 0.5) * size.x / 6, 90)
			draw_circle(p, 11, Color(accent, 0.025))
			draw_circle(p, 3, Color(accent, 0.2 + 0.08 * sin(clock + i)))
