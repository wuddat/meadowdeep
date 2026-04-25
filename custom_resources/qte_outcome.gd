# custom_resources/qte_outcome.gd
class_name QTEOutcome
extends Resource

@export var damage_multiplier: float = 1.0
@export var damage_negation: float = 0.0   # 0=full dmg, 1=negate all
@export var trigger_counter: bool = false
@export var counter_move_id: String = ""
@export var add_status_self: String = ""
@export var add_status_target: String = ""
@export var battle_text: String = ""
