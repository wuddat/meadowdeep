#modifier_handler.gd
class_name ModifierHandler
extends Node

signal mods_changed

func _ready() -> void:
	_establish_connections()

func has_modifier(type: Modifier.Type) -> bool:
	for modifier: Modifier in get_children():
		if modifier.type == type:
			return true
	return false

func add_timed_value(modifier: Modifier.Type, mod_type: ModifierValue.Type, source: String, amount: float, duration: float = 0.0) -> void:
	var mod := get_modifier(modifier)
	mod.add_new_value(mod_type, source, amount, duration)


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


func _on_modifier_timeout(mod_val: ModifierValue, mod_type: ModifierValue.Type, amount: float) -> void:
	match mod_type:
		ModifierValue.Type.PERCENTAGE:
			mod_val.percent_value -= amount
		ModifierValue.Type.FLAT:
			mod_val.flat_value -= amount
	mods_changed.emit()

func _establish_connections() -> void:
	for modifier: Modifier in get_children():
		if not modifier.modifier_timeout.is_connected(_on_modifier_timeout):
			modifier.modifier_timeout.connect(_on_modifier_timeout)
		if not modifier.mod_changed.is_connected(mods_changed.emit):
			modifier.mod_changed.connect(mods_changed.emit)
