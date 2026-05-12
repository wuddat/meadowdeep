#player_character.gd
# The player character node for battle. Holds stat reference and modifier handler.
class_name PlayerCharacter
extends Node2D

@export var stats: PlayerStats : set = set_player_stats

@onready var stats_ui: Node = $StatsUI              # Will become typed StatsUI once ported
@onready var modifier_handler: ModifierHandler = $ModifierHandler


func set_player_stats(value: PlayerStats) -> void:
	stats = value
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	update_player()


func update_player() -> void:
	if not stats is PlayerStats:
		return
	if not is_inside_tree():
		await ready
	update_stats()


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(stats)
