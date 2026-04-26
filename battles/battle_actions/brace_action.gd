class_name BraceAction
extends BattleAction


func can_execute(_user: BattleActor) -> bool:
	return true


func execute_action(user: BattleActor) -> void:
	user.action_queue.enqueue(&"brace", {"duration": 1.0})
