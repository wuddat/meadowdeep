class_name RuinsPrepMenu
extends Control

const MAX_ACTIVE_SKILLS := 4


@onready var creature_sprite: AnimatedSprite2D = %creatureSprite
@onready var name_label: Label = %NameLabel
@onready var element_label: Label = %ElementLabel
@onready var active_skills_grid: GridContainer = %ActiveSkillsGrid
@onready var known_skills_grid: GridContainer = %KnownSkillsGrid
@onready var start_button: Button = %StartButton
@onready var meadow_button: Button = %MeadowButton
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton

var _creatures: Array[CreatureInstance] = []
var _creature_index: int = 0


func _ready() -> void:
	left_button.pressed.connect(_on_left_pressed)
	right_button.pressed.connect(_on_right_pressed)
	meadow_button.pressed.connect(_on_meadow_pressed)
	start_button.pressed.connect(_on_start_pressed)


func setup(stats: PlayerData) -> void:
	if stats:
		_creatures = stats.get_all_creatures()

	if not _creatures.is_empty():
		populate_creature(_creatures[0])


func populate_creature(creature: CreatureInstance) -> void:
	var identity := creature.identity
	var definition := creature.definition
	if identity.known_moves.is_empty() and not definition.starting_moves.is_empty():
		identity.known_moves = definition.starting_moves.duplicate()

	if definition.frames:
		creature_sprite.sprite_frames = definition.frames
		creature_sprite.play("idle")

	name_label.text = definition.creature_name if definition.creature_name else definition.species_id
	element_label.text = definition.element_type

	_rebuild_known_skills(creature)
	_rebuild_active_skills(creature)


func _rebuild_known_skills(creature: CreatureInstance) -> void:
	for child in known_skills_grid.get_children():
		child.queue_free()

	for move_id in creature.identity.known_moves:
		var btn := Button.new()
		btn.text = move_id.capitalize()
		btn.pressed.connect(_on_known_skill_pressed.bind(move_id, creature))
		known_skills_grid.add_child(btn)
		btn.custom_minimum_size = Vector2(80,0)


func _rebuild_active_skills(creature: CreatureInstance) -> void:
	for child in active_skills_grid.get_children():
		child.queue_free()

	for move_id in creature.identity.assigned_moves:
		var btn := Button.new()
		btn.text = move_id.capitalize()
		btn.pressed.connect(_on_active_skill_pressed.bind(move_id, creature))
		active_skills_grid.add_child(btn)
		btn.custom_minimum_size = Vector2(80,0)


func _on_known_skill_pressed(move_id: String, creature: CreatureInstance) -> void:
	if creature.identity.assigned_moves.size() >= MAX_ACTIVE_SKILLS:
		return
	if creature.identity.assigned_moves.has(move_id):
		return
	creature.identity.assigned_moves.append(move_id)
	_rebuild_active_skills(creature)


func _on_active_skill_pressed(move_id: String, creature: CreatureInstance) -> void:
	creature.identity.assigned_moves.erase(move_id)
	_rebuild_active_skills(creature)


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
	Events.scene_transition_requested.emit("ruins")
