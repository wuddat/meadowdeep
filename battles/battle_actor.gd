#battle_actor.gd
# Shared autonomous-fighter spine for all battle participants.
# Brain drives all behavior — movement, attack — via the action queue.
class_name BattleActor
extends CharacterBody2D

@export var move_speed: float = 40.0
@export var battle_action_list: Array[BattleAction]
@export var creature_animation_handler: CreatureAnimationHandler
@export var instance: CreatureInstance : set = set_instance

var action_queue := ActionQueue.new()
var _in_combat: bool = false
var is_dodging: bool = false
var _current_action: BattleAction


var knockback_strength: float = 1000.0
var knockback_exp: float = 8.0

var base_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var brain: Brain = get_node_or_null("Brain") as Brain


func _ready() -> void:
	action_queue.action_started.connect(_on_action_start)
	action_queue.queue_emptied.connect(_on_queue_emptied)


func start_combat() -> void:
	_in_combat = true
	action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func stop_combat() -> void:
	_in_combat = false
	action_queue.clear()

func set_instance(value: CreatureInstance) -> void:
	_hydrate_actions()


func _physics_process(delta: float) -> void:
	if not _in_combat:
		return
	_check_battle_triggers()
	_tick_current_action(delta)
	_decay_knockback(delta)
	velocity = base_velocity + knockback_velocity
	move_and_slide()


func _on_queue_emptied() -> void:
	if not _in_combat:
		return
	if brain == null or battle_action_list.is_empty():
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})
		return
	var chosen := brain.select_action()
	if chosen == null:
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})
		return
	var steps := chosen.build_steps(self)
	if steps.is_empty():
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})
		return
	for step in steps:
		action_queue.enqueue(step["id"], step["data"])
	if action_queue.peek().is_empty():
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"idle":       _play_animation(&"idle")
		&"move":       _play_animation(&"run")
		&"dash":       _play_animation(&"dash")
		&"strike":     _play_animation(&"strike")
		&"brace":      _play_animation(&"brace")
		&"projectile": _play_animation(&"strike")


func _check_battle_triggers() -> void:
	pass


func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if current.is_empty():
		return
	match current["id"]:
		&"idle":       _tick_idle(current["data"], delta)
		&"move":       _tick_move(current["data"], delta)
		&"dash":       _tick_dash(current["data"], delta)
		&"strike":     _tick_strike(current["data"], delta)
		&"brace":      _tick_brace(current["data"], delta)
		&"projectile": _tick_projectile(current["data"], delta)


func _tick_idle(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	_update_action_timer_ui(data["timer"])
	if data["timer"] > 0.0:
		return
	action_queue.done()


func _tick_brace(data:Dictionary, delta: float) -> void:
	data["duration"] -= delta
	_update_action_timer_ui(data["duration"])
	if data["duration"] > 0.0:
		return
	action_queue.done()


func _tick_strike(data: Dictionary, delta: float) -> void:
	var t = data.get("target")
	var effects: Array[Effect] = data.get("effects", [] as Array[Effect])
	if is_instance_valid(t) and not effects.is_empty():
		EffectExecutor.run(effects, [t], self)
		data["effects"] = [] as Array[Effect]
	if data.has("min_duration"):
		data["min_duration"] -= delta
		if data["min_duration"] >= 0.0:
			return
	action_queue.done()


func _tick_move(data: Dictionary, delta: float) -> void:
	var raw = data.get("target")
	if not is_instance_valid(raw):
		base_velocity = Vector2.ZERO
		action_queue.done()
		return
	var target: Node2D = raw

	if data.has("duration"):
		data["duration"] -= delta
		if data["duration"] <= 0.0:
			base_velocity = Vector2.ZERO
			action_queue.done()
			return

	var stop_distance: float = data.get("stop_distance", 32.0)
	var mode: MoveToAction.Mode = data.get("mode", MoveToAction.Mode.TOWARD)
	
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	
	match mode:
		MoveToAction.Mode.TOWARD:
			if dist <= stop_distance:
				base_velocity = Vector2.ZERO
				action_queue.done()
				return
			base_velocity = to_target.normalized() * move_speed

		MoveToAction.Mode.AWAY:
			if dist >= stop_distance: # Assuming stopping at a max distance away, modify if you want continuous flee
				base_velocity = Vector2.ZERO
				action_queue.done()
				return
			base_velocity = -to_target.normalized() * move_speed

		MoveToAction.Mode.ORBITL:
			var tangent := to_target.normalized().rotated(-PI / 2)
			base_velocity = tangent * move_speed

		MoveToAction.Mode.ORBITR:
			var tangent := to_target.normalized().rotated(PI / 2)
			base_velocity = tangent * move_speed

	_face_direction(base_velocity)


func _tick_projectile(data: Dictionary, _delta: float) -> void:
	var scene: PackedScene = data.get("scene")
	var target = data.get("target")
	if scene == null or not is_instance_valid(target):
		action_queue.done()
		return
	var p := scene.instantiate() as ProjectileObject
	if p == null:
		action_queue.done()
		return
	p.art = data.get("art")
	p.effects = data.get("effects", [] as Array[Effect])
	p.duration = data.get("duration", 0.0)
	p.max_distance = data.get("max_distance", 0.0)
	p.speed = data.get("speed", 0.0)
	get_parent().add_child(p)
	p.setup(self, target)
	action_queue.done()


func _tick_dash(data: Dictionary, delta: float) -> void:
	base_velocity = data.get("direction", Vector2.ZERO) * data.get("speed", 120.0)
	data["duration"] -= delta
	if data["duration"] <= 0.0:
		base_velocity = Vector2.ZERO
		is_dodging = false
		action_queue.done()


# ── Virtual hooks ─────────────────────────────────────────────────────────────

func _get_action_interval() -> float:
	return 0.25

func _apply_knockback(source_pos: Vector2) -> void:
	var direction := (global_position - source_pos).normalized()
	knockback_velocity = direction * knockback_strength
	if action_queue.current_action != &"strike":
		if creature_animation_handler:
			creature_animation_handler.RESET()
		action_queue.clear()
		action_queue.enqueue(&"idle", {"timer": 0.2})

func _hydrate_actions() -> void:
	if not instance or not instance.identity:
		return
	var ids: Array[String] = instance.identity.assigned_actions
	if ids.is_empty():
		ids = instance.identity.known_actions
	if ids.is_empty() and instance.definition:
		ids = instance.definition.starting_actions
	battle_action_list = ActionData.get_actions(ids)

func _decay_knockback(delta: float) -> void:
	if knockback_velocity.length() <= 0.01:
		knockback_velocity = Vector2.ZERO
		return
	knockback_velocity *= exp(-knockback_exp * delta)

func _play_animation(_anim_name: StringName) -> void:
	pass

func _face_direction(_vel: Vector2) -> void:
	pass

func _update_action_timer_ui(_remaining: float) -> void:
	pass
