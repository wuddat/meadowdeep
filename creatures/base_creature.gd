class_name BaseCreature
extends CharacterBody2D

# ═══════════════════════════════════════════════════════════════════════════════
# MeadowDeep — Base Creature
#
# All shared creature logic: emotions, action queue, movement, food handling.
# Extend this and override _on_ready_creature() for creature-specific setup.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Emotion bubbles ───────────────────────────────────────────────────────────
const SLEEP_BUBBLE   = preload("res://art/game_art/emoticons/sleep.png")
const LOVE_BUBBLE    = preload("res://art/game_art/emoticons/love.png")
const RELAXED_BUBBLE = preload("res://art/game_art/emoticons/relaxed.png")
const JOY_BUBBLE     = preload("res://art/game_art/emoticons/joy.png")
const HIGHLIGHT_SHADER := preload("res://art/game_art/shaders/highlight.gdshader")

# ── Tuning ────────────────────────────────────────────────────────────────────
@export_group("Movement")
@export var move_speed: float        = 40.0
@export var wander_radius: float     = 80.0

@export_group("Emotion Rates (per second)")
@export var boredom_rate: float      = 4.0
@export var lonely_rate: float       = 2.0
@export var sleepiness_rate: float   = 1.5
@export var hunger_rate: float       = 2.0

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
	"boredom":    0.0,
	"lonely":     0.0,
	"sleepiness": 0.0,
	"joy":        0.0,
	"fear":       0.0,
	"hunger":     55.0,
}

# ── Action queue ──────────────────────────────────────────────────────────────
var _action_queue: Array[Dictionary] = []

var _current_action: StringName:
	get: return _action_queue[0]["id"] if _action_queue.size() > 0 else &""

# ── Scene refs ────────────────────────────────────────────────────────────────
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var boredom: Label            = %Boredom
@onready var lonely: Label             = %Lonely
@onready var sleepy: Label             = %Sleepy
@onready var joy: Label                = %Joy
@onready var fear: Label               = %Fear
@onready var active_behavior: Label    = %Active
@onready var emotion: Sprite2D         = $Emotion
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var _debug_box: VBoxContainer = %Label
@onready var hunger: Label             = %Hunger
@onready var pop: AudioStreamPlayer    = $Pop
@onready var nomnom: AudioStreamPlayer = $nomnom

@export var creature_stats: CreatureStats

var _home: Vector2
var _player: CharacterBody2D
var _food: Area2D
var _eating_food: Node2D = null

var is_held := false
var _holder: Node2D = null
const HOLD_OFFSET := Vector2(20, -24)
var _saved_collision_layer := 0
var _saved_collision_mask := 0


# ═══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_home = global_position
	_ensure_stats()
	_on_ready_creature()
	_sprite.animation_looped.connect(_on_sprite_animation_looped)
	_enqueue_action(&"idle", {})
	var shader_material := ShaderMaterial.new()
	shader_material.shader = HIGHLIGHT_SHADER
	shader_material.set_shader_parameter("width", 0.0)
	_sprite.material = shader_material
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# Override in child scripts for creature-specific setup (visuals, shaders, etc.)
func _on_ready_creature() -> void:
	pass


func _ensure_stats() -> void:
	if not creature_stats:
		creature_stats = CreatureStats.new()
		creature_stats.creature_name = name
	var sb := creature_stats.stat_block
	if not sb:
		creature_stats.stat_block = CreatureStatBlock.new()
		sb = creature_stats.stat_block
	# Auto-generate grades if all at default (all C = grade index 2)
	var all_default := (
		sb.power.grade == StatBlock.Grade.C and
		sb.agility.grade == StatBlock.Grade.C and
		sb.resilience.grade == StatBlock.Grade.C and
		sb.mystic.grade == StatBlock.Grade.C and
		sb.focus.grade == StatBlock.Grade.C
	)
	if all_default:
		sb.power.grade      = _random_grade()
		sb.agility.grade    = _random_grade()
		sb.resilience.grade = _random_grade()
		sb.mystic.grade     = _random_grade()
		sb.focus.grade      = _random_grade()
		sb.personality      = _random_personality()


func _random_grade() -> StatBlock.Grade:
	# Weighted: C most common, S/E rare
	var roll := randi() % 100
	if roll < 5:   return StatBlock.Grade.S
	elif roll < 15: return StatBlock.Grade.A
	elif roll < 35: return StatBlock.Grade.B
	elif roll < 65: return StatBlock.Grade.C
	elif roll < 85: return StatBlock.Grade.D
	else:           return StatBlock.Grade.E


func _random_personality() -> CreatureStatBlock.Personality:
	var values := CreatureStatBlock.Personality.values()
	return values[randi() % values.size()]


func _physics_process(delta: float) -> void:
	if is_held:
		global_position = _holder.global_position + HOLD_OFFSET
		velocity = Vector2.ZERO
		return
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
	_raise("sleepiness", sleepiness_rate * delta)
	_raise("lonely",     lonely_rate     * delta)

	if _current_action == &"idle":
		_raise("boredom", boredom_rate * delta)
		_lower("hunger", hunger_rate * 0.5 * delta)
	else:
		_lower("boredom", boredom_rate * 0.5 * delta)
		_lower("hunger", hunger_rate * delta)


func _check_emotion_triggers() -> void:
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

	if emotions["lonely"] >= lonely_seek_threshold:
		if _current_action != &"seek_player" and not _queue_contains(&"seek_player"):
			_enqueue_action(&"seek_player", {})

	if emotions["boredom"] >= boredom_wander_threshold:
		if _current_action != &"wander" and not _queue_contains(&"wander"):
			_enqueue_action(&"wander", { "target": _pick_wander_target() })


func _update_emotion_text() -> void:
	boredom.text        = "boredom: %s"   % int(emotions["boredom"])
	lonely.text         = "lonely: %s"    % int(emotions["lonely"])
	sleepy.text         = "sleepy: %s"    % int(emotions["sleepiness"])
	joy.text            = "joy: %s"       % int(emotions["joy"])
	fear.text           = "fear: %s"      % int(emotions["fear"])
	hunger.text         = "hunger: %s"    % int(emotions["hunger"])
	active_behavior.text = _current_action


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
		&"seek_food":   _tick_seek_food(action["data"], delta)
		&"eat_food":    _tick_eat_food(action["data"], delta)


func _tick_idle(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	if data["timer"] <= 0.0:
		_action_done()


func _tick_wander(data: Dictionary, _delta: float) -> void:
	var dir: Vector2 = data["target"] - global_position
	if dir.length() < 4.0:
		_lower("boredom", 40.0)
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


func _tick_seek_player(_data: Dictionary, _delta: float) -> void:
	var player := _get_player()
	if not player:
		_action_done()
		return

	var dir: Vector2 = player.global_position - global_position
	if dir.length() < 24.0:
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


func _tick_eat_food(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	_raise("hunger", 20.0 * delta)
	if not nomnom.playing:
		nomnom.pitch_scale = randf_range(0.9, 1.1)
		nomnom.play()
	if data["timer"] <= 0.0 or emotions["hunger"] >= 100.0:
		nomnom.stop()
		animation_player.play("bubble_fade_out")
		if _eating_food:
			_eating_food.queue_free()
			_eating_food = null
		_action_done()


# ═══════════════════════════════════════════════════════════════════════════════
# Food interaction
# ═══════════════════════════════════════════════════════════════════════════════

func pickup(holder: Node2D) -> void:
	is_held = true
	_holder = holder
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0


func release() -> void:
	is_held = false
	_holder = null
	collision_layer = _saved_collision_layer
	collision_mask = _saved_collision_mask
	_push_action_front(&"idle", {})


func receive_food(food_item: Node2D, from_player: Node2D) -> void:
	from_player.set("carried_food", null)
	from_player.set("nearby_food", null)
	if food_item.has_method("drop"):
		food_item.drop()
	food_item.global_position = global_position + Vector2(5, 5)
	_eating_food = food_item
	_food = null
	_action_queue = _action_queue.filter(
		func(e): return e["id"] != &"seek_food" and e["id"] != &"eat_food"
	)
	_push_action_front(&"eat_food", {
		"timer": randf_range(sleep_duration_min, sleep_duration_max)
	})


# ═══════════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════════

func _raise(emotion_key: StringName, amount: float) -> void:
	emotions[emotion_key] = minf(emotions[emotion_key] + amount, 100.0)


func _lower(emotion_key: StringName, amount: float) -> void:
	emotions[emotion_key] = maxf(emotions[emotion_key] - amount, 0.0)


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


func _get_food() -> Area2D:
	if not _food:
		var foods := get_tree().get_nodes_in_group("food")
		if foods.size() > 0:
			_food = foods[0] as Area2D
	return _food


func _on_sprite_animation_looped() -> void:
	if _sprite.animation == &"run":
		pop.pitch_scale = randf_range(0.9, 1.1)
		pop.play()
		
func _set_shader(intensity: float) -> void:
	if _sprite.material is ShaderMaterial:
		(_sprite.material as ShaderMaterial).set_shader_parameter("width", intensity)
	
	

func _on_mouse_entered() -> void:
	_set_shader(1.5)

func _on_mouse_exited() -> void:
	_set_shader(0.0)
