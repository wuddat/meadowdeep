class_name DodgeAction
extends BattleAction

@export var trigger_distance: float = 56.0
@export var dash_effect: DashEffect
@export var dodge_effect: DodgeEffect


func can_execute(user: BattleActor) -> bool:
	var threat := find_nearest_opponent(user)
	return threat != null and range_check(user, threat, trigger_distance)


func execute_action(user: BattleActor) -> void:
	EffectExecutor.run([dash_effect, dodge_effect], [user])
