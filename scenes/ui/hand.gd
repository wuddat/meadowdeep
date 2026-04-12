class_name Hand
extends HBoxContainer

@export var char_stats: ArchaeologistStats
@export var party_handler: PartyHandler
@export var player_handler: PlayerHandler
@export var archaeologist: Archaeologist

@onready var card_ui_scene := preload("res://scenes/card_ui/card_ui.tscn")

var cards_played_this_turn: int = 0
var hand_max: int = 10
var hand_size: int = 0


func _ready() -> void:
	_establish_connections()


func add_card(card: Card) -> void:
	if get_child_count() >= hand_max:
		return

	var new_card_ui: CardUI = card_ui_scene.instantiate()
	add_child(new_card_ui)

	await get_tree().process_frame

	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.card.base_card = card.duplicate(true)
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	new_card_ui.party_handler = party_handler
	new_card_ui.playable = char_stats.card_playable(card) if char_stats else true

	if card.creature_owner_uid != "":
		_assign_battle_unit(new_card_ui, card.creature_owner_uid)
	elif archaeologist:
		new_card_ui.player_pkmn_modifiers = archaeologist.modifier_handler

	_count_children()


func discard_card(card_ui: CardUI) -> void:
	card_ui.queue_free()


func disable_hand() -> void:
	for card_ui in get_children():
		if card_ui is CardUI:
			card_ui.disabled = true


func enable_hand() -> void:
	for card_ui in get_children():
		if card_ui is CardUI:
			card_ui.disabled = false


func refresh_leads_to_base() -> void:
	if cards_played_this_turn > 0:
		for child in get_children():
			if not (child is CardUI):
				continue
			if child.card.base_card != null and child.card.lead_effects:
				child.card.reset_to_base_card()


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	child.reparent(self)
	var new_index := clampi(child.original_index, 0, max(0, get_child_count() - 1))
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)
	child.set_deferred("modulate", Color.WHITE)


func _assign_battle_unit(card_ui: CardUI, uid: String) -> void:
	await get_tree().process_frame
	var tries := 0
	while tries < 10:
		var unit := party_handler.get_creature_by_uid(uid)
		if unit != null:
			card_ui.battle_unit_owner = unit
			card_ui.player_pkmn_modifiers = unit.modifier_handler
			return
		await get_tree().create_timer(0.1).timeout
		tries += 1
	push_warning("Hand: could not find CreatureBattleUnit for uid %s" % uid)


func _count_children() -> void:
	hand_size = get_child_count()
	if hand_size > 7:
		add_theme_constant_override("separation", -(hand_size + hand_size / 2))
	else:
		add_theme_constant_override("separation", 0)


func _establish_connections() -> void:
	if not Events.card_play_initiated.is_connected(disable_hand):
		Events.card_play_initiated.connect(disable_hand)
	if not Events.card_play_completed.is_connected(enable_hand):
		Events.card_play_completed.connect(enable_hand)
	if not Events.card_added_to_hand.is_connected(add_card):
		Events.card_added_to_hand.connect(add_card)
