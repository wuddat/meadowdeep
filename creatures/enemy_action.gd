class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0
@export var action_name: String
@export var intent_type: String
@export var script_type: String

@onready var accumulated_weight := 0.0

var enemy
var target: Node
var targets = []


func is_performable() -> bool:
	return false


func perform_action() -> void:
	pass


func animate_to_targets(
	targets_to_hit: Array[Node],
	index: int,
	total_damage: int,
	splash_damage: int,
	status_effects: Array[Status],
	self_damage: int,
	self_heal: int,
	self_status: Array[Status],
	enemy_ref,
	damage_type: String,
	shift_enabled: int
) -> void:
	if index >= targets_to_hit.size():
		_execute_self_effects(enemy_ref, total_damage, self_damage, self_heal, self_status)
		Events.enemy_action_completed.emit(enemy_ref)
		return

	target = targets_to_hit[index]
	if not is_instance_valid(target):
		animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy_ref, damage_type, shift_enabled)
		return

	if target.stats.health > 0:
		var start_pos = enemy_ref.global_position
		var end_pos = target.global_position + Vector2.RIGHT * 32 if total_damage > 0 else enemy_ref.global_position + Vector2.LEFT * 32

		var tween := create_tween().set_trans(Tween.TRANS_QUINT)
		tween.tween_property(enemy_ref, "global_position", end_pos, 0.3)

		if target.has_method("dodge_check") and target.dodge_check():
			tween.tween_interval(0.2)
			tween.tween_property(enemy_ref, "global_position", start_pos, 0.3)
			tween.finished.connect(func():
				animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy_ref, damage_type, shift_enabled)
			)
		else:
			if target.stats.health > 0:
				var dmg := DamageEffect.new()
				if script_type != "status":
					var mult := TypeChart.get_multiplier(damage_type, target.stats.type)
					dmg.amount = round(total_damage * mult)
					dmg.sound = sound
				tween.tween_callback(func():
					if script_type != "status" and dmg.amount > 0:
						dmg.execute([target])
					if shift_enabled > 0:
						var handler = enemy_ref.get_tree().get_first_node_in_group("enemy_handler")
						if handler:
							handler.call_deferred("shift_enemies")
					if splash_damage > 0:
						for splash_target in targets_to_hit:
							if splash_target != target:
								var splash := DamageEffect.new()
								splash.amount = splash_damage
								splash.execute([splash_target])
					for status in status_effects:
						if status:
							var stat := StatusEffect.new()
							stat.source = enemy_ref
							stat.status = status.duplicate()
							stat.sound = sound
							stat.execute([target])
				)
			tween.tween_interval(0.2)
			tween.tween_property(enemy_ref, "global_position", start_pos, 0.3)
			tween.finished.connect(func():
				animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy_ref, damage_type, shift_enabled)
			)


func _execute_self_effects(enemy_ref, total_damage: int, self_damage: int, self_heal: int, self_status: Array[Status]) -> void:
	if self_damage > 0:
		var recoil := DamageEffect.new()
		recoil.amount = self_damage
		recoil.execute([enemy_ref])
	if self_heal > 0:
		var heal := HealEffect.new()
		heal.amount = round(total_damage / 2.0)
		heal.execute([enemy_ref])
	for effect in self_status:
		if effect:
			var status := StatusEffect.new()
			status.source = enemy_ref
			status.status = effect.duplicate()
			status.execute([enemy_ref])
