#creature_growth_stat.gd
class_name GrowthStat
extends Resource

enum Grade { E, D, C, B, A, S }
enum StatType { PWR, AGI, RES, MYS, FOC }

# Grade value used in the gain formula: (grade_val * 3) + 13 ± 2
const GRADE_VALUES := {
	Grade.E: 0,
	Grade.D: 1,
	Grade.C: 2,
	Grade.B: 3,
	Grade.A: 4,
	Grade.S: 5,
}

const MAX_POINTS := 3069
const COMBAT_MOD := 10

@export var grade: Grade = Grade.C
@export var points: int = 0
@export var lvl: int = 0
@export var pips: int = 0
@export var max_pips: int = 8


static func create(starting_grade: Grade = Grade.C, starting_points: int = 0) -> GrowthStat:
	var block := GrowthStat.new()
	block.grade = starting_grade
	block.points = starting_points
	return block


# Called when stat points are applied. Fills one pip; levels up when full.
func add_pip() -> void:
	pips += 1
	if pips >= max_pips:
		pips = 0
		lvl += 1
		points += calculate_gain()


func calculate_gain() -> int:
	var grade_val: int = GRADE_VALUES[grade]
	var base: int = (grade_val * 3) + 13
	return base + RNG.instance.randi_range(-2, 2)


func get_points() -> int:
	return points


func get_combat_mod() -> int:
	return lvl
