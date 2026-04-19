#battle.gd
# Main battle scene orchestrator.
# Evolution cutscene system stripped for Phase 0 — signals are wired but no UI plays.
# Mewtwo/boss-specific code removed entirely.
class_name Battle
extends Control

@export var battle_stats: BattleStats
@export var char_stats: PlayerStats

@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var party_handler: PartyHandler = $PartyHandler
@onready var creature_combat_handler: CreatureCombatHandler = %CreatureCombatHandler
@onready var left_panel: VBoxContainer = $StatUI/LeftPanel

@export var stats_ui_scene: PackedScene

var stat_ui_by_uid: Dictionary = {}
var _battle_ended := false


func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.player_died.connect(_on_player_died)
	Events.party_creature_fainted.connect(_on_party_creature_fainted)
	Events.evolution_triggered.connect(_on_evolution_triggered)
	Events.evolution_completed.connect(_on_evolution_completed)
	if char_stats.current_party.is_empty():
		char_stats = char_stats.create_instance()
	start_battle()


func start_battle() -> void:
	get_tree().paused = false

	for creature in char_stats.current_party:
		creature.leveled_up_in_battle = false


	party_handler.character_stats = char_stats
	party_handler.stat_ui_by_uid = stat_ui_by_uid
	party_handler.finalize_battle_party(char_stats.current_party.slice(0, 3))
	await party_handler.initialize_party_for_battle()

	initialize_stat_ui_for_party()

	enemy_handler.char_stats = char_stats
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	var units := party_handler.get_active_creature_nodes()
	creature_combat_handler.start_combat(units)
	enemy_handler.start_turn()


func initialize_stat_ui_for_party() -> void:
	if not stats_ui_scene:
		return

	var active_creatures := party_handler.get_active_creatures()
	var seen_uids: Array[String] = []

	for creature in char_stats.current_party:
		seen_uids.append(creature.uid)

		var ui: Node
		if stat_ui_by_uid.has(creature.uid):
			ui = stat_ui_by_uid[creature.uid]
		else:
			ui = stats_ui_scene.instantiate()
			left_panel.add_child(ui)
			stat_ui_by_uid[creature.uid] = ui

		if ui.has_method("update_stats"):
			ui.update_stats(creature)

		if not creature.stats_changed.is_connected(_update_creature_stats_ui.bind(creature, ui)):
			creature.stats_changed.connect(_update_creature_stats_ui.bind(creature, ui))

		ui.visible = true
		ui.modulate = Color(1, 1, 1, 0.5)

	for creature in active_creatures:
		if stat_ui_by_uid.has(creature.uid):
			stat_ui_by_uid[creature.uid].modulate = Color(1, 1, 1, 1)

	for uid in stat_ui_by_uid.keys():
		if not seen_uids.has(uid):
			stat_ui_by_uid[uid].queue_free()
			stat_ui_by_uid.erase(uid)


func _update_creature_stats_ui(creature: CreatureStats, ui: Node) -> void:
	if ui and ui.has_method("update_stats"):
		ui.update_stats(creature)


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
		unit.status_handler.clear_all_statuses()
		unit.stop_combat()

	var fainted_count := 0
	for creature in char_stats.current_party:
		if creature.health <= 0:
			fainted_count += 1

	if fainted_count == char_stats.current_party.size():
		Events.player_died.emit()


func _on_evolution_triggered(creature_stats: CreatureStats) -> void:
	print("Evolution triggered: %s → %s" % [creature_stats.species_id, creature_stats.evolves_to])


func _on_evolution_completed() -> void:
	print("Evolution completed.")
