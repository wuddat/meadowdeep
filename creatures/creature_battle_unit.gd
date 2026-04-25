#creature_battle_unit.gd
# The in-battle representation of a creature. One node per active creature on screen.
# Art/sound preloads are deferred until the art folder is populated.
class_name CreatureBattleUnit
extends Node2D

@export var stats: CreatureStats : set = set_creature_stats
@export var spawn_position: String
@export var sprite_frames: SpriteFrames

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats_ui: HBoxContainer = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var unit_status_indicator: Node = %UnitStatusIndicator  # Will become UnitStatusIndicator once ported
@onready var action_timer: Panel = %ActionTimer
@onready var action_name: Label = %ActionName

var health_bar_ui: Node = null
var _queued_health_bar_ui: Node = null

var skip_turn: bool = false
var has_slept: bool = false
var is_asleep: bool = false
var is_confused: bool = false
var is_froze: bool = false
var is_wild_creature: bool = false  # True for enemy-side creatures (was is_trainer_pkmn)
var last_damage_taken: int = 0

var battle_moves: Array[Card] = []
var _move_index: int = 0
var _action_timer: Timer = null
var _action_fill: ColorRect = null


func _ready() -> void:
	add_to_group("active_creatures")
	status_handler.status_owner = self
	status_handler.statuses_applied.connect(_on_statuses_applied)

	if not Events.enemy_seeded.is_connected(_on_enemy_seeded_turn_start):
		Events.enemy_seeded.connect(_on_enemy_seeded_turn_start)

	if not Events.evolution_completed.is_connected(_on_evolution_completed):
		Events.evolution_completed.connect(_on_evolution_completed)

	if _queued_health_bar_ui != null:
		set_health_bar_ui(_queued_health_bar_ui)


func start_combat() -> void:
	battle_moves.clear()
	_move_index = 0
	for move_id in stats.assigned_moves:
		var card := Utils.create_card(move_id)
		if card:
			battle_moves.append(card)

	if battle_moves.is_empty():
		push_warning("%s has no assigned moves — skipping combat timer" % stats.creature_name)
		return


	_action_timer = Timer.new()
	_action_timer.wait_time = stats.get_action_interval()
	_action_timer.autostart = true
	_action_timer.timeout.connect(_on_action_timer_timeout)
	add_child(_action_timer)
	_action_fill = action_timer.get_node("Fill")
	action_name.text = battle_moves[_move_index].name


func _process(_delta: float) -> void:
	if _action_timer and _action_fill and not _action_timer.is_stopped():
		var fill := 1.0 - (_action_timer.time_left / _action_timer.wait_time)
		_action_fill.size.x = action_timer.size.x * fill


func stop_combat() -> void:
	if _action_timer:
		_action_timer.stop()
		_action_timer.queue_free()
		_action_timer = null


func _on_action_timer_timeout() -> void:
	if stats.health <= 0 or battle_moves.is_empty():
		return
	var card: Card = battle_moves[_move_index]
	_move_index = (_move_index + 1) % battle_moves.size()
	Events.creature_action_started.emit(self, card)
	var preselected := _pick_targets(card)
	var resolved := card._get_targets(preselected, self)
	await card.apply_effects(resolved, modifier_handler, self)
	Events.creature_action_completed.emit(self)
	action_name.text = battle_moves[_move_index].name


func _pick_targets(card: Card) -> Array[Node]:
	match card.target:
		Card.Target.SINGLE_ENEMY, Card.Target.SPLASH:
			var enemies := get_tree().get_nodes_in_group("enemies")
			if enemies.is_empty():
				return []
			return [enemies[RNG.instance.randi() % enemies.size()]]
		Card.Target.SINGLE_ALLY:
			var allies: Array[Node] = get_tree().get_nodes_in_group("active_creatures")
			allies = allies.filter(func(a): return a != self and a.stats.health > 0)
			if allies.is_empty():
				return [self]
			return [allies[RNG.instance.randi() % allies.size()]]
		_:
			return []


func start_of_turn() -> void:
	stats.block = 0
	status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)
	if unit_status_indicator and unit_status_indicator.has_method("update_status_display"):
		unit_status_indicator.update_status_display(self)


func _on_evolution_completed() -> void:
	Utils.print_resource(self.stats)


func set_creature_stats(value: CreatureStats) -> void:
	stats = value
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	update_creature()


func update_creature() -> void:
	if not stats is CreatureStats: return
	if not is_inside_tree(): await ready
	var frames_to_use: SpriteFrames = stats.frames if stats.frames else sprite_frames
	if frames_to_use:
		animated_sprite_2d.sprite_frames = frames_to_use
		animated_sprite_2d.play("idle")
	update_stats()

func play_animation(anim_name: StringName) -> void:
	if animated_sprite_2d and animated_sprite_2d.sprite_frames:
		if animated_sprite_2d.sprite_frames.has_animation(anim_name):
			animated_sprite_2d.play(anim_name)

func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(stats)


func gain_block(block: int, _mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	var up_position := start + Vector2(0, -10)
	tween.tween_property(self, "position", up_position, 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(stats.gain_block.bind(block))
	tween.tween_interval(0.17)


func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0: return
	last_damage_taken = 0

	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)

	if modified_damage > 0 and status_handler.has_status("rage"):
		var atkup_res = load("res://statuses/attack_up.tres")
		if atkup_res:
			var atkup = atkup_res.duplicate()
			atkup.stacks = 2
			var rage_effect = StatusEffect.new()
			rage_effect.source = self
			rage_effect.status = atkup
			rage_effect.execute([self])

	var tween := create_tween()
	# Shaker.shake(self, 25, 0.15)  # TODO: Register Shaker autoload
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)

	if modified_damage > 0:
		show_combat_text("%s" % modified_damage)
		last_damage_taken = modified_damage

	tween.finished.connect(func():
		if stats.health <= 0:
			Events.party_creature_fainted.emit(self)
			hide()
	)


func heal(amount: int) -> void:
	if stats:
		var health_before := stats.health
		stats.heal(amount)
		var actual_heal := stats.health - health_before
		if actual_heal > 0:
			show_combat_text("+ %s HP" % amount, Color.GREEN)
	print("%s healed for %d!" % [stats.species_id, amount])


func set_health_bar_ui(ui: Node) -> void:
	if is_inside_tree() and is_instance_valid(status_handler):
		health_bar_ui = ui
		if "status_container" in ui:
			status_handler.set_status_ui_container(ui.get("status_container"))
	else:
		_queued_health_bar_ui = ui


func _on_statuses_applied(type: Status.Type) -> void:
	if type == Status.Type.START_OF_TURN:
		Events.player_creature_start_status_applied.emit(self)
		if unit_status_indicator and unit_status_indicator.has_method("update_status_display"):
			unit_status_indicator.update_status_display(self)
	elif type == Status.Type.END_OF_TURN:
		Events.player_creature_end_status_applied.emit(self)
		if unit_status_indicator and unit_status_indicator.has_method("update_status_display"):
			unit_status_indicator.update_status_display(self)


func _on_enemy_seeded_turn_start(seeded: Status) -> void:
	heal(seeded.heal_strength)


func on_enemy_defeated(enemy: Enemy) -> void:
	if stats.health <= 0:
		return
	var xp := enemy.stats.max_health
	stats.current_exp += xp
	print("Enemy defeated: %s | Gained EXP: %s" % [enemy.stats.species_id, xp])
	show_combat_text("EXP: %s" % xp, Color.WHITE, "quick_rise")

	await get_tree().create_timer(0.4).timeout

	var level_up_exp := stats.get_xp_for_next_level(stats.level)
	if stats.current_exp >= level_up_exp:
		if not stats.leveled_up_in_battle:
			stats.leveled_up_in_battle = true
			Events.add_leveled_creature_to_rewards.emit(stats)
		stats.level += 1
		stats.max_health += stats.level
		stats.health += stats.level
		show_combat_text("LEVEL UP!", Color.WHITE, "quick_rise")
		# SFXPlayer.pitch_play(LVL_UP)  # TODO: Register SFXPlayer autoload
		if stats.level >= stats.evolution_level:
			Events.evolution_triggered.emit(stats)

	await get_tree().process_frame
	if get_parent().has_node("EnemyHandler"):
		var enemy_handler = get_parent().get_node("EnemyHandler")
		if enemy_handler.get_child_count() == 0:
			await get_tree().process_frame
			await get_tree().create_timer(0.2).timeout


func dodge_check() -> bool:
	if status_handler.has_status("dodge"):
		var dodge_stacks = status_handler.get_status_stacks("dodge")
		var dodge_chance = dodge_stacks * 0.1
		var dodge_outcome = RNG.instance.randf()
		var dodge = status_handler.get_status("dodge")
		dodge.stacks -= 1
		if dodge_outcome < dodge_chance:
			Events.battle_text_requested.emit("%s was able to DODGE the attack!" % stats.species_id.capitalize())
			_play_dodge_tween()
			return true
	return false


func _play_dodge_tween() -> void:
	var start_pos := global_position
	var dodge_offset := Vector2.RIGHT * 24
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", start_pos - dodge_offset, 0.1)
	show_combat_text("DODGE!", Color.WHITE, "quick_rise")
	# SFXPlayer.pitch_play(DODGE)  # TODO: Register SFXPlayer autoload
	tween.tween_property(self, "global_position", start_pos - dodge_offset, 0.5)
	tween.tween_property(self, "global_position", start_pos, 0.1)


func show_combat_text(text: String, color: Color = Color.WHITE, animation: String = "rise_and_fade") -> void:
	var scene = load("uid://dixq55fwxr3b6")
	if not scene:
		return
	var label = scene.instantiate()
	add_child(label)
	if label.has_method("show_text"):
		label.show_text(text, color, animation)


func get_tooltip_data() -> Dictionary:
	return {
		"header": "",
		"description": "Health: %s/%s\nExp: %s/%s" % [
			stats.health, stats.max_health,
			stats.current_exp, stats.get_xp_for_next_level(stats.level)
		]
	}


func _on_mouse_entered() -> void:
	if has_node("%NameContainer"):
		get_node("%NameContainer").show()


func _on_mouse_exited() -> void:
	if has_node("%NameContainer"):
		get_node("%NameContainer").hide()
