#modifier.gd
class_name Modifier
extends Node

enum Type {DMG_DEALT, DMG_TAKEN, BLOCK_GAINED, HEAL_MOD, NO_MODIFIER, STAT_MOD}

@export var type: Type

const MODIFIER_VALUE = preload("res://scenes/modifier_handler/modifier_value.tscn")


func get_value(source: String) -> ModifierValue:
	for value: ModifierValue in get_children():
		if value.source == source:
			return value
	return null


func add_new_value(mod_type: ModifierValue.Type, stat: GrowthStat.StatType, amount: float) -> void:
	var stat_name: String = CreatureData.STAT_NAMES.get(stat)
	var value:ModifierValue = _get_or_create_value(stat_name, mod_type)
	match mod_type:
		ModifierValue.Type.PERCENTAGE:
			value.percent_value += amount
		ModifierValue.Type.FLAT:
			value.flat_value += int(amount)

func _get_or_create_value(stat_name: String, mod_type: ModifierValue.Type) -> ModifierValue:
	for child:ModifierValue in get_children():
		if child.source == stat_name and child.type == mod_type:
			return child
	var new_mod_val:ModifierValue = MODIFIER_VALUE.instantiate() as ModifierValue
	new_mod_val.source = stat_name
	new_mod_val.type = mod_type
	add_child(new_mod_val)
	return new_mod_val

func remove_value(source: String) -> void:
	for value: ModifierValue in get_children():
		if value.source == source:
			value.queue_free()


func clear_values() -> void:
	for value: ModifierValue in get_children():
		value.queue_free()


func get_modified_value(base: int, source: String = "") -> int:
	var flat_result: int = base
	var percent_result: float = 1.0
	# Flat mods applied first, then percentages
	for value: ModifierValue in get_children():
		if source != "":
			if source != value.source:
				continue
		if value.type == ModifierValue.Type.FLAT:
			flat_result += value.flat_value
	for value: ModifierValue in get_children():
		if value.type == ModifierValue.Type.PERCENTAGE:
			percent_result += (value.percent_value / 100.0)
	return floori(flat_result * percent_result)
