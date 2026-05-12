#creature_data.gd
extends Node

var creatures: Dictionary = {}

# Grade int (1-5 from JSON) → GrowthStat.Grade enum index (0-4)
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


func get_creature_data(species_id: String) -> Dictionary:
	return creatures.get(species_id, {})


func create_creature_instance(species_id: String) -> CreatureDef:
	var data := get_creature_data(species_id)
	if data.is_empty():
		push_warning("No data for species: " + species_id)
		return null

	var creature := CreatureDef.new()
	creature.species_id = species_id
	creature.creature_name = data.get("creature_name", species_id)
	creature.element_type = data.get("element_type", "normal")
	creature.max_health = data.get("max_health", 10)
	creature.health = creature.max_health
	creature.is_companion = data.get("is_companion", false)
	creature.egg_rarity = data.get("egg_rarity", "common")
	creature.egg_depth_found = data.get("egg_depth_found", 0)
	var sprite_res = load(data.get("sprite_path", "res://art/placeholder.png"))
	if sprite_res is SpriteFrames:
		creature.frames = sprite_res
	else:
		creature.art = sprite_res
	creature.icon = load(data.get("icon_path", "res://art/placeholder.png"))
	creature.uid = "creature_" + str(Time.get_unix_time_from_system()) + "_" + species_id
	creature.move_ids = Utils.to_typed_string_array(data.get("move_ids", []))
	creature.starting_moves = Utils.to_typed_string_array(data.get("starting_moves", []))
	creature.known_moves = creature.starting_moves.duplicate()
	creature.assigned_moves = creature.known_moves.duplicate()

	# Build stat block from JSON
	if data.has("stat_block"):
		var sb_data: Dictionary = data["stat_block"]
		var sb := creature.stat_block
		sb.personality.type = PERSONALITY_MAP.get(sb_data.get("personality", "neutral"), Personality.Type.NEUTRAL)
		sb.PWR.grade       = GRADE_MAP.get(sb_data.get("PWR_grade", 3),      GrowthStat.Grade.C)
		sb.AGI.grade     = GRADE_MAP.get(sb_data.get("AGI_grade", 3),    GrowthStat.Grade.C)
		sb.RES.grade  = GRADE_MAP.get(sb_data.get("RES_grade", 3), GrowthStat.Grade.C)
		sb.MYS.grade      = GRADE_MAP.get(sb_data.get("MYS_grade", 3),     GrowthStat.Grade.C)
		sb.FOC.grade       = GRADE_MAP.get(sb_data.get("FOC_grade", 3),      GrowthStat.Grade.C)
	return creature


# Returns all species IDs whose egg_depth_found is <= the given depth.
# Use this to populate encounter pools — deeper floors unlock rarer creatures.
func get_species_for_depth(depth: int) -> Array[String]:
	var valid: Array[String] = []
	for species_id in creatures.keys():
		var data = creatures[species_id]
		if data.get("egg_depth_found", 0) <= depth:
			valid.append(species_id)
	return valid
