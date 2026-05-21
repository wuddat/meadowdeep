class_name AttackAction
extends BattleAction

enum Stat_type {NONE, PWR, AGI, RES, MYS, FOC}

@export var stat_scale_type: Stat_type = Stat_type.NONE
@export var stat_scale_val: float = 1.0
@export var max_range: float = 32.0
@export var hit_effects: Array[Effect]
@export var animation_string: String = ""


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	return target != null and range_check(user, target, max_range)


func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null: return []
	var dur: float = 0.0
	if user.creature_animation_handler and animation_string != "":
		var anim := user.creature_animation_handler.get_animation(animation_string)
		if anim: dur = anim.length
	var bonus: int = 0
	if stat_scale_type:
		var stat_name:String = CreatureData.STAT_NAMES.get(stat_scale_type, "")
		if user.instance and user.instance.identity:
			var user_stat := user.instance.identity.get(stat_name) as GrowthStat
			if user_stat:
				bonus = int(user_stat.get_combat_mod() * stat_scale_val)
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

	return [{"id": &"strike", "data": {"target": t, "effects": final_effects, "animation_string": animation_string, "min_duration": dur},  }]
