class_name CreatureTextures
extends AnimatedSprite2D

@export var base_textures: CreatureSkin

@onready var frames: AnimatedSprite2D = $"."
@onready var pattern: Sprite2D = $Pattern
@onready var eyes: Sprite2D = $Eyes
@onready var mouth: Sprite2D = $Eyes/Mouth
@onready var right_arm: Sprite2D = $RightArm
@onready var left_arm: Sprite2D = $LeftArm
