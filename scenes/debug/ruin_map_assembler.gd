class_name RuinMapAssembler
extends Node

#If you forget the systems you used for generation and creature pathing look up:
#BFS (Breadth First Search)
#Random Walk
@export var creature: CreatureBattleUnit
@export var start_block: PackedScene
const ORIGIN := Vector2i.ZERO

const DELTA_DIR := {
	Vector2i.UP: &"N",
	Vector2i.DOWN: &"S",
	Vector2i.RIGHT: &"E",
	Vector2i.LEFT: &"W",
}

const OPPOSITE := { &"N": &"S", &"S": &"N", &"E": &"W", &"W": &"E", }

const BIT_DIR := {
	MapGenerator.ROOM_CONNECT_N: &"N",
	MapGenerator.ROOM_CONNECT_S: &"S",
	MapGenerator.ROOM_CONNECT_E: &"E",
	MapGenerator.ROOM_CONNECT_W: &"W",
}

@export var block_scenes: Array[PackedScene]
@export var chest_loot_table: LootTable

const CHEST_SCENE := preload("uid://c3edij8wnfsgp")

var _catalog: Dictionary = {}
var _placed: Dictionary = {}
var _room_map: Dictionary = {}
var _visited_rooms: Dictionary = {}
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
		var key := _key(block.anchor_directions())
		if _catalog.has(key):
			push_warning("RuinBlockAssembler: duplicate shape %s — %s ignored" % [key, scene.resource_path])
		else:
			_catalog[key] = scene
		block.free()


func assemble(room_map: Dictionary, container: Node2D) -> Dictionary:
	var placed: Dictionary = {}
	var start:Vector2i = Vector2i.ZERO
	if not room_map.has(start):
		push_warning("RuinBlockAssembler: no start room at ZERO")
		return placed
	_validate_map_shapes(room_map)
	placed[start] = _spawn_start(room_map[start], container)
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
	return _build_block(_catalog[key] as PackedScene, room, container)


# Origin always uses the exported start_block scene, ignoring shape-matching.
# Still validates its attach points cover the room's generated doors, so
# neighbors snap correctly (the invariant the catalog normally guarantees).
func _spawn_start(room:Room, container: Node2D) -> RuinMapBlock:
	if start_block == null:
		push_warning("RuinBlockAssembler: start_block unset — falling back to catalog")
		return _spawn(room, container)
	var block := _build_block(start_block, room, container)
	var anchors := block.anchor_directions()
	for door: StringName in _dirs_from_mask(room.doors):
		if door not in anchors:
			push_warning("RuinBlockAssembler: origin door %s has no start_block anchor — neighbor won't snap" % door)
	return block


func origin_anchor_dirs() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if start_block == null:
		return out
	var block := start_block.instantiate() as RuinMapBlock
	var anchors := block.anchor_directions()
	for delta: Vector2i in DELTA_DIR:
		if DELTA_DIR[delta] in anchors:
			out.append(delta)
	block.free()
	return out


func _build_block(scene: PackedScene, room:Room, container: Node2D) -> RuinMapBlock:
	var block:RuinMapBlock = scene.instantiate() as RuinMapBlock
	container.add_child(block)
	block.room = room
	_add_chest(block)
	return block


#TEST Drops a chest at the block's local origin (0,0) — the room center.
#TODO Placeholder for testing, will add proper coord generation
func _add_chest(block: RuinMapBlock) -> void:
	var chest: Chest = CHEST_SCENE.instantiate()
	chest.loot_table = chest_loot_table
	block.add_child(chest)
	chest.position = Vector2.ZERO


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

func _validate_map_shapes(room_map: Dictionary) -> void:
	for pos: Vector2i in room_map:
		var room: Room = room_map[pos]
		if pos == Vector2i.ZERO:
			continue
		var key := _key(_dirs_from_mask(room.doors))
		if not _catalog.has(key):
			push_error("[RUINASSEMBLER]: No block for shape '%s' at %s" % [key,pos])

func _establish_connections() -> void:
	if creature:
		if not creature.navigation_node_requested.is_connected(_on_node_requested):
			creature.navigation_node_requested.connect(_on_node_requested)
