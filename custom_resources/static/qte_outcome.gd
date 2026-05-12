# custom_resources/qte_outcome.gd
class_name QTEOutcome
extends Resource

@export var damage_multiplier: float = 1.0
@export var damage_negation: float = 0.0   # 0=full dmg, 1=negate all
