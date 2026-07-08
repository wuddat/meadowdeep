class_name RuinsManager
extends Node2D


@export var generator: MapGenerator
@export var assembler: RuinMapAssembler
@export var maze: Node2D
@onready var player: CharacterBody2D = %PlayerModel
@onready var creature: CreatureBattleUnit = %PlayerCreature
@onready var bond_radius: CollisionShape2D = %BondRadiusCollider
@onready var creature_combat_handler: CreatureCombatHandler = %CreatureCombatHandler
@onready var enemy_handler: EnemyHandler = %EnemyHandler
@onready var loot_handler: LootHandler = %LootHandler

var _test_combat: bool = false
var _current_block: RuinMapBlock = null
var _active_stats: PlayerData

const PARTICLES = preload("res://effects/particles.tscn")
const RUINS_LOOP = preload("uid://c21qpja5wmsl1")


func _ready() -> void:
	generator.allowed_origin_dirs = assembler.origin_anchor_dirs()
	var room_map: Dictionary = generator.generate_floor(1)
	#for room: Room in room_map.values():
		#print(room._to_string())
	var placed: Dictionary = assembler.assemble(room_map, maze)
	for block: RuinMapBlock in placed.values():
		if block.room.type in [Room.Type.COMBAT, Room.Type.BOSS]:
			block.combat_triggered.connect(_on_combat_triggered)
	_establish_connections()
	_park_player_at_start(placed)
	#MusicPlayer.play(RUINS_LOOP)


func _physics_process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.camera_target_requested.emit(player)
	if event.is_action_pressed("right_mouse"):
		Events.camera_target_requested.emit(creature)
		

func setup(stats: PlayerData) -> void:
	_active_stats = stats
	player.stats = _active_stats
	if not creature.is_node_ready():
		await creature.ready
	if _active_stats.ruins_creature:
		creature.instance = _active_stats.ruins_creature

func _set_creature_state(new_state: String) -> void:
	creature.set_state(new_state)
	print("CreatureState set to: %s" % new_state)

func _test_generation() -> void:
	for child in maze.get_children():
		child.queue_free()
	generator.allowed_origin_dirs = assembler.origin_anchor_dirs()
	var room_map: Dictionary = generator.generate_floor(1)
	#for room: Room in room_map.values():
		#print(room._to_string())
	var placed: Dictionary = assembler.assemble(room_map, maze)

func _test_combat_toggle() -> void:
	if not _test_combat:
		creature.start_combat()
		_test_combat = true
	else:
		creature.stop_combat()
		_test_combat = false


func _park_player_at_start(placed: Dictionary) -> void:
	var start: RuinMapBlock = placed.get(Vector2i.ZERO)
	if start == null:
		push_warning("TESTGENERATOR: NO START BLOCK PLACED")
		return
	var spawn_pos := start.global_position
	if not start.attach_points.is_empty():
		spawn_pos = start.nav_points[0].global_position
	player.global_position = spawn_pos
	creature.global_position = spawn_pos


func _on_combat_triggered(block: RuinMapBlock) -> void:
	var enemy_spawn_points:Array[Vector2] = []
	for nav_point in block.nav_points:
		enemy_spawn_points.append(nav_point.global_position)
	enemy_handler.setup_enemies(block.room.encounter, enemy_spawn_points)
	loot_handler.generate_battle_loot()
	_current_block = block
	creature.set_state("combat")
	creature_combat_handler.start_combat([creature])
	enemy_handler.start_combat()




func _check_battle_progress(_enemy: Enemy) -> void:
	await get_tree().create_timer(1).timeout
	if not enemy_handler.get_children().is_empty() or _current_block == null:
		return
	# Snapshot + clear up front so a second faint can't re-enter and double-pop the reward UI.
	var block := _current_block
	_current_block = null
	block.room.cleared = true
	enemy_handler._in_combat = false
	if block.room.type != Room.Type.BOSS:
		Events.reward_ui_requested.emit()
		await Events.reward_ui_dismissed
	creature.set_state("follow")

func _establish_connections() -> void:
	Events.enemy_fainted.connect(_check_battle_progress)
