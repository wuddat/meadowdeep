class_name RuinsPrepMenu
extends Control

const MAX_ACTIVE_SKILLS := 4
const STAT_PALETTE_SHADER := preload("uid://boy12gwxxdf87")

@onready var creature_textures: CreatureTextures = %CreatureTextures
@onready var name_label: Label = %NameLabel
@onready var element_label: Label = %ElementLabel
@onready var active_actions_grid: GridContainer = %ActiveSkillsGrid
@onready var known_actions_grid: GridContainer = %KnownSkillsGrid
@onready var start_button: Button = %StartButton
@onready var meadow_button: Button = %MeadowButton
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton
@onready var creature_stat_pwr: CreatureStatBar = %CreatureStatPWR
@onready var creature_stat_agi: CreatureStatBar = %CreatureStatAGI
@onready var creature_stat_res: CreatureStatBar = %CreatureStatRES
@onready var creature_stat_mys: CreatureStatBar = %CreatureStatMYS
@onready var creature_stat_foc: CreatureStatBar = %CreatureStatFOC
@onready var stat_panel: VBoxContainer = %StatPanel
@onready var creature_skin_handler: CreatureSkinHandler = %CreatureSkinHandler


var _creatures: Array[CreatureInstance] = []
var _creature_index: int = 0


func _ready() -> void:
	left_button.pressed.connect(_on_left_pressed)
	right_button.pressed.connect(_on_right_pressed)
	meadow_button.pressed.connect(_on_meadow_pressed)
	start_button.pressed.connect(_on_start_pressed)
	if creature_skin_handler:
		var mat := ShaderMaterial.new()
		mat.shader = STAT_PALETTE_SHADER
		creature_skin_handler.adopt_palette_material(mat)


func setup(stats: PlayerData) -> void:
	if stats:
		_creatures = stats.get_all_creatures()

	if _creatures.size():
		populate_creature(_creatures[0])
		left_button.visible = true
		right_button.visible = true


func populate_creature(creature: CreatureInstance) -> void:
	var identity := creature.identity
	var definition := creature.definition
	if identity.known_actions.is_empty() and not definition.starting_actions.is_empty():
		identity.known_actions = definition.starting_actions.duplicate()

	if definition.frames:
		creature_textures.sprite_frames = definition.frames
		creature_textures.play("idle")

	if creature_skin_handler:
		creature_skin_handler.identity = identity
		creature_skin_handler.refresh_palette()

	for child:CreatureStatBar in stat_panel.get_children():
		child.reset()
	creature_stat_pwr.setup(identity.PWR, "PWR")
	creature_stat_agi.setup(identity.AGI, "AGI")
	creature_stat_res.setup(identity.RES, "RES")
	creature_stat_mys.setup(identity.MYS, "MYS")
	creature_stat_foc.setup(identity.FOC, "FOC")

	name_label.text = definition.creature_name if definition.creature_name else definition.species_id
	element_label.text = definition.element_type

	print("[PrepMenu] %s  known=%s  assigned=%s" % [
		definition.species_id, identity.known_actions, identity.assigned_actions
	])
	_rebuild_grids(creature)


func _rebuild_grids(creature: CreatureInstance) -> void:
	_rebuild_known_actions(creature)
	_rebuild_active_actions(creature)


func _rebuild_known_actions(creature: CreatureInstance) -> void:
	for child in known_actions_grid.get_children():
		child.queue_free()

	for action_id in creature.identity.known_actions:
		if creature.identity.assigned_actions.has(action_id):
			continue
		known_actions_grid.add_child(_make_action_button(action_id, creature, true))


func _rebuild_active_actions(creature: CreatureInstance) -> void:
	for child in active_actions_grid.get_children():
		child.queue_free()

	for action_id in creature.identity.assigned_actions:
		active_actions_grid.add_child(_make_action_button(action_id, creature, false))


func _make_action_button(action_id: String, creature: CreatureInstance, is_known: bool) -> Button:
	var btn := Button.new()
	btn.text = _action_label(action_id)
	btn.custom_minimum_size = Vector2(80, 0)
	if is_known:
		btn.pressed.connect(_on_known_action_pressed.bind(action_id, creature))
	else:
		btn.pressed.connect(_on_active_action_pressed.bind(action_id, creature))
	return btn


func _action_label(action_id: String) -> String:
	var act := ActionData.get_action(action_id)
	if act and act.display_name != "":
		return act.display_name
	return action_id.capitalize()


func _on_known_action_pressed(action_id: String, creature: CreatureInstance) -> void:
	if creature.identity.assigned_actions.size() >= MAX_ACTIVE_SKILLS:
		return
	if creature.identity.assigned_actions.has(action_id):
		return
	creature.identity.assigned_actions.append(action_id)
	_rebuild_grids(creature)


func _on_active_action_pressed(action_id: String, creature: CreatureInstance) -> void:
	creature.identity.assigned_actions.erase(action_id)
	_rebuild_grids(creature)


func _on_left_pressed() -> void:
	if _creatures.is_empty():
		return
	_creature_index = (_creature_index - 1 + _creatures.size()) % _creatures.size()
	populate_creature(_creatures[_creature_index])


func _on_right_pressed() -> void:
	if _creatures.is_empty():
		return
	_creature_index = (_creature_index + 1) % _creatures.size()
	populate_creature(_creatures[_creature_index])


func _on_meadow_pressed() -> void:
	Events.scene_transition_requested.emit("meadow")


func _on_start_pressed() -> void:
	Events.ruins_run_started.emit(_creatures[_creature_index])
	Events.scene_transition_requested.emit("ruins")
