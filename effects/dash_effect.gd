#dash_effect.gd
class_name DashEffect
extends Effect

enum DashDirection { AWAY, TOWARD, UP, DOWN }

@export var dash_direction: DashDirection = DashDirection.AWAY
@export var speed: float = 120.0
@export var duration: float = 0.4


func execute(targets: Array[Node], _user: Node = null) -> void:
	for target in targets:
		var actor := target as BattleActor
		if actor == null or not is_instance_valid(actor):
			continue
		var direction := _resolve_direction(actor)
		actor.action_queue.enqueue(&"dash", {
			"direction": direction,
			"speed": speed,
			"duration": duration,
		})
		if sound:
			SFXPlayer.pitch_play(sound)


func _resolve_direction(actor: BattleActor) -> Vector2:
	match dash_direction:
		DashDirection.UP:
			return Vector2.UP
		DashDirection.DOWN:
			return Vector2.DOWN
		_:
			var threat: Node = BattleAction.find_nearest_opponent(actor)
			if not is_instance_valid(threat):
				return Vector2.ZERO
			var to_threat: Vector2 = (threat.global_position - actor.global_position).normalized()
			if dash_direction == DashDirection.AWAY:
				return -to_threat
			return to_threat
