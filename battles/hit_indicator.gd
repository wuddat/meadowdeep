class_name HitIndicator
extends Node2D

@export var color: Color = Color(1.0, 0.3, 0.2, 0.45)

func setup(origin: Vector2, direction: Vector2, length: float, width: float, dur: float) -> void:
	global_position = origin
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = PackedVector2Array([Vector2.ZERO, direction.normalized() * length])
	add_child(line)
	_run_tween(line, dur)

func _run_tween(line_indicator: Line2D, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(line_indicator, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
