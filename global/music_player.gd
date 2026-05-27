extends Node


@onready var _player: AudioStreamPlayer = $AudioStreamPlayer

var _loop := true


func _ready() -> void:
	_player.bus = &"Music"
	_player.finished.connect(_on_finished)


## Play a track. loop=true replays on finish. No-op if track already playing.
func play(track: AudioStream, loop := true, from_time := 0.0) -> void:
	if not track:
		return
	_loop = loop
	if _player.stream == track and _player.playing:
		return
	_player.stream = track
	_player.play(from_time)


func stop() -> void:
	_loop = false
	_player.stop()


func pause() -> void:
	_player.stream_paused = true


func resume() -> void:
	_player.stream_paused = false


func is_playing() -> bool:
	return _player.playing


func _on_finished() -> void:
	if _loop:
		_player.play()
