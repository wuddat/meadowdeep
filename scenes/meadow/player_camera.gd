extends Camera2D

@onready var player: CharacterBody2D = $"../PlayerModel"
@onready var camera_2d: Camera2D = $"."

@export var _camera_target: Node2D
var _transitioning_target: bool = false

const LERP_SPEED:float = 5.0
const ZOOM_DELTA:Vector2 = Vector2(0.1, 0.1)

func _ready() -> void:
	_establish_connections()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _transitioning_target:
		global_position = global_position.lerp(_camera_target.global_position, LERP_SPEED * delta)
		if global_position == _camera_target.global_position:
			_transitioning_target = false
	else:
		global_position = _camera_target.global_position

func _unhandled_input(input: InputEvent) -> void:
	if input.is_action_pressed("cancel") and not (_camera_target == player):
		Events.camera_target_requested.emit(player)
	if input.is_action_pressed("zoom_in"):
		zoom += ZOOM_DELTA
	if input.is_action_pressed("zoom_out"):
		zoom -= ZOOM_DELTA

func _on_shake_requested(strength: float = 25.0, duration:float = 0.15) -> void:
	Shaker.shake(self, strength, duration)

func _on_camera_target_requested(camera_target: Node) -> void:
	if camera_target != _camera_target:
		_transitioning_target = true
		_camera_target = camera_target

func _establish_connections() -> void:
	if not Events.shake_camera_requested.is_connected(_on_shake_requested):
		Events.shake_camera_requested.connect(_on_shake_requested)
	if not Events.camera_target_requested.is_connected(_on_camera_target_requested):
		Events.camera_target_requested.connect(_on_camera_target_requested)
