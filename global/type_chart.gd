extends Node

# Stub — element interactions not yet designed.
# Returns 1.0 (neutral) for all matchups until MeadowDeep's element system is finalised.
# Replace EFFECTIVENESS content (not the function signature) once element design is locked.

const EFFECTIVENESS: Dictionary = {}

const DISPLAY_NAMES: Dictionary = {
	"grass":  "Verdant",
	"fire":   "Ember",
	"water":  "Tide",
	"stone":  "Stone",
	"shade":  "Shade",
	"normal": "Normal",
}

static func get_display_name(internal_type: String) -> String:
	return DISPLAY_NAMES.get(internal_type, internal_type.capitalize())

static func get_multiplier(attack_type: String, target_types: Array[String]) -> float:
	var multiplier := 1.0
	for target_type in target_types:
		if EFFECTIVENESS.has(attack_type) and EFFECTIVENESS[attack_type].has(target_type):
			multiplier *= EFFECTIVENESS[attack_type][target_type]
	return multiplier
