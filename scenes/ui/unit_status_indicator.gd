class_name UnitStatusIndicator
extends Control

@onready var status_icon: TextureRect = $StatusIcon

var drift_tween: Tween


func _ready() -> void:
	hide()
	drift_tween = create_tween()
	drift_tween.set_loops()
	drift_tween.set_trans(Tween.TRANS_SINE)
	drift_tween.set_ease(Tween.EASE_IN_OUT)

	var start_pos := status_icon.position
	drift_tween.tween_property(status_icon, "position", start_pos + Vector2(-4, 0), 0.4)
	drift_tween.parallel().tween_property(status_icon, "rotation_degrees", -5.0, 0.4)
	drift_tween.parallel().tween_property(status_icon, "scale", Vector2(0.6, 0.6), 0.4)
	drift_tween.tween_property(status_icon, "position", start_pos + Vector2(4, 0), 0.8)
	drift_tween.parallel().tween_property(status_icon, "rotation_degrees", 5.0, 0.8)
	drift_tween.parallel().tween_property(status_icon, "scale", Vector2(0.8, 0.8), 0.8)
	drift_tween.tween_property(status_icon, "position", start_pos, 0.4)
	drift_tween.parallel().tween_property(status_icon, "rotation_degrees", 0.0, 0.4)
	drift_tween.parallel().tween_property(status_icon, "scale", Vector2(0.6, 0.6), 0.4)


func update_status_display(unit: Node) -> void:
	if unit.status_handler.has_status("confused"):
		show()
		return
	if unit.is_asleep == true:
		show()
		return
	hide()
