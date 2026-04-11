#enemy_stats.gd
class_name EnemyStats
extends CreatureStats

@export var ai: PackedScene
var skip_turn: bool = false
var has_slept: bool = false


func load_from_data(data: Dictionary) -> void:
	if data.is_empty():
		push_warning("Tried to load enemy stats from empty data.")
		return

	max_health = data.get("max_health", 10)
	health = max_health
	art = load(data.get("sprite_path", "res://art/placeholder.png"))
	icon = load(data.get("icon_path", "res://art/placeholder.png"))
	element_type = data.get("element_type", "normal")
	creature_name = data.get("creature_name", species_id)

	var raw_ids = data.get("move_ids", [])
	var cleaned_ids: Array[String] = []
	if typeof(raw_ids) == TYPE_ARRAY:
		for id in raw_ids:
			cleaned_ids.append(str(id))
	elif typeof(raw_ids) == TYPE_STRING:
		cleaned_ids.append(raw_ids)
	else:
		push_warning("Unexpected move_ids format: " + str(raw_ids))

	move_ids = cleaned_ids
