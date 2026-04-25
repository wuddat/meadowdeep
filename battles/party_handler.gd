#party_handler.gd
class_name PartyHandler
extends Node

@export var POS_0 := Vector2(190, 185)
@export var POS_1 := Vector2(120, 200)
@export var POS_2 := Vector2(95, 210)

@export var max_party_size := 6
@export var character_stats: PlayerStats
@export var creature_battle_unit_scene: PackedScene

var stat_ui_by_uid: Dictionary = {}
var active_battle_party: Array[CreatureStats] = []
var active_indexes := [0, 1, 2]


func initialize_party_for_battle() -> void:
	await get_tree().process_frame
	if character_stats == null:
		push_error("PartyHandler requires a reference to character_stats")
		return
	spawn_active_creatures()


func add_to_battle_party(creature: CreatureStats) -> bool:
	if active_battle_party.size() >= max_party_size:
		return false
	active_battle_party.append(creature)
	return true


func get_active_creatures() -> Array[CreatureStats]:
	var actives: Array[CreatureStats] = []
	for creature in active_battle_party:
		if creature.health > 0:
			actives.append(creature)
		if actives.size() == 3:
			break
	return actives


func spawn_active_creatures() -> void:
	if not creature_battle_unit_scene:
		push_error("PartyHandler: creature_battle_unit_scene is not set in the inspector")
		return

	var actives := get_active_creatures()
	for i in range(actives.size()):
		var creature := actives[i]
		var unit := creature_battle_unit_scene.instantiate() as CreatureBattleUnit

		if stat_ui_by_uid.has(creature.uid):
			unit.set_health_bar_ui(stat_ui_by_uid[creature.uid])

		unit.stats = creature
		unit.spawn_position = "POS_%s" % i

		if not unit.stats.stats_changed.is_connected(sync_battle_health_to_party_data):
			unit.stats.stats_changed.connect(sync_battle_health_to_party_data)

		match i:
			0: unit.position = POS_0
			1: unit.position = POS_1
			2: unit.position = POS_2
			_: unit.position = Vector2(0, 0)
		add_child(unit)


func get_active_creature_nodes() -> Array[CreatureBattleUnit]:
	var result: Array[CreatureBattleUnit] = []
	for node in get_children():
		if node is CreatureBattleUnit:
			result.append(node)
	return result


func get_creature_by_uid(uid: String) -> CreatureBattleUnit:
	for unit in get_children():
		if unit is CreatureBattleUnit and unit.stats.uid == uid:
			return unit as CreatureBattleUnit
	push_warning("No creature in battle with UID %s" % uid)
	return null


func sync_battle_health_to_party_data() -> void:
	if character_stats == null:
		return
	for creature in active_battle_party:
		for i in range(character_stats.current_party.size()):
			if character_stats.current_party[i].uid == creature.uid:
				character_stats.current_party[i] = creature


func finalize_battle_party(creature_list: Array[CreatureStats]) -> void:
	active_battle_party.clear()
	for creature in creature_list:
		if not add_to_battle_party(creature):
			push_warning("Party is full. Could not add: %s" % creature.species_id)
