class_name Brain
extends Node

var _actor: BattleActor
var _personality: Personality


func _ready() -> void:
	_actor = get_parent() as BattleActor
	if _actor == null:
		push_error("Brain must be a child of a BattleActor")
	_personality = _actor.get("stats").stat_block.personality if _actor.get("stats") else null


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

	var chosen := _pick_weighted(pool)
	return chosen


func _evaluate_intent() -> BattleAction.Intent:
	if not _personality:
		return BattleAction.Intent.AGGRESSIVE if RNG.instance.randi_range(0, 1) == 0 \
			else BattleAction.Intent.DEFENSIVE
	var aggression_score := _calc_aggression_score()
	var intent := BattleAction.Intent.AGGRESSIVE if RNG.instance.randf() < aggression_score \
		else BattleAction.Intent.DEFENSIVE
	return intent
	

func _calc_aggression_score() -> float:
	var base := _normalize_trait(_personality.courage)
	var score := base  + _get_personality_bias()
	return clamp(score, 0.0, 1.0)

func _normalize_trait(creature_trait: int) -> float:
	return (creature_trait + 100.0)/200.0

func _get_personality_bias() -> float:
	match _personality.type:
		Personality.Type.BRAVE:
			return 0.15
		Personality.Type.TIMID:
			return -0.15
		_:
			return 0


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
