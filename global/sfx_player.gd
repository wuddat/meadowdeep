extends Node

const SFX_VOL:float = -25.0

func _ready() -> void:
	for player in get_children():
		(player as AudioStreamPlayer).bus = &"SFX"


func play(audio: AudioStream, vol: float = SFX_VOL, single: bool = false) -> void:
	if not audio:
		return
	if single:
		stop()
	for player in get_children():
		player = player as AudioStreamPlayer
		if not player.playing:
			player.stream = audio
			player.pitch_scale = 1.0
			player.volume_db = vol
			player.play()
			break


func play_from_time(audio: AudioStream, from_time := 0.0, vol: float = SFX_VOL, single:bool = false) -> void:
	if not audio:
		return
	if single:
		stop()
	for player in get_children():
		player = player as AudioStreamPlayer
		if not player.playing:
			player.stream = audio
			player.pitch_scale = 1.0
			player.volume_db = vol
			player.play(from_time)
			break


func pitch_play(audio: AudioStream, vol: float = SFX_VOL, min_pitch: float = 0.95, max_pitch: float = 1.05, single: bool = false) -> void:
	if not audio:
		return
	if single:
		stop()
	for player in get_children():
		player = player as AudioStreamPlayer
		if player == null:
			continue
		if not player.playing:
			player.stream = audio
			player.pitch_scale = randf_range(min_pitch, max_pitch)
			player.volume_db = vol
			player.play()
			break


func stop() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		player.stop()


func pause() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		if player.playing:
			player.stream_paused = true


func resume() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		if player.stream_paused:
			player.stream_paused = false
