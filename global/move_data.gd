#move_data.gd
extends Node

var moves: Dictionary = {}
var element_to_moves: Dictionary = {}  # element_type string → Array[move_id]


func _ready() -> void:
	var file := FileAccess.open("res://data/move_list.json", FileAccess.READ)
	if not file:
		push_error("move_list.json not found")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed.has("moves"):
		moves = parsed["moves"]
	else:
		push_error("Missing 'moves' key in move_list.json")
		return

	# Build element → move lookup
	# NOTE: Phase 0 uses PokéSpire move data, so type strings here are Pokemon
	# type names ("grass", "fire", etc.), not MeadowDeep element names.
	# This mapping will drift until move_list.json is replaced with MeadowDeep content.
	for move_id in moves:
		var move = moves[move_id]
		var element = move.get("type", "normal")
		if not element_to_moves.has(element):
			element_to_moves[element] = []
		element_to_moves[element].append(move_id)
