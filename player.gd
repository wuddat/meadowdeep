extends CharacterBody2D

@export var speed: float = 200.0
@export var roll_speed: float = 400.0
@export var roll_duration: float = 0.3

@onready var sprite: AnimatedSprite2D = $Player 

var is_rolling := false
var roll_timer := 0.0
var roll_direction := Vector2.ZERO
var is_attacking := false

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	# Movement input (WASD)
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	# Handle roll
	if is_rolling:
		roll_timer -= delta
		velocity = roll_direction * roll_speed
		
		if roll_timer <= 0:
			is_rolling = false
	
	# Start roll
	elif Input.is_action_just_pressed("ui_accept"):
		is_rolling = true
		roll_timer = roll_duration
		roll_direction = input_vector if input_vector != Vector2.ZERO else Vector2.RIGHT
		sprite.play("roll")
	
	# Attack
	elif Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		velocity = Vector2.ZERO
		sprite.play("attack")
	
	# Normal movement
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


func _on_player_animation_finished() -> void:
	is_attacking = false
	print("this ran")
