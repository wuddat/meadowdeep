class_name MoveTowardAction
extends BattleAction

@export var stop_distance: float = 32.0


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	if target == null:
		return false
	return user.global_position.distance_to(target.global_position) > stop_distance


func execute_action(user: BattleActor) -> void:
	var target := find_nearest_opponent(user)
	if target == null:
		return
	user.action_queue.enqueue(&"move", {
		"target": target,
		"stop_distance": stop_distance,
		"mode": "toward",
	})
