#battle_actor.gd
# Shared autonomous-fighter spine for all battle participants.
# Handles the action queue, movement, and the idle → seek → attack loop.
# Subclasses implement virtual hooks for their specific behavior.
class_name BattleActor
extends CharacterBody2D

@export var move_speed: float = 40.0

var action_queue := ActionQueue.new()
var _in_combat: bool = false

var knockback_strength: float = 1000.0
var knockback_decay: float = 1200.0
var knockback_exp: float = 8.0

var base_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	action_queue.action_started.connect(_on_action_start)
	action_queue.queue_emptied.connect(_on_queue_emptied)


func start_combat() -> void:
	_in_combat = true
	action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func stop_combat() -> void:
	_in_combat = false
	action_queue.clear()


func _physics_process(delta: float) -> void:
	if not _in_combat:
		return
	_check_battle_triggers()
	_tick_current_action(delta)
	_decay_knockback(delta)
	if knockback_velocity != Vector2.ZERO:
		velocity = base_velocity + knockback_velocity
	else: velocity = base_velocity
	move_and_slide()


func _on_queue_emptied() -> void:
	action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"idle":   _play_animation(&"idle")
		&"seek":   _play_animation(&"run")
		&"attack": _begin_attack(data)


func _check_battle_triggers() -> void:
	pass


func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if current.is_empty():
		return
	match current["id"]:
		&"idle":   _tick_idle(current["data"], delta)
		&"seek":   _tick_seek(current["data"], delta)
		&"attack": pass


func _tick_idle(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	_update_action_timer_ui(data["timer"])
	if data["timer"] > 0.0:
		return
	action_queue.enqueue(&"seek", {})
	action_queue.done()


func _tick_seek(_data: Dictionary, _delta: float) -> void:
	var target := _get_target()
	if not is_instance_valid(target):
		action_queue.done()
		return
	var dir: Vector2 = target.global_position - global_position
	if dir.length() < _get_attack_range():
		base_velocity = Vector2.ZERO
		action_queue.enqueue(&"attack", {"target": target})
		action_queue.done()
		return
	base_velocity = dir.normalized() * move_speed
	_face_direction(base_velocity)
	


# ── Virtual hooks ─────────────────────────────────────────────────────────────

func _get_target() -> Node2D:
	return null

func _begin_attack(_data: Dictionary) -> void:
	pass

func _get_action_interval() -> float:
	return 1.5

func _get_attack_range() -> float:
	return 32.0

func _get_attack_damage() -> int:
	return 3

func _apply_knockback(source_pos: Vector2) -> void:
	var direction = (global_position - source_pos).normalized()
	knockback_velocity = direction * knockback_strength
	
	action_queue.clear()
	action_queue.enqueue(&"idle", {"timer": 0.2})

func _decay_knockback(delta) -> void:
	if knockback_velocity.length() <= 0.01:
		knockback_velocity = Vector2.ZERO
		return
	var decay_factor = exp(-knockback_exp * delta)
	knockback_velocity *= decay_factor


func _play_animation(_anim_name: StringName) -> void:
	pass

func _face_direction(_vel: Vector2) -> void:
	pass

func _update_action_timer_ui(_remaining: float) -> void:
	pass
