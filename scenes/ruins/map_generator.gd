class_name MapGenerator
extends Node

const ROOM_BASE := 20
const FLOOR_MOD := 2
const MAX_RADIUS := 25

const CARDINALS := [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

const ROOM_CONNECT_N := 1
const ROOM_CONNECT_S := 2
const ROOM_CONNECT_E := 4
const ROOM_CONNECT_W := 8

const ROOM_PIXEL_SPACING := Vector2(32, 32)
const SAFETY_LIMIT := 4000

enum FrontierSelection { NEWEST, RANDOM }

const SKELETON_ROOM_CONNECTS_PER_VISIT := 1
const SPRAWL_ROOM_CONNECTS_PER_VISIT := 4
const ROOM_CONNECTS_PER_VISIT_BY_PHASE := [SKELETON_ROOM_CONNECTS_PER_VISIT, SPRAWL_ROOM_CONNECTS_PER_VISIT]

const FRONTIER_SELECTION_BY_PHASE := [FrontierSelection.NEWEST, FrontierSelection.RANDOM]

const LOOP_FUSION_CHANCE := 0.12
const SKELETON_FRACTION_OF_TARGET := 0.35

const BLOB_NEIGHBOR_THRESHOLD := 3
const LOOP_NEIGHBOR_THRESHOLD := 2

const SKELETON_PHASE := 0
const SPRAWL_PHASE := 1

const COMBAT_WEIGHT := 100.0
const REST_SITE_WEIGHT := 0
const SHOP_WEIGHT := 0
const EVENT_WEIGHT := 0
const EGG_CHAMBER_WEIGHT := 0

@export var combat_only: bool = false
@export var encounter_pool: EncounterPool

var _random_room_weights: Dictionary = {}
var _total_weight := 0.0

var allowed_origin_dirs: Array[Vector2i] = []

var room_map: Dictionary = {}


func generate_floor(floor_num: int) -> Dictionary:
	room_map.clear()
	var target := ROOM_BASE + (floor_num - 1) * FLOOR_MOD
	_spider(target)
	_calc_doors()
	_calc_depths()
	_assign_room_types(floor_num)
	return room_map


func _spider(target: int) -> void:
	var start := Vector2i.ZERO
	room_map[start] = _make_room(start)

	var expandable_rooms: Array[Vector2i] = [start]
	var skeleton_room_target := int(target * SKELETON_FRACTION_OF_TARGET)
	var remaining_attempts := SAFETY_LIMIT

	while room_map.size() < target and remaining_attempts > 0:
		remaining_attempts -= 1

		var phase := SKELETON_PHASE if room_map.size() < skeleton_room_target else SPRAWL_PHASE
		var doors_to_open: int = ROOM_CONNECTS_PER_VISIT_BY_PHASE[phase]
		var selection_mode: int = FRONTIER_SELECTION_BY_PHASE[phase]

		if expandable_rooms.is_empty():
			expandable_rooms = _rooms_with_open_neighbor()
			if expandable_rooms.is_empty():
				break

		var expandable_room_index: int
		if selection_mode == FrontierSelection.NEWEST:
			expandable_room_index = expandable_rooms.size() - 1
		else:
			expandable_room_index = RNG.instance.randi_range(0, expandable_rooms.size() - 1)
		var current: Vector2i = expandable_rooms[expandable_room_index]

		var directions := CARDINALS.duplicate()
		directions.shuffle()
		var doors_opened := 0

		for direction: Vector2i in directions:
			if doors_opened >= doors_to_open:
				break
			var neighbor: Vector2i = current + direction
			if not _can_place(neighbor):
				continue
			room_map[neighbor] = _make_room(neighbor)
			expandable_rooms.append(neighbor)
			doors_opened += 1
			if room_map.size() >= target:
				break

		if doors_opened == 0:
			expandable_rooms.remove_at(expandable_room_index)


func _can_place(pos: Vector2i) -> bool:
	if room_map.has(pos):
		return false
	if abs(pos.x) + abs(pos.y) > MAX_RADIUS:
		return false
	if not allowed_origin_dirs.is_empty() and pos in CARDINALS and pos not in allowed_origin_dirs:
		return false
	var neighbor_count := _count_neighbors(pos)
	if neighbor_count >= BLOB_NEIGHBOR_THRESHOLD:
		return false
	if neighbor_count == LOOP_NEIGHBOR_THRESHOLD:
		return RNG.instance.randf() < LOOP_FUSION_CHANCE
	return true


func _rooms_with_open_neighbor() -> Array[Vector2i]:
	var rooms_with_room_to_grow: Array[Vector2i] = []
	for pos: Vector2i in room_map.keys():
		for direction: Vector2i in CARDINALS:
			var neighbor: Vector2i = pos + direction
			if room_map.has(neighbor):
				continue
			if abs(neighbor.x) + abs(neighbor.y) > MAX_RADIUS:
				continue
			if _count_neighbors(neighbor) <= 1:
				rooms_with_room_to_grow.append(pos)
				break
	return rooms_with_room_to_grow


func _make_room(grid_pos: Vector2i) -> Room:
	var room: Room = Room.new()
	room.grid_pos = grid_pos
	room.position = Vector2(grid_pos) * ROOM_PIXEL_SPACING
	room.next_rooms = []
	return room


func _count_neighbors(pos: Vector2i) -> int:
	var count:int = 0
	for dir in CARDINALS:
		if room_map.has(pos + dir):
			count += 1
	return count


func _calc_doors() -> void:
	for pos: Vector2i in room_map.keys():
		var room: Room = room_map[pos]
		var mask:int = 0
		if room_map.has(pos + Vector2i.UP):
			mask |= ROOM_CONNECT_N
			room.next_rooms.append(room_map[pos + Vector2i.UP])
		if room_map.has(pos + Vector2i.DOWN):
			mask |= ROOM_CONNECT_S
			room.next_rooms.append(room_map[pos + Vector2i.DOWN])
		if room_map.has(pos + Vector2i.RIGHT):
			mask |= ROOM_CONNECT_E
			room.next_rooms.append(room_map[pos + Vector2i.RIGHT])
		if room_map.has(pos + Vector2i.LEFT):
			mask |= ROOM_CONNECT_W
			room.next_rooms.append(room_map[pos + Vector2i.LEFT])
		room.doors = mask


func _calc_depths() -> void:
	var start: Vector2i = Vector2i.ZERO
	if not room_map.has(start):
		return
	var visited := {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var pos: Vector2i = frontier.pop_front()
		var d: int = visited[pos]
		room_map[pos].depth = d
		for dir in CARDINALS:
			var n: Vector2i = pos + dir
			if room_map.has(n) and not visited.has(n):
				visited[n] = d+ 1
				frontier.append(n)


func _assign_room_types(_floor_num: int) -> void:
	encounter_pool.setup()
	_setup_random_room_weights()

	# start room — left as NOT_ASSIGNED, identified by grid_pos == ZERO
	var start := Vector2i.ZERO
	room_map[start].tier = 0

	var terminals := _get_terminals()
	terminals.sort_custom(func(a: Room, b: Room) -> bool: return a.depth > b.depth)

	# deepest dead-end = boss
	if terminals.size() > 0:
		var boss_room: Room = terminals.pop_front()
		boss_room.type = Room.Type.BOSS
		boss_room.tier = 1
		boss_room.encounter = encounter_pool.get_boss_battle_for_tier(1)

	# next deepest = egg chamber
	if terminals.size() > 0:
		terminals.pop_front().type = Room.Type.EGG_CHAMBER

	# mid dead-end = treasure
	if terminals.size() > 0:
		var mid := terminals.size() / 2
		terminals.pop_at(mid).type = Room.Type.TREASURE

	# shallowest leftover dead-end = rest
	if terminals.size() > 0:
		terminals.pop_back().type = Room.Type.REST_SITE

	# fill remaining non-start rooms with combat
	for room: Room in room_map.values():
		if room.grid_pos == Vector2i.ZERO:
			continue
		if room.type != Room.Type.NOT_ASSIGNED:
			continue
		var t := Room.Type.COMBAT if combat_only else _get_random_room_type_by_weight()
		room.type = t
		var tier := 1 if room.depth > 4 else 0
		room.tier = tier
		if t == Room.Type.COMBAT:
			room.encounter = encounter_pool.get_wild_battle_for_tier(tier)

func _get_terminals() -> Array[Room]:
	var out: Array[Room] = []
	for room: Room in room_map.values():
		if room.grid_pos == Vector2i.ZERO:
			continue
		if _door_count(room.doors) == 1:
			out.append(room)
	return out

func _door_count(mask: int) -> int:
	var c: int = 0
	for bit in [ROOM_CONNECT_N, ROOM_CONNECT_S, ROOM_CONNECT_E, ROOM_CONNECT_W]:
		if mask & bit:
			c += 1
	return c


func _setup_random_room_weights() -> void:
	var cumulative := 0.0
	_random_room_weights = {}

	for entry in [
		[Room.Type.COMBAT,      COMBAT_WEIGHT],
		[Room.Type.REST_SITE,   REST_SITE_WEIGHT],
		[Room.Type.SHOP,        SHOP_WEIGHT],
		[Room.Type.EVENT,       EVENT_WEIGHT],
		[Room.Type.EGG_CHAMBER, EGG_CHAMBER_WEIGHT],
	]:
		cumulative += entry[1]
		_random_room_weights[entry[0]] = cumulative

	_total_weight = cumulative


func _get_random_room_type_by_weight() -> Room.Type:
	var roll := RNG.instance.randf_range(0.0, _total_weight)

	for type: Room.Type in _random_room_weights:
		if _random_room_weights[type] > roll:
			return type

	return Room.Type.COMBAT


# Useful for adjacency rules (e.g. no two rest sites touching).
# In BoI grid model "parent" = any connected neighbor.
func _room_has_parent_of_type(room: Room, type: Room.Type) -> bool:
	for dir in CARDINALS:
		var n: Vector2i = room.grid_pos + dir
		if room_map.has(n) and room_map[n].type == type:
			return true
	return false
