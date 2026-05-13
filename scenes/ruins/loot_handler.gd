class_name LootHandler
extends Node

@export var enemy_handler: EnemyHandler
@export var item_scene: PackedScene = preload("uid://bqr0k0qv2mv3m")

var _pending_drops: Dictionary = {}


func _ready() -> void:
	_establish_connections()


func _establish_connections() -> void:
	if not Events.enemy_fainted.is_connected(_on_enemy_fainted):
		Events.enemy_fainted.connect(_on_enemy_fainted)


func generate_battle_loot() -> void:
	if not enemy_handler:
		push_warning("[LOOTHANDLER]: enemy_handler not set")
		return
	_aggregate_loot()
	_roll_loot()


func _aggregate_loot() -> void:
	_pending_drops.clear()
	for enemy in enemy_handler.get_enemies():
		if not enemy is Enemy:
			continue
		var e := enemy as Enemy
		if e.instance and e.loot_table:
			_pending_drops[e.instance.uid] = e.loot_table


func _roll_loot() -> void:
	for uid in _pending_drops.keys():
		var table: LootTable = _pending_drops[uid]
		_pending_drops[uid] = table.roll_drops()


func _on_enemy_fainted(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or not enemy.instance:
		return
	var uid := enemy.instance.uid
	if not _pending_drops.has(uid):
		return
	_spawn_loot(_pending_drops[uid], enemy.global_position)
	_pending_drops.erase(uid)


func _spawn_loot(drops: Array, at: Vector2) -> void:
	if item_scene == null:
		push_warning("[LOOTHANDLER]: item_scene not set")
		return
	var spread := 12.0
	for entry: InventoryEntry in drops:
		for i in entry.qty:
			var item_node: WorldItemBase = item_scene.instantiate()
			item_node.item_data = entry.item
			var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
			item_node.global_position = at + offset
			get_parent().add_child(item_node)
