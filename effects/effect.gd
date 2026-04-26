#effect.gd
class_name Effect
extends Resource

@export var sound: AudioStream
@export var amount := 0

func execute(_targets: Array[Node]) -> void:
	pass
