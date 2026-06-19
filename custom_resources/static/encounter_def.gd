#encounter_def.gd
class_name EncounterDef
extends Resource

@export_range(0, 5) var depth_tier: int
@export_range(0.0, 10.0) var weight: float

@export var spawn_layout: PackedScene   # Scene that defines enemy count and placement
@export var spawn_coords: Array[Vector2]
@export var is_boss: bool = false
@export var min_enemies: int = 1
@export var max_enemies: int = 1

@export_category("Creature Party")
@export var enemy_creature_party: Array[String] = []

@export_category("Rewards")
@export var gold_reward_min: int
@export var gold_reward_max: int

var accumulated_weight: float = 0.0

func start_encounter(_handler: EnemyHandler) -> void:
	push_error("[ENCOUNTERDEF]: start_encounter() MUST be overridden")

func on_enemy_fainted(_handler: EnemyHandler) -> void:
	pass

func is_complete(handler:EnemyHandler) -> bool:
	return handler.get_enemies().is_empty()


func roll_gold_reward() -> int:
	return RNG.instance.randi_range(gold_reward_min, gold_reward_max)


# Populates enemy_creature_party from creatures available at this depth tier.
func assign_creature_party() -> void:
	if not enemy_creature_party.is_empty():
		return
	enemy_creature_party = CreatureData.get_species_for_depth(depth_tier)
	RNG.array_shuffle(enemy_creature_party)
	enemy_creature_party = enemy_creature_party.slice(0, max_enemies)
