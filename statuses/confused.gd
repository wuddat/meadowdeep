class_name ConfusedStatus
extends Status

const CONFUSED_ICON := preload("res://art/statuseffects/confused-effect.png")

func get_tooltip() -> String:
	return "This unit is confused and may attack the wrong target!"

func initialize_status(target: Node) -> void:
	if not (target is Enemy):
		return

	var enemy_target := target as Enemy
	enemy_target.is_confused = true
	if target.has_method("show_combat_text"):
		target.show_combat_text("CONFUSED", Color.ROSY_BROWN)
