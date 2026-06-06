#knockback_effect.gd
class_name KnockbackEffect
extends Effect

@export var strength: float = 1000.0

func execute(targets: Array[Node], user: Node = null) -> void:
	if not is_instance_valid(user):
		return
	for target in targets:
		var actor := target as BattleActor
		if actor == null or not is_instance_valid(actor):
			continue
		if actor.is_dodging:
			continue
		actor.apply_knockback(user.global_position, strength)
		if sound:
			SFXPlayer.pitch_play(sound)
