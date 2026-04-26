class_name Brain
extends Node

var _actor: BattleActor


func _ready() -> void:
	_actor = get_parent() as BattleActor
	if _actor == null:
		push_error("Brain must be a child of a BattleActor")


func select_action() -> BattleAction:
	var intent := _evaluate_intent()

	var pool: Array = _actor.battle_action_list.filter(
		func(a: BattleAction) -> bool:
			return a.intent == intent and a.can_execute(_actor)
	)

	if pool.is_empty():
		pool = _actor.battle_action_list.filter(
			func(a: BattleAction) -> bool: return a.can_execute(_actor)
		)

	return _pick_weighted(pool)


func _evaluate_intent() -> BattleAction.Intent:
	return BattleAction.Intent.AGGRESSIVE if RNG.instance.randi_range(0, 100) >= 50 \
		else BattleAction.Intent.DEFENSIVE


func _pick_weighted(pool: Array) -> BattleAction:
	if pool.is_empty():
		return null
	var total := 0.0
	for action: BattleAction in pool:
		total += action.chance_weight
	if total <= 0.0:
		return pool[0]
	var roll := RNG.instance.randf_range(0.0, total)
	var running := 0.0
	for action: BattleAction in pool:
		running += action.chance_weight
		if running > roll:
			return action
	return pool.back()
