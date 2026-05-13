#player_character.gd
# The player character node for battle. Holds player_data reference.
# The player is not a combatant in autobattle — no health/block wiring.
class_name PlayerCharacter
extends Node2D

@export var player_data: PlayerData

@onready var stats_ui: Node = $StatsUI


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(player_data)
