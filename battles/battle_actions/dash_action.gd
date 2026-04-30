class_name DashAction
extends BattleAction

enum Mode { TOWARD, AWAY, LEFT, RIGHT }

@export var mode: Mode = Mode.TOWARD
@export var speed: float = 200.0
@export var duration: float = 0.25
@export var min_distance: float = 0.0
@export var max_distance: float = INF


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	if target == null:
		return false
	var dist := user.global_position.distance_to(target.global_position)
	return dist >= min_distance and dist <= max_distance


func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null: return []
	var to_target: Vector2 = t.global_position - user.global_position
	if to_target == Vector2.ZERO:
		to_target = Vector2.RIGHT
	var dir: Vector2
	match mode:
		Mode.TOWARD: dir = to_target.normalized()
		Mode.AWAY:   dir = -to_target.normalized()
		Mode.LEFT:   dir = to_target.normalized().rotated(-PI / 2)
		Mode.RIGHT:  dir = to_target.normalized().rotated(PI / 2)
	return [{
		"id": &"dash",
		"data": {
			"direction": dir,
			"speed": speed,
			"duration": duration,
		}
	}]
