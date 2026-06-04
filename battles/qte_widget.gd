class_name QTEWidget
extends Control

signal QTE_resolved(quality: String)

@onready var button: Button = $Button

var _data: QTEData
var _resolved: bool
var _start_time: int
var _origin: Vector2


func _process(_delta: float) -> void:
	if not _data or _resolved:
		return
	var _elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var t := clampf(_elapsed / _data.total_duration, 0.0 , 1.0)
	Engine.time_scale = ease(t, 1.0)
	if _elapsed >= _data.total_duration:
		_resolved = true
		Engine.time_scale = 1.0
		QTE_resolved.emit("miss")




func setup(data:QTEData) -> void:
	if data:
		_origin = position
		_resolved = false
		_data = data
		_start_time = Time.get_ticks_msec()
		randomize_position()
		Engine.time_scale = 0.0


func randomize_position() -> void:
	position = _origin + Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))


func _on_button_pressed() -> void:
	Engine.time_scale = 1.0
	_resolved = true
	QTE_resolved.emit("perfect")
