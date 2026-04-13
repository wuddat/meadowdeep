#enemy.gd
# Enemy creature in battle. Catching mechanics are removed entirely —
# MeadowDeep uses the egg system for creature acquisition, not catching.
class_name Enemy
extends Area2D

const ARROW_OFFSET := 20

@export var stats: EnemyStats : set = set_enemy_stats
@export var sprite_frames: SpriteFrames

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: Node = %StatsUI                          # Will become StatsUI once ported
@onready var intent_ui: Node = %IntentUI                        # Will become IntentUI once ported
@onready var animation_handler: Node = $AnimationHandler
@onready var name_container: Node = %NameContainer
@onready var unit_status_indicator: Node = %UnitStatusIndicator
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

# EnemyActionPicker and EnemyAction typed as Node until those systems are ported.
var enemy_action_picker: Node = null
var current_action: Node = null : set = set_current_action
var spawn_coords: Vector2

var is_asleep: bool = false
var is_confused: bool = false
var is_froze: bool = false
var skip_turn: bool = false
var has_slept: bool = false
var last_damage_taken: int = 0

var enemy_text_delay: float = 0.4


func _ready() -> void:
	await get_tree().process_frame

	if stats and stats.species_id != "" and stats.uid == "":
		var creature_data := CreatureData.get_creature_data(stats.species_id)
		if not creature_data.is_empty():
			stats.load_from_data(creature_data)
			if sprite_frames:
				animated_sprite_2d.sprite_frames = sprite_frames
				animated_sprite_2d.play("idle")
			setup_ai()
		else:
			push_warning("No creature data found for: " + stats.species_id)
	else:
		if stats:
			if sprite_frames:
				animated_sprite_2d.sprite_frames = sprite_frames
				animated_sprite_2d.play("idle")
		setup_ai()

	if intent_ui:
		if "parent" in intent_ui:
			intent_ui.set("parent", self)
		if "status_handler" in intent_ui:
			intent_ui.set("status_handler", status_handler)

	spawn_coords = global_position


func set_current_action(value: Node) -> void:
	current_action = value
	update_intent(current_action)


func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance() as EnemyStats
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
	update_enemy()


func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()

	if not stats:
		return
	if not stats.ai:
		stats.ai = load("res://creatures/enemy_action_picker.tscn")
	if not stats.ai:
		return

	var new_action_picker: Node = stats.ai.instantiate()
	add_child(new_action_picker)
	enemy_action_picker = new_action_picker
	if "enemy" in enemy_action_picker:
		enemy_action_picker.set("enemy", self)

	if enemy_action_picker.has_method("setup_actions_from_moves"):
		enemy_action_picker.setup_actions_from_moves(self, stats.move_ids)

	await get_tree().process_frame
	update_action()


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(stats)


func update_action() -> void:
	if not enemy_action_picker:
		return
	if not current_action:
		if enemy_action_picker.has_method("get_action"):
			current_action = enemy_action_picker.get_action()
		return

	if enemy_action_picker.has_method("get_first_conditional_action"):
		var new_conditional = enemy_action_picker.get_first_conditional_action()
		if new_conditional and current_action != new_conditional:
			current_action = new_conditional

	update_intent(current_action)


func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.art
	arrow.position = Vector2.UP * (sprite_2d.get_rect().size.y / 2 + ARROW_OFFSET)
	setup_ai()
	update_stats()


func update_intent(action: Node) -> void:
	await get_tree().process_frame
	if not current_action:
		return
	if current_action.has_method("update_intent_text"):
		current_action.update_intent_text()
	if intent_ui and intent_ui.has_method("update_intent"):
		intent_ui.update_intent(current_action)


func do_turn() -> void:
	if stats.health <= 0:
		Events.enemy_fainted.emit(self)
		return
	stats.block = 0
	if enemy_action_picker and enemy_action_picker.has_method("_on_party_shifted"):
		enemy_action_picker._on_party_shifted()
	await status_effect_checks()

	if skip_turn:
		skip_turn = false
		Events.enemy_action_completed.emit(self)
		return

	if not current_action:
		return

	if current_action.has_method("update_intent_text"):
		current_action.update_intent_text()
	if intent_ui and intent_ui.has_method("update_intent"):
		intent_ui.update_intent(current_action)

	var action_name: String = current_action.get("action_name") if "action_name" in current_action else "???"
	Events.battle_text_requested.emit("Enemy [color=red]%s[/color] used %s!" % [
		stats.species_id.capitalize(), action_name
	])
	await get_tree().create_timer(enemy_text_delay).timeout

	if current_action.has_method("perform_action"):
		current_action.perform_action()
	if enemy_action_picker and enemy_action_picker.has_method("select_valid_target"):
		enemy_action_picker.select_valid_target()

	if status_handler.has_status("seeded"):
		get_tree().create_timer(0.5).timeout
		var seeded := status_handler.get_status("seeded")
		Events.enemy_seeded.emit(seeded)


func status_effect_checks() -> void:
	if not status_handler.has_any_status() and not is_asleep and not is_confused:
		return

	if status_handler.has_status("flinched"):
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] flinched!" % stats.species_id.capitalize())
		await get_tree().create_timer(enemy_text_delay).timeout
		status_handler.remove_status("flinched")
		skip_turn = true

	if status_handler.has_status("froze"):
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is FROZEN!" % stats.species_id.capitalize())
		await get_tree().create_timer(enemy_text_delay).timeout
		status_handler.remove_status("froze")
		is_froze = false
		skip_turn = true

	if is_asleep:
		await get_tree().create_timer(1.0).timeout
		if RNG.instance.randf() < 0.4:
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is fast asleep..!" % stats.species_id.capitalize())
			await get_tree().create_timer(1.0).timeout
			has_slept = true
			skip_turn = true
			return
		else:
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] WOKE UP!" % stats.species_id.capitalize())
			has_slept = true
			is_asleep = false
			if unit_status_indicator and unit_status_indicator.has_method("update_status_display"):
				unit_status_indicator.update_status_display(self)
			await get_tree().create_timer(2.0).timeout

	if status_handler.has_status("paralyze"):
		await get_tree().create_timer(enemy_text_delay).timeout
		if RNG.instance.randf() < 0.25:
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is PARALYZED!" % stats.species_id.capitalize())
			skip_turn = true
			return

	if status_handler.has_status("confused"):
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is CONFUSED!" % stats.species_id.capitalize())
		await get_tree().create_timer(enemy_text_delay).timeout
		if enemy_action_picker and enemy_action_picker.has_method("select_confused_target"):
			enemy_action_picker.select_confused_target()
		is_confused = true
	else:
		is_confused = false


func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	last_damage_taken = 0

	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)

	if modified_damage > 0:
		if status_handler.has_status("rage"):
			var atkup_res = load("res://statuses/attack_up.tres")
			if atkup_res:
				var atkup = atkup_res.duplicate()
				atkup.stacks = 2
				var rage_effect = StatusEffect.new()
				rage_effect.source = self
				rage_effect.status = atkup
				rage_effect.execute([self])

		var combat_scene = load("res://scenes/ui/combat_text_label.tscn")
		if combat_scene:
			var dmg_text = combat_scene.instantiate()
			add_child(dmg_text)
			if dmg_text.has_method("show_text"):
				dmg_text.show_text("%s" % modified_damage)
		last_damage_taken = modified_damage

	var tween := create_tween()
	# Shaker.shake(self, 25, 0.15)  # TODO: Register Shaker autoload
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	update_intent(current_action)
	tween.finished.connect(func():
		if stats.health <= 0:
			Events.enemy_fainted.emit(self)
	)


func heal(amount: int) -> void:
	if stats:
		var health_before := stats.health
		stats.heal(amount)
		var actual_heal := stats.health - health_before
		if actual_heal > 0:
			var combat_scene = load("res://scenes/ui/combat_text_label.tscn")
			if combat_scene:
				var label = combat_scene.instantiate()
				add_child(label)
				if label.has_method("show_text"):
					label.show_text("+ %s HP" % amount, Color.GREEN)
	print("%s healed for %d!" % [stats.species_id, amount])


func gain_block(block: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	var modified_block := modifier_handler.get_modified_value(block, mod_type)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	tween.tween_property(self, "position", start + Vector2(0, -10), 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(stats.gain_block.bind(modified_block))
	tween.tween_interval(0.17)


func dodge_check() -> bool:
	if status_handler.has_status("dodge"):
		var dodge_stacks = status_handler.get_status_stacks("dodge")
		var dodge_chance = dodge_stacks * 0.1
		var dodge = status_handler.get_status("dodge")
		dodge.stacks -= 1
		if randf() < dodge_chance:
			Events.battle_text_requested.emit("%s was able to DODGE the attack!" % stats.species_id.capitalize())
			_play_dodge_tween()
			return true
	return false


func _play_dodge_tween() -> void:
	var start_pos := global_position
	var dodge_offset := Vector2.LEFT * 24
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", start_pos - dodge_offset, 0.1)
	var combat_scene = load("res://scenes/ui/combat_text_label.tscn")
	if combat_scene:
		var label = combat_scene.instantiate()
		add_child(label)
		if label.has_method("show_text"):
			label.show_text("DODGE!")
	tween.tween_property(self, "global_position", start_pos - dodge_offset, 0.5)
	tween.tween_property(self, "global_position", start_pos, 0.1)


func _on_mouse_entered() -> void:
	pass
	#if name_container:
		#name_container.show()


func _on_mouse_exited() -> void:
	pass
	#if name_container:
		#name_container.hide()
