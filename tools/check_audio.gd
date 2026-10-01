extends SceneTree
## Headless smoke test of the real native AudioStreamPlayer implementation.
## godot --headless --audio-driver Dummy --path . --script tools/check_audio.gd

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var audio = load("res://scripts/sound.gd").new()
	root.add_child(audio)
	audio.set_volume(0.7)
	audio.music("menu")
	await create_timer(0.8).timeout
	assert(audio._music[audio._active_music].playing, "Menu score must play")
	assert(audio._music[audio._active_music].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Score must loop")
	for cue in ["click", "launch", "clash", "ability", "burst", "win", "lose", "charge", "telegraph", "countdown"]:
		audio.play(cue)
		assert(audio._cache.has(audio.CUES[cue]), "Every cue must import")
		await create_timer(0.03).timeout
	audio.music("battle")
	await create_timer(0.8).timeout
	assert(audio._music[audio._active_music].playing, "Battle score must play")
	audio.set_volume(0.0)
	audio.play("clash")
	audio.stop()
	for player in audio._music:
		assert(not player.playing, "Stop must end both crossfade channels")
	await create_timer(0.15).timeout
	audio.free()
	await process_frame
	print("AUDIO_OK: imports, looping score crossfades, ten cues, mute and stop under Dummy driver")
	quit()
