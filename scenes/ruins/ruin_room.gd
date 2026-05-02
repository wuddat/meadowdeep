class_name RuinRoom
extends Node2D

const DOOR = preload("uid://j0qtggfhqrak")

const DOOR_POS := {
	&"N": Vector2(313, 19),
	&"S": Vector2(319, 341),
	&"E": Vector2(622, 177),
	&"W": Vector2(20, 167),
}

const DIR_VEC := {
	&"N": Vector2i.UP,
	&"S": Vector2i.DOWN,
	&"E": Vector2i.RIGHT,
	&"W": Vector2i.LEFT,
}

const DIR_BIT := {
	&"N": MapGenerator.DOOR_N,
	&"S": MapGenerator.DOOR_S,
	&"E": MapGenerator.DOOR_E,
	&"W": MapGenerator.DOOR_W,
}

const OPPOSITE := {
	&"N": &"S",
	&"S": &"N",
	&"E": &"W",
	&"W": &"E",
}

const PLAYER_INSET := 60.0

@onready var room_type_label: Label = $RoomTypeLabel
@onready var map_generator: MapGenerator = $MapGenerator
@onready var doors_container: Node2D = $Doors
@onready var player: Node2D = $PlayerModel
@onready var creature_battle_unit: CreatureBattleUnit = $CreatureBattleUnit

var current_pos: Vector2i = Vector2i.ZERO
var visited: Dictionary = {}
var doors: Dictionary = {}  # &"N" -> Door


func _ready() -> void:
	map_generator.generate_floor(1)
	_spawn_doors()
	enter_room(Vector2i.ZERO)


# Instantiate the 4 doors once at start. Per-room logic only calls setup() on these.
func _spawn_doors() -> void:
	for dir: StringName in DOOR_POS.keys():
		var door := DOOR.instantiate() as Door
		door.position = DOOR_POS[dir]
		door.rotation = _door_rotation(dir)
		doors_container.add_child(door)
		door.entered.connect(_on_door_entered)
		doors[dir] = door


func enter_room(pos: Vector2i, from_direction: StringName = &"") -> void:
	var room: Room = map_generator.room_map.get(pos)
	if room == null:
		push_warning("RuinRoom: no room at %s" % pos)
		return
	current_pos = pos
	visited[pos] = true
	_refresh_label(room)
	refresh_doors(room)
	if from_direction != &"":
		_park_player_at(OPPOSITE[from_direction])


func _refresh_label(room: Room) -> void:
	room_type_label.text = "%s @ %s  depth=%d" % [
		Room.Type.keys()[room.type], room.grid_pos, room.depth
	]


func refresh_doors(room: Room) -> void:
	for dir: StringName in DOOR_POS.keys():
		var door: Door = doors[dir]
		if room.doors & DIR_BIT[dir]:
			var neighbor_pos: Vector2i = current_pos + DIR_VEC[dir]
			var neighbor: Room = map_generator.room_map.get(neighbor_pos)
			door.setup(neighbor, dir, Door.State.OPEN)
		else:
			door.setup(null, dir, Door.State.NO_DOOR)


func _door_rotation(dir: StringName) -> float:
	match dir:
		&"N": return 0.0
		&"E": return PI / 2.0
		&"S": return PI
		&"W": return -PI / 2.0
	return 0.0


func _park_player_at(dir: StringName) -> void:
	var door_pos: Vector2 = DOOR_POS[dir]
	var inward := Vector2.ZERO
	match dir:
		&"N": inward = Vector2(0,  PLAYER_INSET)
		&"S": inward = Vector2(0, -PLAYER_INSET)
		&"E": inward = Vector2(-PLAYER_INSET, 0)
		&"W": inward = Vector2( PLAYER_INSET, 0)
	player.position = door_pos + inward
	creature_battle_unit.position = door_pos + inward


func _on_door_entered(destination: Room, from_direction: StringName) -> void:
	enter_room(destination.grid_pos, from_direction)
