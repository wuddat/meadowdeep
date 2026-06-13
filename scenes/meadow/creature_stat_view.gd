class_name CreatureStatView
extends Control

@onready var creature_name: Label = %CreatureName
@onready var creature_stat_pwr: CreatureStatBar = %CreatureStatPWR
@onready var creature_stat_agi: CreatureStatBar = %CreatureStatAGI
@onready var creature_stat_res: CreatureStatBar = %CreatureStatRES
@onready var creature_stat_mys: CreatureStatBar = %CreatureStatMYS
@onready var creature_stat_foc: CreatureStatBar = %CreatureStatFOC
@onready var stat_container: VBoxContainer = %StatContainer

var _instance: CreatureInstance = null
var _active_uid: String = ""

const PING_SFX: AudioStream = preload("res://art/game_art/sfx/ping_SFX.wav")
const LEVEL_UP_SFX: AudioStream = preload("uid://brvwitg2xvkor")
const PIP_GAIN = preload("uid://b6nlu0hd7mhw1")
const DEBUG_SFX: AudioStream = preload("res://art/sounds/sfx/card_sfx1.mp3")

func _ready() -> void:
	_establish_connections()
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

func _on_camera_target_requested(node: Node) -> void:
	if node is BaseCreature:
		_on_stat_view_requested(node.instance)
	else: 
		_on_stat_view_dismissed(_active_uid)
		

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


func _stat_pip_filled_sfx() -> void:
	if visible:
		SFXPlayer.play(PIP_GAIN)

func _stat_level_up_sfx() -> void:
	if visible:
		SFXPlayer.play(LEVEL_UP_SFX)

func _establish_connections() -> void:
	if not Events.creature_stat_view_requested.is_connected(_on_stat_view_requested):
		Events.creature_stat_view_requested.connect(_on_stat_view_requested)
	if not Events.creature_stat_view_dismissed.is_connected(_on_stat_view_dismissed):
		Events.creature_stat_view_dismissed.connect(_on_stat_view_dismissed)
	if not Events.creature_stat_updated.is_connected(_on_stat_updated):
		Events.creature_stat_updated.connect(_on_stat_updated)
	if not Events.camera_target_requested.is_connected(_on_camera_target_requested):
		Events.camera_target_requested.connect(_on_camera_target_requested)
	for stat:CreatureStatBar in stat_container.get_children():
		if not stat.stat_level_up.is_connected(_stat_level_up_sfx):
			stat.stat_level_up.connect(_stat_level_up_sfx)
		if not stat.pip_filled.is_connected(_stat_pip_filled_sfx):
			stat.pip_filled.connect(_stat_pip_filled_sfx)
