class_name AudioManagerClass
extends Node

## Centralized Audio & Sound Effects Manager for Finest Garden (BloomHaven).
## Manages pooled polyphonic SFX playback with pitch variance and cozy BGM looping.

const SFX_FILES: Dictionary = {
	"click": "res://assets/audio/sfx/sfx_click.wav",
	"plant": "res://assets/audio/sfx/sfx_plant.wav",
	"water": "res://assets/audio/sfx/sfx_water.wav",
	"prune": "res://assets/audio/sfx/sfx_prune.wav",
	"harvest": "res://assets/audio/sfx/sfx_harvest.wav",
	"coin": "res://assets/audio/sfx/sfx_coin.wav",
	"upgrade": "res://assets/audio/sfx/sfx_upgrade.wav",
	"error": "res://assets/audio/sfx/sfx_error.wav",
	"step": "res://assets/audio/sfx/sfx_step.wav"
}

const MUSIC_FILES: Dictionary = {
	"garden": "res://assets/audio/music/bgm_garden_loop.wav"
}

const SFX_POOL_SIZE: int = 8

var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_player_index: int = 0
var _music_player: AudioStreamPlayer = null

var sfx_volume_db: float = 0.0
var music_volume_db: float = -6.0
var is_muted: bool = false


func _init() -> void:
	_preload_audio_streams()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()


func _setup_audio_players() -> void:
	# Pool of SFX players for polyphonic sounds
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	# Dedicated looping music player
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = music_volume_db
	add_child(_music_player)


func _preload_audio_streams() -> void:
	for key in SFX_FILES:
		var path: String = SFX_FILES[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream != null:
				_sfx_cache[key] = stream

	for key in MUSIC_FILES:
		var path: String = MUSIC_FILES[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream != null:
				# Ensure WAV loops seamlessly
				if stream is AudioStreamWAV:
					stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
					stream.loop_begin = 0
					var rate: float = float(stream.mix_rate) if "mix_rate" in stream else 44100.0
					stream.loop_end = int(stream.get_length() * rate)
				_music_cache[key] = stream


func play_sfx(sfx_name: String, pitch_randomness: float = 0.06, volume_offset_db: float = 0.0) -> void:
	if is_muted or _sfx_players.is_empty():
		return

	var stream: AudioStream = _sfx_cache.get(sfx_name, null)
	if stream == null:
		return

	# Round-robin player selection from pool
	var player: AudioStreamPlayer = _sfx_players[_sfx_player_index]
	_sfx_player_index = (_sfx_player_index + 1) % _sfx_players.size()

	player.stop()
	player.stream = stream
	player.volume_db = sfx_volume_db + volume_offset_db
	if pitch_randomness > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
	else:
		player.pitch_scale = 1.0
	player.play()


func play_music(track_name: String = "garden", fade_time: float = 1.2) -> void:
	if _music_player == null:
		return

	var stream: AudioStream = _music_cache.get(track_name, null)
	if stream == null:
		return

	if _music_player.playing and _music_player.stream == stream:
		return

	_music_player.stream = stream
	_music_player.volume_db = -40.0 if fade_time > 0.0 else music_volume_db
	_music_player.play()

	if fade_time > 0.0 and not is_muted:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", music_volume_db, fade_time)


func stop_music(fade_time: float = 0.6) -> void:
	if _music_player == null or not _music_player.playing:
		return

	if fade_time > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


func set_muted(muted: bool) -> void:
	is_muted = muted
	if _music_player != null:
		_music_player.volume_db = -80.0 if is_muted else music_volume_db


func toggle_mute() -> bool:
	set_muted(not is_muted)
	return is_muted


func has_sfx(sfx_name: String) -> bool:
	return _sfx_cache.has(sfx_name)


func has_music(track_name: String) -> bool:
	return _music_cache.has(track_name)
