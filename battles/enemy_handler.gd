#enemy_handler.gd
# Manages enemy spawning, turn sequencing, and faint handling.
# Trainer battles and boss battle complexity stripped for Phase 0.
class_name EnemyHandler
extends Node2D

@export var player_data: PlayerData : set = set_character
@export var enemy_scene: PackedScene
@export var stats_ui_scene: PackedScene
@export var prop_controller: PropController

var encounter: EncounterDef = null

const BAT_SFX_1 = preload("uid://b6ei6ar836t2r")
const BAT_DEATH_1 = preload("uid://c3284gsyob4n7")

var _in_combat: bool = false

func _ready() -> void:
	Events.enemy_fainted.connect(_on_enemy_fainted)


func set_character(new_player_data: PlayerData) -> void:
	player_data = new_player_data


func setup_enemies(bat_stats: EncounterDef, spawn_points: Array[Vector2] = []) -> void:
	if not bat_stats:
		return
	encounter = bat_stats.duplicate()
	if not _in_combat:
		for enemy: Enemy in get_children():
			enemy.queue_free()
		_in_combat = true
	if encounter.enemy_creature_party.is_empty():
		encounter.assign_creature_party()
	var species_ids: Array[String] = encounter.enemy_creature_party.duplicate()
	if not encounter.spawn_layout:
		push_error("EnemyHandler: EncounterDef.enemies PackedScene is not set")
		return
	if _is_boss(species_ids, spawn_points):
		return
	var count: int = min(species_ids.size(), spawn_points.size())
	for i in range(count):
		spawn_enemy(species_ids[i], spawn_points[i])


func start_combat() -> void:
	for enemy: Enemy in get_children():
		enemy.start_combat()


func spawn_enemy(species_id: String, spawn_pos: Vector2, scene: PackedScene = enemy_scene) -> void:
	if not scene:
		push_error("EnemyHandler: enemy_scene is not set in the inspector")
		return

	var enemy: Enemy = scene.instantiate()
	if spawn_pos:
		enemy.global_position = spawn_pos

	var instance: CreatureInstance = CreatureData.create_creature_instance(species_id)
	if not instance:
		push_warning("[ENEMYHANDLER]: No creature data for '%s'" % species_id)
		enemy.queue_free()
		return
	instance.uid = "enemy_%s_%d" % [species_id, Time.get_ticks_msec()]
	enemy.instance = instance
	if enemy.instance.definition.species_id == "test_chaser":
		enemy.sfx = BAT_SFX_1
		enemy.death_sfx = BAT_DEATH_1
	add_child(enemy)
	if "boss_controller" in enemy:
		enemy.boss_controller.prop_controller = prop_controller


func _on_enemy_fainted(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	if is_instance_valid(enemy):
		enemy.queue_free()
	child_order_changed.emit()



func get_enemies() -> Array[Node]:
	return get_children()

func _is_boss(species_ids, spawn_points: Array[Vector2]) -> bool:
	if encounter is BossEncounterDef and encounter.boss_scene:
		var pos: Vector2 = spawn_points[0] if not spawn_points.is_empty() else global_position
		spawn_enemy(species_ids[0], pos, encounter.boss_scene)
		return true
	return false
