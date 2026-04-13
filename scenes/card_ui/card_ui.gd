class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

@export var card: Card : set = _set_card
@export var char_stats: PlayerStats
@export var player_pkmn_modifiers: ModifierHandler
@export var battle_unit_owner: CreatureBattleUnit
@export var party_handler: PartyHandler

@onready var label: Label = $Panel/Label
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_state_machine: CardStateMachine = $CardStateMachine

var original_index := 0
var parent: Control
var tween: Tween
var playable := true : set = _set_playable
var disabled := false : set = _set_disabled
var targets: Array[Node] = []


func _ready() -> void:
	card_state_machine.init(self)


func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)


func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()


func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()


func animate_to_position(new_position: Vector2, duration: float) -> void:
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)


func play() -> void:
	if not card or not char_stats:
		return
	Events.card_play_initiated.emit()
	hide()
	Events.card_played.emit(card)
	char_stats.mana -= card.current_cost
	card.apply_effects(_get_play_targets(), player_pkmn_modifiers, battle_unit_owner)
	Events.card_play_completed.emit()
	queue_free()


func _get_play_targets() -> Array[Node]:
	# Single-targeted cards use whatever the DropPointDetector found.
	if not targets.is_empty() and card.is_single_targeted():
		return targets

	# All other cards resolve from groups.
	var result: Array[Node] = []
	match card.target:
		Card.Target.SINGLE_ENEMY, Card.Target.ALL_ENEMIES, Card.Target.RANDOM_ENEMY, Card.Target.SPLASH:
			result.assign(get_tree().get_nodes_in_group("enemies"))
		Card.Target.SELF:
			if battle_unit_owner:
				result.append(battle_unit_owner)
		Card.Target.SINGLE_ALLY, Card.Target.ALL_ALLIES:
			result.assign(get_tree().get_nodes_in_group("active_creatures"))
		Card.Target.ALL:
			result.assign(get_tree().get_nodes_in_group("enemies"))
			result.append_array(get_tree().get_nodes_in_group("active_creatures"))
	return result


func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	if value == null:
		return
	card = value
	if label:
		label.text = "%s\n[%d]" % [card.name, card.current_cost]


func _set_playable(value: bool) -> void:
	playable = value
	if not disabled:
		modulate.a = 0.5 if not playable else 1.0


func _set_disabled(value: bool) -> void:
	disabled = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE if value else Control.MOUSE_FILTER_STOP
	modulate.a = 0.5 if (value or not playable) else 1.0


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)
