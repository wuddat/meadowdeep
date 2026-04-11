#enemy_handler.gd
# Manages enemy spawning, turn sequencing, and faint handling.
# Trainer battles and boss battle complexity stripped for Phase 0.
class_name EnemyHandler
extends Node2D

@export var char_stats: ArchaeologistStats : set = set_character

@onready var right_panel: VBoxContainer = $"../StatUI/RightPanel"
@onready var party_handler: PartyHandler = $"../PartyHandler"

# Set in the Godot editor once scenes are created.
@export var enemy_scene: PackedScene
@export var stats_ui_scene: PackedScene  # HealthBarUI.tscn — optional, for stat display

var acting_enemies: Array[Enemy] = []
var battle_stats: BattleStats = null
var enemy_text_delay: float = 0.4


func _ready() -> void:
	Events.enemy_fainted.connect(_on_enemy_fainted)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_hand_discarded.connect(_on_player_hand_drawn)
	Events.party_creature_fainted.connect(_on_party_creature_fainted)


func set_character(new_char_stats: ArchaeologistStats) -> void:
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
	if get_child_count() == 0:
		return
	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)
	_start_next_enemy_turn()


func shift_enemies() -> void:
	await get_tree().create_timer(0.3).timeout
	var enemies: Array[Enemy] = []
	var positions: Array[Vector2] = []

	for child in get_children():
		if child is Enemy:
			enemies.append(child)
			positions.append(child.spawn_coords)

	if positions.size() < 2:
		return

	enemies.sort_custom(func(a, b): return a.spawn_coords.x < b.spawn_coords.x)
	positions.sort_custom(func(a, b): return a.x < b.x)

	var new_order := enemies.duplicate()
	new_order.push_front(new_order.pop_back())

	for i in range(new_order.size()):
		var enemy: Enemy = new_order[i]
		enemy.spawn_coords = positions[i]
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(enemy, "global_position", positions[i], 0.4)


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

	if stats_ui_scene and right_panel:
		var ui := stats_ui_scene.instantiate()
		right_panel.add_child(ui)
		if ui.has_method("update_stats"):
			ui.update_stats(stats)
		if not enemy.stats.stats_changed.is_connected(func(): ui.update_stats(enemy.stats)):
			enemy.stats.stats_changed.connect(func(): ui.update_stats(enemy.stats))

	if enemy.status_handler:
		enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))


func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		Events.enemy_turn_ended.emit()
		return
	await get_tree().process_frame
	acting_enemies[0].status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func _on_enemy_statuses_applied(type: Status.Type, enemy: Enemy) -> void:
	match type:
		Status.Type.START_OF_TURN:
			enemy.do_turn()
		Status.Type.END_OF_TURN:
			acting_enemies.erase(enemy)
			_start_next_enemy_turn()


func _on_enemy_fainted(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return

	Events.battle_text_requested.emit(
		"Enemy [color=red]%s[/color] FAINTED!" % enemy.stats.species_id.capitalize()
	)

	for battler in party_handler.get_active_creature_nodes():
		if battler.has_method("on_enemy_defeated"):
			battler.on_enemy_defeated(enemy)

	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()
	child_order_changed.emit()

	if is_enemy_turn:
		_start_next_enemy_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func _on_party_creature_fainted(unit: CreatureBattleUnit) -> void:
	for enemy in acting_enemies:
		if enemy.current_action and "target" in enemy.current_action:
			if enemy.current_action.get("target") == unit:
				if enemy.enemy_action_picker and enemy.enemy_action_picker.has_method("select_valid_target"):
					enemy.enemy_action_picker.select_valid_target()


func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent(enemy.current_action)


func get_enemies() -> Array[Node]:
	return get_children()
