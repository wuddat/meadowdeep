class_name AttackAction
extends BattleAction

@export var max_range: float = 32.0
@export var hit_delay: float = 0.15
# Secondary effects applied after damage (status, etc.). Damage is always stat-derived.
@export var effects: Array[Effect]


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	return target != null and range_check(user, target, max_range)


func execute_action(user: BattleActor) -> void:
	var target := find_nearest_opponent(user)
	if target == null:
		return
	user.action_queue.enqueue(&"attack", {"target": target})


func run_effects_async(user: BattleActor, data: Dictionary) -> void:
	if user is CreatureBattleUnit:
		Events.creature_action_started.emit(user)

	await user.get_tree().create_timer(hit_delay, false).timeout

	if not is_instance_valid(user) or ("stats" in user and user.stats and user.stats.health <= 0):
		return

	var target: Node = data.get("target")
	if is_instance_valid(target) and target.has_method("take_damage"):
		var dmg_effect := DamageEffect.new()
		dmg_effect.amount = _calculate_damage(user)
		dmg_effect.execute([target])
		EffectExecutor.run(effects, [target])

	if user is CreatureBattleUnit:
		Events.creature_action_completed.emit(user)

	user.action_queue.done()


func _calculate_damage(user: BattleActor) -> int:
	if "stats" in user and user.stats and user.stats.stat_block:
		return max(3, user.stats.stat_block.PWR.points)
	return 3
