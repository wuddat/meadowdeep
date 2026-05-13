class_name CreatureStatView
extends Control

@onready var creature_name: Label = %CreatureName
@onready var creature_stat_pwr: CreatureStatBar = %CreatureStatPWR
@onready var creature_stat_agi: CreatureStatBar = %CreatureStatAGI
@onready var creature_stat_res: CreatureStatBar = %CreatureStatRES
@onready var creature_stat_mys: CreatureStatBar = %CreatureStatMYS
@onready var creature_stat_foc: CreatureStatBar = %CreatureStatFOC

var _instance: CreatureInstance = null
var _active_uid: String = ""


func _ready() -> void:
	Events.creature_stat_view_requested.connect(_on_stat_view_requested)
	Events.creature_stat_view_dismissed.connect(_on_stat_view_dismissed)
	Events.creature_stat_updated.connect(_on_stat_updated)
	hide()


func _on_stat_view_requested(instance: CreatureInstance) -> void:
	if _active_uid != "" and _active_uid != instance.uid:
		return
	populate(instance)
	show()


func _on_stat_view_dismissed(uid: String) -> void:
	if uid != _active_uid:
		return
	_active_uid = ""
	hide()


func _on_stat_updated(uid: String) -> void:
	if uid == _active_uid:
		update_display()


func populate(instance: CreatureInstance) -> void:
	_instance = instance
	_active_uid = instance.uid
	update_display()


func update_display() -> void:
	if not _instance:
		return
	var sb: CreatureIdentity = _instance.identity
	creature_name.text = _instance.definition.creature_name
	creature_stat_pwr.setup(sb.PWR, "PWR")
	creature_stat_agi.setup(sb.AGI, "AGI")
	creature_stat_res.setup(sb.RES, "RES")
	creature_stat_mys.setup(sb.MYS, "MYS")
	creature_stat_foc.setup(sb.FOC, "FOC")
