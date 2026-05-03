class_name Taunt
extends Status

func get_tooltip() -> String:
	return "This unit was TAUNTED!"

func initialize_status(target: Node) -> void:
	if not (target is Enemy):
		return

	var enemy_target := target as Enemy
	SFXPlayer.play(preload("res://art/enemy_block.ogg"))
	if enemy_target.status_handler:
		enemy_target.status_handler.remove_status("taunt")
