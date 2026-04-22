extends Node


func play(audio: AudioStream, single := false) -> void:
	if not audio:
		return
	if single:
		stop()
	for player in get_children():
		player = player as AudioStreamPlayer
		if not player.playing:
			player.stream = audio
			player.pitch_scale = 1.0
			player.play()
			break


func play_from_time(audio: AudioStream, from_time := 0.0, single := false) -> void:
	if not audio:
		return
	if single:
		stop()
	for player in get_children():
		player = player as AudioStreamPlayer
		if not player.playing:
			player.stream = audio
			player.pitch_scale = 1.0
			player.play(from_time)
			break


func pitch_play(audio: AudioStream, min_pitch := 0.95, max_pitch := 1.05, single := false) -> void:
	print("[SFXPlayer] pitch_play called | audio=%s children=%d" % [audio, get_child_count()])
	if not audio:
		print("[SFXPlayer] early return — audio null")
		return
	if single:
		stop()
	for player in get_children():
		player = player as AudioStreamPlayer
		if player == null:
			print("[SFXPlayer] child is not AudioStreamPlayer")
			continue
		print("[SFXPlayer] checking player=%s playing=%s" % [player, player.playing])
		if not player.playing:
			player.stream = audio
			player.pitch_scale = randf_range(min_pitch, max_pitch)
			player.play()
			print("[SFXPlayer] playing on %s" % player)
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
