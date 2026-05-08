class_name RuinsEntrance
extends Area2D

@export var sprite_2d: Sprite2D
@export var collision_shape_2d: CollisionShape2D

var _is_active: bool = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		print("not player")
		return
	_is_active = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_is_active = false


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if not (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo):
		return
	Events.scene_transition_requested.emit("ruins_prep")
	get_viewport().set_input_as_handled()
