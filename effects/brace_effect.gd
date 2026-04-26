#brace_effect.gd
class_name BraceEffect
extends Effect

@export var duration: float = 1.0


func execute(targets: Array[Node]) -> void:
	for actor in targets:
		var battle_actor := actor as BattleActor
		if battle_actor == null or not is_instance_valid(battle_actor):
			continue
		battle_actor.action_queue.enqueue(&"brace", {"duration": duration})
