class_name AttackAction
extends BattleAction

@export var max_range: float = 32.0
@export var effects: Array[Effect]


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	return target != null and range_check(user, target, max_range)


func execute_action(user: BattleActor) -> void:
	var target := find_nearest_opponent(user)
	if target == null:
		return
	user.action_queue.enqueue(&"attack", {"target": target})


func run_effects(user: BattleActor, data: Dictionary) -> void:
	if not is_instance_valid(user):
		return

	var targets: Node = data.get("target")
	if not is_instance_valid(targets):
		Events.battle_action_complete.emit(user.stats.uid)
		return

	await EffectExecutor.run(effects, [targets], user)
