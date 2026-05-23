extends Node2D

@export var spawn_item: ItemDef

const MEADOW_WORLD_ITEM = preload("uid://d4g4hbpijemuw")

func _ready() -> void:
	if not child_order_changed.is_connected(_on_child_order_changed):
		child_order_changed.connect(_on_child_order_changed)
	_on_child_order_changed()

func _on_child_order_changed() -> void:
	if get_children().is_empty():
		var new_item: MeadowItemOneUse = MEADOW_WORLD_ITEM.instantiate()
		new_item.item_data = spawn_item
		add_child(new_item)
		new_item.global_position = global_position
