class_name BattleStatsPool
extends Resource

@export var pool: Array[BattleStats]

var total_weights_by_tier := [0.0, 0.0, 0.0]


func _get_all_battles_for_tier_and_type(tier: int, type: String) -> Array[BattleStats]:
	return pool.filter(
		func(battle: BattleStats):
			return battle.depth_tier == tier and battle.encounter_type == type
	)


func get_random_battle_for_tier_and_type(tier: int, type: String) -> BattleStats:
	var filtered := _get_all_battles_for_tier_and_type(tier, type)
	if filtered.is_empty():
		push_warning("BattleStatsPool: no battles for tier %d type %s" % [tier, type])
		return null

	var selected_battle: BattleStats = RNG.array_pick_random(filtered).duplicate()
	selected_battle.assign_creature_party()
	return selected_battle


func get_wild_battle_for_tier(tier: int) -> BattleStats:
	return get_random_battle_for_tier_and_type(tier, "Wild")


func get_boss_battle_for_tier(tier: int) -> BattleStats:
	return get_random_battle_for_tier_and_type(tier, "Boss")


func _setup_weight_for_tier(tier: int) -> void:
	var battles := pool.filter(func(b: BattleStats): return b.depth_tier == tier)
	total_weights_by_tier[tier] = 0.0

	for battle: BattleStats in battles:
		total_weights_by_tier[tier] += battle.weight
		battle.accumulated_weight = total_weights_by_tier[tier]


func setup() -> void:
	for i in 3:
		_setup_weight_for_tier(i)
