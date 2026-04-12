class_name EnemyActionPicker
extends Node

@export var enemy: Enemy : set = _set_enemy
@export var target: Node2D : set = _set_target

@onready var total_weight := 0.0
var target_pool: Array = []
var confused_target_pool: Array = []
var current_target_pos: String = ""
var player_party_pool: Array = []
var enemy_ally_pool: Array[Node] = []


func _ready() -> void:
	await _wait_for_party_handler()
	_initialize_connections()
	refresh_target_pool()
	select_valid_target()


func _wait_for_party_handler() -> void:
	await get_tree().process_frame
	while get_tree().get_first_node_in_group("party_handler") == null:
		await get_tree().process_frame


func refresh_target_pool() -> void:
	var party_handler = get_tree().get_first_node_in_group("party_handler")
	var enemy_handler = get_tree().get_first_node_in_group("enemy_handler")

	target_pool.clear()
	confused_target_pool.clear()
	player_party_pool.clear()
	enemy_ally_pool.clear()

	if party_handler:
		player_party_pool = party_handler.get_active_creature_nodes()
		player_party_pool.sort_custom(func(a, b): return a.spawn_position < b.spawn_position)
		player_party_pool = player_party_pool.filter(
			func(unit): return is_instance_valid(unit) and unit.stats and unit.stats.health > 0
		)
		target_pool = player_party_pool.duplicate()
		confused_target_pool += player_party_pool

	if enemy_handler:
		enemy_ally_pool = enemy_handler.get_children().filter(
			func(n): return n is Enemy and n.stats and n.stats.health > 0
		)
		confused_target_pool += enemy_ally_pool

	confused_target_pool = confused_target_pool.filter(func(n): return is_instance_valid(n))


func select_valid_target() -> void:
	var valid_targets := target_pool.filter(
		func(unit): return is_instance_valid(unit) and unit.stats and unit.stats.health > 0
	)
	if valid_targets.is_empty():
		target = null
		for action in get_children():
			action.target = null
		return
	target = RNG.array_pick_random(valid_targets)
	current_target_pos = target.spawn_position
	for action in get_children():
		action.target = target


func select_confused_target() -> void:
	if confused_target_pool.is_empty():
		target = null
	else:
		refresh_target_pool()
		target = RNG.array_pick_random(confused_target_pool)
	for action in get_children():
		action.target = target


func get_action() -> EnemyAction:
	var action := get_first_conditional_action()
	if action:
		return action
	return get_chance_based_action()


func get_first_conditional_action() -> EnemyAction:
	for child in get_children():
		var action := child as EnemyAction
		if action and action.type == EnemyAction.Type.CONDITIONAL and action.is_performable():
			return action
	return null


func get_chance_based_action() -> EnemyAction:
	var roll := RNG.instance.randf_range(0.0, total_weight)
	for child in get_children():
		var action := child as EnemyAction
		if action and action.type == EnemyAction.Type.CHANCE_BASED and action.accumulated_weight > roll:
			return action
	return null


func setup_actions_from_moves(enemy_ref: Enemy, move_ids: Array[String]) -> void:
	refresh_target_pool()
	enemy = enemy_ref

	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()
		await get_tree().process_frame

	for move_id in move_ids:
		var move_data: Dictionary = MoveData.moves.get(move_id, {})
		if move_data.is_empty():
			push_warning("EnemyActionPicker: missing move data for: " + move_id)
			continue
		var category: String = move_data.get("category", "attack")
		var action := EnemyActionFactory.create_action(category, move_data)
		if not action:
			continue
		add_child(action)
		action.enemy = enemy_ref
		resolve_action_targets(action, move_data.get("target", "enemy"))

	setup_chances()


func resolve_action_targets(action: EnemyAction, target_type: String) -> void:
	match target_type:
		"single_enemy", "enemy":
			action.target = target
		"all_enemies":
			action.targets = player_party_pool.duplicate()
		"all_allies", "allies":
			action.targets = enemy_ally_pool.duplicate()
		"all":
			action.targets = player_party_pool.duplicate() + enemy_ally_pool.duplicate()
		"self":
			action.targets = [enemy]
		_:
			action.target = target


func setup_chances() -> void:
	for child in get_children():
		var action := child as EnemyAction
		if action and action.type == EnemyAction.Type.CHANCE_BASED:
			total_weight += action.chance_weight
			action.accumulated_weight = total_weight


func _on_party_shifted() -> void:
	refresh_target_pool()
	if not is_instance_valid(target):
		select_valid_target()
		return
	var new_target: Node = null
	for candidate in target_pool:
		if candidate.spawn_position == current_target_pos:
			new_target = candidate
			break
	if not new_target and not target_pool.is_empty():
		new_target = target_pool.front()
		current_target_pos = new_target.spawn_position
	if new_target:
		target = new_target
		for action in get_children():
			action.target = new_target


func _on_creature_fainted(_fainted: Node) -> void:
	refresh_target_pool()
	select_valid_target()


func _on_creature_switch(_creature_stats: CreatureStats) -> void:
	refresh_target_pool()
	_on_party_shifted()


func _set_enemy(value: Enemy) -> void:
	enemy = value
	for action in get_children():
		action.enemy = enemy


func _set_target(value: Node2D) -> void:
	target = value
	for action in get_children():
		action.target = target


func _initialize_connections() -> void:
	if not Events.player_creature_switch_completed.is_connected(_on_creature_switch):
		Events.player_creature_switch_completed.connect(_on_creature_switch)
	if not Events.party_creature_fainted.is_connected(_on_creature_fainted):
		Events.party_creature_fainted.connect(_on_creature_fainted)
	if not Events.party_shifted.is_connected(_on_party_shifted):
		Events.party_shifted.connect(_on_party_shifted)
