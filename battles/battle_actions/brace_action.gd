class_name BraceAction
extends BattleAction

@export var duration: float = 1.0


func can_execute(_user: BattleActor) -> bool:
	return true


func execute_action(user: BattleActor) -> void:
	var brace := BraceEffect.new()
	brace.duration = duration
	EffectExecutor.run([brace], [user], user)
