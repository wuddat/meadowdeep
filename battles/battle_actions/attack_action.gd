class_name AttackAction
extends BattleAction

enum Stat_type {PWR, AGI, RES, MYS, FOC}

@export var stat_scaling: bool = false
@export var stat_scale_type: GrowthStat.StatType
@export var stat_scale_val: float = 1.0
@export var max_range: float = 32.0
@export var hit_effects: Array[Effect]
@export var aoe_radius: float = 0.0
@export var animation_string: String = ""


func can_execute(user: BattleActor) -> bool:
	if aoe_radius <= 0.0:
		var target := find_nearest_opponent(user)
		return target != null and range_check(user, target, max_range)
	else:
		var targets := find_opponents_in_radius(user, aoe_radius)
		return targets != []

func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t: Array[Node] = []
	if aoe_radius > 0.0:
		t = find_opponents_in_radius(user, aoe_radius)
	else:
		var nearest := find_nearest_opponent(user)
		if nearest: t.append(nearest)
	if t.is_empty(): return []
	var dur: float = 0.0
	if user.creature_animation_handler and animation_string != "":
		var anim := user.creature_animation_handler.get_animation(animation_string)
		if anim: dur = anim.length
	var bonus: int = 0
	if stat_scaling:
		var stat_name:String = CreatureData.STAT_NAMES.get(stat_scale_type, "")
		if user.instance and user.instance.identity:
			var user_stat := user.instance.identity.get(stat_name) as GrowthStat
			var stat_mod := user.modifier_handler.get_modifier(Modifier.Type.STAT_MOD)
			if user_stat:
				var base_dam: int
				for effect in hit_effects:
					if effect is DamageEffect:
						base_dam = effect.amount
				#print("[ATTACKACTION] %s: base: %s, lvl: %s, mod: %s" % [stat_name, base_dam, user_stat.get_combat_mod(), (stat_mod.get_modified_value(user_stat.get_combat_mod())-user_stat.get_combat_mod())])
				bonus = int(stat_mod.get_modified_value(user_stat.get_combat_mod(), stat_name) * stat_scale_val)
	var final_effects: Array[Effect] = []
	if bonus != 0:
		for effect in hit_effects:
			if effect is DamageEffect:
				var new_damage_effect: DamageEffect = effect.duplicate()
				new_damage_effect.amount += bonus
				final_effects.append(new_damage_effect)
			else:
				final_effects.append(effect)
	else:
		final_effects = hit_effects

	return [{"id": &"strike", "data": {"target": t, "effects": final_effects, "animation_string": animation_string, "min_duration": dur, "aoe_radius": aoe_radius},  }]
