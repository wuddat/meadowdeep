#creature_stat_block.gd
# The portable identity record for a creature — everything about who it is,
# independent of combat. Safe to inspect in the meadow, habitat, biography,
# or during creature interactions without touching CreatureStats.
class_name CreatureStatBlock
extends Resource

# ── Growth Stats ──────────────────────────────────────────────────────────────
@export_group("Growth Stats")
@export var PWR: StatBlock
@export var AGI: StatBlock
@export var RES: StatBlock
@export var MYS: StatBlock
@export var FOC: StatBlock

# ── Identity ──────────────────────────────────────────────────────────────────
@export_group("Identity")
@export_range(-100,100,1) var courage: int = 0
@export var personality: Personality
@export var dominant_stat: String = ""   # "PWR" | "AGI" | "RES" | "MYS" | "FOC"
@export var evolution_stage: int = 0

# ── Alignment ─────────────────────────────────────────────────────────────────
# TODO: Placeholder axes — ranges and meaning to be designed.
# wild_bonded: -1.0 (fully wild) to 1.0 (fully bonded)
# feral_MYS: -1.0 (fully feral) to 1.0 (fully MYS)
@export_group("Alignment")
@export var wild_bonded_alignment: float = 0.0
@export var feral_MYS_alignment: float = 0.0

# ── Bonds ─────────────────────────────────────────────────────────────────────
@export_group("Bonds")
@export var bond_with_player: float = 0.0      # 0.0 – 100.0
@export var bond_with_companion: float = 0.0   # 0.0 – 100.0
var bonds_with_creatures: Dictionary = {}       # uid (String) → bond score (float)

# ── History ───────────────────────────────────────────────────────────────────
@export_group("History")
@export var age: int = 0
@export var reincarnation_count: int = 0


# ── Item History ──────────────────────────────────────────────────────────────
@export_group("Item History")
@export var total_items_received: int = 0
@export var total_meals_eaten: int = 0
# item_id (String) → total times received (int)
var item_affinity: Dictionary = {}


func _init() -> void:
	PWR = StatBlock.new()
	AGI = StatBlock.new()
	RES = StatBlock.new()
	MYS = StatBlock.new()
	FOC = StatBlock.new()
	personality = Personality.new()
	personality.create_personality()
