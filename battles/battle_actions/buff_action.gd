class_name BuffAction
extends BattleAction

@export var buffs: Array[BuffDef] = []
@export var animation_string: String = ""
@export var min_duration: float = 0.35


func can_execute(user: BattleActor) -> bool:
	if buffs.is_empty():
		return false
	for buff in buffs:
		var mod := user.modifier_handler.get_modifier(buff.mod)
		if mod == null or mod.get_value(buff.source) == null:
			return true
	return false


func build_steps(_user: BattleActor) -> Array[Dictionary]:
	if buffs.is_empty():
		return []
	return [{
		"id": &"buff",
		"data": {
			"buffs": buffs,
			"animation_string": animation_string,
			"min_duration": min_duration,
		},
	}]
