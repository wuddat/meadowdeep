class_name Meadow
extends Node2D

const MEADOW_WORLD_ITEM := preload("res://scenes/meadow/meadow_world_item.tscn")

const TOSS_RADIUS_MIN := 16.0
const TOSS_RADIUS_MAX := 48.0
const TOSS_ARC_HEIGHT := 40.0
const TOSS_DURATION  := 0.5
const TOSS_STAGGER   := 0.5
const START_LOOT_SPAWN_DELAY := 3.0

@onready var player_model: CharacterBody2D = $PlayerModel
@onready var pop_sfx: AudioStreamPlayer = $Pop
@export var base_creature: BaseCreature

var player_data: PlayerData


func setup(run_data: PlayerData) -> void:
	player_data = run_data
	player_model.stats = run_data
	if player_data.creatures.size():
		base_creature.instance = player_data.creatures[0]
	_print_inventory()
	_spawn_loot_party()


func _print_inventory() -> void:
	if not player_data or not player_data.inventory:
		print("[Meadow] no inventory")
		return
	var entries := player_data.inventory.entries
	print("[Meadow] inventory entries: %d (rid=%d)" % [entries.size(), player_data.inventory.get_instance_id()])
	for e in entries:
		var n: String = e.item.id if e.item else "<null>"
		print("  - %s x%d" % [n, e.qty])


func save_meadow_stats() -> PlayerData:
	if base_creature:
		player_data.creatures.append(base_creature.instance)
	return player_data


func _spawn_loot_party() -> void:
	if not player_data or not player_data.inventory:
		return
	var entries := player_data.inventory.entries.duplicate()
	if entries.is_empty():
		return
	await get_tree().create_timer(START_LOOT_SPAWN_DELAY).timeout
	var i := 0
	for entry in entries:
		if not entry.item:
			continue
		for _q in entry.qty:
			_toss_item(entry.item, i * TOSS_STAGGER)
			i += 1
	player_data.inventory.entries.clear()
	player_data.inventory.inventory_changed.emit()


func _toss_item(item_data: ItemDef, delay: float) -> void:
	var node: WorldItemBase = MEADOW_WORLD_ITEM.instantiate()
	node.item_data = item_data
	add_child(node)
	var start: Vector2 = player_model.global_position
	var angle := randf() * TAU
	var dist := randf_range(TOSS_RADIUS_MIN, TOSS_RADIUS_MAX)
	var end: Vector2 = start + Vector2.RIGHT.rotated(angle) * dist
	node.global_position = start
	node.collision_shape.disabled = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_instance_valid(node):
		return
	pop_sfx.pitch_scale = randf_range(0.9, 1.15)
	pop_sfx.play()
	var tween := node.create_tween()
	tween.tween_method(
		func(t: float) -> void:
			node.global_position = start.lerp(end, t) + Vector2(0, -TOSS_ARC_HEIGHT * sin(t * PI)),
		0.0, 1.0, TOSS_DURATION
	).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		if is_instance_valid(node) and node.collision_shape:
			node.collision_shape.disabled = false
	)
