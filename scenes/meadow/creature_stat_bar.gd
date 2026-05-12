class_name CreatureStatBar
extends Control

@onready var stat_name: Label = %StatName
@onready var lvl: Label = %Lvl
@onready var pill_box: HBoxContainer = %PillBox
@onready var stat_grade: Label = %StatGrade
@onready var score: Label = %Score

const PILL_EMPTY = preload("uid://cg4v0q208cksl")
const PILL_FULL = preload("uid://d3wnng60mj0x0")


func setup(block: GrowthStat, label: String) -> void:
	stat_name.text = label
	stat_grade.text = GrowthStat.Grade.keys()[block.grade]
	lvl.text = "LV: %d" % block.lvl
	score.text = str(block.points)

	for child in pill_box.get_children():
		child.queue_free()

	for i in block.max_pips:
		var p := TextureRect.new()
		p.texture = PILL_FULL if i < block.pips else PILL_EMPTY
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pill_box.add_child(p)
