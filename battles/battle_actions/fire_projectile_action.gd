class_name FireProjectileAction
extends BattleAction

@export var projectile_scene: PackedScene
@export var min_range: float = 64.0
@export var max_range: float = 200.0

@export var art: CompressedTexture2D
@export var effects: Array[Effect]
@export var duration: float
@export var speed: float
@export var max_distance: float


func can_execute(user: BattleActor) -> bool:
	var target := find_nearest_opponent(user)
	if target == null:
		return false
	if projectile_scene == null:
		return false
	var dist := user.global_position.distance_to(target.global_position)
	return dist >= min_range and dist <= max_range


func build_steps(user: BattleActor) -> Array[Dictionary]:
	var t := find_nearest_opponent(user)
	if t == null: return []
	return [{
		"id": &"projectile",
		"data": {
			"target": t,
			"scene": projectile_scene,
			"art": art,
			"effects": effects,
			"duration": duration,
			"max_distance": max_distance,
			"speed": speed,
		}
	}]
