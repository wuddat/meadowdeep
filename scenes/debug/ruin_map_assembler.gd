class_name RuinBlockAssembler
extends Node

#If you forget the systems you used for generation and creature pathing look up:
#BFS (Breadth First Search)
#Random Walk
@export var creature: CreatureBattleUnit

const ROTATIONS: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5]

const DELTA_DIR := {
	Vector2i.UP: &"N",
	Vector2i.DOWN: &"S",
	Vector2i.RIGHT: &"E",
	Vector2i.LEFT: &"W",
}

const OPPOSITE := { &"N": &"S", &"S": &"N", &"E": &"W", &"W": &"E", }

const BIT_DIR := {
	TestMapGenerator.DOOR_N: &"N",
	TestMapGenerator.DOOR_S: &"S",
	TestMapGenerator.DOOR_E: &"E",
	TestMapGenerator.DOOR_W: &"W",
}

@export var block_scenes: Array[PackedScene]

var _catalog: Dictionary = {}
var _placed: Dictionary = {}
var _room_map: Dictionary = {}
var _visited_rooms: Dictionary = {}
var _origin: Vector2
var _current_room: Vector2i = Vector2i.ZERO
var _pending_room: Vector2i = Vector2i.ZERO
var _has_pending: bool = false
var _waypoints: Array[Marker2D] = []


func _ready() -> void:
	_establish_connections()
	_build_catalog()


func _build_catalog() -> void:
	_catalog.clear()
	for scene: PackedScene in block_scenes:
		var block := scene.instantiate() as RuinMapBlock
		for rotation_dir: float in ROTATIONS:
			block.rotation = rotation_dir
			var key := _key(block.anchor_directions())
			if not _catalog.has(key):
				_catalog[key] = {"scene": scene, "rotation": rotation_dir}
		block.free()


func assemble(room_map: Dictionary, container: Node2D) -> Dictionary:
	var placed: Dictionary = {}
	var start:Vector2i = Vector2i.ZERO
	if not room_map.has(start):
		push_warning("RuinBlockAssembler: no start room at ZERO")
		return placed
	placed[start] = _spawn(room_map[start], container)
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current_block: Vector2i = queue.pop_front()
		var parent_block: RuinMapBlock = placed[current_block]
		for delta: Vector2i in DELTA_DIR:
			var npos: Vector2i = current_block + delta
			if not room_map.has(npos) or placed.has(npos):
				continue
			var dir: StringName = DELTA_DIR[delta]
			var child_block := _spawn(room_map[npos], container)
			if child_block == null:
				continue
			_snap(parent_block, child_block, dir)
			placed[npos] = child_block
			queue.append(npos)
	_placed = placed
	_room_map = room_map
	_origin = placed[start].global_position
	_visited_rooms.clear()
	_current_room = start
	_has_pending = false
	_waypoints.clear()
	return placed


func _spawn(room:Room, container: Node2D) -> RuinMapBlock:
	var key := _key(_dirs_from_mask(room.doors))
	if not _catalog.has(key):
		push_warning("RuinBlockAssembler: Unmatched shape %s @ %s" % [key, room.grid_pos])
		return null
	var entry: Dictionary = _catalog[key]
	var block := (entry["scene"] as PackedScene).instantiate() as RuinMapBlock
	container.add_child(block)
	block.rotation = entry["rotation"]
	return block


func _snap(parent_block: RuinMapBlock, child_block: RuinMapBlock, dir:StringName) -> void:
	var parent_exit = parent_block.anchor_for_direction(dir)
	var child_entry = child_block.anchor_for_direction(OPPOSITE[dir])
	if parent_exit == null or child_entry == null:
		push_warning("RuinBlockAssembler: missing anchor for %s" % dir)
		return
	child_block.global_position += parent_exit.global_position - child_entry.global_position


func _dirs_from_mask(mask: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for bit: int in BIT_DIR:
		if mask & bit:
			out.append(BIT_DIR[bit])
	return out


func _key(dirs: Array[StringName]) -> String:
	var s: Array[String] = []
	for d: StringName in dirs:
		s.append(String(d))
	s.sort()
	return ",".join(s)

func _on_node_requested(creature_pos: Vector2) -> void:
	var new_nav_target: Node = _get_nav_target(creature_pos)
	if new_nav_target:
		creature.nav_target = new_nav_target


func _get_nav_target(creature_pos: Vector2) -> Node:
	if _placed.is_empty():
		push_warning("RuinBlockAssembler: No blocks to place!")
		return null
	if not _waypoints.is_empty():
		return _waypoints.pop_front()
	if _has_pending:
		_current_room = _pending_room
		_has_pending = false
	_visited_rooms[_current_room] = true

	# Step toward the nearest unvisited room in the array.
	var next_room := _first_step_to_unvisited(_current_room)
	if next_room == _current_room:
		push_warning("RuinBlockAssembler: Everything reachable is explored!")
		return null 

	var dir: StringName = DELTA_DIR[next_room - _current_room]
	var door: Marker2D = _placed[next_room].anchor_for_direction(OPPOSITE[dir])
	if door == null:
		return null
	_pending_room = next_room
	_has_pending = true

	# Route across the current block
	_waypoints = _plan_crossing(_current_room, creature_pos, door)
	return _waypoints.pop_front()


# Orders the current block's nav_points nearest-first from `from_pos`
func _plan_crossing(room_pos: Vector2i, from_pos: Vector2, door: Marker2D) -> Array[Marker2D]:
	var block: RuinMapBlock = _placed[room_pos]
	var remaining := block.nav_points.duplicate()
	var ordered: Array[Marker2D] = []
	var cursor := from_pos
	while not remaining.is_empty():
		var best_i := 0
		var best_d := INF
		for i in remaining.size():
			var d := cursor.distance_to(remaining[i].global_position)
			if d < best_d:
				best_d = d
				best_i = i
		var m: Marker2D = remaining[best_i]
		ordered.append(m)
		cursor = m.global_position
		remaining.remove_at(best_i)
	ordered.append(door)
	return ordered


#BFS from `start` over connected rooms; returns the neighbor of `start` to move
func _first_step_to_unvisited(start: Vector2i) -> Vector2i:
	var came_from: Dictionary = {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur != start and not _visited_rooms.has(cur):
			var step := cur
			while came_from[step] != start:
				step = came_from[step]
			return step
		for delta: Vector2i in DELTA_DIR:
			var n: Vector2i = cur + delta
			if not _room_map.has(n):  # adjacency == connectivity in this gen
				continue
			if came_from.has(n):
				continue
			came_from[n] = cur
			queue.append(n)
	return start

func _establish_connections() -> void:
	if creature:
		if not creature.navigation_node_requested.is_connected(_on_node_requested):
			creature.navigation_node_requested.connect(_on_node_requested)
