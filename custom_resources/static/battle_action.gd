class_name BattleAction
extends Resource

enum Intent { AGGRESSIVE, DEFENSIVE }
enum ActionSlot { UNIVERSAL, BASIC, SECONDARY, DEFENSIVE, DASH }
#TODO will influence where actions can be placed in ruins_prep_menu
# UNIVERSAL will be reserved for moves all creatures get like, move_toward, move_away


@export var intent: Intent = Intent.AGGRESSIVE
@export var stat_categories: Array[GrowthStat.StatType] = []
@export var action_slot: ActionSlot = ActionSlot.UNIVERSAL
@export var display_name: String = ""
@export var on_gcd: bool = true
@export_range(0.0, 10.0) var chance_weight: float = 1.0


func can_execute(_user: BattleActor) -> bool:
	return false


func build_steps(_user: BattleActor) -> Array[Dictionary]:
	return []


static func range_check(user: Node, target: Node, max_range: float) -> bool:
	if not is_instance_valid(user) or not is_instance_valid(target):
		return false
	return user.global_position.distance_to(target.global_position) <= max_range


static func find_opponents_in_radius(user: Node, aoe_radius: float) -> Array[Node]:
	var radius := int(aoe_radius)
	var group := "enemies" if user.is_in_group("active_creatures") else "active_creatures"
	var candidates := user.get_tree().get_nodes_in_group(group)
	var opps: Array[Node] = []
	for c in candidates:
		if not is_instance_valid(c):
			continue
		if "instance" in c and c.instance and c.instance.health <= 0:
			continue
		var d: float = user.global_position.distance_to(c.global_position)
		if d < radius:
			opps.append(c)
	return opps

static func find_nearest_opponent(user: BattleActor) -> Node:
	var group := "enemies" if user.is_in_group("active_creatures") else "active_creatures"
	var candidates := user.get_tree().get_nodes_in_group(group)
	var nearest: Node = null
	var nearest_dist := INF
	for c in candidates:
		if not is_instance_valid(c):
			continue
		if "instance" in c and c.instance and c.instance.health <= 0:
			continue
		var d: float = user.global_position.distance_to(c.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = c
	return nearest
