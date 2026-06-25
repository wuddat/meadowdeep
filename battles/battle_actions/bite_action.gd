class_name BiteAction
extends BattleAction


@export var animated_hitbox: PackedScene
@export var approach_distance: float = 28.0  # how close before the chomp
@export var max_range: float = 140.0         # can start the approach from here
@export var bite_duration: float = 0.5       # commit window ≈ chomp anim length
@export var hit_effects: Array[Effect] = []


func can_execute(user: BattleActor) -> bool:
	var t := find_nearest_opponent(user)
	return t != null and range_check(user, t, max_range)


func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null:
		return []
	return [
		{"id": &"move", "data": {
			"target": t,
			"mode": MoveToAction.Mode.TOWARD,
			"stop_distance": approach_distance,
		}},
		{"id": &"bite", "data": {
			"target": t,
			"animated_hitbox": animated_hitbox,
			"effects": hit_effects,
			"timer": bite_duration,
		}},
	]
