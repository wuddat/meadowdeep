#damage_effect.gd
class_name DamageEffect
extends Effect

@export var amount := 0

func execute(targets: Array[Node], user: Node = null) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("take_damage") and not target.is_dodging:
			target.take_damage(amount, Modifier.Type.DMG_TAKEN, user)
			if sound:
				SFXPlayer.pitch_play(sound)
