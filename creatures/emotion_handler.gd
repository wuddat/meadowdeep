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

# Set by the owning BaseCreature on _ready.
var instance: CreatureInstance


func tick_emotions(delta: float, current_action: StringName) -> void:
	if instance == null:
		return
	instance.raise_emotion(&"sleepiness", sleepiness_rate * delta)
	instance.raise_emotion(&"lonely",     lonely_rate     * delta)

	if current_action == &"idle":
		instance.raise_emotion(&"boredom", boredom_rate * delta)
		instance.lower_emotion(&"hunger",  hunger_rate * 0.5 * delta)
	else:
		instance.lower_emotion(&"boredom", boredom_rate * 0.5 * delta)
		instance.lower_emotion(&"hunger",  hunger_rate * delta)
