extends Node

signal stat_changed(uid: String)
signal item_received(item: ItemDef)

var identity: CreatureIdentity

@export var creature_uid: String


func apply_item(item: ItemDef) -> void:
	if not item:
		return
	match item.category:
		ItemDef.ItemCategory.FOOD:
			apply_food(item as FoodDef)
		ItemDef.ItemCategory.TOY:
			pass  # stub — ToyItem not yet implemented
		ItemDef.ItemCategory.MEDICINE:
			pass  # stub — MedicineItem not yet implemented
		ItemDef.ItemCategory.RELIC:
			pass  # stub — RelicItem not yet implemented
		ItemDef.ItemCategory.STAT_FRAGMENT:
			absorb_item(item as FragmentDef)
	item_received.emit(item)


func apply_food(food_data: FoodDef) -> void:
	if not identity or not food_data:
		return
	var stat_name: String = CreatureData.STAT_NAMES.get(food_data.creature_attribute, "")
	if not stat_name:
		return
	var stat: GrowthStat = identity.get(stat_name)
	if stat:
		for _i in food_data.attribute_increment:
			stat.add_pip()
		stat_changed.emit(creature_uid)
		Events.creature_stat_updated.emit(creature_uid)

func absorb_item(frag: FragmentDef) -> void:
	if not identity or not frag:
		return
	var stat_name: String = CreatureData.STAT_NAMES.get(frag.creature_attribute, "")
	if not stat_name:
		return
	var stat: GrowthStat = identity.get(stat_name)
	if stat:
		for _i in frag.pips:
			stat.add_pip()
		stat_changed.emit(creature_uid)
		Events.creature_stat_updated.emit(creature_uid)
	
