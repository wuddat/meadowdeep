class_name Sleep
extends Status

const SLEEP_ICON := preload("res://art/statuseffects/sleep.png")

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	if target:
		if target.is_asleep:
			target.status_handler.remove_status("sleep")
			target.unit_status_indicator.update_status_display(target)
			return
		if not target.has_slept:
			target.is_asleep = true
			target.status_handler.remove_status("sleep")
			target.unit_status_indicator.update_status_display(target)
			print("Sleep: First application - flagging")


func apply_status(target: Node) -> void:
	print("Sleep: apply_status() called on %s" % target.name)
	print("Sleep current stacks: %d" % stacks)
	print("Sleep target has_slept: %s" % target.has_slept)

	if target:
		if target.is_asleep:
			target.status_handler.remove_status("sleep")
			target.unit_status_indicator.update_status_display(target)
			return
		if target.has_slept:
			if stacks > 1:
				target.is_asleep = true
				target.status_handler.remove_status("sleep")
				target.unit_status_indicator.update_status_display(target)
		else:
			print("Sleep: stacked up, but not enough to re-trigger sleep")
	else:
		print("Sleep: skipping logic — should've been handled in initialize_status()")
	target.unit_status_indicator.update_status_display(target)
	status_applied.emit(self)
