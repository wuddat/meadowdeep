class_name AnimatedHitBox
extends Node2D

signal deliver_damage

# A committing, animation-driven bite. The AnimatedSprite2D drives the hit: on
# `damage_frame` we fire a one-shot HitBox.deliver(); the fang frees itself when the
# (non-looping) animation finishes. We just inject what to deal and play it.


@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var hit_box: HitBox = %HitBox
@export var damage_frame: int
@export var attack_frames: SpriteFrames
const BITE = preload("uid://dsjb816efs7tx")
const ANIMATION = &"default"


func _ready() -> void:
	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_anim_finished):
		animated_sprite.animation_finished.connect(_on_anim_finished)
	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)


# Called by the spawner. Effects + source are injected into the HitBox;
func setup(effects: Array[Effect], source: Node) -> void:
	if hit_box:
		hit_box.setup(effects, source)
	if animated_sprite:
		animated_sprite.play(ANIMATION)
	else:
		queue_free()  # nothing to play — kill

func _on_frame_changed() -> void:
	if animated_sprite.frame == damage_frame:
		hit_box.deliver()  # frame-synced one-shot; monitoring is already live from spawn

func _on_anim_finished() -> void:
	queue_free()
