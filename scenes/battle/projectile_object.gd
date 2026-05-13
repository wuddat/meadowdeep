class_name ProjectileObject
extends RigidBody2D

@export var art: CompressedTexture2D
@export var effects: Array[Effect]
@export var duration: float = 0.0
@export var max_distance: float = 0.0
@export var speed: float = 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var _source: Node
var _target: Node
var _direction: Vector2 = Vector2.RIGHT
var _start_position: Vector2
var _elapsed: float = 0.0


func _ready() -> void:
	gravity_scale = 0.0
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	if art:
		sprite_2d.texture = art


# Spawner calls after add_child so direction + position are live.
func setup(source: Node, target: Node) -> void:
	_source = source
	_target = target
	if is_instance_valid(source) and source.has_method("get") and source.get("projectile_spawn"):
		global_position = source.projectile_spawn.global_position
	_start_position = global_position
	# Direction is from spawn position (which mirrors with creature facing),
	# NOT from source root — otherwise off-axis when creature faces left.
	if is_instance_valid(target):
		_direction = (target.global_position - global_position).normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	linear_velocity = _direction * speed
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if duration > 0.0 and _elapsed >= duration:
		queue_free()
		return
	if max_distance > 0.0 and global_position.distance_to(_start_position) >= max_distance:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == _source:
		return
	if "instance" in body and body.instance and not effects.is_empty():
		EffectExecutor.run(effects, [body], _source)
	queue_free()
