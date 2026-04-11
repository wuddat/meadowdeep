#stat_block.gd
class_name StatBlock
extends Resource

# SA2-inspired stat grades — determines how efficiently points convert to effective value.
# TODO: Grade multipliers are placeholders. Tune once combat feel is testable.
enum Grade { E, D, C, B, A, S }

const GRADE_MULTIPLIERS := {
	Grade.E: 0.5,
	Grade.D: 0.75,
	Grade.C: 1.0,
	Grade.B: 1.25,
	Grade.A: 1.5,
	Grade.S: 2.0,
}

@export var grade: Grade = Grade.C
@export var points: int = 0


func get_effective_value() -> int:
	return int(points * GRADE_MULTIPLIERS[grade])


static func create(starting_grade: Grade = Grade.C, starting_points: int = 0) -> StatBlock:
	var block := StatBlock.new()
	block.grade = starting_grade
	block.points = starting_points
	return block
