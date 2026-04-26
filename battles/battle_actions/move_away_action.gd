class_name MoveAwayAction
extends BattleAction

@export var desired_distance: float = 96.0
@export var max_duration: float = 1.5


func can_execute(user: BattleActor) -> bool:
	var threat := find_nearest_opponent(user)
	if threat == null:
		return false
	return user.global_position.distance_to(threat.global_position) < desired_distance


func execute_action(user: BattleActor) -> void:
	var threat := find_nearest_opponent(user)
	if threat == null:
		return
	var movement := MovementEffect.new()
	movement.target = threat
	movement.mode = "away"
	movement.stop_distance = desired_distance
	movement.max_duration = max_duration
	EffectExecutor.run([movement], [user])
