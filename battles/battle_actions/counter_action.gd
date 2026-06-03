class_name CounterAction
extends BattleAction

@export var max_duration: float = 2.0
@export var threat_range: float = 48.0
@export var animation_string: String = "counter"


func can_execute(user: BattleActor) -> bool:
	# Only drop into a counter stance when a threat is in striking range.
	var t := find_nearest_opponent(user)
	return t != null and range_check(user, t, threat_range)


func build_steps(_user: BattleActor) -> Array[Dictionary]:
	return [{
		"id": &"counter",
		"data": {
			"duration": max_duration,
			"animation_string": animation_string,
		},
	}]
