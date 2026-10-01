extends SceneTree

var failures := 0
const PATH := "user://career_test.json"

func _initialize() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var career := Career.new(PATH)
	check(career.rung == 0 and career.credits == 180, "new profile starts at the first rival with credits")
	for family in ["blade", "disc", "driver", "core"]:
		var count := 0
		for id in career.owned:
			if Catalog.part(id).category == family:
				count += 1
		check(count >= 2, "every family offers an owned starting alternative: " + family)
	check(career.rivals().size() == 12, "career has twelve distinct rivals")
	var ids: Array = []
	var arena_ids: Array = []
	for arena in Catalog.arenas():
		arena_ids.append(arena.id)
	for rival in career.rivals():
		check(rival.id not in ids, "rivals are distinct")
		ids.append(rival.id)
		check(rival.arena in arena_ids, "rival arena exists")
		for family in rival.loadout:
			check(not Catalog.part(rival.loadout[family]).is_empty(), "rival part exists")
	check(not career.buy("bastion"), "future league parts are locked")
	var prior_loadout := career.loadout.duplicate(true)
	career.equip("bastion")
	check(career.loadout == prior_loadout, "unowned parts cannot be equipped")
	var lose := {"winner": 1, "reason": "Burst finish", "time": 15.0, "launch_quality": 0.8}
	career.record_match(lose, false)
	check(career.credits == 180 and career.rung == 0 and career.losses == 1, "losses have no currency or ladder penalty")
	check("burst lock" in career.last_report.lesson.to_lower(), "a burst defeat suggests an actionable correction")
	var win := {"winner": 0, "reason": "Spin finish", "time": 20.0, "launch_quality": 0.9}
	career.record_match(win, true)
	check(career.wins == 0 and career.credits == 180 and career.rung == 0, "practice does not alter rewards or the career")
	for index in range(3):
		career.record_match(win, false)
	check(career.unlocked_tier() == 1 and career.last_report.promoted, "three wins promote the player")
	var before_purchase := career.credits
	check(career.buy("bastion"), "unlocked affordable part can be purchased")
	check(career.credits == before_purchase - int(Catalog.part("bastion").cost), "purchase charges the documented price")
	var after_purchase := career.credits
	check(career.buy("bastion") and career.credits == after_purchase, "already owned purchases never double charge")
	career.equip("bastion")
	check(career.loadout.blade == "bastion", "an owned part can be equipped")
	check(career.store_build(0), "current build can be stored in a custom slot")
	var stored_loadout := career.loadout.duplicate(true)
	career.equip("fang")
	check(career.recall_build(0) and career.loadout == stored_loadout, "saved build recalls the complete loadout")
	check(not career.store_build(-1) and not career.recall_build(8) and not career.recall_build(2), "invalid and empty build slots are safe")
	career.settings.volume = 0.2
	career.settings.reduced_flashes = true
	career.save_profile()
	var resumed := Career.new(PATH)
	check(resumed.loadout.blade == "bastion" and resumed.credits == career.credits, "profile restores purchases and loadout")
	check(resumed.saved_builds[0].loadout == stored_loadout and resumed.saved_builds[1].is_empty(), "custom build slots persist across restart")
	check(resumed.settings.reduced_flashes and is_equal_approx(resumed.settings.volume, 0.2), "settings survive restart")
	for index in range(9):
		career.record_match(win, false)
	check(career.is_champion() and career.rung == 12 and career.last_report.ending, "twelfth win reaches the champion ending")
	check(career.unlocked_tier() == 3, "champion owns access to all part tiers")
	career.record_match(win, false)
	check(career.rung == 12 and career.endgame_wins == 1 and not career.last_report.ending, "legend rematches progress without re-triggering the ending")
	check(career.current_rival().get("endgame", false), "champion gets an endless authored rematch challenge")
	var saved_credits := career.credits
	_write("{broken")
	var recovered := Career.new(PATH)
	check(recovered.is_champion() and recovered.credits <= saved_credits, "corrupt primary profile recovers its prior atomic backup")
	_write(JSON.stringify({"version": 1, "credits": -1000, "rung": 8000, "wins": "broken", "owned": ["unknown", 7], "loadout": {"blade": "no-such-part", "driver": "lotus"}, "settings": {"volume": 7, "fullscreen": "yes", "shake": false}, "last_report": {"lesson": "X".repeat(5000)}, "saved_builds": [{"name": "invalid", "loadout": {"blade": "crown", "driver": "unknown"}}]}))
	var sanitized := Career.new(PATH)
	check(sanitized.credits == 0 and sanitized.rung == 12 and sanitized.wins == 0, "out-of-range and incorrect save fields are sanitized")
	check(sanitized.loadout == Catalog.default_loadout(), "invalid or wrongly categorized loadout parts are ignored")
	check(sanitized.settings.volume == 1.0 and sanitized.settings.fullscreen == false and sanitized.settings.shake == false, "settings types and ranges are validated")
	check(sanitized.saved_builds[0].is_empty(), "invalid and unowned saved builds cannot bypass ownership")
	check(sanitized.last_report.lesson.length() == 1000, "untrusted strings are bounded")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("CAREER TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _write(value: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(value)
	file.close()
