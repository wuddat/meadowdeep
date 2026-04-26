#movement_effect.gd
class_name MovementEffect
extends Effect

# Set by the action before calling execute — who to move toward/away from.
var target: Node

@export var mode: String = "toward"  # "toward" or "away"
@export var stop_distance: float = 32.0
@export var max_duration: float = 0.0


func execute(targets: Array[Node]) -> void:
	for actor in targets:
		var battle_actor := actor as BattleActor
		if battle_actor == null or not is_instance_valid(battle_actor):
			continue
		if not is_instance_valid(target):
			continue
		var data := {
			"target": target,
			"mode": mode,
			"stop_distance": stop_distance,
		}
		if max_duration > 0.0:
			data["duration"] = max_duration
		battle_actor.action_queue.enqueue(&"move", data)
