extends Node2D

@onready var body: AnimatedSprite2D = $Body
@onready var eyes: AnimatedSprite2D = $Eyes
@onready var mouth: AnimatedSprite2D = $Mouth

const EYES_1 = preload("uid://b8gb1vvx20p6k")
const EYES_2 = preload("uid://cyc33641aeu7l")
const EYES_3 = preload("uid://xk3kdc683msx")
const EYES_4 = preload("uid://cstedqux7kdv6")
const MOUTH_1 = preload("uid://56m83agxkd2s")
const MOUTH_2 = preload("uid://c3yoykqopiwex")
const MOUTH_3 = preload("uid://cfaamh8wchmvh")
const MOUTH_4 = preload("uid://btpgy10qt543w")
const EYES_5 = preload("uid://bb7valacfs3uh")
const MOUTH_5 = preload("uid://b2fbfukt7buy0")


const EYE_TEXTURES   = [EYES_1,  EYES_2,  EYES_3,  EYES_4, EYES_5]
const MOUTH_TEXTURES = [MOUTH_1, MOUTH_2, MOUTH_3, MOUTH_4, MOUTH_5]


func _ready() -> void:
	eyes.sprite_frames  = _make_frames(EYE_TEXTURES[randi() % EYE_TEXTURES.size()])
	mouth.sprite_frames = _make_frames(MOUTH_TEXTURES[randi() % MOUTH_TEXTURES.size()])
	eyes.play("default")
	mouth.play("default")
	_randomize_color()


func _randomize_color() -> void:
	var c := Color.from_hsv(randf(), randf_range(0.5, 0.9), randf_range(0.6, 1.0))
	body.modulate  = c
	#eyes.modulate  = c
	#mouth.modulate = c


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		var frame    := eyes.frame
		var progress := eyes.frame_progress
		eyes.sprite_frames  = _make_frames(EYE_TEXTURES[randi() % EYE_TEXTURES.size()])
		mouth.sprite_frames = _make_frames(MOUTH_TEXTURES[randi() % MOUTH_TEXTURES.size()])
		eyes.play("default")
		mouth.play("default")
		eyes.set_frame_and_progress(frame, progress)
		mouth.set_frame_and_progress(frame, progress)
		_randomize_color()


func _make_frames(tex: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 10)
	var cols := tex.get_width()  / 32
	var rows := tex.get_height() / 32
	for row in rows:
		for col in cols:
			var atlas := AtlasTexture.new()
			atlas.atlas  = tex
			atlas.region = Rect2(col * 32, row * 32, 32, 32)
			frames.add_frame("default", atlas)
	return frames
