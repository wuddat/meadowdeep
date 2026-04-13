#player_stats.gd
class_name PlayerStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture2D
@export var frames: SpriteFrames

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_move_ids: Array[String] = []
@export var cards_per_turn: int = 5
@export var max_mana: int = 3
@export var starting_moves: Array[String] = []

@export_group("Creature Data")
@export var starting_party: Array[String] = []
@export var current_party: Array[CreatureStats] = []

@export var mana: int : set = set_mana
@export var deck: CardPile
@export var discard: CardPile
@export var draw_pile: CardPile
@export var faint_pile: Dictionary = {}  # uid (String) → CardPile
@export var battle_deck: CardPile
@export var draftable_cards: CardPile


func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()


func reset_mana() -> void:
	mana = max_mana


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func card_playable(card: Card) -> bool:
	return mana >= card.current_cost


func create_instance() -> Resource:
	var instance: PlayerStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()

	instance.current_party = []
	for species_id in starting_party:
		var creature = CreatureData.create_creature_instance(species_id)
		if creature:
			instance.current_party.append(creature)
		else:
			push_warning("Missing creature data for %s" % species_id)

	instance.deck = CardPile.new()
	for creature in instance.current_party:
		var creature_cards = build_deck_from_creature(creature)
		instance.deck.cards.append_array(creature_cards.cards)

	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	instance.draftable_cards = CardPile.new()
	if not instance.current_party.is_empty():
		instance.draftable_cards = build_deck_from_creature(instance.current_party[0])

	return instance


func get_faint_pile(uid: String) -> CardPile:
	if faint_pile.has(uid):
		return faint_pile[uid]
	return CardPile.new()


func get_all_creatures() -> Array[CreatureStats]:
	return current_party


func build_deck_from_creature(creature: CreatureStats) -> CardPile:
	var pile := CardPile.new()
	var move_cards := Utils.create_card_pile(starting_moves).cards
	for card in move_cards:
		card.creature_owner_uid = creature.uid
		card.creature_icon = creature.icon
		card.creature_owner_name = creature.species_id
		pile.add_card(card)
	return pile


func build_deck_from_move_ids(move_ids: Array[String]) -> CardPile:
	return Utils.create_card_pile(move_ids)


func build_battle_deck(selected_creatures: Array[CreatureStats]) -> CardPile:
	var pile := CardPile.new()
	for card in deck.cards:
		var owner_uid := card.creature_owner_uid
		var is_active_card := selected_creatures.any(func(c): return c.uid == owner_uid)
		var is_item_card := owner_uid == "" or owner_uid == null
		var not_in_faint = not faint_pile.has(owner_uid) or not faint_pile[owner_uid].cards.has(card)
		if (is_active_card or is_item_card) and not_in_faint:
			pile.add_card(card)
	return pile


func update_draftable_cards() -> void:
	var new_draft_deck := CardPile.new()
	for creature in current_party:
		var draft_cards := build_deck_from_creature(creature)
		for card in draft_cards.cards:
			new_draft_deck.add_card(card)
		for card in deck.cards:
			if creature.uid == card.creature_owner_uid:
				card.creature_icon = creature.icon
	draftable_cards = new_draft_deck


func on_creature_added_to_party(creature: CreatureStats) -> void:
	current_party.append(creature)
	print("Creature added to party: %s" % creature.species_id)

	var base_cards := build_deck_from_creature(creature).cards
	if base_cards.is_empty():
		push_warning("No cards found for creature: %s" % creature.species_id)
		return

	var result_cards: Array[Card] = []
	RNG.array_shuffle(base_cards)
	base_cards = base_cards.slice(0, 4)
	while result_cards.size() < 10:
		RNG.array_shuffle(base_cards)
		for card in base_cards:
			var new_card = card.duplicate()
			var move_data = MoveData.moves.get(card.id)
			if move_data and new_card.has_method("setup_from_data"):
				new_card.setup_from_data(move_data)
			result_cards.append(new_card)
			if result_cards.size() >= 10:
				break
	for card in result_cards:
		deck.add_card(card)


func check_if_all_party_fainted() -> void:
	if current_party.any(func(c): return c.health > 0):
		return
	Events.player_died.emit()


func get_creature_cards(creature_uid: String) -> CardPile:
	var pile := CardPile.new()
	for card in deck.cards:
		if card.creature_owner_uid == creature_uid:
			pile.add_card(card)
	return pile


func get_creature_by_uid(creature_uid: String) -> CreatureStats:
	for c in current_party:
		if c.uid == creature_uid:
			return c
	push_warning("No creature in party with UID: " + creature_uid)
	return null
