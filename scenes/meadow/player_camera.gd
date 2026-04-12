extends Camera2D

@onready var player: CharacterBody2D = $"../PlayerModel"
@onready var camera_2d: Camera2D = $"."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = player.position
