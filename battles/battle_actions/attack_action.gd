class_name AttackAction
extends BattleAction

@export var max_range: float = 32.0
@export var hit_effects: Array[Effect]


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	return target != null and range_check(user, target, max_range)


func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null: return []
	return [{"id": &"strike", "data": {"target": t, "effects": hit_effects} }]
