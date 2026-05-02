class_name Room
extends Resource

enum Type {NOT_ASSIGNED, START, COMBAT, TREASURE, REST_SITE, SHOP, BOSS, EVENT, EGG_CHAMBER}

@export var type: Type
@export var grid_pos: Vector2i
@export var position: Vector2
@export var next_rooms: Array[Room]
@export var selected := false
@export var battle_stats: BattleStats
@export var tier: int = 0
var doors: int
var depth: int


func _to_string() -> String:
	return "%s (%s)" % [grid_pos, Type.keys()[type]]
