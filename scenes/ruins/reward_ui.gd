class_name RewardUI
extends Control


@export var creature: CreatureBattleUnit
@export var reward_array: Array[RewardDef]

@onready var reward_container: HBoxContainer = %RewardContainer


const REWARD_CHOICE = preload("uid://d2yhbcx0kroha")

func _ready() -> void:
	_establish_connections()
	_kill_children()

func populate_rewards() -> void:
	for reward in reward_array:
		var new_choice = REWARD_CHOICE.instantiate() as RewardChoice
		reward_container.add_child(new_choice)
		if not new_choice.is_node_ready():
			await new_choice.ready
		new_choice.reward = reward
		


func _on_reward_ui_requested() -> void:
	populate_rewards()
	show()

func _on_reward_ui_dismissed() -> void:
	hide()
	_kill_children()


func _kill_children() -> void:
	for child in reward_container.get_children():
		child.queue_free()


func _establish_connections() -> void:
	Events.reward_ui_requested.connect(_on_reward_ui_requested)
	Events.reward_ui_dismissed.connect(_on_reward_ui_dismissed)
