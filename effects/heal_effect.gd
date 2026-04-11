#heal_effect.gd
class_name HealEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("heal"):
			target.heal(amount)
			SFXPlayer.play(sound)
			var health_before: int = target.stats.health - amount
			print("%s HEAL by %s from %s to %s/%s" % [target.stats.species_id, amount, health_before, target.stats.health, target.stats.max_health])
