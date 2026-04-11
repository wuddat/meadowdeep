#battle_stats.gd
class_name BattleStats
extends Resource

@export_enum("Wild", "Boss") var encounter_type := "Wild"

@export_range(0, 2) var depth_tier: int
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var enemies: PackedScene   # Scene that defines enemy count and placement
@export var enemy_amt: int

@export_category("Creature Party")
@export var enemy_creature_party: Array[String] = []

var accumulated_weight: float = 0.0

var is_boss_battle: bool:
	get:
		return encounter_type == "Boss"


func roll_gold_reward() -> int:
	return RNG.instance.randi_range(gold_reward_min, gold_reward_max)


# Populates enemy_creature_party from creatures available at this depth tier.
func assign_creature_party() -> void:
	if not enemy_creature_party.is_empty():
		return
	enemy_creature_party = CreatureData.get_species_for_depth(depth_tier)
	RNG.array_shuffle(enemy_creature_party)
	enemy_creature_party = enemy_creature_party.slice(0, enemy_amt)
