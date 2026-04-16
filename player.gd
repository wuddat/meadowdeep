extends CharacterBody2D

const STAT_VIEW_SCENE := preload("res://scenes/meadow/creature_stat_view.tscn")

@export var speed: float = 200.0
@export var roll_speed: float = 400.0
@export var roll_duration: float = 0.3

@onready var sprite: AnimatedSprite2D = $Player

var is_rolling := false
var roll_timer := 0.0
var roll_direction := Vector2.ZERO
var is_attacking := false

var nearby_food: Node2D = null
var carried_food: Node2D = null

var nearby_creature: Node2D = null
var held_creature: Node2D = null
var _stat_view: Control = null

var nearby_egg: Node2D = null


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta):
	var input_vector = Vector2.ZERO

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if is_rolling:
		roll_timer -= delta
		velocity = roll_direction * roll_speed
		if roll_timer <= 0:
			is_rolling = false

	elif Input.is_action_just_pressed("ui_accept"):
		is_rolling = true
		roll_timer = roll_duration
		roll_direction = input_vector if input_vector != Vector2.ZERO else Vector2.RIGHT
		sprite.play("roll")

	elif Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		velocity = Vector2.ZERO
		sprite.play("attack")

	elif not is_attacking:
		velocity = input_vector * speed
		if input_vector != Vector2.ZERO:
			if sprite.animation != "run":
				sprite.play("run")
			if input_vector.x != 0:
				sprite.flip_h = input_vector.x < 0
		else:
			if sprite.animation != "idle":
				sprite.play("idle")

	move_and_slide()

	# Food delivery on collision
	if carried_food:
		for i in get_slide_collision_count():
			var collider = get_slide_collision(i).get_collider()
			if collider.has_method("receive_food") and collider.emotions.get("hunger", 100.0) < 80.0:
				collider.receive_food(carried_food, self)
				break

	# Track nearby creature via slide collision
	if not held_creature:
		nearby_creature = null
		for i in get_slide_collision_count():
			var collider = get_slide_collision(i).get_collider()
			if collider.has_method("pickup"):
				nearby_creature = collider
				break


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo):
		return

	# Priority: drop held creature → hatch egg → drop/pick food
	if held_creature:
		held_creature.release()
		held_creature = null
		_hide_stat_view()
	elif nearby_egg:
		nearby_egg.begin_hatch()
	elif nearby_creature:
		nearby_creature.pickup(self)
		held_creature = nearby_creature
		nearby_creature = null
		_show_stat_view()
	elif carried_food:
		carried_food.drop()
		carried_food = null
	elif nearby_food:
		nearby_food.pickup(self)
		carried_food = nearby_food
		nearby_food = null


func _show_stat_view() -> void:
	if not held_creature or not held_creature.get("creature_stats"):
		print("[StatView] no creature_stats on held creature — panel skipped")
		return
	if _stat_view:
		_stat_view.queue_free()
	var canvas := CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)
	_stat_view = STAT_VIEW_SCENE.instantiate()
	canvas.add_child(_stat_view)
	_stat_view.populate(held_creature.creature_stats)
	_stat_view.update_display()
	print("[StatView] shown for: ", held_creature.creature_stats.creature_name)


func _hide_stat_view() -> void:
	if _stat_view:
		_stat_view.get_parent().queue_free()
		_stat_view = null
		print("[StatView] hidden")


func _on_player_animation_finished() -> void:
	is_attacking = false
