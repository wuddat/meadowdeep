class_name CreatureAnimationHandler
extends AnimationPlayer

signal damage_frame

@export var emotion_display: Node2D
@export var emotion_player: AnimationPlayer
@export var particles: Particles

var move_SFX: AudioStream
var move_anim: String = "move_hop"

# ── Emotion bubbles ───────────────────────────────────────────────────────────
const SLEEP_BUBBLE   = preload("res://art/game_art/emoticons/sleep.png")
const LOVE_BUBBLE    = preload("res://art/game_art/emoticons/love.png")
const RELAXED_BUBBLE = preload("res://art/game_art/emoticons/relaxed.png")
const JOY_BUBBLE     = preload("res://art/game_art/emoticons/joy.png")
const HIGHLIGHT_SHADER := preload("res://art/game_art/shaders/highlight.gdshader")
const QUESTION_BUBBLE = preload("res://art/game_art/emoticons/question.png")

const CURIOUS_1 = preload("res://art/game_art/sfx/curious1.wav")
const HAH = preload("uid://c7des6ggaas3i")

const ABSORB_ITEM = preload("uid://bhgt7fphiyuus")
const GIVE_ITEM = preload("uid://bavc86swxvjti")
const SFX_VOL: float = -20.0

const IDLE_WEIGHTS := {
	"think": 1,
	"idle": 20,
	"wave": 1,
}

func play_idle() -> void:
	play("RESET")
	if not emotion_player.is_node_ready():
		return
	if emotion_player.is_playing() and emotion_player.assigned_animation == "bubble_fade_in":
		await emotion_player.animation_finished
		emotion_player.play("bubble_fade_out")
		await emotion_player.animation_finished
	var anim := _select_idle_anim(IDLE_WEIGHTS)
	
	if anim == "think":
		SFXPlayer.pitch_play(CURIOUS_1)
		emotion_display.texture = QUESTION_BUBBLE
		emotion_bubble_fade_in_out()
	if anim == "wave":
		SFXPlayer.play(HAH)
		
	queue(anim)

func RESET() -> void:
	play("RESET")
	advance(0.0)


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

func emit_damage() -> void:
	damage_frame.emit()

func play_move_animation() -> void:
	if current_animation != move_anim:
		play(move_anim)

func footstep() -> void:
	if move_SFX:
		SFXPlayer.pitch_play(move_SFX)

func release_particles() -> void:
	if particles:
		particles.emit_particles()
		SFXPlayer.play(ABSORB_ITEM)

func play_growth_item_received_SFX() -> void:
	SFXPlayer.play(GIVE_ITEM)
