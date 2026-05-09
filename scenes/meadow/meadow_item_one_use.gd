class_name MeadowItemOneUse
extends WorldItemBase


func drop() -> void:
	is_carried = false
	_carrier = null
	collision_shape.call_deferred("set_disabled", false)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		body.nearby_item = self


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.get("nearby_item") == self: 
		body.nearby_item = null

func on_delivered(creature: Node) -> void:
	var handler = creature.get("creature_stat_handler")
	if handler: handler.apply_item(item_data)
	Events.item_used.emit(item_data, creature)
