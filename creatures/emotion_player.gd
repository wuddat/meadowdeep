class_name EmotionPlayer
extends AnimationPlayer

@export var emotion_display: Sprite2D

func bubble_in_out() -> void:
	play("bubble_fade_in")
	await animation_finished
	play("bubble_fade_out")
