class_name BaseCreature
extends CharacterBody2D

# ═══════════════════════════════════════════════════════════════════════════════
# MeadowDeep — Base Creature
#
# All shared creature logic: emotions, action queue, movement, food handling.
# Extend this and override _on_ready_creature() for creature-specific setup.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Creature Const ───────────────────────────────────────────────────────────
const MOVE_ANIM: String = "walk_hop"
const MOVE_SFX: String = "uid://dlxj66hun1l4t"
const PICKUP_SFX: AudioStream = preload("uid://do140slmgni2k")

# ── Emotion bubbles ───────────────────────────────────────────────────────────
const SLEEP_BUBBLE   = preload("uid://egy4dv4ia6wo")
const LOVE_BUBBLE    = preload("uid://bqlkju2dhllnv")
const RELAXED_BUBBLE = preload("uid://belrasl0o441s")
const JOY_BUBBLE     = preload("uid://b2g1rvgiv1pxs")
const STAT_PALETTE_SHADER := preload("uid://boy12gwxxdf87")
const QUESTION_BUBBLE = preload("uid://bpd78uay7a3i6")


const EYES_CLOSED = preload("uid://skq2nptaavw4")
const EYES_CUTE = preload("uid://capxhpxiavcru")
const EYES_HAPPY = preload("uid://bpik3cnbaygqr")
const EYES_HEART = preload("uid://ca3ebsrm3drr")
const EYES_SAD = preload("uid://dnx21qcy3ajs2")
const MOUTH_FROWN = preload("uid://bxx62nul0ymkg")
const MOUTH_GRIN = preload("uid://vbg5tgivr72c")
const MOUTH_SMILE = preload("uid://bdc3kfksvk4uu")
const MOUTH_SURPRISE = preload("uid://cf2hju6xyyjsb")
const MOUTH_TONGUE = preload("uid://bajaqeslch3vf")


# ── Tuning ────────────────────────────────────────────────────────────────────
@export_group("Movement")
@export var movespeed: float        = 40.0
@export var wander_radius: float     = 80.0

@export_group("Action Timing")
@export var idle_time_min: float      = 1.5
@export var idle_time_max: float      = 4.0
@export var action_duration_min: float = 4.0
@export var action_duration_max: float = 10.0


# ── Action queue ──────────────────────────────────────────────────────────────
var action_queue := ActionQueue.new()
const BUSY_ACTIONS: Array[StringName] = [&"sleep", &"eat_food", &"absorb_item"]

# ── Scene refs ────────────────────────────────────────────────────────────────
@onready var _sprite: CreatureTextures         = %CreatureTextures
@onready var creature_node: CanvasGroup        = %CreatureNode
@onready var emotion_display: Sprite2D         = %EmotionDisplay
@onready var animation_player: AnimationPlayer = %EmotionPlayer
@onready var emotion_handler: Node             = %EmotionHandler
@onready var action_sfx: AudioStreamPlayer     = %ActionSFX
@onready var creature_stat_handler: Node       = %CreatureStatHandler
@onready var eyes: Sprite2D                    = %CreatureTextures/Eyes
@onready var mouth: Sprite2D                   = %CreatureTextures/Eyes/Mouth
@onready var creature_animation_handler: AnimationPlayer = %CreatureAnimationHandler
@onready var creature_skin_handler: CreatureSkinHandler  = $CreatureSkinHandler
@onready var hold_pos: Node2D = %CreatureTextures/HoldPos
@onready var collider: CollisionShape2D = %CollisionShape2D
@onready var mouse_detector: Area2D = $MouseDetector

# ── Creature Ref ────────────────────────────────────────────────────────────────
@export var instance: CreatureInstance : set = set_instance

const SNORE_SOUND  = preload("res://art/game_art/sfx/snore1.wav")
const NOMNOM_SOUND = preload("res://art/game_art/sfx/nomnom.wav")

# ── Node/Position refs ────────────────────────────────────────────────────────────────
var _home: Vector2
var _player: CharacterBody2D
var _food: Area2D
var _eating_food: Node2D = null
var _held_item: Node2D = null
const HOLD_OFFSET := Vector2(0, -18)
const ITEM_SEEK_RANGE := 200.0
var _holder: Node2D = null

var is_held := false
var _saved_collision_layer := 0
var _saved_collision_mask := 0
var _being_pet:bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if not instance:
		_ensure_stats()
	# Palette material must exist before _wire_instance triggers refresh_palette.
	var shader_material := ShaderMaterial.new()
	shader_material.shader = STAT_PALETTE_SHADER
	if creature_skin_handler:
		creature_skin_handler.adopt_palette_material(shader_material)
	_wire_instance()
	_establish_connections()
	_setup_creature_animation_handler()
	action_queue.action_started.connect(_on_action_start)
	action_queue.queue_emptied.connect(_on_queue_emptied)
	_on_ready_creature()
	action_queue.enqueue(&"idle", {})
	input_pickable = true


func set_instance(data: CreatureInstance) -> void:
	instance = data
	if not is_node_ready():
		return
	_wire_instance()


func _wire_instance() -> void:
	if not instance:
		return
	if not _home:
		_set_home_pos()
	if creature_stat_handler:
		creature_stat_handler.identity = instance.identity
		creature_stat_handler.creature_uid = instance.uid
	if emotion_handler:
		emotion_handler.instance = instance
	if creature_skin_handler:
		creature_skin_handler.identity = instance.identity
		if creature_stat_handler and not creature_stat_handler.stat_changed.is_connected(creature_skin_handler.refresh_palette):
			creature_stat_handler.stat_changed.connect(creature_skin_handler.refresh_palette)
		creature_skin_handler.refresh_palette()

# Override in child scripts for creature-specific setup (visuals, shaders, etc.)
func _on_ready_creature() -> void:
	pass


func _ensure_stats() -> void:
	if not instance:
		instance = CreatureInstance.new()
		instance.definition = CreatureDef.new()
		instance.definition.creature_name = name
		instance.identity = CreatureIdentity.new()
		instance.health = instance.definition.max_health
	if instance.uid == "":
		instance.uid = str(RNG.instance.randi())
	if not instance.identity:
		instance.identity = CreatureIdentity.new()
	var sb := instance.identity
	# Auto-generate grades if all at default (all C = grade index 2)
	var all_default := (
		sb.PWR.grade == GrowthStat.Grade.C and
		sb.AGI.grade == GrowthStat.Grade.C and
		sb.RES.grade == GrowthStat.Grade.C and
		sb.MYS.grade == GrowthStat.Grade.C and
		sb.FOC.grade == GrowthStat.Grade.C
	)
	if all_default:
		sb.randomize_grades()


func _physics_process(delta: float) -> void:
	if _being_pet:
		return
	if is_held:
		var carry_node := _holder.get("carry_position") as Node2D
		global_position = carry_node.global_position if carry_node else _holder.global_position + HOLD_OFFSET
		velocity = Vector2.ZERO
		return
	emotion_handler.tick_emotions(delta, action_queue.current_action)
	_check_emotion_triggers()
	_tick_current_action(delta)

# ═══════════════════════════════════════════════════════════════════════════════
# Action Queue
# ═══════════════════════════════════════════════════════════════════════════════

func _on_queue_emptied() -> void:
	action_queue.enqueue(&"idle", {})

func is_busy() -> bool:
	return action_queue.current_action in BUSY_ACTIONS

func _on_action_start(id: StringName, data: Dictionary) -> void:
	creature_animation_handler.RESET()
	_set_home_pos()
	match id:
		&"idle":
			if not _being_pet:
				creature_animation_handler.play_idle()
			if _held_item:
				toss_item(_held_item)
			velocity = Vector2.ZERO
			data["timer"] = randf_range(idle_time_min, idle_time_max)
		&"wander":
			if creature_animation_handler:
				creature_animation_handler.play_move_animation()
			if eyes:
				eyes.texture = EYES_CUTE
		&"sleep":
			velocity = Vector2.ZERO
			if creature_skin_handler:
				creature_skin_handler.set_eyes("closed")
			emotion_display.texture = SLEEP_BUBBLE
			animation_player.play("bubble_fade_in")
			action_sfx.stream = SNORE_SOUND
			action_sfx.play()
		&"seek_player":
			creature_animation_handler.play(&"frolic")
			creature_skin_handler.set_both("happy", "grin")
			emotion_display.texture = LOVE_BUBBLE
			animation_player.bubble_in_out()
		&"seek_food":
			if creature_animation_handler:
				creature_animation_handler.play_move_animation()
		&"eat_food":
			emotion_display.texture = JOY_BUBBLE
			animation_player.play(&"bubble_fade_in")
			creature_animation_handler.play(&"pickup_item")
			await creature_animation_handler.animation_finished
			creature_animation_handler.play(&"eat")
			data["timer"] = randf_range(action_duration_min, action_duration_max)
			action_sfx.stream = NOMNOM_SOUND
			action_sfx.pitch_scale = randf_range(0.9, 1.1)
			action_sfx.play()
		&"absorb_item":
			creature_animation_handler.play(&"absorb_item")
			creature_animation_handler.animation_finished.connect(_on_absorb_finished, CONNECT_ONE_SHOT)
		&"uppies":
			creature_animation_handler.play(&"uppies")
			data["timer"] = 3.0
			data["anim_name"] = &"uppies"


# ═══════════════════════════════════════════════════════════════════════════════
# Per-frame action ticks
# ═══════════════════════════════════════════════════════════════════════════════

func _check_emotion_triggers() -> void:
	if action_queue.current_action == &"absorb_item":
		return
	if instance.get_emotion(&"sleepiness") >= emotion_handler.sleepiness_sleep_threshold:
		if action_queue.current_action != &"sleep":
			action_queue.push_front(&"sleep", {
				"timer": randf_range(action_duration_min, action_duration_max)
			})
		return

	if instance.get_emotion(&"hunger") <= emotion_handler.hunger_seek_food_threshold:
		if action_queue.current_action != &"seek_food" and action_queue.current_action != &"eat_food" and not action_queue.contains(&"seek_food"):
			action_queue.enqueue(&"seek_food", {})
			return

	if instance.get_emotion(&"lonely") >= emotion_handler.lonely_seek_threshold:
		if action_queue.current_action != &"seek_player" and not action_queue.contains(&"seek_player"):
			action_queue.enqueue(&"seek_player", {})

	if instance.get_emotion(&"boredom") >= emotion_handler.boredom_wander_threshold:
		if action_queue.current_action != &"wander" and not action_queue.contains(&"wander"):
			action_queue.enqueue(&"wander", { "target": _pick_wander_target() })


func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if current.is_empty():
		return
	match current["id"]:
		&"idle":        _tick_idle(current["data"], delta)
		&"wander":      _tick_wander(current["data"], delta)
		&"sleep":       _tick_sleep(current["data"], delta)
		&"seek_player": _tick_seek_player(current["data"], delta)
		&"seek_food":   _tick_seek_food(current["data"], delta)
		&"eat_food":    _tick_eat_food(current["data"], delta)
		&"absorb_item": pass
		&"uppies":      _tick_anim_for_time(current["data"], delta)


func _tick_idle(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	if data["timer"] <= 0.0:
		action_queue.done()


func _tick_wander(data: Dictionary, _delta: float) -> void:
	if creature_animation_handler and creature_animation_handler.current_animation != MOVE_ANIM:
		creature_animation_handler.play_move_animation()
	var dir: Vector2 = data["target"] - global_position

	if dir.length() < 4.0:
		instance.lower_emotion(&"boredom", 40.0)
		action_queue.done()
		return
	velocity = dir.normalized() * movespeed
	creature_node.scale.x = -1.0 if velocity.x < 0 else 1.0
	move_and_slide()


func _tick_sleep(data: Dictionary, delta: float) -> void:
	if creature_animation_handler and creature_animation_handler.current_animation != &"sleep":
		creature_animation_handler.play(&"sleep")
	data["timer"] -= delta
	instance.lower_emotion(&"sleepiness", 20.0 * delta)
	if not action_sfx.playing:
		action_sfx.pitch_scale = randf_range(0.9, 1.1)
		action_sfx.play()
	if data["timer"] <= 0.0 or instance.get_emotion(&"sleepiness") <= 0.0:
		action_sfx.stop()
		action_queue.done()
		animation_player.play(&"bubble_fade_out")


func _tick_seek_player(_data: Dictionary, _delta: float) -> void:
	if creature_animation_handler and creature_animation_handler.current_animation != MOVE_ANIM:
		if creature_animation_handler.current_animation != &"frolic":
			creature_animation_handler.play_move_animation()
	var player := _get_player()
	if not player:
		action_queue.done()
		return
	var dir: Vector2 = player.global_position - global_position
	if dir.length() < 24.0:
		instance.lower_emotion(&"lonely", 60.0)
		instance.raise_emotion(&"joy", 30.0)
		action_queue.enqueue(&"uppies", {})
		action_queue.done()
		return

	velocity = dir.normalized() * movespeed
	creature_node.scale.x = -1.0 if velocity.x < 0 else 1.0
	move_and_slide()


func _tick_seek_food(_data: Dictionary, _delta: float) -> void:
	if creature_animation_handler and creature_animation_handler.current_animation != MOVE_ANIM:
		creature_animation_handler.play_move_animation()
	var food:CreatureFoodItem = _get_food()
	if not food:
		action_queue.done()
		return
	var dir: Vector2 = food.global_position - global_position
	if dir.length() < 20.0:
		if not food.being_eaten:
			food.start_being_eaten()
			_eating_food = food
			pickup_item(food)
			if creature_animation_handler and not creature_animation_handler.current_animation == &"pickup_item":
				creature_animation_handler.play(&"pickup_item")
			action_queue.enqueue(&"eat_food", {"timer": randf_range(action_duration_min, action_duration_max)})
		action_queue.done()
		return
	velocity = dir.normalized() * movespeed
	creature_node.scale.x = -1.0 if velocity.x < 0 else 1.0
	move_and_slide()


func _tick_eat_food(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	data["stage_timer"] = data.get("stage_timer", 0.0) + delta
	if data["stage_timer"] >= 1.0 and _eating_food:
		data["stage_timer"] -= 1.0
		_eating_food.decrement_stage()
		var food_data: FoodDef = _eating_food.get("item_data")
		if food_data and creature_stat_handler:
			creature_stat_handler.apply_food(food_data)
	instance.raise_emotion(&"hunger", 20.0 * delta)
	if not action_sfx.playing:
		action_sfx.pitch_scale = randf_range(0.9, 1.1)
		action_sfx.play()
	if data["timer"] <= 0.0 or instance.get_emotion(&"hunger") >= 100.0:
		action_sfx.stop()
		animation_player.play(&"bubble_fade_out")
		if _eating_food:
			if _eating_food.get("stages") == 0:
				drop_item(_eating_food)
				_eating_food.queue_free()
			else:
				toss_item(_eating_food)
				_eating_food.set("being_eaten", false)
			_eating_food = null
		Events.creature_stat_view_dismissed.emit(instance.uid)
		action_queue.done()

func _tick_anim_for_time(data: Dictionary, delta: float) -> void:
	if creature_animation_handler and creature_animation_handler.current_animation != data["anim_name"]:
		creature_animation_handler.play(data["anim_name"])
	data["timer"] -= delta
	if data["timer"] <= 0.0:
		action_queue.done()

# ═══════════════════════════════════════════════════════════════════════════════
# Food interaction
# ═══════════════════════════════════════════════════════════════════════════════

func be_pet() -> void:
	if _being_pet:
		return
	_being_pet = true
	velocity = Vector2.ZERO
	action_queue.push_front(&"idle", {})
	if creature_animation_handler and creature_animation_handler.current_animation != &"be_pet":
		creature_animation_handler.play(&"be_pet")
	emotion_display.texture = LOVE_BUBBLE
	animation_player.bubble_in_out()
	if instance:
		instance.identity.increment_bond(0.05)

func end_pet() -> void:
	if not _being_pet:
		return
	_being_pet = false
	if creature_skin_handler:
		creature_skin_handler.reset_base()

func pickup(holder: Node2D) -> void:
	if is_busy():
		return
	is_held = true
	_holder = holder
	action_queue.clear()
	creature_animation_handler.RESET()
	creature_animation_handler.play(&"idle")
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	Events.creature_stat_view_requested.emit(instance)

func pickup_item(item:WorldItemBase) -> void:
	if _held_item:
		return
	SFXPlayer.play(PICKUP_SFX)
	match item.item_data.get_category():
		item.item_data.ItemCategory.FOOD:
			_food = item
			_held_item = item
			item.pickup(self)
		_:
			_held_item = item
			item.pickup(self)

func drop_item(item:WorldItemBase) -> void:
	if not _held_item:
		return
	_food = null
	_held_item = null
	item.drop()

func toss_item(item:WorldItemBase) -> void:
	if not _held_item:
		return
	_food = null
	_held_item = null
	item.toss()

func release() -> void:
	is_held = false
	_holder = null
	collision_layer = _saved_collision_layer
	collision_mask = _saved_collision_mask
	action_queue.push_front(&"idle", {})
	_set_home_pos()
	Events.creature_stat_view_dismissed.emit(instance.uid)


func receive_food(food_item: Node2D, from_player: Node2D) -> void:
	if is_busy():
		return
	from_player.set("carried_food", null)
	from_player.set("nearby_food", null)
	if food_item.has_method("start_eating"):
		food_item.start_eating()
	_eating_food = food_item
	pickup_item(food_item)
	action_queue.remove(&"seek_food")
	action_queue.remove(&"eat_food")
	action_queue.push_front(&"eat_food", {
		"timer": randf_range(action_duration_min, action_duration_max)
	})
	if instance:
		instance.identity.increment_bond(0.05)
	Events.creature_stat_view_requested.emit(instance)

func receive_item(world_item: Node2D, from_player: Node2D) -> void:
	if is_busy():
		return
	from_player.set("carried_item", null)
	from_player.set("nearby_item", null)
	if world_item.has_method("pickup"):
		pickup_item(world_item)
	action_queue.push_front(&"absorb_item", {})
	if instance:
		instance.identity.increment_bond(0.05)
	Events.creature_stat_view_requested.emit(instance)



# ═══════════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════════


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


func _get_food() -> CreatureFoodItem:
	var foods := get_tree().get_nodes_in_group("food")
	if foods.is_empty():
		return null
	var nearest_food: CreatureFoodItem = null
	var nearest_dist: = INF
	for f in foods:
		if f.being_eaten:
			continue
		var dis := global_position.distance_squared_to(f.global_position)
		if dis < nearest_dist:
			nearest_dist = dis
			nearest_food = f
	return nearest_food


func _get_item() -> WorldItemBase:
	var nearest: WorldItemBase = null
	var nearest_dist := ITEM_SEEK_RANGE * ITEM_SEEK_RANGE
	for item in get_tree().get_nodes_in_group("items"):
		if item.get("is_carried"):  # skip already-held items
			continue
		var d := global_position.distance_squared_to(item.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = item
	return nearest


func _on_absorb_finished(anim_name: StringName) -> void:
	if anim_name != &"absorb_item":
		return
	creature_stat_handler.apply_item(_held_item.item_data)
	_held_item.queue_free()
	_held_item = null
	action_queue.done()
	action_queue.push_front(&"idle", {})

		
func _set_shader(intensity: float) -> void:
	if creature_node.material is ShaderMaterial:
		(creature_node.material as ShaderMaterial).set_shader_parameter("width", intensity)

func _set_home_pos() -> void:
	_home = global_position

func face_direction(dir_x: float) -> void:
	if dir_x == 0.0:
		return
	var target_scale := -1.0 if dir_x < 0.0 else 1.0
	if creature_node.scale.x != target_scale:
		creature_node.scale.x = target_scale

func _setup_creature_animation_handler() -> void:
	if MOVE_ANIM:
		creature_animation_handler.move_anim = MOVE_ANIM
	if MOVE_SFX:
		creature_animation_handler.move_SFX = load(MOVE_SFX)
		

func _establish_connections() -> void:
	if not mouse_detector.mouse_entered.is_connected(_on_mouse_detector_entered):
		mouse_detector.mouse_entered.connect(_on_mouse_detector_entered)
	if not mouse_detector.mouse_exited.is_connected(_on_mouse_detector_exited):
		mouse_detector.mouse_exited.connect(_on_mouse_detector_exited)
	if not mouse_detector.input_event.is_connected(_on_mouse_detector_input_event):
		mouse_detector.input_event.connect(_on_mouse_detector_input_event)

func _on_mouse_detector_input_event(_viewport: Node, input: InputEvent, _shape_idx: int) -> void:
	if input.is_action_pressed("right_mouse"):
		Events.camera_target_requested.emit(self)


func _on_mouse_detector_entered() -> void:
	print("mouse entered")
	_set_shader(4.5)

func _on_mouse_detector_exited() -> void:
	_set_shader(0.0)
