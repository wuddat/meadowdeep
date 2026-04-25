#card.gd
class_name Card
extends Resource

enum Type {ATTACK, SKILL, POWER, SHIFT, STATUS}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, SINGLE_ALLY, ALL_ENEMIES, ALL_ALLIES, ALL, RANDOM_ENEMY, SPLASH}

# TODO: Replace placeholder element types with MeadowDeep originals once element design is finalised.
# These are stand-ins copied from PokéSpire — the TypeChart and creature data will drive what
# actually lives here. See DEV_NOTES.md.
enum ElementType {NORMAL, VERDANT, EMBER, TIDE, STRIKE, SPARK, GALE, CRAWL, VENOM, FROST, STONE, EARTH, IRON, ETHER, SHADE, DUSK, CHARM, WYRM}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
}

const TYPE_COLORS := {
	Card.Type.ATTACK: Color.WHITE_SMOKE,
	Card.Type.SKILL: Color.WHITE_SMOKE,
	Card.Type.POWER: Color.WHITE_SMOKE,
	Card.Type.SHIFT: Color.WHITE_SMOKE,
	Card.Type.STATUS: Color.WHITE_SMOKE
}

# TODO: Assign real MeadowDeep element colors once element types are finalised.
const ELEMENT_COLORS := {
	Card.ElementType.NORMAL:  Color(.659, .655, .478),
	Card.ElementType.VERDANT: Color(.478, .78,  .298),
	Card.ElementType.EMBER:   Color(.933, .506, .188),
	Card.ElementType.TIDE:    Color(.388, .565, .941),
	Card.ElementType.STRIKE:  Color(.761, .18,  .157),
	Card.ElementType.SPARK:   Color(.969, .816, .173),
	Card.ElementType.GALE:    Color(.663, .561, .953),
	Card.ElementType.CRAWL:   Color(.651, .725, .102),
	Card.ElementType.VENOM:   Color(.639, .243, .631),
	Card.ElementType.FROST:   Color(.588, .851, .839),
	Card.ElementType.STONE:   Color(.714, .631, .212),
	Card.ElementType.EARTH:   Color(.886, .749, .396),
	Card.ElementType.IRON:    Color(.718, .718, .808),
	Card.ElementType.ETHER:   Color(.976, .333, .529),
	Card.ElementType.SHADE:   Color(.451, .341, .592),
	Card.ElementType.DUSK:    Color(.439, .341, .275),
	Card.ElementType.CHARM:   Color(.839, .522, .678),
	Card.ElementType.WYRM:    Color(.435, .208, .988),
}


@export_group("Card Attributes")
@export var id: String
@export var name: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var power: int
@export var target_damage_percent_hp: float = 0.0
@export var damage_type: String
@export var exhausts: bool = false
@export var creature_owner_uid: String
@export var creature_owner_name: String
@export var base_power: int


@export_group("Card Visuals")
@export var icon: Texture
@export var creature_icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

@export_group("Card Effects")
@export var status_effects: Array[Status]
@export var effect_chance: float = 1
@export var dmg_block: int = 0
@export var multiplay: int = 1
@export var randomplay: int = 0
@export var requires_status: String = ""
@export var bonus_damage_if_target_has_status: String = ""
@export var bonus_damage_multiplier: float = 1.0
@export var splash_damage: int = 0
@export var shift_enabled: int = 0
@export var lead_effects: Dictionary = {}
@export var card_draw: int = 0

@export_group("Self Effects")
@export var self_heal: int
@export var self_damage: int = 0
@export var self_damage_percent_hp: float = 0
@export var self_status: Array[Status] = []
@export var self_block: int = 0
@export var self_shift: int = 0

@export_group("QTE")
@export var qte_data: QTEData

var random_targets = []
@export var current_cost: int
@export var base_card: Card = null
@export var lead_enabled: bool = false


func is_single_targeted() -> bool:
	return target in [Target.SINGLE_ENEMY, Target.SINGLE_ALLY, Target.SPLASH]


func _get_targets(targets: Array[Node], battle_unit_owner: CreatureBattleUnit) -> Array[Node]:
	if not battle_unit_owner:
		return []

	var tree := battle_unit_owner.get_tree()

	var _is_player := battle_unit_owner.is_in_group("active_creatures")
	var player_party := tree.get_nodes_in_group("active_creatures")
	var allies_group: Array[Node] = []
	for creature in player_party:
		if creature.stats.uid != battle_unit_owner.stats.uid:
			allies_group.append(creature)
	var enemy_group := tree.get_nodes_in_group("enemies")

	match target:
		Target.SELF:
			return [battle_unit_owner]
		Target.SINGLE_ENEMY, Target.SINGLE_ALLY:
			return targets
		Target.ALL_ENEMIES:
			return enemy_group
		Target.ALL_ALLIES:
			allies_group.append(battle_unit_owner)
			return allies_group
		Target.ALL:
			return player_party + enemy_group
		Target.SPLASH:
			var splash_targets: Array[Node] = enemy_group.duplicate()
			splash_targets = splash_targets.filter(func(enemy): return enemy != targets[0])
			return targets + splash_targets
		Target.RANDOM_ENEMY:
			if enemy_group.size() > 0:
				var selected = enemy_group[RNG.instance.randi() % enemy_group.size()]
				return [selected]
			return []
		_:
			return []


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler, _battle_unit_owner: CreatureBattleUnit) -> void:
	pass


func get_default_tooltip() -> String:
	return tooltip_text


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler, _targets: Array[Node]) -> String:
	return tooltip_text


# Card generation from move data
func setup_from_data(data: Dictionary) -> void:
	id = data.get("id", "CardIDError")
	name = data.get("name", "CardNameError")
	power = data.get("power", 88)
	base_power = power
	damage_type = data.get("type", "normal")
	target_damage_percent_hp = data.get("target_damage_percent_hp", 0.0)
	cost = data.get("cost", 88)
	current_cost = cost
	tooltip_text = data.get("description", "CardToolTipError")
	var iconpath = data.get("icon_path", "res://art/arrow.png")
	icon = load(iconpath)
	multiplay = data.get("multiplay", 1)
	randomplay = data.get("randomplay", 0)
	self_damage = data.get("self_damage", 0)
	self_damage_percent_hp = data.get("self_damage_percent_hp", 0)
	self_heal = data.get("self_heal", 0)
	self_block = data.get("self_block", 0)
	dmg_block = data.get("dmg_block", 0)
	effect_chance = data.get("effect_chance", 1.0)
	splash_damage = data.get("splash_damage", 0)
	requires_status = data.get("requires_status", "")
	bonus_damage_if_target_has_status = data.get("bonus_damage_if_target_has_status", "")
	bonus_damage_multiplier = data.get("bonus_damage_multiplier", 1.0)
	shift_enabled = data.get("shift_enabled", 0)
	self_shift = data.get("self_shift", 0)
	card_draw = data.get("card_draw", 0)
	qte_data = QTEData.new()
	qte_data.total_duration = 0.5
	qte_data.on_perfect = QTEOutcome.new()
	qte_data.on_perfect.damage_multiplier = 2.0
	qte_data.on_miss = QTEOutcome.new()
	qte_data.on_miss.damage_multiplier = 0.0

	match data.get("category", "attack"):
		"attack":
			type = Type.ATTACK
		"defense", "stat_mod", "status_effect":
			type = Type.SKILL
		"power":
			type = Type.POWER
		"shift":
			type = Type.SHIFT
		"status", "buff", "debuff":
			type = Type.STATUS

	match data.get("target", "enemy"):
		"self":
			target = Target.SELF
		"enemy", "single_enemy":
			target = Target.SINGLE_ENEMY
		"ally":
			target = Target.SINGLE_ALLY
		"allies", "all_allies":
			target = Target.ALL_ALLIES
		"all_enemies":
			target = Target.ALL_ENEMIES
		"all":
			target = Target.ALL
		"splash":
			target = Target.SPLASH
		"random_enemy":
			target = Target.RANDOM_ENEMY

	match data.get("rarity", "common"):
		"common", "Common":
			rarity = Rarity.COMMON
		"uncommon", "Uncommon":
			rarity = Rarity.UNCOMMON
		"rare", "Rare":
			rarity = Rarity.RARE

	if data.has("sound_path"):
		sound = load(data["sound_path"])
	else:
		sound = load("res://art/sounds/Tackle.wav")

	status_effects.clear()
	if data.has("status_effects"):
		var typed_ids = Utils.to_typed_string_array(data["status_effects"])
		status_effects.append_array(StatusData.get_status_effects_from_ids(typed_ids))

	self_status.clear()
	if data.has("self_status"):
		var typed_ids = Utils.to_typed_string_array(data["self_status"])
		self_status.append_array(StatusData.get_status_effects_from_ids(typed_ids))

	if data.has("lead_effects"):
		lead_effects = data["lead_effects"]


func emit_dialogue(texts: Array[String]) -> void:
	for text in texts:
		Events.battle_text_requested.emit(text)
		print(text)


func get_element_color() -> Color:
	var type_str := damage_type.to_upper()
	match type_str:
		"NORMAL":  return ELEMENT_COLORS[ElementType.NORMAL]
		"VERDANT": return ELEMENT_COLORS[ElementType.VERDANT]
		"EMBER":   return ELEMENT_COLORS[ElementType.EMBER]
		"TIDE":    return ELEMENT_COLORS[ElementType.TIDE]
		"STRIKE":  return ELEMENT_COLORS[ElementType.STRIKE]
		"SPARK":   return ELEMENT_COLORS[ElementType.SPARK]
		"GALE":    return ELEMENT_COLORS[ElementType.GALE]
		"CRAWL":   return ELEMENT_COLORS[ElementType.CRAWL]
		"VENOM":   return ELEMENT_COLORS[ElementType.VENOM]
		"FROST":   return ELEMENT_COLORS[ElementType.FROST]
		"STONE":   return ELEMENT_COLORS[ElementType.STONE]
		"EARTH":   return ELEMENT_COLORS[ElementType.EARTH]
		"IRON":    return ELEMENT_COLORS[ElementType.IRON]
		"ETHER":   return ELEMENT_COLORS[ElementType.ETHER]
		"SHADE":   return ELEMENT_COLORS[ElementType.SHADE]
		"DUSK":    return ELEMENT_COLORS[ElementType.DUSK]
		"CHARM":   return ELEMENT_COLORS[ElementType.CHARM]
		"WYRM":    return ELEMENT_COLORS[ElementType.WYRM]
		_:
			return Color.WHITE


func apply_lead_mods(card: Card) -> void:
	lead_enabled = true
	if card.lead_effects.has("power"):
		card.power = card.lead_effects["power"]
		card.base_power = card.power

	if card.lead_effects.has("self_damage"):
		card.self_damage = card.lead_effects["self_damage"]

	if card.lead_effects.has("description"):
		card.tooltip_text = card.lead_effects["description"]

	if card.lead_effects.has("multiplay"):
		card.multiplay = card.lead_effects["multiplay"]

	if card.lead_effects.has("status_effects"):
		var typed_ids = Utils.to_typed_string_array(card.lead_effects["status_effects"])
		status_effects.clear()
		status_effects.append_array(StatusData.get_status_effects_from_ids(typed_ids))

	if card.lead_effects.has("self_status"):
		var typed_ids = Utils.to_typed_string_array(lead_effects["self_status"])
		self_status.clear()
		self_status.append_array(StatusData.get_status_effects_from_ids(typed_ids))


func reset_to_base_card() -> void:
	if base_card == null:
		push_warning("Tried to reset card without a base_card.")
		return

	lead_enabled = false

	# Card Attributes
	id = base_card.id
	name = base_card.name
	type = base_card.type
	rarity = base_card.rarity
	cost = base_card.cost
	current_cost = base_card.current_cost
	power = base_card.power
	base_power = base_card.base_power
	target_damage_percent_hp = base_card.target_damage_percent_hp
	damage_type = base_card.damage_type
	exhausts = base_card.exhausts
	creature_owner_uid = base_card.creature_owner_uid
	creature_owner_name = base_card.creature_owner_name

	# Card Visuals
	icon = base_card.icon
	creature_icon = base_card.creature_icon
	tooltip_text = base_card.tooltip_text
	sound = base_card.sound

	# Card Effects
	status_effects = base_card.status_effects.duplicate()
	effect_chance = base_card.effect_chance
	dmg_block = base_card.dmg_block
	multiplay = base_card.multiplay
	randomplay = base_card.randomplay
	requires_status = base_card.requires_status
	bonus_damage_if_target_has_status = base_card.bonus_damage_if_target_has_status
	bonus_damage_multiplier = base_card.bonus_damage_multiplier
	splash_damage = base_card.splash_damage
	shift_enabled = base_card.shift_enabled
	lead_effects = base_card.lead_effects.duplicate()
	card_draw = base_card.card_draw
	qte_data = base_card.qte_data

	# Self Effects
	self_heal = base_card.self_heal
	self_damage = base_card.self_damage
	self_damage_percent_hp = base_card.self_damage_percent_hp
	self_status = base_card.self_status.duplicate()
	self_block = base_card.self_block
	self_shift = base_card.self_shift
