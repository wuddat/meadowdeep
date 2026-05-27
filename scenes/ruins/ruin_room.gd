class_name RuinRoom
extends Node2D

const DOOR = preload("uid://j0qtggfhqrak")
const COMBAT_START_DELAY: float = 0.75
const BATTLE_COLLIDER_LAYER: int = 8
const DOOR_SLAM = preload("uid://cfh2snlwrbn8s")
const RUINS_LOOP = preload("uid://c21qpja5wmsl1")


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
@onready var player_creature: CreatureBattleUnit = %PlayerCreature
@onready var battle_colliders: StaticBody2D = %BattleColliders
@onready var room_colliders: StaticBody2D = %RoomColliders
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var creature_combat_handler: CreatureCombatHandler = %CreatureCombatHandler
@onready var loot_handler: LootHandler = %LootHandler

var current_pos: Vector2i = Vector2i.ZERO
var visited: Dictionary = {}
var doors: Dictionary = {}  # &"N" -> Door
var _active_stats: PlayerData
var _active_combat_room: Room

func _ready() -> void:
	map_generator.generate_floor(1)
	_spawn_doors()
	_establish_connections()


func setup(stats: PlayerData) -> void:
	_active_stats = stats
	player.stats = _active_stats
	if not player_creature.is_node_ready():
		await player_creature.ready
	if _active_stats.ruins_creature:
		player_creature.instance = _active_stats.ruins_creature
	print("[RUINROOM] ruins_creature: ", _active_stats.ruins_creature)
	battle_colliders.collision_layer = 0
	room_colliders.collision_layer = BATTLE_COLLIDER_LAYER
	MusicPlayer.play(RUINS_LOOP)
	enter_room(Vector2i.ZERO)
	
func _establish_connections() -> void:
	Events.enemy_fainted.connect(_on_combat_progress)
	Events.player_died.connect(_on_player_died)

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
	print("[RuinRoom] enter_room pos=%s, room=%s, room_map_size=%d" % [pos, room, map_generator.room_map.size()])
	if room == null:
		push_warning("RuinRoom: no room at %s" % pos)
		return
	_update_current_room_info(room, pos)
	if from_direction != &"":
		_park_player_at(OPPOSITE[from_direction])
	if room.type in [Room.Type.COMBAT, Room.Type.BOSS] and not room.cleared:
		_start_room_combat(room)


func _update_current_room_info(room: Room, pos: Vector2i) -> void:
	current_pos = pos
	visited[pos] = true
	_refresh_label(room)
	refresh_doors(room)


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
	player_creature.position = door_pos + inward


func _start_room_combat(room: Room) -> void:
	for door in doors.values():
		if door.state == Door.State.OPEN:
			door.close()
	await get_tree().create_timer(.15).timeout
	SFXPlayer.play(DOOR_SLAM)
	Events.shake_camera_requested.emit()
			
	battle_colliders.collision_layer = BATTLE_COLLIDER_LAYER
	room_colliders.collision_layer = 0
	await get_tree().create_timer(COMBAT_START_DELAY).timeout
	enemy_handler.player_data = _active_stats
	enemy_handler.setup_enemies(room.encounter)
	loot_handler.generate_battle_loot()
	creature_combat_handler.start_combat([player_creature])
	enemy_handler.start_turn()
	_active_combat_room = room

func _finish_room_combat(victory: bool) -> void:
	creature_combat_handler.stop_combat()
	if victory and _active_combat_room.type != Room.Type.BOSS:
		battle_colliders.collision_layer = 0
		room_colliders.collision_layer = BATTLE_COLLIDER_LAYER
		_active_combat_room.cleared = true
		refresh_doors(_active_combat_room)
		_active_combat_room = null
		SFXPlayer.pitch_play(DOOR_SLAM,1.2,1.2)
		Events.shake_camera_requested.emit()
	else:
		Events.scene_transition_requested.emit("meadow")

func _on_door_entered(destination: Room, from_direction: StringName) -> void:
	enter_room(destination.grid_pos, from_direction)

func _on_player_died() -> void:
	print_rich("[color=red]POC defeat — frozen[/color]")
	var victory: bool = false
	_finish_room_combat(victory)

#ref battle.gd > _on_enemies_child_order_changed()
func _on_combat_progress(_enemy: Enemy) -> void:
	if not is_instance_valid(get_tree()):
		return
	await get_tree().create_timer(1).timeout
	if enemy_handler.get_child_count() == 0 and _active_combat_room != null:
		var victory: bool = true
		_finish_room_combat(victory)
		
