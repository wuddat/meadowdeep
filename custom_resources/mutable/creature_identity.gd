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
@export var evolution_stage: int = 0

# ── Moves ─────────────────────────────────────────────────────────────────────
@export_group("BattleActions")
@export var known_actions: Array[String] = []     # actions learned so far
@export var assigned_actions: Array[String] = []  # actions for next run

# ── Element Alignment ─────────────────────────────────────────────────────────────────

@export_group("Alignment")
@export var fire_alignment: float = 0.0
@export var water_alignment: float = 0.0
@export var earth_alignment: float = 0.0
@export var air_alignment: float = 0.0
@export var corruption_alignment: float = 0.0
@export_range(-1, 1, 0.05) var pwr_mys_alignment: float = 0.0
@export_range(-1, 1, 0.05) var agi_res_alignment: float = 0.0

# ── Bonds ─────────────────────────────────────────────────────────────────────
@export_group("Bonds")
@export_range(-1, 1, 0.05) var bond: float = 0.0
@export_range(-1, 1, 0.05) var bond_with_companion: float = 0.0
var creature_bonds: Dictionary = {}       # uid (String) → bond score (float)

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


# Weighted grade roll: C common, S/E rare. Shared by hatch + BaseCreature default setup.
func randomize_grades() -> void:
	PWR.grade = _roll_grade()
	AGI.grade = _roll_grade()
	RES.grade = _roll_grade()
	MYS.grade = _roll_grade()
	FOC.grade = _roll_grade()


func _roll_grade() -> GrowthStat.Grade:
	var roll := randi() % 100
	if roll < 5:    return GrowthStat.Grade.S
	elif roll < 15: return GrowthStat.Grade.A
	elif roll < 35: return GrowthStat.Grade.B
	elif roll < 65: return GrowthStat.Grade.C
	elif roll < 85: return GrowthStat.Grade.D
	else:           return GrowthStat.Grade.E


func increment_bond(val: float = 0.05) -> void:
	bond += val
