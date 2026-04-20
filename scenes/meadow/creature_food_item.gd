class_name CreatureFoodItem
extends WorldItemBase

@export var food_data: CreatureFood

@export var stages: int = 5

var _total_stages: int = 0


func _ready() -> void:
	item_data = food_data
	super._ready()
	add_to_group("food")


func decrement_stage() -> void:
	if stages <= 0 or _total_stages <= 0:
		return
	stages -= 1
	scale = Vector2.ONE * (float(stages) / float(_total_stages))


func start_eating() -> void:
	being_eaten = true
	if _total_stages == 0:
		_total_stages = stages


func on_delivered(creature: Node) -> void:
	super.on_delivered(creature)
