class_name CreatureFoodItem
extends Area2D

@export var food_data: CreatureFood

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const CARRY_OFFSET := Vector2(0, -10)

var is_carried := false
var _carrier: Node2D = null


func _ready() -> void:
	add_to_group("food")
	if food_data and food_data.art:
		sprite.texture = food_data.art
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if is_carried and _carrier:
		global_position = _carrier.global_position + CARRY_OFFSET


func pickup(carrier: Node2D) -> void:
	is_carried = true
	_carrier = carrier
	collision_shape.disabled = true


func drop() -> void:
	is_carried = false
	_carrier = null
	collision_shape.call_deferred("set_disabled", false)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_food = self


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.get("nearby_food") == self:
		body.nearby_food = null
