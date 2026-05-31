#effect.gd
class_name Effect
extends Resource

enum TargetType { USER, TARGETS}

@export var target_type: TargetType = TargetType.TARGETS
@export var sound: AudioStream

func execute(_targets: Array[Node], _user: Node = null) -> void:
	pass
