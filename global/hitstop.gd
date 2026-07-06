extends Node

var _is_running: bool = false

func go(duration: float = 0.1) -> void:
	if _is_running:
		return
	_is_running = true
	Engine.time_scale = 0.00
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1
	_is_running = false
