class_name RewardChoice
extends Panel

@onready var reward_title: Label = $MarginContainer/VBoxContainer/RewardTitle
@onready var reward_icon: TextureRect = $MarginContainer/VBoxContainer/RewardIcon
@onready var reward_description: RichTextLabel = $MarginContainer/VBoxContainer/RewardDescription
@onready var select_button: Button = $MarginContainer/VBoxContainer/SelectButton


@export var reward: RewardDef

func setup() -> void:
	reward_title.text = reward.title
	reward_icon.texture = reward.icon
	reward_description.text = reward.description
	


func _on_select_button_button_up() -> void:
	Events.reward_selected.emit(reward)
	Events.reward_ui_dismissed.emit()
