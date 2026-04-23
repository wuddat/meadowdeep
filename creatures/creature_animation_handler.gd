class_name CreatureAnimationHandler
extends AnimationPlayer

@export var base_eyes: CompressedTexture2D
@export var emotion_display: Node2D
@export var emotion_player: AnimationPlayer

# ── Emotion bubbles ───────────────────────────────────────────────────────────
const SLEEP_BUBBLE   = preload("res://art/game_art/emoticons/sleep.png")
const LOVE_BUBBLE    = preload("res://art/game_art/emoticons/love.png")
const RELAXED_BUBBLE = preload("res://art/game_art/emoticons/relaxed.png")
const JOY_BUBBLE     = preload("res://art/game_art/emoticons/joy.png")
const HIGHLIGHT_SHADER := preload("res://art/game_art/shaders/highlight.gdshader")
const QUESTION_BUBBLE = preload("res://art/game_art/emoticons/question.png")

const CURIOUS_1 = preload("res://art/game_art/sfx/curious1.wav")
const IDLE_WEIGHTS := {
	"think": 1,
	"hover": 4,
}

func play_idle() -> void:
	play("RESET")
	if emotion_player.is_playing() and emotion_player.assigned_animation == "bubble_fade_in":
		await emotion_player.animation_finished
		emotion_player.play("bubble_fade_out")
		await emotion_player.animation_finished
	var anim := _select_idle_anim(IDLE_WEIGHTS)
	
	if anim == "think":
		SFXPlayer.pitch_play(CURIOUS_1)
		emotion_display.texture = QUESTION_BUBBLE
		emotion_bubble_fade_in_out()
	queue(anim)
	
func _select_idle_anim(weights: Dictionary) -> String:
	var total: int = 0
	for w in weights.values(): total += w
	var roll := RNG.instance.randi() % total
	var acc:= 0
	for anim in weights:
		acc += weights[anim]
		if roll < acc:
			return anim
	return weights.keys()[0]


func emotion_bubble_fade_in_out() -> void:
	if emotion_player.is_playing():
		emotion_player.play("bubble_fade_out")
		await emotion_player.animation_finished
	emotion_player.play("bubble_fade_in")
	emotion_player.play("bubble_fade_out")
