#heal_effect.gd
class_name HealEffect
extends Effect

@export var amount: int = 0

func execute(targets: Array[Node], _user: Node = null) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("heal"):
			target.heal(amount)
			if sound:
				SFXPlayer.play(sound)
