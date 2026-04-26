#battle_actor.gd
# Shared autonomous-fighter spine for all battle participants.
# Brain drives all behavior — movement, attack, brace — via the action queue.
class_name BattleActor
extends CharacterBody2D

@export var move_speed: float = 40.0
@export var battle_action_list: Array[BattleAction]

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
	_current_action = chosen
	chosen.execute_action(self)
	if action_queue.peek().is_empty():
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"idle":   _play_animation(&"idle")
		&"move":   _play_animation(&"run")
		&"brace":  _play_animation(&"idle")
		&"dodge":  _play_animation(&"dodge")
		&"attack":
			if _current_action != null:
				_current_action.run_effects_async(self, data)


func _check_battle_triggers() -> void:
	pass


func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if current.is_empty():
		return
	match current["id"]:
		&"idle":   _tick_idle(current["data"], delta)
		&"move":   _tick_move(current["data"], delta)
		&"brace":  _tick_brace(current["data"], delta)
		&"attack": pass
		&"dodge":  _tick_dodge(current["data"], delta)

func _tick_idle(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	_update_action_timer_ui(data["timer"])
	if data["timer"] > 0.0:
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
	var mode: String = data.get("mode", "toward")
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()

	if mode == "toward":
		if dist <= stop_distance:
			base_velocity = Vector2.ZERO
			action_queue.done()
			return
		base_velocity = to_target.normalized() * move_speed
	else:
		if dist >= stop_distance:
			base_velocity = Vector2.ZERO
			action_queue.done()
			return
		base_velocity = -to_target.normalized() * move_speed

	_face_direction(base_velocity)


func _tick_brace(data: Dictionary, delta: float) -> void:
	data["duration"] -= delta
	if data["duration"] <= 0.0:
		action_queue.done()


func _tick_dodge(data: Dictionary, delta: float) -> void:
	base_velocity = data.get("direction", Vector2.ZERO) * data.get("speed", 120.0)
	data["duration"] -= delta
	if data["duration"] <= 0.0:
		base_velocity = Vector2.ZERO
		is_dodging = false
		action_queue.done()


# ── Virtual hooks ─────────────────────────────────────────────────────────────

func _get_action_interval() -> float:
	return 1.5

func _apply_knockback(source_pos: Vector2) -> void:
	var direction := (global_position - source_pos).normalized()
	knockback_velocity = direction * knockback_strength
	action_queue.clear()
	action_queue.enqueue(&"idle", {"timer": 0.2})

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
