#enemy_handler.gd
# Manages enemy spawning, turn sequencing, and faint handling.
# Trainer battles and boss battle complexity stripped for Phase 0.
class_name EnemyHandler
extends Node2D

@export var char_stats: PlayerStats : set = set_character
@export var enemy_scene: PackedScene
@export var stats_ui_scene: PackedScene

@onready var right_panel: VBoxContainer = $"../StatUI/RightPanel"
@onready var party_handler: PartyHandler = $"../PartyHandler"

var battle_stats: BattleStats = null


func _ready() -> void:
	Events.enemy_fainted.connect(_on_enemy_fainted)
	Events.party_creature_fainted.connect(_on_party_creature_fainted)


func set_character(new_char_stats: PlayerStats) -> void:
	char_stats = new_char_stats


func setup_enemies(bat_stats: BattleStats) -> void:
	if not bat_stats:
		return
	battle_stats = bat_stats.duplicate()

	for enemy: Enemy in get_children():
		enemy.queue_free()

	if battle_stats.enemy_creature_party.is_empty():
		battle_stats.assign_creature_party()

	var species_ids: Array[String] = battle_stats.enemy_creature_party.duplicate()

	if not battle_stats.enemies:
		push_error("EnemyHandler: BattleStats.enemies PackedScene is not set")
		return

	var all_new_enemies := battle_stats.enemies.instantiate()
	var enemy_nodes := all_new_enemies.get_children()

	for i in range(min(species_ids.size(), enemy_nodes.size())):
		_spawn_enemy(species_ids[i], enemy_nodes[i])

	all_new_enemies.queue_free()


func reset_enemy_actions() -> void:
	for child in get_children():
		if child is Enemy:
			child.current_action = null
			child.update_action()


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

	var creature_data := CreatureData.get_creature_data(species_id)
	var stats := EnemyStats.new()
	stats.species_id = species_id
	stats.uid = "enemy_%s_%d" % [species_id, Time.get_ticks_msec()]
	if not creature_data.is_empty():
		stats.load_from_data(creature_data)
	else:
		push_warning("EnemyHandler: No creature data for '%s' — using defaults" % species_id)
		stats.max_health = 10
		stats.health = 10

	enemy.stats = stats
	add_child(enemy)


func _on_enemy_fainted(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	Events.battle_text_requested.emit(
		"Enemy [color=red]%s[/color] FAINTED!" % enemy.stats.species_id.capitalize()
	)
	for battler in party_handler.get_active_creature_nodes():
		if battler.has_method("on_enemy_defeated"):
			battler.on_enemy_defeated(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()
	child_order_changed.emit()


func _on_party_creature_fainted(unit: CreatureBattleUnit) -> void:
	for enemy in get_children():
		if enemy is Enemy and enemy.enemy_action_picker:
			if enemy.enemy_action_picker.has_method("select_valid_target"):
				enemy.enemy_action_picker.select_valid_target()


func get_enemies() -> Array[Node]:
	return get_children()
