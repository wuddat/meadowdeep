class_name WorldItemBase
extends Area2D

@export var item_data: ItemDef

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const CARRY_OFFSET := Vector2(0, -18)
const TOSS_DISTANCE := 70.0
const TOSS_ARC_HEIGHT := 30.0
const TOSS_DURATION := 0.35

var uid: String = ""
var is_carried: bool = false
var _carrier: Node2D = null
var _old_z_index: int
var _tween: Tween

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
		if _tween.is_running():
			return
		var carry_node:Node2D = _get_carry_node()
		global_position = carry_node.global_position if carry_node else _carrier.global_position + CARRY_OFFSET


func pickup(carrier: Node2D) -> void:
	is_carried = true
	_carrier = carrier
	collision_shape.disabled = true
	if not _old_z_index:
		_old_z_index = self.z_index
	var carrier_z: int = carrier.z_index + 1
	self.z_index = carrier_z
	var carry_node:Node2D = _get_carry_node()
	var target_pos: Vector2 = carry_node.global_position if carry_node else _carrier.global_position + CARRY_OFFSET
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property( self, "global_position", target_pos, (0.1) )


func drop() -> void:
	is_carried = false
	_carrier = null
	collision_shape.call_deferred("set_disabled", false)
	if _old_z_index:
		self.z_index = _old_z_index



func toss() -> void:
	# Read facing off the creature before we drop the carrier ref.
	var facing:int = 1
	var creature_node: Node2D = _carrier.get("creature_node") if _carrier else null
	if creature_node:
		facing = 1 if creature_node.scale.x < 0 else -1

	drop()

	var start_pos:Vector2 = global_position
	var end_pos:Vector2 = start_pos + Vector2(TOSS_DISTANCE * facing, 0.0)
	_tween = create_tween()
	_tween.tween_method(
		func(t: float) -> void:
			var pos := start_pos.lerp(end_pos, t)
			pos.y -= TOSS_ARC_HEIGHT * sin(t * PI)  # 0 at ends, peak at midpoint
			global_position = pos,
		0.0, 1.0, TOSS_DURATION)
	

func _get_carry_node() -> Node2D:
	var carry_node: Node2D = _carrier.get("carry_position") if _carrier.get("carry_position") else _carrier.get("hold_pos")
	return carry_node

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
