#modifier_handler.gd
class_name ModifierHandler
extends Node


#func _ready() -> void:
	#_establish_connections()

func has_modifier(type: Modifier.Type) -> bool:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return true
	return false


func get_modifier(type: Modifier.Type) -> Modifier:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return modifier
	return null


func get_modified_value(base: int, type: Modifier.Type) -> int:
	var modifier := get_modifier(type)
	if not modifier:
		return base

	return modifier.get_modified_value(base)


#func _establish_connections() -> void:
	#for modifier: Modifier in get_children():
		#if not modifier.child_order_changed.is_connected(_on_modifier_changed):
			#modifier.child_order_changed.connect(_on_modifier_changed)
