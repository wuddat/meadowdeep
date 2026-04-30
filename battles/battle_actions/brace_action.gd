class_name BraceAction
extends BattleAction

@export var duration: float = 1.0


func can_execute(_user: BattleActor) -> bool:
	return true


func build_steps(_user: BattleActor) -> Array[Dictionary]:
	return [{"id": &"brace", "data": {"duration": duration} }]
