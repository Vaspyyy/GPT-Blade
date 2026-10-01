# SPIN//ASCEND implementation contracts

Native Linux desktop game, Godot 4.6.3, GL compatibility renderer. Logical canvas 1440×900. No browser wrapper. Work directly in this checkout.

## Catalog (scripts/catalog.gd, class_name Catalog)
- static func parts(category: String) -> Array[Dictionary], categories `blade`, `disc`, `driver`, `core`.
- static func part(id: String) -> Dictionary.
- static func default_loadout() -> Dictionary: blade/disc/driver/core IDs.
- static func stats(loadout: Dictionary) -> Dictionary: attack, defense, stamina, speed, weight, burst, control (numbers 0–100), plus behavior String, ability String, color Color, name String.
- static func arenas() -> Array[Dictionary]. Each arena: id, name, subtitle, description, color Color, grip, radius, hazard String.
- Each part: id, category, name, title (brief archetype), description, cost (int), tier (int 0–3), color Color, stats Dictionary; drivers include behavior, cores include ability.

## Career (scripts/career.gd, class_name Career)
- extends RefCounted; `loadout: Dictionary`, `owned: Array`, `credits: int`, `rung: int`, `wins: int`, `losses: int`, `settings: Dictionary`, `last_report: Dictionary`.
- func rivals() -> Array[Dictionary]; rival: id, name, title, quote, loadout, arena (id), reward, tier, color.
- func current_rival() -> Dictionary.
- func buy(id: String) -> bool, equip(id: String), record_match(result: Dictionary, practice: bool) -> Dictionary, save_profile(), reset_profile().
- record_match accepts winner int (0 player/1 opponent), reason String, time float, launch_quality float, player_stats Dictionary, opponent_stats Dictionary. Returns reward summary. Losing does NOT remove parts or money. Practice grants no ladder progress.

## Simulation (scripts/battle_sim.gd, class_name BattleSim)
- extends RefCounted; pure deterministic gameplay, no renderer.
- func setup(player_loadout: Dictionary, opponent_loadout: Dictionary, launch: Dictionary, arena: Dictionary, seed_value: int = 1).
- launch has power, timing, angle, tilt in 0–1 (angle radians), quality 0–1; opponent uses arena/rival reasonable default.
- func step(dt: float) -> Array[Dictionary] new events from that step; accumulate `history: Array`.
- `tops: Array` two Dictionary objects: pos Vector2 (unit arena radius), vel Vector2, spin float (0–100), hp float (0–100 burst lock), energy float (0–100), rotation float, stats Dictionary, color Color, name String, ability String, active bool.
- `time: float`, `finished: bool`, `result: Dictionary` winner, reason (Spin finish / Burst finish / Ring out), time, launch_quality, player_stats, opponent_stats.
- Event dictionaries: type clash/ability/burst/ringout/finish, pos Vector2, intensity float, actor int, name String. Extra keys fine. Ability is automatic; anticipation energy before discharge.
- Battle radius roughly 1; tops radius roughly 0.09. Typical fight 15–35s. Match guaranteed finite ≤60s. Dramatic finish but no random undiagnosable reversals.

## Workshop (scripts/workshop.gd, class_name Workshop)
- extends Control; func initialize(profile: Career); signal battle_requested(rival: Dictionary, practice: bool); signal settings_requested; optional signal title_requested.
- Occupies entire screen. Root main instantiates and adds before initialize.
- Own career/workshop/part browser presentation. Provide prominent next rival + battle button and practice mode, build preview, stats, unlocked/locked shop; explain behavior and abilities. Display last_report if present.
- Can preload `res://scripts/ui.gd` (class_name UI) static helpers: label(text, size=18, color=WHITE) -> Label; button(text, callback=Callable(), primary=false) -> Button; panel(bg=Color(...), border=Color(...), radius=12) -> StyleBoxFlat; title font UI.font_title(), body UI.font_body(); accent `UI.CYAN`, `UI.GOLD`, `UI.PINK`, `UI.INK`, `UI.MUTED`.
- Main owns launch, match, and results screen and calls career.record_match then returns to workshop.

## Audio (scripts/sound.gd, class_name Sound)
- extends Node; func play(cue: String, intensity: float = 1.0), func music(mode: String); cues click/launch/clash/ability/burst/win/lose, modes menu/battle; func set_volume(value: float), optional stop().
- Generate original audio assets to assets/audio. No runtime dependency on Python. Godot can load supplied .wav assets. Music must loop and not overwhelm battle cues.

## Visual direction
Night blue, cyan player, coral rival, warm gold highlights. Neon anime sports broadcast; large numbers, condensed headings, lots of negative space. Arena ellipse/pseudo-3D tops with layered sculpted shapes, sparks, trails, impact freeze, attack names and radial spirit effects. Original title and original parts/rivals; fan-inspired spinning-top fantasy, no borrowed franchise artwork.

## Ownership
Simulation agent: catalog.gd, battle_sim.gd, tests/test_sim.gd.
Workshop agent: career.gd, workshop.gd, tests/test_career.gd.
Audio agent: sound.gd, assets/audio, generating tools.
Platform agent: tools/platform*, export_presets.cfg, tools/package*, platform docs.
Root: main.gd, ui.gd, top_view.gd, arena_view.gd, main.tscn, project.godot, README, UPDATES, integration and release.
Do not commit other agents' unfinished files. Notify root when owned work is ready; root batches and pushes commits. Do not change contracts silently; send proposed changes.
