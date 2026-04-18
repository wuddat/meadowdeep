class_name EmotionHandler
extends Node

@export_group("Emotion Rates (per second)")
@export var boredom_rate: float      = 4.0
@export var lonely_rate: float       = 2.0
@export var sleepiness_rate: float   = 1.5
@export var hunger_rate: float       = 2.0

@export_group("Emotion Thresholds")
@export var boredom_wander_threshold: float   = 60.0
@export var lonely_seek_threshold: float      = 80.0
@export var sleepiness_sleep_threshold: float = 90.0
@export var hunger_seek_food_threshold: float = 50.0

# ── Emotion state ─────────────────────────────────────────────────────────────
@export var emotions: Dictionary = {
	"boredom":    0.0,
	"lonely":     0.0,
	"sleepiness": 0.0,
	"joy":        0.0,
	"fear":       0.0,
	"hunger":     55.0,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# ═══════════════════════════════════════════════════════════════════════════════
# Emotions
# ═══════════════════════════════════════════════════════════════════════════════

func tick_emotions(delta: float, current_action: StringName) -> void:
	raise("sleepiness", sleepiness_rate * delta)
	raise("lonely",     lonely_rate     * delta)

	if current_action == &"idle":
		raise("boredom", boredom_rate * delta)
		lower("hunger", hunger_rate * 0.5 * delta)
	else:
		lower("boredom", boredom_rate * 0.5 * delta)
		lower("hunger", hunger_rate * delta)


func raise(emotion_key: StringName, amount: float) -> void:
	emotions[emotion_key] = minf(emotions[emotion_key] + amount, 100.0)


func lower(emotion_key: StringName, amount: float) -> void:
	emotions[emotion_key] = maxf(emotions[emotion_key] - amount, 0.0)
