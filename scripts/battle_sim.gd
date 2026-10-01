class_name BattleSim
extends RefCounted
## Deterministic 120 Hz bowl simulation. Steering supplies top behavior; momentum
## supplies contact outcomes. Spirit attacks announce their aim before resolving.

const TICK := 1.0 / 120.0
const TOP_RADIUS := 0.085
const ABILITY_NAMES := {"nova": "NOVA BREAK", "aegis": "AEGIS GUARD", "vortex": "VORTEX PULL", "phoenix": "ASHEN REBIRTH", "thunder": "THUNDER RING", "eclipse": "ECLIPSE FEINT"}

var tops: Array = []
var history: Array = []
var time := 0.0
var finished := false
var result: Dictionary = {}
var arena: Dictionary = {}
var launch_quality := 0.0
var _accumulator := 0.0
var _contact_cooldown := 0.0
var _pending: Array[Dictionary] = []
var _phase := 0.0
var _pulse_index := -1
var _heat_active := false

func setup(player_loadout: Dictionary, opponent_loadout: Dictionary, launch: Dictionary, arena_data: Dictionary, seed_value: int = 1) -> void:
	# Seed varies reproducible footwork phase; it never rolls damage or a winner.
	arena = arena_data.duplicate(true)
	time = 0.0
	finished = false
	result = {}
	history = []
	tops = []
	_pending = []
	_accumulator = 0.0
	_contact_cooldown = 0.0
	_pulse_index = -1
	_heat_active = false
	_phase = fposmod(float(seed_value) * 0.6180339887, TAU)
	launch_quality = clampf(float(launch.get("quality", 0.65 * float(launch.get("timing", 0.75)) + 0.35 * float(launch.get("power", 0.75)))), 0.0, 1.0)
	var angle := float(launch.get("angle", 0.0))
	var tilt := clampf(float(launch.get("tilt", 0.35)), 0.0, 1.0)
	var power := clampf(float(launch.get("power", 0.8)), 0.0, 1.0)
	for actor in range(2):
		var loadout: Dictionary = player_loadout if actor == 0 else opponent_loadout
		var stats := Catalog.stats(loadout)
		var quality := launch_quality if actor == 0 else 0.78
		var top_tilt := tilt if actor == 0 else 0.5
		var pos := Vector2(-0.43, 0.12) if actor == 0 else Vector2(0.43, -0.12)
		var direction := Vector2.from_angle(angle) if actor == 0 else Vector2(-0.86, 0.5).normalized()
		var launch_speed := (0.72 + (power if actor == 0 else 0.78) * 0.7) * (0.66 + quality * 0.34)
		tops.append({"pos": pos, "vel": direction * launch_speed, "spin": 62.0 + quality * 34.0,
			"hp": clampf(68.0 + float(stats.burst) * 0.17 + quality * 20.0, 0.0, 100.0), "energy": 18.0, "rotation": float(actor) * PI,
			"stats": stats, "color": stats.color, "name": stats.name, "blade": str(loadout.get("blade", "comet")), "loadout": loadout.duplicate(), "ability": stats.ability, "active": true,
			"tilt": top_tilt, "launch_angle": angle if actor == 0 else PI, "quality": quality,
			"mass": 0.68 + float(stats.weight) * 0.011, "shield_until": -1.0, "boost_until": -1.0,
			"vortex_until": -1.0, "charge_until": -1.0, "charging": false, "aim": Vector2.ZERO,
			"ability_cooldown": 0.0, "revivals": 0, "pressure": 0.0,
			"diagnostics": {"hits": 0, "damage_dealt": 0.0, "spin_damage": 0.0, "abilities": 0,
				"ability_hits": 0, "wall_hits": 0, "ring_pressure": 0.0, "distance": 0.0,
				"peak_speed": launch_speed, "guarded_damage": 0.0, "heat_loss": 0.0, "revived_spin": 0.0}})

func step(dt: float) -> Array[Dictionary]:
	_pending = []
	if finished: return _pending
	_accumulator += clampf(dt, 0.0, 0.5)
	while _accumulator + 0.00000001 >= TICK and not finished:
		_accumulator -= TICK
		_tick()
	return _pending

func _event(type: String, pos: Vector2, intensity: float, actor: int, name: String, extra: Dictionary = {}) -> void:
	var event := {"type": type, "pos": pos, "intensity": intensity, "actor": actor, "name": name, "time": time}
	event.merge(extra)
	_pending.append(event)
	history.append(event)

func _tick() -> void:
	time += TICK
	_contact_cooldown = maxf(0.0, _contact_cooldown - TICK)
	_hazards()
	for actor in range(2):
		var top: Dictionary = tops[actor]
		var other: Dictionary = tops[1 - actor]
		var stats: Dictionary = top.stats
		var pos: Vector2 = top.pos
		var vel: Vector2 = top.vel
		var spin_factor := 0.36 + 0.64 * clampf(float(top.spin) / 80.0, 0.0, 1.0)
		var desired := _desired_velocity(actor) * spin_factor
		var steering := (1.65 + float(stats.control) * 0.022) * float(arena.get("grip", 1.0))
		if top.charging: steering *= 0.42
		if time < float(top.boost_until): steering *= 0.12
		vel += (desired - vel) * minf(0.08, steering * TICK)
		# The bowl supplies a real inward slope. Heavy tops recover their footing slowly.
		vel -= pos * (0.30 + pos.length_squared() * 0.58) * TICK
		if time < float(other.vortex_until):
			vel += (Vector2(other.pos) - pos).normalized() * 1.5 * TICK / float(top.mass)
		vel = vel.limit_length(3.4)
		top.pos = pos + vel * TICK / float(arena.get("radius", 1.0))
		top.vel = vel
		top.rotation += (18.0 + float(top.spin) * 0.65) * TICK * (1.0 if actor == 0 else -1.0)
		top.diagnostics.distance += vel.length() * TICK
		top.diagnostics.peak_speed = maxf(float(top.diagnostics.peak_speed), vel.length())
		var motion_cost := vel.length() * 0.22
		var tilt_cost := float(top.tilt) * (0.85 - float(stats.control) * 0.005)
		var drain := 3.85 - float(stats.stamina) * 0.022 + motion_cost + tilt_cost
		if stats.behavior == "gyro" or stats.behavior == "needle": drain -= 0.20
		if time > 38.0: drain += (time - 38.0) * 0.23
		top.spin = maxf(0.0, float(top.spin) - drain * TICK)
		top.energy = minf(100.0, float(top.energy) + (5.1 + vel.length() * 1.15) * TICK)
		top.pressure = maxf(0.0, float(top.pressure) - TICK * 0.75)
		_abilities(actor)
		_rim(actor)
		if finished: return
	_contact()
	if finished: return
	# Weaker spin loses ties. An exact mirror tie rewards the better launch, then player.
	if float(tops[0].spin) <= 0.0 or float(tops[1].spin) <= 0.0:
		var winner := 1 if float(tops[0].spin) < float(tops[1].spin) else 0
		_finish(winner, "Spin finish")
	elif time >= 58.0:
		var winner := 1 if float(tops[0].spin) + float(tops[0].hp) * 0.05 < float(tops[1].spin) + float(tops[1].hp) * 0.05 else 0
		_finish(winner, "Spin finish")

func _desired_velocity(actor: int) -> Vector2:
	var top: Dictionary = tops[actor]
	var rival: Dictionary = tops[1 - actor]
	var pos: Vector2 = top.pos
	var to_rival := Vector2(rival.pos) - pos
	var speed := 0.43 + float(top.stats.speed) * 0.013
	var center := -pos
	var tangent := Vector2(-pos.y, pos.x).normalized()
	var orbit_phase := time * 1.15 + _phase + float(actor) * 0.87
	var lean := (float(top.tilt) - 0.35) * 0.22
	var behavior := str(top.stats.behavior)
	match behavior:
		"hunter":
			# A small strafing offset creates meaningful crossing blows rather than sticky contacts.
			if to_rival.length() < 0.30 and sin(orbit_phase * 1.55) < -0.1:
				return (-to_rival.normalized() * 0.42 + tangent * 0.85 + center * 0.16).normalized() * speed
			return (to_rival.normalized() + tangent * sin(orbit_phase) * 0.44 + center * 0.20).normalized() * speed
		"surge":
			return (to_rival.normalized() + tangent * sin(orbit_phase * 0.72) * 0.23).normalized() * speed * 1.14
		"orbit", "drift":
			if behavior == "orbit" and sin(orbit_phase) > 0.25:
				return (to_rival.normalized() + tangent * 0.18).normalized() * speed * 1.12
			var target_radius := (0.51 if behavior == "orbit" else 0.42) + sin(orbit_phase * 0.68) * 0.14 + lean
			var radial := pos.normalized() * (target_radius - pos.length()) * 4.0
			var intercept := to_rival.normalized() * (0.68 if sin(orbit_phase) > 0.35 else 0.06)
			return (tangent * 0.86 + radial + intercept).limit_length(1.1) * speed
		"anchor", "needle", "gyro":
			var target := Vector2.from_angle(orbit_phase * 0.4) * (0.11 if behavior == "anchor" else 0.07)
			return (target - pos).limit_length(0.65) * (1.65 if behavior == "anchor" else 1.05)
		"counter", "pivot":
			if to_rival.length() < 0.40 and sin(orbit_phase * 1.65) > -0.25:
				return to_rival.normalized() * speed * (1.12 if behavior == "counter" else 0.92)
			return (-pos * 1.6 + tangent * 0.22) * 0.7
		"rebound":
			var radial := pos.normalized() * (0.74 - pos.length()) * 3.0
			return (tangent * 0.7 + radial + to_rival.normalized() * (0.9 if sin(orbit_phase) > 0.2 else 0.0)).limit_length(1.2) * speed
	return to_rival.normalized() * speed

func _contact() -> void:
	var a: Dictionary = tops[0]
	var b: Dictionary = tops[1]
	var delta := Vector2(b.pos) - Vector2(a.pos)
	var distance := delta.length()
	if distance >= TOP_RADIUS * 2.0: return
	var normal := delta / maxf(distance, 0.0001)
	if distance < 0.0001: normal = Vector2.RIGHT
	var overlap := TOP_RADIUS * 2.0 - distance
	a.pos = Vector2(a.pos) - normal * overlap * 0.5
	b.pos = Vector2(b.pos) + normal * overlap * 0.5
	var relative := Vector2(a.vel) - Vector2(b.vel)
	var closing := maxf(0.0, relative.dot(normal))
	if _contact_cooldown > 0.0:
		# Separation still happens while the previous hit is cooling down.
		a.vel = Vector2(a.vel) - normal * closing * 0.48
		b.vel = Vector2(b.vel) + normal * closing * 0.48
		return
	_contact_cooldown = 0.25
	var intensity := clampf(0.35 + closing * 0.43, 0.35, 1.55)
	var a_force := _contact_force(a, closing)
	var b_force := _contact_force(b, closing)
	var impulse := 0.22 + closing * 0.72
	a.vel = Vector2(a.vel) - normal * (impulse + b_force * 0.022) / float(a.mass)
	b.vel = Vector2(b.vel) + normal * (impulse + a_force * 0.022) / float(b.mass)
	_hit(0, 1, a_force, normal, time < float(a.boost_until))
	if not finished: _hit(1, 0, b_force, -normal, time < float(b.boost_until))
	var attacker := 0 if a_force >= b_force else 1
	_event("clash", (Vector2(a.pos) + Vector2(b.pos)) * 0.5, intensity, attacker, "HEAVY CLASH" if closing > 1.15 else "CLASH", {"relative_speed": closing, "damage": [a_force, b_force]})

func _contact_force(top: Dictionary, closing: float) -> float:
	var spin_power := 0.30 + float(top.spin) / 135.0
	var force := (2.0 + float(top.stats.attack) * 0.085) * (0.45 + closing * 0.48) * spin_power
	# Aggressive lean converts reserve and rim stability into stronger contact.
	force *= 0.90 + float(top.tilt) * 0.30
	if time < float(top.boost_until): force *= 1.65
	return force

func _hit(attacker: int, defender: int, force: float, normal: Vector2, spirit: bool) -> void:
	var source: Dictionary = tops[attacker]
	var target: Dictionary = tops[defender]
	var defense := 1.0 - float(target.stats.defense) * 0.0065
	var lock := 1.10 - float(target.stats.burst) * 0.0035
	var damage := force * defense * lock * 1.16
	var spin_damage := force * (0.14 + (100.0 - float(target.stats.defense)) * 0.0014)
	if time < float(target.shield_until):
		target.diagnostics.guarded_damage += damage * 0.73
		damage *= 0.27
		spin_damage *= 0.48
		source.vel = Vector2(source.vel) - normal * force * 0.025 / float(source.mass)
	if target.charging and target.ability == "phoenix":
		damage *= 1.3
		# The revival is vulnerable, but only a real strong strike breaks concentration.
		if force > 8.5:
			target.charging = false
			target.energy = 55.0
			target.ability_cooldown = time + 3.0
			_event("interrupt", target.pos, 0.8, attacker, "REBIRTH INTERRUPTED")
	target.hp = maxf(0.0, float(target.hp) - damage)
	target.spin = maxf(0.0, float(target.spin) - spin_damage)
	target.energy = minf(100.0, float(target.energy) + damage * 0.9)
	source.energy = minf(100.0, float(source.energy) + damage * 0.5)
	target.pressure = minf(4.0, float(target.pressure) + force * 0.09)
	source.diagnostics.damage_dealt += damage
	source.diagnostics.spin_damage += spin_damage
	source.diagnostics.hits += 1
	if spirit: source.diagnostics.ability_hits += 1
	source.diagnostics.ring_pressure += force * maxf(0.0, normal.dot(Vector2(target.pos).normalized()))
	if float(target.hp) <= 0.0:
		_event("burst", target.pos, 1.4, defender, "BURST LOCK BROKEN")
		_finish(attacker, "Burst finish")

func _abilities(actor: int) -> void:
	var top: Dictionary = tops[actor]
	var other: Dictionary = tops[1 - actor]
	if top.charging:
		if time >= float(top.charge_until):
			top.charging = false
			top.energy = 0.0
			top.ability_cooldown = time + 5.0
			_activate(actor)
		return
	if float(top.energy) < 99.99 or time < float(top.ability_cooldown): return
	if top.ability == "phoenix" and (float(top.spin) > 46.0 or int(top.revivals) >= 2): return
	top.charging = true
	top.charge_until = time + (0.90 if top.ability == "phoenix" else 0.72)
	top.aim = (Vector2(other.pos) + Vector2(other.vel) * 0.20 - Vector2(top.pos)).normalized()
	_event("charge", top.pos, 0.7, actor, str(ABILITY_NAMES.get(top.ability, "SPIRIT RISE")), {"duration": float(top.charge_until) - time, "aim": top.aim})

func _activate(actor: int) -> void:
	var top: Dictionary = tops[actor]
	var target: Dictionary = tops[1 - actor]
	var delta := Vector2(target.pos) - Vector2(top.pos)
	var normal := delta.normalized()
	var distance := delta.length()
	var attack := 7.5 + float(top.stats.attack) * 0.085
	top.diagnostics.abilities += 1
	top.spin = maxf(0.0, float(top.spin) - 1.4)
	match str(top.ability):
		"nova":
			top.vel = Vector2(top.aim) * (2.3 + float(top.stats.speed) * 0.009)
			top.boost_until = time + 0.8
		"aegis":
			top.shield_until = time + 2.7
			top.vel = Vector2(top.vel) * 0.45
		"vortex":
			top.vortex_until = time + 2.1
			if distance < 0.47:
				_hit(actor, 1 - actor, attack * 0.82, normal, true)
		"phoenix":
			var recovered := 11.0 + float(top.stats.stamina) * 0.065
			top.spin = minf(73.0, float(top.spin) + recovered)
			top.hp = minf(100.0, float(top.hp) + 5.0)
			top.revivals += 1
			top.diagnostics.revived_spin += recovered
		"thunder":
			if distance < 0.74:
				var falloff := 1.0 - distance * 0.65
				target.vel = Vector2(target.vel) + normal * (1.65 + float(top.stats.attack) * 0.008) * falloff / float(target.mass)
				_hit(actor, 1 - actor, attack * falloff, normal, true)
				target.pressure = minf(4.0, float(target.pressure) + 1.1)
		"eclipse":
			var side := Vector2(-normal.y, normal.x)
			top.vel = side * 1.2 + normal * 2.0
			top.boost_until = time + 0.68
			if distance < 0.42:
				_hit(actor, 1 - actor, attack * 0.75, normal, true)
	_event("ability", top.pos, 1.0, actor, str(ABILITY_NAMES.get(top.ability, "SPIRIT RISE")), {"aim": top.aim, "duration": 2.7 if top.ability == "aegis" else 1.0})

func _rim(actor: int) -> void:
	var top: Dictionary = tops[actor]
	var pos: Vector2 = top.pos
	var radius := pos.length()
	if radius < 0.89: return
	var outward := pos.normalized()
	var radial_speed := Vector2(top.vel).dot(outward)
	var wall := float(arena.get("wall", 0.94))
	var stability := float(top.stats.control) * 0.003 + float(top.mass) * 0.13 + float(top.spin) * 0.002 - float(top.tilt) * 0.20
	# Only forceful outward contact can clear a wall. Ordinary autonomous footwork rebounds.
	var clear_speed := 1.22 + wall * 0.72 + stability - float(top.pressure) * 0.20
	if radial_speed > clear_speed and radius > 0.933 and float(top.pressure) > 0.55:
		_event("ringout", pos, 1.3, actor, "OVER THE RIM")
		_finish(1 - actor, "Ring out")
		return
	if radius >= 0.93:
		top.pos = outward * 0.927
		if radial_speed > 0.0:
			top.vel = Vector2(top.vel) - outward * radial_speed * (1.50 if top.stats.behavior == "rebound" else 1.34)
			top.spin = maxf(0.0, float(top.spin) - radial_speed * 0.16)
			top.diagnostics.wall_hits += 1
			_event("wall", top.pos, clampf(radial_speed * 0.5, 0.1, 0.8), actor, "RIM REBOUND")

func _hazards() -> void:
	var hazard := str(arena.get("hazard", "none"))
	if hazard == "heat":
		var heat := time > 5.0 and fposmod(time - 5.0, 6.0) < 2.0
		if heat and not _heat_active: _event("hazard", Vector2.ZERO, 0.7, -1, "OUTER RING OVERHEAT", {"duration": 2.0})
		_heat_active = heat
		if heat:
			for top in tops:
				if Vector2(top.pos).length() > 0.57:
					top.spin = maxf(0.0, float(top.spin) - 1.65 * TICK)
					top.diagnostics.heat_loss += 1.65 * TICK
	elif hazard == "pulse":
		var pulse := int(floor((time - 5.0) / 7.0))
		if time > 5.0 and pulse > _pulse_index:
			_pulse_index = pulse
			_event("hazard", Vector2.ZERO, 0.85, -1, "STORMWELL PULSE", {"duration": 0.8})
		if time > 5.0 and fposmod(time - 5.0, 7.0) < 0.8:
			for top in tops:
				var pos: Vector2 = top.pos
				if pos.length() < 0.64:
					top.vel = Vector2(top.vel) + pos.normalized() * TICK * 1.25 / float(top.mass)

func _finish(winner: int, reason: String) -> void:
	if finished: return
	finished = true
	var loser := 1 - winner
	tops[loser].active = false
	var explanation := _explain(winner, reason)
	result = {"winner": winner, "reason": reason, "time": time, "launch_quality": launch_quality,
		"player_stats": tops[0].stats.duplicate(true), "opponent_stats": tops[1].stats.duplicate(true),
		"diagnostics": [tops[0].diagnostics.duplicate(true), tops[1].diagnostics.duplicate(true)],
		"final_spin": [tops[0].spin, tops[1].spin], "final_hp": [tops[0].hp, tops[1].hp],
		"explanation": explanation, "seed_phase": _phase}
	_event("finish", tops[loser].pos, 1.0, winner, reason, {"explanation": explanation})

func _explain(winner: int, reason: String) -> String:
	var victor: Dictionary = tops[winner]
	var defeated: Dictionary = tops[1 - winner]
	var subject := "Your top" if winner == 0 else "The rival"
	if reason == "Burst finish":
		return "%s broke the lock with %d contacts. Defense softens hits; burst protection keeps the lock intact." % [subject, int(victor.diagnostics.hits)]
	if reason == "Ring out":
		return "%s converted momentum into ring pressure. Heavier discs, more control, and guarded centers resist shoves." % subject
	if float(victor.diagnostics.revived_spin) > 0.0:
		return "%s survived with Phoenix's %.0f recovered spin. Fast pressure can interrupt its revival." % [subject, float(victor.diagnostics.revived_spin)]
	if float(defeated.diagnostics.heat_loss) > 2.0:
		return "%s outlasted the rival. The outer heat ring cost the losing top %.0f spin; a center driver avoids it." % [subject, float(defeated.diagnostics.heat_loss)]
	if absf(float(victor.stats.stamina) - float(defeated.stats.stamina)) > 14.0:
		return "%s kept more spin through stamina and movement economy. Pressure its lock or send it to the rim before the final spin." % subject
	if launch_quality < 0.65 and winner == 1:
		return "Your launch left spin on the table. Find the timing window, build clean power, and try the same matchup again."
	return "%s balanced launch reserve, contact damage, and efficient movement. Change a driver or spirit to test a new answer." % subject
