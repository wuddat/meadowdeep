# status.gd
extends Card

func get_default_tooltip() -> String:
	if tooltip_text.find("%") != -1:
		return tooltip_text % str(base_power)
	else:
		return tooltip_text


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler, _targets: Array[Node]) -> String:
	if tooltip_text.find("%") != -1:
		return tooltip_text % "0"
	else:
		return tooltip_text


func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: CreatureBattleUnit) -> void:
	if targets.is_empty():
		return

	var move_data = MoveData.moves.get(id)
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return

	var primary_target = targets[0]
	if not is_instance_valid(primary_target):
		return

	if primary_target.has_method("dodge_check") and primary_target.dodge_check():
		return

	EffectExecutor.execute_status_effects(status_effects, targets, battle_unit_owner, effect_chance, sound)

	if shift_enabled > 0:
		EffectExecutor.execute_shift(targets, battle_unit_owner, shift_enabled)

	EffectExecutor.execute_self_effects(
		battle_unit_owner,
		self_damage,
		self_damage_percent_hp,
		self_heal,
		self_block,
		self_status,
		modifiers,
		0
	)
