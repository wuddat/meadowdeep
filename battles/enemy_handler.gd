#enemy_handler.gd
# Manages enemy spawning, turn sequencing, and faint handling.
# Trainer battles and boss battle complexity stripped for Phase 0.
class_name EnemyHandler
extends Node2D

@export var player_data: PlayerData : set = set_character
@export var enemy_scene: PackedScene
@export var stats_ui_scene: PackedScene

@onready var party_handler: PartyHandler = $"../PartyHandler"

var encounter: EncounterDef = null


func _ready() -> void:
	Events.enemy_fainted.connect(_on_enemy_fainted)


func set_character(new_player_data: PlayerData) -> void:
	player_data = new_player_data


func setup_enemies(bat_stats: EncounterDef) -> void:
	if not bat_stats:
		return
	encounter = bat_stats.duplicate()
	for enemy: Enemy in get_children():
		enemy.queue_free()
	if encounter.enemy_creature_party.is_empty():
		encounter.assign_creature_party()
	var species_ids: Array[String] = encounter.enemy_creature_party.duplicate()
	if not encounter.spawn_layout:
		push_error("EnemyHandler: EncounterDef.enemies PackedScene is not set")
		return
	var spawn_layout = encounter.spawn_layout.instantiate()
	var enemy_nodes = spawn_layout.get_children()
	for i in range(min(species_ids.size(), enemy_nodes.size())):
		_spawn_enemy(species_ids[i], enemy_nodes[i])
	spawn_layout.queue_free()


func start_turn() -> void:
	for enemy: Enemy in get_children():
		enemy.start_combat()


func _spawn_enemy(species_id: String, enemy_node: Node2D) -> void:
	if not is_instance_valid(enemy_node):
		return
	if not enemy_scene:
		push_error("EnemyHandler: enemy_scene is not set in the inspector")
		return

	var enemy: Enemy = enemy_scene.instantiate()
	if enemy_node:
		enemy.global_position = enemy_node.global_position

	var instance: CreatureInstance = CreatureData.create_creature_instance(species_id)
	if not instance:
		push_warning("[ENEMYHANDLER]: No creature data for '%s'" % species_id)
		enemy.queue_free()
		return
	instance.uid = "enemy_%s_%d" % [species_id, Time.get_ticks_msec()]
	enemy.instance = instance
	add_child(enemy)


func _on_enemy_fainted(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	if is_instance_valid(enemy):
		enemy.queue_free()
	child_order_changed.emit()


func get_enemies() -> Array[Node]:
	return get_children()
