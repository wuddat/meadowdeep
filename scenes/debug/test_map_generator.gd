class_name TestMapGenerator
extends Node

const ROOM_BASE := 500
const FLOOR_MOD := 2
const MAX_RADIUS := 25

const CARDINALS := [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

const DOOR_N := 1
const DOOR_S := 2
const DOOR_E := 4
const DOOR_W := 8

const ROOM_PIXEL_SPACING := Vector2(32, 32)
const SAFETY_CONST := 500

const COMBAT_WEIGHT := 100.0
const REST_SITE_WEIGHT := 0
const SHOP_WEIGHT := 0
const EVENT_WEIGHT := 0
const EGG_CHAMBER_WEIGHT := 0

@export var encounter_pool: EncounterPool

var _random_room_weights: Dictionary = {}
var _total_weight := 0.0

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

	var start_door_count := RNG.instance.randi_range(1, 3)
	var seed_dirs := CARDINALS.duplicate()
	seed_dirs.shuffle()
	var queue: Array[Vector2i] = []
	var seeded := 0
	for dir: Vector2i in seed_dirs:
		if seeded >= start_door_count or room_map.size() >= target:
			break
		var n: Vector2i = start + dir
		room_map[n] = _make_room(n)
		queue.append(n)
		seeded += 1

	var safety := SAFETY_CONST
	while room_map.size() < target and not queue.is_empty() and safety > 0:
		safety -= 1
		var current: Vector2i = queue[RNG.instance.randi_range(0, queue.size() - 1)]
		var dirs := CARDINALS.duplicate()
		dirs.shuffle()

		var expanded: bool = false
		for dir: Vector2i in dirs:
			var neighbor: Vector2i = current + dir
			if room_map.has(neighbor):
				continue
			if abs(neighbor.x) + abs(neighbor.y) > MAX_RADIUS:
				continue
			#count neighbors inc current (<=1 means no OTHER rooms touch)
			if _count_neighbors(neighbor) > 1:
				continue
			room_map[neighbor] = _make_room(neighbor)
			queue.append(neighbor)
			expanded = true
			if room_map.size() >= target:
				return
		#no parent options, kill
		if not expanded:
			queue.erase(current)


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
			mask |= DOOR_N
			room.next_rooms.append(room_map[pos + Vector2i.UP])
		if room_map.has(pos + Vector2i.DOWN):
			mask |= DOOR_S
			room.next_rooms.append(room_map[pos + Vector2i.DOWN])
		if room_map.has(pos + Vector2i.RIGHT):
			mask |= DOOR_E
			room.next_rooms.append(room_map[pos + Vector2i.RIGHT])
		if room_map.has(pos + Vector2i.LEFT):
			mask |= DOOR_W
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
	if encounter_pool:
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
		var t := Room.Type.COMBAT
		room.type = t
		var tier := 1 if room.depth > 4 else 0
		room.tier = tier
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
	for bit in [DOOR_N, DOOR_S, DOOR_E, DOOR_W]:
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
