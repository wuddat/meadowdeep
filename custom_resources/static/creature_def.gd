#creature_stats.gd
# The battle-relevant creature resource. Extends Stats for combat mechanics
# and holds a CreatureIdentity reference for the full identity layer.
class_name CreatureDef
extends Stats


# ── Egg Origin ────────────────────────────────────────────────────────────────
@export_group("Egg Origin")
@export var egg_rarity: String = ""     # "common" | "uncommon" | "rare" | "ancient"
@export var egg_depth_found: int = 0    # Ruin floor the egg was found on

# ── Party ─────────────────────────────────────────────────────────────────────
@export_group("Party")
@export var is_companion: bool = false
@export var is_battling: bool = false
@export var leveled_up_in_battle: bool = false

# ── Moves ─────────────────────────────────────────────────────────────────────
@export var known_moves: Array[String] = []     # moves learned so far
@export var assigned_moves: Array[String] = []  # chosen for next run

# ── Identity Record ───────────────────────────────────────────────────────────
@export_group("Identity Record")
@export var stat_block: CreatureIdentity


func _init() -> void:
	stat_block = CreatureIdentity.new()



# ── Combat ────────────────────────────────────────────────────────────────────
func get_action_interval() -> float:
	var agi_points: float = stat_block.AGI.points if stat_block else 5.0
	return lerp(1.0, 0.25, agi_points / 10.0)
