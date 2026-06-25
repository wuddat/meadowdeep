class_name TackleAction
extends BattleAction

@export var speed: float = 160.0
@export var max_duration: float = 0.35
@export var min_range: float = 0.0
@export var max_range: float = 120.0
@export var hit_effects: Array[Effect] = []
@export var animation_string: String = ""
@export var indicate_duration: float = 0.5  # wind-up beat; lane is painted during it
@export var lane_width: float = 24.0

func can_execute(user: BattleActor) -> bool:
	var t := find_nearest_opponent(user)
	if t == null: return false
	var d := user.global_position.distance_to(t.global_position)
	return d >= min_range and d <= max_range

func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null: return []
	var dir: Vector2 = (t.global_position - user.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	# Every tackle indicates first: paint the lane, hold, then charge it.
	return [
		{"id": &"indicate", "data": {
			"direction": dir,
			"length": speed * max_duration,
			"width": lane_width,
			"timer": indicate_duration,
			"indicator_duration": indicate_duration + max_duration,
		}},
		{"id": &"tackle", "data": {
			"direction": dir,
			"speed": speed,
			"duration": max_duration,
			"effects": hit_effects,
			"animation_string": animation_string,
		}},
	]
