#block_effect.gd
class_name BlockEffect
extends Effect

@export var amount := 0

func execute(targets: Array[Node], _user: Node = null) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("gain_block"):
			target.gain_block(amount, Modifier.Type.BLOCK_GAINED)
			if sound:
				SFXPlayer.play(sound)
			if target.has_method("show_combat_text"):
				target.show_combat_text("BLOCK", Color.BLUE)
