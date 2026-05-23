class_name EncounterPool
extends Resource

@export var pool: Array[EncounterDef]

var total_weights_by_tier := [0.0, 0.0, 0.0]


func _get_all_battles_for_tier(tier: int, is_boss: bool) -> Array[EncounterDef]:
	return pool.filter(
		func(battle: EncounterDef):
			return battle.depth_tier == tier and battle.is_boss == is_boss
	)


func _get_random_battle_for_tier(tier: int, is_boss: bool) -> EncounterDef:
	var filtered := _get_all_battles_for_tier(tier, is_boss)
	if filtered.is_empty():
		push_warning("EncounterPool: no %s battles for tier %d" % ["boss" if is_boss else "wild", tier])
		return null

	var selected_battle: EncounterDef = RNG.array_pick_random(filtered).duplicate()
	selected_battle.assign_creature_party()
	return selected_battle


func get_wild_battle_for_tier(tier: int) -> EncounterDef:
	return _get_random_battle_for_tier(tier, false)


func get_boss_battle_for_tier(tier: int) -> EncounterDef:
	return _get_random_battle_for_tier(tier, true)


func _setup_weight_for_tier(tier: int) -> void:
	var battles := pool.filter(func(b: EncounterDef): return b.depth_tier == tier)
	total_weights_by_tier[tier] = 0.0

	for battle: EncounterDef in battles:
		total_weights_by_tier[tier] += battle.weight
		battle.accumulated_weight = total_weights_by_tier[tier]


func setup() -> void:
	for i in 3:
		_setup_weight_for_tier(i)
