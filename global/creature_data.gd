#creature_data.gd
extends Node

var creatures: Dictionary = {}
var _definitions: Dictionary = {}  # species_id → CreatureDef (cached)
var _uid_seq: int = 0

# Grade int (1-5 from JSON) → GrowthStat.Grade enum index (0-4).
# JSON.parse_string returns numeric literals as floats — callers MUST int()-cast before lookup.
const GRADE_MAP := {
	1: GrowthStat.Grade.E,
	2: GrowthStat.Grade.D,
	3: GrowthStat.Grade.C,
	4: GrowthStat.Grade.B,
	5: GrowthStat.Grade.A,
}

const PERSONALITY_MAP := {
	"neutral":  Personality.Type.NEUTRAL,
	"brave":    Personality.Type.BRAVE,
	"timid":    Personality.Type.TIMID,
}

const STAT_NAMES := {
	GrowthStat.StatType.PWR: "PWR",
	GrowthStat.StatType.AGI: "AGI",
	GrowthStat.StatType.RES: "RES",
	GrowthStat.StatType.MYS: "MYS",
	GrowthStat.StatType.FOC: "FOC",
}


func _ready() -> void:
	var file := FileAccess.open("res://data/creatures.json", FileAccess.READ)
	if not file:
		push_error("creatures.json not found")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed.has("creatures"):
		creatures = parsed["creatures"]
	else:
		push_error("Missing 'creatures' key in creatures.json")
		return

	_build_definitions()


func _build_definitions() -> void:
	for species_id in creatures.keys():
		var data: Dictionary = creatures[species_id]
		var def := CreatureDef.new()
		def.species_id = species_id
		def.creature_name = data.get("creature_name", species_id)
		def.element_type = data.get("element_type", "normal")
		def.max_health = data.get("max_health", 10)
		def.base_speed = data.get("base_speed", 0.0)
		def.egg_rarity = data.get("egg_rarity", "common")
		def.egg_depth_found = data.get("egg_depth_found", 0)
		var sprite_res = load(data.get("sprite_path", "res://art/placeholder.png"))
		if sprite_res is SpriteFrames:
			def.frames = sprite_res
		else:
			def.art = sprite_res
		var battlecry = data.get("battlecry", "")
		if battlecry != "":
			def.battlecry = load(battlecry)
		def.action_ids = Utils.to_typed_string_array(data.get("action_ids", []))
		def.starting_actions = Utils.to_typed_string_array(data.get("starting_actions", []))
		def.evolves_to = data.get("evolves_to", "")
		def.evolution_level = data.get("evolution_level", 101)
		_definitions[species_id] = def


func get_creature_data(species_id: String) -> Dictionary:
	return creatures.get(species_id, {})


func get_definition(species_id: String) -> CreatureDef:
	return _definitions.get(species_id)


func create_creature_instance(species_id: String) -> CreatureInstance:
	var def := get_definition(species_id)
	if def == null:
		push_warning("No definition for species: " + species_id)
		return null

	var identity := CreatureIdentity.new()
	identity.known_actions = def.starting_actions.duplicate()
	# assigned_actions left empty — prep menu picks for player creatures,
	# BattleActor._hydrate_actions falls back to known_actions for enemies.

	var data: Dictionary = creatures.get(species_id, {})
	if data.has("identity"):
		var sb_data: Dictionary = data["identity"]
		identity.personality.type = PERSONALITY_MAP.get(sb_data.get("personality", "neutral"), Personality.Type.NEUTRAL)
		identity.PWR.grade = GRADE_MAP.get(int(sb_data.get("PWR_grade", 3)), GrowthStat.Grade.C)
		identity.AGI.grade = GRADE_MAP.get(int(sb_data.get("AGI_grade", 3)), GrowthStat.Grade.C)
		identity.RES.grade = GRADE_MAP.get(int(sb_data.get("RES_grade", 3)), GrowthStat.Grade.C)
		identity.MYS.grade = GRADE_MAP.get(int(sb_data.get("MYS_grade", 3)), GrowthStat.Grade.C)
		identity.FOC.grade = GRADE_MAP.get(int(sb_data.get("FOC_grade", 3)), GrowthStat.Grade.C)

	var instance := CreatureInstance.new()
	instance.definition = def
	instance.identity = identity
	instance.health = def.max_health
	instance.block = 0
	instance.uid = _next_uid(species_id)
	return instance


func _next_uid(species_id: String) -> String:
	_uid_seq += 1
	return "%s_%d_%d" % [species_id, Time.get_unix_time_from_system(), _uid_seq]


# Returns all species IDs whose egg_depth_found is <= the given depth.
# Use this to populate encounter pools — deeper floors unlock rarer creatures.
func get_species_for_depth(depth: int) -> Array[String]:
	var valid: Array[String] = []
	for species_id in creatures.keys():
		var data = creatures[species_id]
		if data.get("egg_depth_found", 0) <= depth:
			valid.append(species_id)
	return valid
