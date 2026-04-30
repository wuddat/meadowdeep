class_name MoveToAction
extends BattleAction

enum Mode {TOWARD, AWAY, ORBITL, ORBITR}

@export var max_duration: float = 0
@export var stop_distance: float = 32.0
@export var mode: Mode = Mode.TOWARD


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	if target == null:
		return false
	return user.global_position.distance_to(target.global_position) > stop_distance


func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null: return []
	var data:={"target": t, "mode": mode, "stop_distance": stop_distance, }
	if max_duration > 0.0:
		data["duration"] = max_duration
	return [{"id": &"move", "data": data}]
