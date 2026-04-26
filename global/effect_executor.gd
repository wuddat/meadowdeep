# effect_executor.gd
extends Node


func run(effects: Array[Effect], targets: Array[Node]) -> void:
	for effect in effects:
		if effect:
			effect.execute(targets)


func execute_status_effects(
	status_effects: Array[Status],
	targets: Array[Node],
	source: Node,
	effect_chance: float = 1.0,
	sound: AudioStream = null
) -> void:
	for status in status_effects:
		if not status:
			continue
		if RNG.instance.randf() <= effect_chance:
			var stat_effect := StatusEffect.new()
			stat_effect.source = source
			stat_effect.status = status.duplicate(true)
			if sound:
				stat_effect.sound = sound
			stat_effect.execute(targets)
