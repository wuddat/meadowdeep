#flat_damage_effect.gd
# Used by status effects (poison, headshot). No modifier applied — raw damage.
class_name FlatDamageEffect
extends Effect


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("take_damage"):
			target.take_damage(amount, Modifier.Type.NO_MODIFIER)
			if sound:
				SFXPlayer.play(sound)
