class_name WorldItemBase
extends Area2D

@export var item_data: ItemDef

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const CARRY_OFFSET := Vector2(0, -18)

var uid: String = ""
var is_carried: bool = false
var _carrier: Node2D = null


func _ready() -> void:
	var type_id := item_data.id if item_data and item_data.id != "" else "item"
	uid = str(RNG.instance.randi())
	add_to_group("items")
	if item_data:
		if item_data.art:
			sprite.texture = item_data.art
		if item_data.color:
			sprite.modulate = item_data.color
	_establish_connections()


func _process(_delta: float) -> void:
	if is_carried and _carrier:
		var carry_node:Node2D = _carrier.get("carry_position") if _carrier.get("carry_position") else _carrier.get("hold_pos")
		global_position = carry_node.global_position if carry_node else _carrier.global_position + CARRY_OFFSET


func pickup(carrier: Node2D) -> void:
	is_carried = true
	_carrier = carrier
	collision_shape.disabled = true


func drop() -> void:
	is_carried = false
	_carrier = null
	collision_shape.call_deferred("set_disabled", false)


func _establish_connections() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(_body: Node2D) -> void:
	pass


func _on_body_exited(_body: Node2D) -> void:
	pass


## Override in subclasses to add delivery-specific behavior.
func on_delivered(_creature: Node) -> void:
	pass
