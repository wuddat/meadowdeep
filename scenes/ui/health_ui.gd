class_name HealthUI 
extends HBoxContainer

@export var show_max_hp: bool
@export var bar_type: bool


@onready var health_label: Label = %HealthLabel
@onready var max_health_label: Label = %MaxHealthLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var health_image: TextureRect = %HealthImage


func update_stats(instance: CreatureInstance) -> void:
	var max_hp: int = instance.definition.max_health if instance.definition else 1
	health_label.text = str(instance.health)
	max_health_label.text = "/%s" % str(max_hp)

	health_label.visible = !bar_type
	max_health_label.visible = !bar_type and show_max_hp
	progress_bar.visible = bar_type

	progress_bar.max_value = max_hp
	progress_bar.value = instance.health
