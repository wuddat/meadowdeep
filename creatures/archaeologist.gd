#archaeologist.gd
# The player character node. Holds stat reference and status/modifier handlers.
# Rename note: replaces Player from PokéSpire. Full class is called Archaeologist
# per the MeadowDeep design doc, but the design of this character is not final.
class_name Archaeologist
extends Node2D

@export var stats: ArchaeologistStats : set = set_archaeologist_stats

@onready var stats_ui: Node = $StatsUI              # Will become typed StatsUI once ported
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler


func set_archaeologist_stats(value: ArchaeologistStats) -> void:
	stats = value
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	update_archaeologist()


func update_archaeologist() -> void:
	if not stats is ArchaeologistStats:
		return
	if not is_inside_tree():
		await ready
	update_stats()


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(stats)
