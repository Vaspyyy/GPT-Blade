class_name Sound
extends Node
## Original stereo score and cues. Godot's Dummy driver handles silent/headless
## machines; there is no dependency on an audio device or external synthesizer.

const CUES := {
	"click": "res://assets/audio/click.wav",
	"launch": "res://assets/audio/launch.wav",
	"clash": "res://assets/audio/clash.wav",
	"ability": "res://assets/audio/ability.wav",
	"burst": "res://assets/audio/burst.wav",
	"win": "res://assets/audio/win.wav",
	"lose": "res://assets/audio/lose.wav",
	"charge": "res://assets/audio/charge.wav",
	"telegraph": "res://assets/audio/telegraph.wav",
	"countdown": "res://assets/audio/countdown.wav",
}
const TRACKS := {
	"menu": "res://assets/audio/menu.wav",
	"battle": "res://assets/audio/battle.wav",
}
const POOL_SIZE := 12
var _effects: Array[AudioStreamPlayer] = []
var _music: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _master := 0.72
var _mode := ""
var _active_music := 0
var _fade: Tween
var _clash_cooldown := 0.0


func _ready() -> void:
	_ensure_players()


func _ensure_players() -> void:
	if not _effects.is_empty():
		return
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "Cue%d" % i
		add_child(player)
		_effects.append(player)
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "Score%d" % i
		add_child(player)
		_music.append(player)


func _stream(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path] as AudioStream


func _volume_db(gain: float = 1.0) -> float:
	return linear_to_db(maxf(0.0001, _master * gain))


func set_volume(value: float) -> void:
	_master = clampf(value, 0.0, 1.0)
	_ensure_players()
	# Keep master mute exact. Finished fades also use this value on each update.
	for player in _effects:
		player.volume_db = _volume_db(0.78)
	for i in range(_music.size()):
		_music[i].volume_db = _volume_db(0.30) if i == _active_music else -80.0


func play(cue: String, intensity: float = 1.0) -> void:
	_ensure_players()
	var actual := cue
	if actual == "victory":
		actual = "win"
	if actual == "loss":
		actual = "lose"
	if actual == "ringout":
		actual = "burst"
	if not CUES.has(actual) or _master <= 0.0001:
		return
	# Contact can last several simulation frames; avoid a machine-gun sound.
	if actual == "clash":
		var now := Time.get_ticks_msec() / 1000.0
		if now - _clash_cooldown < 0.105:
			return
		_clash_cooldown = now
	var selected: AudioStreamPlayer = _effects[0]
	for player in _effects:
		if not player.playing:
			selected = player
			break
	selected.stop()
	selected.stream = _stream(CUES[actual])
	var gain := clampf(intensity, 0.25, 1.35)
	if actual == "click":
		gain *= 0.44
	elif actual in ["telegraph", "charge", "countdown"]:
		gain *= 0.70
	selected.volume_db = _volume_db(gain * 0.78)
	selected.pitch_scale = randf_range(0.94, 1.06) if actual in ["clash", "burst"] else 1.0
	selected.play()


func music(mode: String) -> void:
	_ensure_players()
	if mode == _mode:
		return
	if not TRACKS.has(mode):
		stop()
		return
	if _fade and _fade.is_valid():
		_fade.kill()
	var old := _music[_active_music]
	_active_music = 1 - _active_music
	var next := _music[_active_music]
	next.stop()
	var track := _stream(TRACKS[mode]).duplicate() as AudioStreamWAV
	if track == null:
		return
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_begin = 0
	track.loop_end = int(track.get_length() * track.mix_rate)
	next.stream = track
	next.volume_db = -80.0
	next.pitch_scale = 1.0
	next.play()
	_mode = mode
	_fade = create_tween().set_parallel(true)
	_fade.tween_method(func(g: float) -> void: next.volume_db = _volume_db(g), 0.0001, 0.30, 0.65)
	_fade.tween_property(old, "volume_db", -80.0, 0.65)
	_fade.chain().tween_callback(old.stop)


func stop() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	for player in _music:
		player.stop()
	for player in _effects:
		player.stop()
	_mode = ""
