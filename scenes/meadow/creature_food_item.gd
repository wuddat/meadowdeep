class_name CreatureFoodItem
extends WorldItemBase

@export var stages: int = 5

var _max_stages: int = 0
var being_eaten: bool = false


func _ready() -> void:
	super._ready()
	_max_stages = stages
	add_to_group("food")


func decrement_stage() -> void:
	if stages <= 0:
		self.queue_free()
		return
	stages -= 1
	scale = Vector2.ONE * (float(stages) / float(_max_stages))


func start_eating() -> void:
	if stages == 0:
		return
	being_eaten = true


func on_delivered(creature: Node) -> void:
	var handler = creature.get("creature_stat_handler")
	if handler and handler.has_method("apply_item"):
		handler.apply_item(item_data)
		Events.item_used.emit(item_data, creature)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_food = self


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.get("nearby_food") == self:
		body.nearby_food = null
