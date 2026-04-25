class_name CreatureSkinHandler
extends Node

@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var pattern: Sprite2D = $"../AnimatedSprite2D/Pattern"
@onready var mouth: Sprite2D = $"../AnimatedSprite2D/Eyes/Mouth"
@onready var eyes: Sprite2D = $"../AnimatedSprite2D/Eyes"
@onready var left_arm: Sprite2D = $"../AnimatedSprite2D/LeftArm"
@onready var right_arm: Sprite2D = $"../AnimatedSprite2D/RightArm"


const EYES_CAT = preload("res://art/game_art/creatures/base_creature/eyes_cat.png")
const EYES_CLOSED = preload("res://art/game_art/creatures/base_creature/eyes_closed.png")
const EYES_CL_SOFT = preload("res://art/game_art/creatures/base_creature/eyes_cl_soft.png")
const EYES_CL_TIGHT = preload("res://art/game_art/creatures/base_creature/eyes_cl_tight.png")
const EYES_CUTE = preload("res://art/game_art/creatures/base_creature/eyes_cute.png")
const EYES_EVIL = preload("res://art/game_art/creatures/base_creature/eyes_evil.png")
const EYES_HAPPY = preload("res://art/game_art/creatures/base_creature/eyes_happy.png")
const EYES_HEART = preload("res://art/game_art/creatures/base_creature/eyes_heart.png")
const EYES_HOLLOW = preload("res://art/game_art/creatures/base_creature/eyes_hollow.png")
const EYES_ISAAC = preload("res://art/game_art/creatures/base_creature/eyes_isaac.png")
const EYES_RETRO = preload("res://art/game_art/creatures/base_creature/eyes_retro.png")
const EYES_RETRO_INVERTED = preload("res://art/game_art/creatures/base_creature/eyes_retro_inverted.png")
const EYES_SAD = preload("res://art/game_art/creatures/base_creature/eyes_sad.png")
const EYES_YAWN = preload("res://art/game_art/creatures/base_creature/eyes_yawn.png")
const EYES_CUTE_DETERMINED = preload("res://art/game_art/creatures/base_creature/eyes_cute_determined.png")

const MOUTH_FROWN = preload("res://art/game_art/creatures/base_creature/mouth_frown.png")
const MOUTH_GRIN = preload("res://art/game_art/creatures/base_creature/mouth_grin.png")
const MOUTH_SMILE = preload("res://art/game_art/creatures/base_creature/mouth_smile.png")
const MOUTH_SURPRISE = preload("res://art/game_art/creatures/base_creature/mouth_surprise.png")
const MOUTH_TONGUE = preload("res://art/game_art/creatures/base_creature/mouth_tongue.png")
const MOUTH_UWU = preload("res://art/game_art/creatures/base_creature/mouth_uwu.png")


var eyes_states: Dictionary = {
	"base": EYES_CUTE, "happy": EYES_HAPPY, "cl_tight": EYES_CL_TIGHT, "sad": EYES_SAD,
	"determined": EYES_CUTE_DETERMINED, "closed": EYES_CLOSED, "cl_soft": EYES_CL_SOFT,
	"yawn": EYES_YAWN
}

var mouth_states: Dictionary = {
	"smile": MOUTH_SMILE, "grin": MOUTH_GRIN, "frown": MOUTH_FROWN,
	"tongue": MOUTH_TONGUE, "surprise": MOUTH_SURPRISE, "open": MOUTH_SURPRISE
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
