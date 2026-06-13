class_name CreatureFoodItem
extends WorldItemBase

@export var stages: int = 5

var edible: bool = true
var _max_stages: int = maxi(stages, 1)
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
	var old_scale: Vector2 = Vector2.ONE * (float(stages) / float(_max_stages))
	var new_scale: Vector2 = Vector2.ONE
	new_scale.x = maxf(0.5, old_scale.x)
	new_scale.y = maxf(0.5, old_scale.y)
	scale = new_scale


func start_being_eaten() -> void:
	if stages == 0 or being_eaten == true:
		return
	being_eaten = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_food = self


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.get("nearby_food") == self:
		body.nearby_food = null
