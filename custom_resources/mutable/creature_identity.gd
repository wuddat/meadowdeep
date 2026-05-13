#creature_identity.gd
# The portable identity record for a creature — everything about who it is,
# independent of combat. Safe to inspect in the meadow, habitat, biography,
# or during creature interactions without touching CreatureDef.
class_name CreatureIdentity
extends Resource

# ── Growth Stats ──────────────────────────────────────────────────────────────
@export_group("Growth Stats")
@export var PWR: GrowthStat
@export var AGI: GrowthStat
@export var RES: GrowthStat
@export var MYS: GrowthStat
@export var FOC: GrowthStat

# ── Identity ──────────────────────────────────────────────────────────────────
@export_group("Identity")
@export_range(-100,100,1) var courage: int = 0
@export var personality: Personality
@export var dominant_stat: String = ""   # "PWR" | "AGI" | "RES" | "MYS" | "FOC"
@export var evolution_stage: int = 0

# ── Moves ─────────────────────────────────────────────────────────────────────
@export_group("Moves")
@export var known_moves: Array[String] = []     # moves learned so far
@export var assigned_moves: Array[String] = []  # chosen for next run

# ── Element Alignment ─────────────────────────────────────────────────────────────────

@export_group("Alignment")
@export var fire_alignment: float = 0.0
@export var water_alignment: float = 0.0
@export var earth_alignment: float = 0.0
@export var air_alignment: float = 0.0
@export var corruption_alignment: float = 0.0

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
	PWR = GrowthStat.new()
	AGI = GrowthStat.new()
	RES = GrowthStat.new()
	MYS = GrowthStat.new()
	FOC = GrowthStat.new()
	personality = Personality.new()
	personality.create_personality()
