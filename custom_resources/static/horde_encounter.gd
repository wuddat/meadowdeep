class_name HordeEncounterDef
extends EncounterDef

@export var max_active: int = 3
@export var total_to_spawn: int = 10

var _remaining: int

func start_encounter(handler: EnemyHandler) -> void:
	_remaining = total_to_spawn
	_refill(handler)

func on_enemy_fainted(handler: EnemyHandler) -> void:
	_refill(handler)

func is_complete(handler: EnemyHandler) -> bool:
	return _remaining <= 0 and handler.get_enemies().is_empty()

func _refill(handler: EnemyHandler) -> void:
	pass
	#while handler.get_enemies().size() < max_active and _remaining > 0:
		#handler.spawn_enemy(_pick_species(1)[0], _pick_spawn_point())
		#_remaining -= 1
