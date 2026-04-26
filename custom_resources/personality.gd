class_name Personality
extends Resource

enum Type { NEUTRAL, BRAVE, TIMID,}


@export var courage = 0
@export var type: Type = Type.NEUTRAL

func get_personality_value(spectrum: String) -> int:
	match spectrum:
		"courage":
			return courage
		_:
			return 0


func create_personality() -> void:
	courage = _roll()
	if courage < -33:
		type = Type.TIMID
	elif courage > 33:
		type = Type.BRAVE
	else: type = Type.NEUTRAL


func _roll() -> int:
	var roll = randi_range(-100,100)
	return roll
