#battle.gd

class_name Battle
extends Control

@export var battle_stats: BattleStats
@export var char_stats: PlayerStats

@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var party_handler: PartyHandler = $PartyHandler
@onready var creature_combat_handler: CreatureCombatHandler = %CreatureCombatHandler

@export var stats_ui_scene: PackedScene

var stat_ui_by_uid: Dictionary = {}
var _battle_ended := false
var player_creature_nodes: Array[CreatureBattleUnit]


func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.player_died.connect(_on_player_died)
	Events.party_creature_fainted.connect(_on_party_creature_fainted)
	if char_stats.creatures.is_empty():
		char_stats = char_stats.create_instance()
	await initialize_battle()
	await battle_intro()
	start_battle()


func battle_intro() -> void:
	await get_tree().create_timer(3.0).timeout

func initialize_battle() -> void:
	get_tree().paused = false

	party_handler.character_stats = char_stats
	party_handler.stat_ui_by_uid = stat_ui_by_uid
	party_handler.finalize_battle_party(char_stats.creatures.slice(0, 3))
	await party_handler.initialize_party_for_battle()

	enemy_handler.char_stats = char_stats
	enemy_handler.setup_enemies(battle_stats)

	player_creature_nodes = party_handler.get_active_creature_nodes()


func start_battle() -> void:
	creature_combat_handler.start_combat(player_creature_nodes)
	enemy_handler.start_turn()


func _on_enemies_child_order_changed() -> void:
	if not is_instance_valid(get_tree()):
		return
	await get_tree().create_timer(1).timeout
	if enemy_handler.get_child_count() == 0:
		if _battle_ended:
			return
		_battle_ended = true
		creature_combat_handler.stop_combat()
		Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)


func _on_player_died() -> void:
	if _battle_ended:
		return
	_battle_ended = true
	creature_combat_handler.stop_combat()
	Events.battle_over_screen_requested.emit("Oh no!", BattleOverPanel.Type.LOSE)


func _on_party_creature_fainted(unit: CreatureBattleUnit) -> void:
	if unit and unit.is_inside_tree():
		unit.stop_combat()

	var fainted_count := 0
	for creature in char_stats.creatures:
		if creature.health <= 0:
			fainted_count += 1

	if fainted_count == char_stats.creatures.size():
		Events.player_died.emit()
