class_name Meadow
extends Node2D

const MEADOW_WORLD_ITEM := preload("uid://d4g4hbpijemuw")
const MEADOW_CREATURE_SCN := preload("uid://bio1g4lsk4beu")
const MEADOW = preload("uid://byyiynr17r81x")

const SPAWN_COORDS: Array[Vector2] = [Vector2(486,331), Vector2(461,336), Vector2(631,461)]

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

func _ready() -> void:
	MusicPlayer.play(MEADOW)


func setup(run_data: PlayerData) -> void:
	player_data = run_data
	player_model.stats = run_data
	_spawn_creatures()
	#base_creature.instance = player_data.creatures[0] (can use as fallback for testing)
	_print_inventory()
	_spawn_loot_party()


func _spawn_creatures() -> void:
	if player_data.creatures.is_empty():
		return
	if base_creature:
		base_creature.queue_free()
	for i in player_data.creatures.size():
		var creature_node: BaseCreature = MEADOW_CREATURE_SCN.instantiate()
		creature_node.instance = player_data.creatures[i]
		add_child(creature_node)
		creature_node.position = SPAWN_COORDS[i % SPAWN_COORDS.size()]


func _print_inventory() -> void:
	if not player_data or not player_data.inventory:
		print("[Meadow] no inventory")
		return
	var entries := player_data.inventory.entries
	print("[Meadow] inventory entries: %d (rid=%d)" % [entries.size(), player_data.inventory.get_instance_id()])
	for e in entries:
		var n: String = e.item.id if e.item else "<null>"
		print("  - %s x%d" % [n, e.qty])


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
