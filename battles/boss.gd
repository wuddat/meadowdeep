class_name Boss
extends Enemy

@onready var boss_controller: Node2D = %BossController
@onready var tentacles: AnimatedSprite2D = $Tentacles
@onready var collider: CollisionShape2D = $CollisionShape2D



func _on_queue_emptied() -> void:
	if knockbackable:
		knockbackable = false
	if not _in_combat:
		return
	var steps = boss_controller.next_steps(self)
	if steps.is_empty():
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})
		return
	for step in steps:
		action_queue.enqueue(step["id"], step["data"])

func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"strike": _strike_on_frame(data)
		_: super(id,data)

func _strike_on_frame(data) -> void:
	var target = data.get("target")
	var effects: Array[Effect] = data.get("effects", [] as Array[Effect])
	tentacles.play("strike")
	while is_instance_valid(target) and tentacles.frame != 7:
		await tentacles.frame_changed
	if is_instance_valid(target) and not effects.is_empty():
		EffectExecutor.run(effects, [target], self)


func _tick_strike(data: Dictionary, delta: float) -> void:
	if data.has("min_duration"):
		data["min_duration"] -= delta
		if data["min_duration"] >= 0.0:
			return
	action_queue.done()
