extends CharacterBody2D

const STAT_VIEW_SCENE := preload("res://scenes/meadow/creature_stat_view.tscn")

@export var speed: float = 200.0
@export var roll_speed: float = 400.0
@export var roll_duration: float = 0.3
@export var stats:PlayerData

@onready var sprite: AnimatedSprite2D = $Player
@onready var carry_position: Node2D = %CarryPosition
@onready var drop_position: Node2D = %DropPosition

var is_rolling := false
var roll_timer := 0.0
var roll_direction := Vector2.ZERO
var is_attacking := false

var nearby_food: Node2D = null
var nearby_creature: Node2D = null
var nearby_item: Node2D = null
var nearby_egg: Node2D = null

var held_creature: Node2D = null
var carried_food: Node2D = null
var carried_item: Node2D = null

var _stat_view: Control = null
var _drop_offset_x: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_drop_offset_x = absf(drop_position.position.x)

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
				drop_position.position.x = _drop_offset_x * (-1.0 if sprite.flip_h else 1.0)
		else:
			var idle_anim := "carry" if held_creature || carried_food || carried_item else "idle"
			if sprite.animation != idle_anim:
				sprite.play(idle_anim)

	move_and_slide()

	# Food delivery on collision
	if carried_food:
		for i in get_slide_collision_count():
			var collider = get_slide_collision(i).get_collider()
			if collider.has_method("receive_food") and collider.instance.get_emotion(&"hunger") < 80.0:
				collider.receive_food(carried_food, self)
				break
	
	if carried_item:
		for i in get_slide_collision_count():
			var collider = get_slide_collision(i).get_collider()
			if collider.has_method("receive_item"):
				collider.receive_item(carried_item, self)
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

#listed by prio
	if held_creature:
		held_creature.global_position = drop_position.global_position
		held_creature.release()
		held_creature = null
		_hide_stat_view()
	elif nearby_creature:
		nearby_creature.pickup(self)
		held_creature = nearby_creature
		nearby_creature = null
		_show_stat_view()
	elif carried_food:
		carried_food.global_position = drop_position.global_position
		carried_food.drop()
		carried_food = null
	elif carried_item:
		carried_item.global_position = drop_position.global_position
		carried_item.drop()
		carried_item = null
	elif nearby_food:
		nearby_food.pickup(self)
		carried_food = nearby_food
		nearby_food = null
	elif nearby_item:
		nearby_item.pickup(self)
		carried_item = nearby_item
		nearby_item = null
	elif nearby_egg:
		nearby_egg.begin_hatch()


func _show_stat_view() -> void:
	if not held_creature or not held_creature.get("instance"):
		print("[StatView] no instance on held creature — panel skipped")
		return
	if _stat_view:
		_stat_view.queue_free()
	var canvas := CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)
	_stat_view = STAT_VIEW_SCENE.instantiate()
	canvas.add_child(_stat_view)
	_stat_view.populate(held_creature.instance)
	_stat_view.update_display()
	print("[StatView] shown for: ", held_creature.instance.definition.creature_name)


func _hide_stat_view() -> void:
	if _stat_view:
		_stat_view.get_parent().queue_free()
		_stat_view = null
		print("[StatView] hidden")


func _on_player_animation_finished() -> void:
	is_attacking = false


func _on_ruins_entrance_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
