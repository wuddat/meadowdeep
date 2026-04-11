#creature_stat_block.gd
# The portable identity record for a creature — everything about who it is,
# independent of combat. Safe to inspect in the meadow, habitat, biography,
# or during creature interactions without touching CreatureStats.
class_name CreatureStatBlock
extends Resource

enum Personality {
	NEUTRAL,
	BRAVE,
	TIMID,
	GENTLE,
	FIERCE,
	CURIOUS,
	STOIC,
	PLAYFUL,
	ALOOF,
}

# ── Growth Stats ──────────────────────────────────────────────────────────────
@export_group("Growth Stats")
@export var power: StatBlock
@export var agility: StatBlock
@export var resilience: StatBlock
@export var mystic: StatBlock
@export var focus: StatBlock

# ── Identity ──────────────────────────────────────────────────────────────────
@export_group("Identity")
@export var personality: Personality = Personality.NEUTRAL
@export var dominant_stat: String = ""   # "power" | "agility" | "resilience" | "mystic" | "focus"
@export var evolution_stage: int = 0

# ── Alignment ─────────────────────────────────────────────────────────────────
# TODO: Placeholder axes — ranges and meaning to be designed.
# wild_bonded: -1.0 (fully wild) to 1.0 (fully bonded)
# feral_mystic: -1.0 (fully feral) to 1.0 (fully mystic)
@export_group("Alignment")
@export var wild_bonded_alignment: float = 0.0
@export var feral_mystic_alignment: float = 0.0

# ── Bonds ─────────────────────────────────────────────────────────────────────
@export_group("Bonds")
@export var bond_with_player: float = 0.0      # 0.0 – 100.0
@export var bond_with_companion: float = 0.0   # 0.0 – 100.0
var bonds_with_creatures: Dictionary = {}       # uid (String) → bond score (float)

# ── History ───────────────────────────────────────────────────────────────────
@export_group("History")
@export var age: int = 0
@export var reincarnation_count: int = 0


func _init() -> void:
	power = StatBlock.new()
	agility = StatBlock.new()
	resilience = StatBlock.new()
	mystic = StatBlock.new()
	focus = StatBlock.new()
