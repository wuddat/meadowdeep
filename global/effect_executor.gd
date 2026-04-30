# effect_executor.gd
extends Node


func run(effects: Array[Effect], targets: Array[Node], user: Node) -> void:
	for effect in effects:
		var t_resolved: Array[Node] = [user] as Array[Node] if effect.target_type == Effect.TargetType.USER else targets
		effect.execute(t_resolved)
