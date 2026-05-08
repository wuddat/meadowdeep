class_name Meadow
extends Node2D

@onready var player_model: CharacterBody2D = $PlayerModel
@export var base_creature: BaseCreature

var player_stats: PlayerStats


func setup(stats: PlayerStats) -> void:
	player_stats = stats
	player_model.stats = stats
	_print_inventory()


func _print_inventory() -> void:
	if not player_stats or not player_stats.inventory:
		print("[Meadow] no inventory")
		return
	var entries := player_stats.inventory.entries
	print("[Meadow] inventory entries: %d (rid=%d)" % [entries.size(), player_stats.inventory.get_instance_id()])
	for e in entries:
		var n: String = e.item.id if e.item else "<null>"
		print("  - %s x%d" % [n, e.qty])


func save_meadow_stats() -> PlayerStats:
	if base_creature:
		player_stats.creatures.append(base_creature.creature_stats)
	return player_stats
