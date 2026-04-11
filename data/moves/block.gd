# block.gd
extends Card

func get_default_tooltip() -> String:
	return tooltip_text % base_power


func get_updated_tooltip(player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler, _targets: Array[Node]) -> String:
	var mod_block := player_modifiers.get_modified_value(base_power, Modifier.Type.BLOCK_GAINED)
	if mod_block <= 0:
		mod_block = 0

	return tooltip_text % mod_block


func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: CreatureBattleUnit) -> void:
	var move_data = MoveData.moves.get(id)
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return

	EffectExecutor.execute_block(base_power, targets, battle_unit_owner, modifiers, sound)

	EffectExecutor.execute_status_effects(status_effects, targets, battle_unit_owner, effect_chance)

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

	emit_dialogue(["%s used %s!" % [battle_unit_owner.stats.species_id.capitalize(), name]])
