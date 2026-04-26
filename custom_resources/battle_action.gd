class_name BattleAction
extends Resource

enum Intent { AGGRESSIVE, DEFENSIVE }

@export var intent: Intent = Intent.AGGRESSIVE
@export var display_name: String = ""
@export_range(0.0, 10.0) var chance_weight: float = 1.0


func can_execute(_user: BattleActor) -> bool:
	return false


func execute_action(_user: BattleActor) -> void:
	pass


# Override in actions that use the &"attack" primitive (async, called from _on_action_start).
# Base impl just closes the queue entry immediately.
func run_effects_async(user: BattleActor, _data: Dictionary) -> void:
	user.action_queue.done()


static func range_check(user: Node, target: Node, max_range: float) -> bool:
	if not is_instance_valid(user) or not is_instance_valid(target):
		return false
	return user.global_position.distance_to(target.global_position) <= max_range


static func find_nearest_opponent(user: BattleActor) -> Node:
	var group := "enemies" if user.is_in_group("active_creatures") else "active_creatures"
	var candidates := user.get_tree().get_nodes_in_group(group)
	var nearest: Node = null
	var nearest_dist := INF
	for c in candidates:
		if not is_instance_valid(c):
			continue
		if "stats" in c and c.stats and c.stats.health <= 0:
			continue
		var d: float = user.global_position.distance_to(c.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = c
	return nearest
