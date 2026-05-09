class_name CreatureSkinHandler
extends Node

@onready var animated_sprite_2d: AnimatedSprite2D = $"../CreatureTextures"
@onready var pattern: Sprite2D = $"../CreatureTextures/Pattern"
@onready var mouth: Sprite2D = $"../CreatureTextures/Eyes/Mouth"
@onready var eyes: Sprite2D = $"../CreatureTextures/Eyes"
@onready var left_arm: Sprite2D = $"../CreatureTextures/LeftArm"
@onready var right_arm: Sprite2D = $"../CreatureTextures/RightArm"


const EYES_CLOSED = preload("res://art/game_art/creatures/greenie/eyes_cl.png")
const EYES_CL_SOFT = preload("res://art/game_art/creatures/greenie/eyes_cl.png")
const EYES_CL_TIGHT = preload("res://art/game_art/creatures/greenie/eyes_X.png")
const EYES_CUTE = preload("res://art/game_art/creatures/greenie/eyes_op.png")
const EYES_EVIL = preload("res://art/game_art/creatures/greenie/eyes_ang.png")
const EYES_HAPPY = preload("res://art/game_art/creatures/greenie/eyes_happy.png")
const EYES_HEART = preload("res://art/game_art/creatures/base_creature/eyes_heart.png")
const EYES_SAD = preload("res://art/game_art/creatures/greenie/eyes_sad.png")
const EYES_YAWN = preload("res://art/game_art/creatures/greenie/eyes_slant.png")
const EYES_CUTE_DETERMINED = preload("res://art/game_art/creatures/greenie/eyes_ang.png")

const MOUTH_FROWN = preload("res://art/game_art/creatures/greenie/mouth_frown.png")
const MOUTH_GRIN = preload("res://art/game_art/creatures/greenie/mouth_grin.png")
const MOUTH_SMILE = preload("res://art/game_art/creatures/greenie/mouth_uwu.png")
const MOUTH_SURPRISE = preload("res://art/game_art/creatures/greenie/mouth_surprise.png")
const MOUTH_UWU = preload("res://art/game_art/creatures/greenie/mouth_uwu.png")


var eyes_states: Dictionary = {
	"base": EYES_CUTE, "happy": EYES_HAPPY, "cl_tight": EYES_CL_TIGHT, "sad": EYES_SAD,
	"determined": EYES_CUTE_DETERMINED, "closed": EYES_CLOSED, "cl_soft": EYES_CL_SOFT,
	"yawn": EYES_YAWN, "open": EYES_CUTE,
}

var mouth_states: Dictionary = {
	"smile": MOUTH_SMILE, "grin": MOUTH_GRIN, "frown": MOUTH_FROWN,
	 "surprise": MOUTH_SURPRISE, "open": MOUTH_SURPRISE
}

var base_textures: Dictionary = {"eyes": null, "mouth": null}

func _ready() -> void:
	if not eyes.texture or not mouth.texture:
		apply_skin()
	base_textures["eyes"] = eyes.texture
	base_textures["mouth"] = mouth.texture

func apply_skin() -> void:
	set_eyes("base")
	set_mouth("smile")

func set_eyes(state: String) -> void:
	if eyes_states.has(state):
		eyes.texture = eyes_states[state]

func set_mouth(state: String) -> void:
	if mouth_states.has(state):
		mouth.texture = mouth_states[state]
		
func set_both(eye_state:String, mouth_state:String) -> void:
	set_eyes(eye_state)
	set_mouth(mouth_state)

func reset_base() -> void:
	eyes.texture = base_textures["eyes"]
	mouth.texture = base_textures["mouth"]
