class_name RuinsWorldItem
extends WorldItemBase

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var stats = body.get("stats")
	if stats == null or stats.inventory == null:
		push_warning("[RUINSWORLDITEM]: No player inventory")
		return
	stats.inventory.add_item(item_data, 1)
	Events.item_picked_up.emit(item_data, 1)
	queue_free()
