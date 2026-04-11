#creature_stats.gd
# The battle-relevant creature resource. Extends Stats for combat mechanics
# and holds a CreatureStatBlock reference for the full identity layer.
class_name CreatureStats
extends Stats

# ── Identity Surface ──────────────────────────────────────────────────────────
@export_group("Identity")
@export var species_id: String
@export var creature_name: String
@export var element_type: String        # e.g. "verdant", "ember" — matches Card.damage_type

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
@export_group("Moves")
@export var move_ids: Array[String] = []

# ── Progression ───────────────────────────────────────────────────────────────
@export_group("Progression")
@export var level: int = 1
@export var current_exp: int = 0
@export var evolves_to: String = ""
@export var evolution_level: int = 101

# ── Identity Record ───────────────────────────────────────────────────────────
@export_group("Identity Record")
@export var stat_block: CreatureStatBlock


func _init() -> void:
	stat_block = CreatureStatBlock.new()


# ── Progression ───────────────────────────────────────────────────────────────

func get_xp_for_next_level(lvl: int) -> int:
	return 10 + max_health * 1.2 * lvl


func try_gain_exp_from(enemy: Enemy) -> bool:
	var gained_exp := enemy.stats.max_health * 2
	current_exp += gained_exp
	var did_level := false

	if current_exp >= get_xp_for_next_level(level):
		if level < 100:
			level += 1
			max_health += level
			health += level
			did_level = true
	return did_level


# ── Evolution ─────────────────────────────────────────────────────────────────

func get_evolved_species_id() -> String:
	return evolves_to


func evolve_to(new_species_id: String) -> void:
	# TODO: Replace with CreatureData.get_creature_data() once data loader is ported.
	var data := CreatureData.get_creature_data(new_species_id)
	if data.is_empty():
		push_error("Missing evolution data for: " + new_species_id)
		return

	species_id = new_species_id
	art = load(data.get("sprite_path", "res://art/dottedline.png"))
	icon = load(data.get("icon_path", "res://art/dottedline.png"))
	max_health += 10
	health = max_health
	move_ids = Utils.to_typed_string_array(data.get("move_ids", []))
	element_type = data.get("element_type", element_type)
	evolves_to = data.get("evolves_to", "")
	evolution_level = data.get("evolution_level", 101)
	stat_block.evolution_stage += 1


# ── Card Helpers ──────────────────────────────────────────────────────────────

func get_draft_cards_from_element() -> Array[String]:
	return MoveData.element_to_moves.get(element_type, [])


# ── Factory ───────────────────────────────────────────────────────────────────

static func from_enemy_stats(stats: CreatureStats) -> CreatureStats:
	var new_stats := CreatureStats.new()
	new_stats.species_id = stats.species_id
	new_stats.move_ids = stats.move_ids.duplicate()
	new_stats.max_health = stats.max_health
	new_stats.health = stats.max_health
	new_stats.art = stats.art
	new_stats.icon = stats.icon
	new_stats.element_type = stats.element_type
	return new_stats
