class_name StatsUI
extends HBoxContainer

@onready var block: HBoxContainer = $Block
@onready var block_label: Label = %BlockLabel
@onready var health: HBoxContainer = %Health


func update_stats(instance: CreatureInstance) -> void:
	if block_label == null or health == null:
		await ready  # Wait until node is fully added to tree
	if block_label == null or health == null:
		push_warning("StatsUI is not fully initialized")
		return

	block_label.text = str(instance.block)
	health.update_stats(instance)

	block.visible = instance.block > 0
	health.visible = instance.health > 0
