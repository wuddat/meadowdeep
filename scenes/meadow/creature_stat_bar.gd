class_name CreatureStatBar
extends Control

@export var max_pills: int = 8

@onready var stat_name: Label = %StatName
@onready var lvl: Label = %Lvl
@onready var pill_box: HBoxContainer = %PillBox

const PILL_EMPTY = preload("uid://cg4v0q208cksl")
const PILL_FULL = preload("uid://d3wnng60mj0x0")


func setup(block: StatBlock, label: String) -> void:
	stat_name.text = label
	lvl.text = StatBlock.Grade.keys()[block.grade]
	for child in pill_box.get_children():
		child.queue_free()
	var filled := mini(block.points, max_pills)
	for i in filled:
		var p := TextureRect.new()
		p.texture = PILL_FULL
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pill_box.add_child(p)
	for i in max_pills - filled:
		var p := TextureRect.new()
		p.texture = PILL_EMPTY
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pill_box.add_child(p)
		
