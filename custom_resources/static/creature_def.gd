# creature_def.gd
# Static species definition. Immutable per-species data shared across all
# instances. Loaded from JSON at boot. Not saved — already on disk.
class_name CreatureDef
extends Resource

# ── Identity ──────────────────────────────────────────────────────────────────
@export_group("Identity")
@export var species_id: String
@export var creature_name: String
@export var element_type: String        # e.g. "verdant", "ember"

# ── Combat baseline ───────────────────────────────────────────────────────────
@export_group("Combat")
@export var max_health: int = 1

# ── Visuals ───────────────────────────────────────────────────────────────────
@export_group("Visuals")
@export var frames: SpriteFrames
@export var art: Texture
@export var icon: Texture

# ── Moves ─────────────────────────────────────────────────────────────────────
@export_group("Moves")
@export var move_ids: Array[String] = []        # learnable pool
@export var starting_moves: Array[String] = []  # moves at creation

# ── Egg Origin ────────────────────────────────────────────────────────────────
@export_group("Egg Origin")
@export var egg_rarity: String = ""     # "common" | "uncommon" | "rare" | "ancient"
@export var egg_depth_found: int = 0    # Ruin floor the egg was found on
@export var is_companion: bool = false

# ── Evolution ─────────────────────────────────────────────────────────────────
@export_group("Evolution")
@export var evolves_to: String = ""
@export var evolution_level: int = 101


func get_action_interval(identity: CreatureIdentity) -> float:
	var agi_points: float = identity.AGI.points if identity else 5.0
	return lerp(1.0, 0.25, agi_points / 10.0)
