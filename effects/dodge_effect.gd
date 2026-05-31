class_name DodgeEffect
extends Effect


func execute(targets: Array[Node], _user: Node = null) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		target.is_dodging = !target.is_dodging
		if sound:
			SFXPlayer.pitch_play(sound)
