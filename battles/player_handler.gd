#player_handler.gd
class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.3
const HAND_DISCARD_INTERVAL := 0.2

# Typed as Node until Hand and PlayerCharacter scenes are wired in the battle scene.
@export var hand: Node
@export var player_character: Node

@onready var party_handler: PartyHandler = $"../PartyHandler"
@onready var end_turn_button: Button = %EndTurnButton

var character: PlayerStats


func _ready() -> void:
	_establish_connections()
	if end_turn_button:
		end_turn_button.pressed.connect(func(): Events.player_turn_ended.emit())


func start_battle(char_stats: PlayerStats) -> void:
	character = char_stats
	if hand and "char_stats" in hand:
		hand.set("char_stats", char_stats)
	character.faint_pile.clear()

	character.battle_deck = character.build_battle_deck(party_handler.active_battle_party)
	character.draw_pile = character.battle_deck.duplicate(true)
	character.draw_pile.shuffle()

	for creature in character.current_party:
		if creature.health <= 0:
			exhaust_cards_on_faint(creature.uid)

	character.discard = CardPile.new()
	_establish_connections()
	await get_tree().process_frame
	start_turn()


func start_turn() -> void:
	if player_character and player_character.has_node("StatusHandler"):
		player_character.get_node("StatusHandler").apply_statuses_by_type(Status.Type.START_OF_TURN)
	character.block = 0
	character.reset_mana()
	end_turn_button.show()

	for creature_node in party_handler.get_active_creature_nodes():
		creature_node.start_of_turn()


func end_turn() -> void:
	if hand and hand.has_method("disable_hand"):
		hand.disable_hand()
	end_turn_button.hide()

	if player_character and player_character.has_node("StatusHandler"):
		player_character.get_node("StatusHandler").apply_statuses_by_type(Status.Type.END_OF_TURN)

	for creature_node in party_handler.get_active_creature_nodes():
		creature_node.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)
		creature_node.status_handler.remove_status("flinched")


func draw_card() -> void:
	reshuffle_deck_from_discard()
	if character.draw_pile.empty():
		print("No cards left to draw!")
		return
	if hand and hand.has_method("add_card"):
		hand.add_card(character.draw_pile.draw_card())
	if hand and hand.has_method("_count_children"):
		hand._count_children()
	reshuffle_deck_from_discard()


func draw_cards(amount: int) -> void:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	tween.finished.connect(func(): Events.player_hand_drawn.emit())


func discard_cards() -> void:
	if not hand or hand.get_child_count() == 0:
		Events.player_hand_discarded.emit()
		return

	var tween := create_tween()
	for card_ui in hand.get_children():
		tween.tween_callback(character.discard.add_card.bind(card_ui.card))
		tween.tween_callback(func():
			if hand.has_method("discard_card"):
				hand.discard_card(card_ui)
		)
		tween.tween_interval(HAND_DISCARD_INTERVAL)
	tween.finished.connect(func(): Events.player_hand_discarded.emit())


func reshuffle_deck_from_discard() -> void:
	if not character.draw_pile.empty():
		return
	while not character.discard.empty():
		character.draw_pile.add_card(character.discard.draw_card())
	character.draw_pile.shuffle()


func exhaust_cards_on_faint(uid: String) -> void:
	if not character.faint_pile.has(uid):
		character.faint_pile[uid] = CardPile.new()

	var cards_to_exhaust := CardPile.new()

	for card: Card in character.draw_pile.cards:
		if card.creature_owner_uid == uid:
			cards_to_exhaust.add_card(card)
	character.draw_pile.cards = character.draw_pile.cards.filter(
		func(c): return c.creature_owner_uid != uid
	)

	if hand:
		for card_ui in hand.get_children():
			if card_ui.card.creature_owner_uid == uid:
				cards_to_exhaust.add_card(card_ui.card)
				if hand.has_method("discard_card"):
					hand.discard_card(card_ui)
				draw_card()

	for card: Card in character.discard.cards:
		if card.creature_owner_uid == uid:
			cards_to_exhaust.add_card(card)
	character.discard.cards = character.discard.cards.filter(
		func(c): return c.creature_owner_uid != uid
	)

	if hand:
		for card_ui in hand.get_children():
			if card_ui == null or card_ui.card == null:
				return
			if card_ui.card.creature_owner_uid == uid:
				cards_to_exhaust.add_card(card_ui.card)
				if hand.has_method("discard_card"):
					hand.discard_card(card_ui)

	for card in cards_to_exhaust.cards:
		character.faint_pile[uid].add_card(card)

	character.draw_pile.shuffle()


func restore_fainted_cards(uid: String) -> void:
	if not character.faint_pile.has(uid):
		return
	var pile: CardPile = character.faint_pile[uid]
	if pile.empty():
		return
	for card in pile.cards:
		character.draw_pile.add_card(card)
	character.faint_pile.erase(uid)


func _on_card_played(card: Card) -> void:
	if card.exhausts or card.type == Card.Type.POWER:
		return
	if card.id == "nightshade":
		character.discard.add_card(card)
		character.discard.add_card(card)
		if hand and "hand_size" in hand:
			hand.set("hand_size", hand.get("hand_size") - 1)
		if hand and hand.has_method("_count_children"):
			hand._count_children()
		return
	character.discard.add_card(card)
	if hand:
		if "cards_played_this_turn" in hand:
			hand.set("cards_played_this_turn", hand.get("cards_played_this_turn") + 1)
		if "hand_size" in hand:
			hand.set("hand_size", hand.get("hand_size") - 1)
		if hand.has_method("refresh_leads_to_base"):
			hand.refresh_leads_to_base()
		if hand.has_method("_count_children"):
			hand._count_children()


func _on_statuses_applied(type: Status.Type) -> void:
	match type:
		Status.Type.START_OF_TURN:
			draw_cards(character.cards_per_turn)
		Status.Type.END_OF_TURN:
			discard_cards()


func _on_party_creature_fainted(unit: CreatureBattleUnit) -> void:
	exhaust_cards_on_faint(unit.stats.uid)


func _on_party_creature_switch_requested(uid_out: String, uid_in: String) -> void:
	exhaust_cards_on_faint(uid_out)
	for card: Card in character.deck.cards:
		if card.creature_owner_uid == uid_in:
			character.draw_pile.add_card(card)
	character.draw_pile.shuffle()


func _on_evolution_triggered(_creature_stats: CreatureStats) -> void:
	if hand and hand.has_method("disable_hand"):
		hand.disable_hand()


func _on_evolution_completed() -> void:
	if hand and hand.has_method("enable_hand"):
		hand.enable_hand()


func _establish_connections() -> void:
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.evolution_triggered.is_connected(_on_evolution_triggered):
		Events.evolution_triggered.connect(_on_evolution_triggered)
	if not Events.evolution_completed.is_connected(_on_evolution_completed):
		Events.evolution_completed.connect(_on_evolution_completed)

	if player_character and player_character.has_node("StatusHandler"):
		var sh = player_character.get_node("StatusHandler")
		if not sh.statuses_applied.is_connected(_on_statuses_applied):
			sh.statuses_applied.connect(_on_statuses_applied)

	if not Events.party_creature_fainted.is_connected(_on_party_creature_fainted):
		Events.party_creature_fainted.connect(_on_party_creature_fainted)
	if not Events.player_creature_switch_requested.is_connected(_on_party_creature_switch_requested):
		Events.player_creature_switch_requested.connect(_on_party_creature_switch_requested)
	if not Events.card_draw_requested.is_connected(draw_cards):
		Events.card_draw_requested.connect(draw_cards)
