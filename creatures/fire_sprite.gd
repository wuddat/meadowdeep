extends CharacterBody2D

# ═══════════════════════════════════════════════════════════════════════════════
# MeadowDeep — Creature Base (Slime)
#
# Architecture: emotions are numeric pressures that rise over time.
# When an emotion crosses a threshold it enqueues an action.
# The action queue runs one action at a time; when an action signals
# completion (_action_done()) it pops and the next begins.
#
# To add a new creature: extend this script, override _on_ready_creature()
# and tune the @export values in the Inspector.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Emotions ──────────────────────────────────────────────────────────────────
var SLEEP_BUBBLE = preload("res://art/game_art/emoticons/sleep.png")
var LOVE_BUBBLE = preload("res://art/game_art/emoticons/love.png")
var RELAXED_BUBBLE = preload("res://art/game_art/emoticons/relaxed.png")
var JOY_BUBBLE = preload("res://art/game_art/emoticons/joy.png")
# ── Tuning ────────────────────────────────────────────────────────────────────
@export_group("Movement")
@export var move_speed: float        = 40.0
@export var wander_radius: float     = 80.0

@export_group("Emotion Rates (per second)")
@export var boredom_rate: float      = 4.0    # rises while idle
@export var lonely_rate: float       = 2.0    # rises always
@export var sleepiness_rate: float   = 1.5    # rises always
@export var hunger_rate: float       = 2.0   #falls slowly

@export_group("Emotion Thresholds")
@export var boredom_wander_threshold: float   = 60.0
@export var lonely_seek_threshold: float      = 80.0
@export var sleepiness_sleep_threshold: float = 90.0
@export var hunger_seek_food_threshold: float = 50.0

@export_group("Action Timing")
@export var idle_time_min: float      = 1.5
@export var idle_time_max: float      = 4.0
@export var sleep_duration_min: float = 4.0
@export var sleep_duration_max: float = 10.0


# ── Emotion state ─────────────────────────────────────────────────────────────
var emotions: Dictionary = {
	"boredom":    0.0,   # 0–100
	"lonely":     0.0,   # 0–100
	"sleepiness": 0.0,   # 0–100
	"joy":        0.0,   # 0–100  (future: rises when player interacts)
	"fear":       0.0,   # 0–100  (future: rises from bad interactions)
	"hunger":     55.0,   # 0–100 
}


# ── Action queue ──────────────────────────────────────────────────────────────
# Each entry: { "id": StringName, "data": Dictionary }
# "data" holds whatever the action needs (target pos, timer, etc.)
# When an action finishes it calls _action_done() which pops the queue.
var _action_queue: Array[Dictionary] = []

var _current_action: StringName:
	get: return _action_queue[0]["id"] if _action_queue.size() > 0 else &""


# ── Scene refs ────────────────────────────────────────────────────────────────
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var boredom: Label = %Boredom
@onready var lonely: Label = %Lonely
@onready var sleepy: Label = %Sleepy
@onready var joy: Label = %Joy
@onready var fear: Label = %Fear
@onready var active_behavior: Label = %Active
@onready var emotion: Sprite2D = $Emotion
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var _debug_box: VBoxContainer = %Label
@onready var hunger: Label = %Hunger
@onready var pop: AudioStreamPlayer = $Pop
@onready var nomnom: AudioStreamPlayer = $nomnom

var _home: Vector2
var _player: CharacterBody2D   # resolved lazily via "player" group
var _food: Area2D              # resolved lazily via "food" group


# ═══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_home = global_position
	_on_ready_creature()
	_sprite.animation_looped.connect(_on_sprite_animation_looped)
	_enqueue_action(&"idle", {})


# Override in child scripts for creature-specific setup
func _on_ready_creature() -> void:
	pass


func _physics_process(delta: float) -> void:
	_tick_emotions(delta)
	_check_emotion_triggers()
	_tick_current_action(delta)
	_update_emotion_text()
	var viewport_pos := get_viewport().get_canvas_transform() * global_position
	_debug_box.position = viewport_pos + Vector2(-18, 20)
	active_behavior.position = viewport_pos + Vector2(-18, 10)

# ═══════════════════════════════════════════════════════════════════════════════
# Emotions
# ═══════════════════════════════════════════════════════════════════════════════

func _tick_emotions(delta: float) -> void:
	# Sleepiness and loneliness rise constantly
	_raise("sleepiness", sleepiness_rate * delta)
	_raise("lonely",     lonely_rate     * delta)
	

	# Boredom rises faster while idle, drains slowly while active
	# Hunger rises faster while moving, drains slowly while idle
	if _current_action == &"idle":
		_raise("boredom", boredom_rate * delta)
		_lower("hunger", hunger_rate * 0.5 * delta)
	else:
		_lower("boredom", boredom_rate * 0.5 * delta)
		_lower("hunger", hunger_rate * delta)


func _check_emotion_triggers() -> void:
	# Sleepiness wins — push to front so it interrupts anything
	if emotions["sleepiness"] >= sleepiness_sleep_threshold:
		if _current_action != &"sleep":
			_push_action_front(&"sleep", {
				"timer": randf_range(sleep_duration_min, sleep_duration_max)
			})
		return
	
	if emotions["hunger"] <= hunger_seek_food_threshold:
		if _current_action != &"seek_food" and not _queue_contains(&"seek_food"):
			_enqueue_action(&"seek_food", {})
			_enqueue_action(&"eat_food", {"timer": randf_range(sleep_duration_min, sleep_duration_max)})
			return

	# Loneliness — seek player (enqueue once)
	if emotions["lonely"] >= lonely_seek_threshold:
		if _current_action != &"seek_player" and not _queue_contains(&"seek_player"):
			_enqueue_action(&"seek_player", {})

	# Boredom — go for a wander (enqueue once)
	if emotions["boredom"] >= boredom_wander_threshold:
		if _current_action != &"wander" and not _queue_contains(&"wander"):
			_enqueue_action(&"wander", { "target": _pick_wander_target() })

func _on_emotion_change() -> void:
	_update_emotion_text()

func _update_emotion_text() -> void:
	boredom.text = ("boredom: %s" % int(emotions["boredom"]) )
	lonely.text = ("lonely: %s" % int(emotions["lonely"]))
	sleepy.text = ("sleepy: %s" % int(emotions["sleepiness"]))
	joy.text = ("joy: %s" % int(emotions["joy"]))
	fear.text = ("fear: %s" % int(emotions["fear"]))
	hunger.text = ("hunger: %s" % int(emotions["hunger"]))
	active_behavior.text = (_current_action)
# ═══════════════════════════════════════════════════════════════════════════════
# Action Queue
# ═══════════════════════════════════════════════════════════════════════════════

func _enqueue_action(id: StringName, data: Dictionary) -> void:
	_action_queue.append({ "id": id, "data": data })
	if _action_queue.size() == 1:
		_on_action_start(id, data)


func _push_action_front(id: StringName, data: Dictionary) -> void:
	_action_queue.push_front({ "id": id, "data": data })
	_on_action_start(id, data)


func _action_done() -> void:
	if _action_queue.is_empty():
		return
	_action_queue.pop_front()
	if _action_queue.is_empty():
		_enqueue_action(&"idle", {})
	else:
		_on_action_start(_action_queue[0]["id"], _action_queue[0]["data"])


func _queue_contains(id: StringName) -> bool:
	for entry in _action_queue:
		if entry["id"] == id:
			return true
	return false


func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"idle":
			velocity = Vector2.ZERO
			_sprite.play("idle")
			data["timer"] = randf_range(idle_time_min, idle_time_max)
		&"wander":
			_sprite.play("run")
			pop.pitch_scale = randf_range(0.9, 1.1)
			pop.play()
		&"sleep":
			velocity = Vector2.ZERO
			_sprite.play("sleep")   
			emotion.texture = SLEEP_BUBBLE
			animation_player.play("bubble_fade_in")
		&"seek_player":
			_sprite.play("run")
			pop.pitch_scale = randf_range(0.9, 1.1)
			pop.play()
		&"seek_food":
			_sprite.play("run")
			pop.pitch_scale = randf_range(0.9, 1.1)
			pop.play()
		&"eat_food":
			_sprite.play("eat")
			emotion.texture = JOY_BUBBLE
			animation_player.play("bubble_fade_in")
			data["timer"] = randf_range(idle_time_min, idle_time_max)
			nomnom.pitch_scale = randf_range(0.9, 1.1)
			nomnom.play()


# ═══════════════════════════════════════════════════════════════════════════════
# Per-frame action ticks
# ═══════════════════════════════════════════════════════════════════════════════

func _tick_current_action(delta: float) -> void:
	if _action_queue.is_empty():
		return
	var action: Dictionary = _action_queue[0]
	match action["id"]:
		&"idle":        _tick_idle(action["data"], delta)
		&"wander":      _tick_wander(action["data"], delta)
		&"sleep":       _tick_sleep(action["data"], delta)
		&"seek_player": _tick_seek_player(action["data"], delta)
		&"seek_food": _tick_seek_food(action["data"], delta)
		&"eat_food": _tick_eat_food(action["data"], delta)


func _tick_idle(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	if data["timer"] <= 0.0:
		_action_done()


func _tick_wander(data: Dictionary, delta: float) -> void:
	var dir: Vector2 = data["target"] - global_position
	if dir.length() < 4.0:
		_lower("boredom", 40.0)   # arriving somewhere satisfies boredom
		_action_done()
		return
	velocity = dir.normalized() * move_speed
	_sprite.flip_h = velocity.x < 0
	move_and_slide()


func _tick_sleep(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	_lower("sleepiness", 20.0 * delta)
	if data["timer"] <= 0.0 or emotions["sleepiness"] <= 0.0:
		_action_done()
		animation_player.play("bubble_fade_out")

func _tick_eat_food(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	_raise("hunger", 20.0 * delta)
	if not nomnom.playing:
		nomnom.pitch_scale = randf_range(0.9, 1.1)
		nomnom.play()
	if data["timer"] <= 0.0 or emotions["hunger"] >= 100.0:
		nomnom.stop()
		animation_player.play("bubble_fade_out")
		_action_done()


func _tick_seek_player(_data: Dictionary, _delta: float) -> void:
	var player := _get_player()
	if not player:
		_action_done()
		return

	var dir: Vector2 = player.global_position - global_position
	if dir.length() < 24.0:
		# Close enough — nuzzle: joy spike, loneliness drops
		_lower("lonely", 60.0)
		_raise("joy",    30.0)
		_action_done()
		return

	velocity = dir.normalized() * move_speed
	_sprite.flip_h = velocity.x < 0
	move_and_slide()

func _tick_seek_food(_data: Dictionary, _delta: float) -> void:
	var food := _get_food()
	if not food:
		_action_done()
		return
	var dir: Vector2 = food.global_position - global_position
	if dir.length() < 20.0:
		_action_done()
		return
		
	velocity = dir.normalized() * move_speed
	_sprite.flip_h = velocity.x < 0
	move_and_slide()

# ═══════════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════════

func _raise(emotion: StringName, amount: float) -> void:
	emotions[emotion] = minf(emotions[emotion] + amount, 100.0)


func _lower(emotion: StringName, amount: float) -> void:
	emotions[emotion] = maxf(emotions[emotion] - amount, 0.0)


func _pick_wander_target() -> Vector2:
	var angle := randf() * TAU
	var dist  := randf() * wander_radius
	return _home + Vector2(cos(angle), sin(angle)) * dist


func _get_player() -> CharacterBody2D:
	if not _player:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as CharacterBody2D
	return _player

func _on_sprite_animation_looped() -> void:
	if _sprite.animation == &"run":
		pop.pitch_scale = randf_range(0.9, 1.1)
		pop.play()


func _get_food() -> Area2D:
	if not _food:
		var foods := get_tree().get_nodes_in_group("food")
		if foods.size() > 0:
			_food = foods[0] as Area2D
	return _food
