#status_effect.gd
class_name StatusEffect
extends Effect

var status: Status
var source: Node


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		if not "status_handler" in target:
			continue
		var unique_status := status.duplicate()
		unique_status.status_source = source
		target.status_handler.add_status(unique_status)
		if sound:
			SFXPlayer.play(sound)
