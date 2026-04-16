class_name CreatureStatView
extends Control

@onready var creature_name_label: Label = $bg/VBoxContainer/CreatureName
@onready var personality_label: Label   = $bg/VBoxContainer/Personality
@onready var pwr_val: Label   = $bg/VBoxContainer/Panel/VBoxContainer/Stat/PWRval
@onready var pwr_grade: Label = $bg/VBoxContainer/Panel/VBoxContainer/Stat/PWRgrade
@onready var agi_val: Label   = $bg/VBoxContainer/Panel/VBoxContainer/Stat2/AGIval
@onready var agi_grade: Label = $bg/VBoxContainer/Panel/VBoxContainer/Stat2/AGIgrade
@onready var res_val: Label   = $bg/VBoxContainer/Panel/VBoxContainer/Stat3/RESval
@onready var res_grade: Label = $bg/VBoxContainer/Panel/VBoxContainer/Stat3/RESgrade
@onready var mys_val: Label   = $bg/VBoxContainer/Panel/VBoxContainer/Stat4/MYSval
@onready var mys_grade: Label = $bg/VBoxContainer/Panel/VBoxContainer/Stat4/MYSgrade
@onready var fcs_val: Label   = $bg/VBoxContainer/Panel/VBoxContainer/Stat5/FCSval
@onready var fcs_grade: Label = $bg/VBoxContainer/Panel/VBoxContainer/Stat5/FCSgrade
@onready var lck_row: HBoxContainer = $bg/VBoxContainer/Panel/VBoxContainer/Stat6


func _ready() -> void:
	lck_row.hide()  # no luck stat yet


var _creature_stats: CreatureStats = null


func populate(creature_stats: CreatureStats) -> void:
	_creature_stats = creature_stats
	update_display()


func update_display() -> void:
	if not _creature_stats:
		return
	var sb: CreatureStatBlock = _creature_stats.stat_block
	creature_name_label.text = _creature_stats.creature_name
	personality_label.text   = CreatureStatBlock.Personality.keys()[sb.personality].capitalize()
	_set_stat(pwr_val, pwr_grade, sb.power)
	_set_stat(agi_val, agi_grade, sb.agility)
	_set_stat(res_val, res_grade, sb.resilience)
	_set_stat(mys_val, mys_grade, sb.mystic)
	_set_stat(fcs_val, fcs_grade, sb.focus)


func _set_stat(val_label: Label, grade_label: Label, block: StatBlock) -> void:
	val_label.text   = str(block.get_effective_value())
	grade_label.text = StatBlock.Grade.keys()[block.grade]
