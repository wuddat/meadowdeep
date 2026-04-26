class_name AttackAction
extends BattleAction

@export var max_range: float = 32.0


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	return target != null and range_check(user, target, max_range)


func execute_action(user: BattleActor) -> void:
	var target := find_nearest_opponent(user)
	if target == null:
		return
	user.action_queue.enqueue(&"attack", {"target": target})
