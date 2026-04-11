# body_blow.gd
class_name BodyBlow
extends Status

func apply_status(target: Node) -> void:
	super.apply_status(target)

	if not target.status_handler:
		print("No StatusHandler found on target.")
		return

	var headshot_stacks = target.status_handler.get_status_stacks("headshot")
	if headshot_stacks and headshot_stacks >= 3:
		var paralyze = preload("res://statuses/paralyze.tres").duplicate()
		print("HEADSHOT TRIGGERED — Applying PARALYZE!")
		var paralyze_effect := StatusEffect.new()
		paralyze_effect.status = paralyze
		paralyze_effect.execute([target])
		target.status_handler.remove_status("body_blow")
		target.status_handler.remove_status("headshot")
	if target.has_method("show_combat_text"):
		target.show_combat_text("BODY BLOW!", Color.RED)
	else:
		return
