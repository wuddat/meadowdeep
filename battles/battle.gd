#battle.gd
# Main battle scene orchestrator.
# Evolution cutscene system stripped for Phase 0 — signals are wired but no UI plays.
# Mewtwo/boss-specific code removed entirely.
class_name Battle
extends Node2D

@export var battle_stats: BattleStats
@export var char_stats: ArchaeologistStats
@export var music: AudioStream
@export var battle_music: AudioStream

@onready var battle_ui: Node = $BattleUI               # Will become BattleUI once ported
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var archaeologist: Archaeologist = $Archaeologist
@onready var party_handler: PartyHandler = $PartyHandler
@onready var left_panel: VBoxContainer = $StatUI/LeftPanel

# Set to HealthBarUI.tscn in the editor once it's created.
@export var stats_ui_scene: PackedScene

var stat_ui_by_uid: Dictionary = {}


func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	Events.player_creature_switch_completed.connect(_update_stat_ui)
	Events.player_creature_switch_requested.connect(_hide_switch_ui)
	Events.party_creature_fainted.connect(_on_party_creature_fainted)
	Events.evolution_triggered.connect(_on_evolution_triggered)
	Events.evolution_completed.connect(_on_evolution_completed)


func start_battle() -> void:
	get_tree().paused = false

	if battle_ui and "char_stats" in battle_ui:
		battle_ui.set("char_stats", char_stats)

	archaeologist.stats = char_stats

	for creature in char_stats.current_party:
		creature.leveled_up_in_battle = false

	party_handler.character_stats = char_stats
	party_handler.stat_ui_by_uid = stat_ui_by_uid
	party_handler.finalize_battle_party(char_stats.current_party.slice(0, 3))
	party_handler.initialize_party_for_battle()

	initialize_stat_ui_for_party()

	enemy_handler.char_stats = char_stats
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	player_handler.start_battle(char_stats)

	if battle_ui and battle_ui.has_method("initialize_card_pile_ui"):
		battle_ui.initialize_card_pile_ui()


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
		# MusicPlayer.play(music, true)  # TODO: Register MusicPlayer autoload
		Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


func _on_player_died() -> void:
	Events.battle_over_screen_requested.emit("You Whited Out!", BattleOverPanel.Type.LOSE)
	# SaveData.delete_data()  # TODO: Port SaveData when save system is built


func _update_stat_ui(creature: CreatureStats) -> void:
	if not stat_ui_by_uid.has(creature.uid):
		return
	var ui = stat_ui_by_uid[creature.uid]
	if ui.has_method("update_stats"):
		ui.update_stats(creature)
	ui.modulate = Color(1, 1, 1, 1)
	if not creature.stats_changed.is_connected(_update_creature_stats_ui.bind(creature, ui)):
		creature.stats_changed.connect(_update_creature_stats_ui.bind(creature, ui))
	_update_creature_stats_ui(creature, ui)


func _hide_switch_ui(switch_out_uid: String, _switch_in_uid: String) -> void:
	if stat_ui_by_uid.has(switch_out_uid):
		stat_ui_by_uid[switch_out_uid].modulate = Color(1, 1, 1, 0.5)


func _on_party_creature_fainted(unit: CreatureBattleUnit) -> void:
	if unit and unit.is_inside_tree():
		unit.status_handler.clear_all_statuses()

	var fainted_count := 0
	for creature in char_stats.current_party:
		if creature.health <= 0:
			fainted_count += 1

	if fainted_count == char_stats.current_party.size():
		Events.player_died.emit()


# Evolution — Phase 0: no UI, just print and continue.
# TODO Phase 3: Wire up evolution cutscene and card-swap reward screen.
func _on_evolution_triggered(creature_stats: CreatureStats) -> void:
	print("Evolution triggered: %s → %s" % [creature_stats.species_id, creature_stats.evolves_to])


func _on_evolution_completed() -> void:
	print("Evolution completed.")
