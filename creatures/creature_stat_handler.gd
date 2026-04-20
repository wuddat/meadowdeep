extends Node

signal stat_changed
signal item_received(item: MeadowWorldItem)

var stat_block: CreatureStatBlock


func apply_item(item: MeadowWorldItem) -> void:
	if not item:
		return
	match item.category:
		MeadowWorldItem.ItemCategory.FOOD:
			apply_food(item as CreatureFood)
		MeadowWorldItem.ItemCategory.TOY:
			pass  # stub — ToyItem not yet implemented
		MeadowWorldItem.ItemCategory.MEDICINE:
			pass  # stub — MedicineItem not yet implemented
		MeadowWorldItem.ItemCategory.RELIC:
			pass  # stub — RelicItem not yet implemented
	item_received.emit(item)


func apply_food(food_data: CreatureFood) -> void:
	if not stat_block or not food_data:
		return
	var stat_name: String = CreatureData.STAT_NAMES.get(food_data.creature_attribute, "")
	if not stat_name:
		return
	var stat: StatBlock = stat_block.get(stat_name)
	if stat:
		for _i in food_data.attribute_increment:
			stat.add_pip()
		stat_changed.emit()
