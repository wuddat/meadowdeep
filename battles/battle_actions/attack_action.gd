class_name AttackAction
extends BattleAction

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
	return [{"id": &"strike", "data": {"target": t, "effects": hit_effects, "animation_string": animation_string, "min_duration": dur},  }]
