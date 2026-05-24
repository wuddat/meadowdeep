extends Camera2D

@onready var player: CharacterBody2D = $"../PlayerModel"
@onready var camera_2d: Camera2D = $"."


func _ready() -> void:
	if not Events.shake_camera_requested.is_connected(_on_shake_requested):
		Events.shake_camera_requested.connect(_on_shake_requested)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = player.position

func _on_shake_requested(strength: float = 25.0, duration:float = 0.15) -> void:
	Shaker.shake(self, strength, duration)
