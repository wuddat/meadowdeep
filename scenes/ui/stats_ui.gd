class_name StatsUI
extends HBoxContainer

@onready var block: HBoxContainer = $Block
@onready var block_label: Label = %BlockLabel
@onready var health: HBoxContainer = %Health


func update_stats(stats: Stats) -> void:
	if block_label == null or health == null:
		await ready  # Wait until node is fully added to tree
	if block_label == null or health == null:
		push_warning("StatsUI is not fully initialized")
		return
	
	block_label.text = str(stats.block)
	health.update_stats(stats)

	block.visible = stats.block > 0
	health.visible = stats.health > 0
