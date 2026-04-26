class_name DodgeEffect
extends Effect


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.is_dodging:
			continue
		target.is_dodging = true
		if sound:
			SFXPlayer.pitch_play(sound)
