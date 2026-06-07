class_name CreatureSkinHandler
extends Node

@export var stat_palette: StatPalette = StatPalette.new()
@export var identity: CreatureIdentity


@onready var pattern: Sprite2D = $"../CreatureNode/CreatureTextures/Pattern"
@onready var eyes: Sprite2D = $"../CreatureNode/CreatureTextures/Eyes"
@onready var mouth: Sprite2D = $"../CreatureNode/CreatureTextures/Eyes/Mouth"
@onready var right_arm: Sprite2D = $"../CreatureNode/CreatureTextures/RightArm"
@onready var left_arm: Sprite2D = $"../CreatureNode/CreatureTextures/LeftArm"
@onready var creature_textures: CreatureTextures = %CreatureTextures

const GREENIE_FRAMES = preload("res://scenes/ruins/greenie_frames.tres")
const BLUIE_FRAMES = preload("uid://o3im86e3myve")
const PINKIE_FRAMES = preload("uid://rmy5i47q2y07")


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
const EYES_TEARS = preload("uid://b41u2vlw0idid")

const MOUTH_FROWN = preload("res://art/game_art/creatures/greenie/mouth_frown.png")
const MOUTH_GRIN = preload("res://art/game_art/creatures/greenie/mouth_grin.png")
const MOUTH_SMILE = preload("res://art/game_art/creatures/greenie/mouth_uwu.png")
const MOUTH_SURPRISE = preload("res://art/game_art/creatures/greenie/mouth_surprise.png")
const MOUTH_UWU = preload("res://art/game_art/creatures/greenie/mouth_uwu.png")
const MOUTH_HURT = preload("uid://sf2pw5whfepr")


var eyes_states: Dictionary = {
	"base": EYES_CUTE, "happy": EYES_HAPPY, "cl_tight": EYES_CL_TIGHT, "sad": EYES_SAD,
	"determined": EYES_CUTE_DETERMINED, "closed": EYES_CLOSED, "cl_soft": EYES_CL_SOFT,
	"yawn": EYES_YAWN, "open": EYES_CUTE, "tears": EYES_TEARS
}

var mouth_states: Dictionary = {
	"smile": MOUTH_SMILE, "grin": MOUTH_GRIN, "frown": MOUTH_FROWN,
	 "surprise": MOUTH_SURPRISE, "open": MOUTH_SURPRISE, "hurt": MOUTH_HURT,
}

var base_textures: Dictionary = {"eyes": EYES_CUTE, "mouth": MOUTH_SMILE}
var _palette_material: ShaderMaterial

func _ready() -> void:
	apply_skin()
	base_textures["eyes"] = eyes.texture
	base_textures["mouth"] = mouth.texture


# Called by base_creature once the palette ShaderMaterial is built.
# Apply to body + pattern + arms; eyes/mouth keep their own textures.
func adopt_palette_material(mat: ShaderMaterial) -> void:
	_palette_material = mat
	if creature_textures:
		creature_textures.material = mat
	if pattern:
		pattern.material = mat
	if left_arm:
		left_arm.material = mat
	if right_arm:
		right_arm.material = mat
	#if eyes:
		#eyes.material = mat
	if mouth:
		mouth.material = mat


func refresh_palette(_uid: String = "") -> void:
	if not _palette_material or not identity:
		return
	_palette_material.set_shader_parameter("gradient", StatPalette.build_gradient(identity))
	var pwr_pts := identity.PWR.get_points()
	var agi_pts := identity.AGI.get_points()
	if pwr_pts > 50:
		creature_textures.sprite_frames = PINKIE_FRAMES
	elif agi_pts > 50:
		creature_textures.sprite_frames = BLUIE_FRAMES
	elif agi_pts > pwr_pts:
		creature_textures.sprite_frames = BLUIE_FRAMES
	else: creature_textures.sprite_frames = GREENIE_FRAMES

func apply_skin() -> void:
	set_eyes("base")
	set_mouth("smile")


# Picks a random eyes/mouth pairing from the pools and re-caches base_textures
# so reset_base reverts to the hatched look, not the scene default.
func randomize_skin() -> void:
	var eye_key: String = eyes_states.keys().pick_random()
	var mouth_key: String = mouth_states.keys().pick_random()
	set_both(eye_key, mouth_key)
	base_textures["eyes"] = eyes.texture
	base_textures["mouth"] = mouth.texture

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
