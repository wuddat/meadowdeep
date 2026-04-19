extends Node

signal stat_changed

var stat_block: CreatureStatBlock


func apply_food(food_data: CreatureFood) -> void:
	if not stat_block or not food_data:
		return
	var stat_name: String = CreatureData.STAT_NAMES.get(food_data.creature_attribute, "")
	if not stat_name:
		return
	var stat: StatBlock = stat_block.get(stat_name)
	if stat:
		stat.points += food_data.attribute_increment
		stat_changed.emit()
