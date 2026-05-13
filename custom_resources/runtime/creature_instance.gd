# creature_instance.gd
# A specific creature in the world. Holds live combat state, emotion values,
# and references to the species definition and persistent identity.
# What the player owns, what enters the ruins, what gets saved.
class_name CreatureInstance
extends Resource

signal stats_changed
signal emotions_changed

@export var definition: CreatureDef
@export var identity: CreatureIdentity

@export var uid: String

# ── Combat ────────────────────────────────────────────────────────────────────
@export var health: int : set = set_health
@export var block: int : set = set_block

# ── Meadow ────────────────────────────────────────────────────────────────────
@export var emotions: Dictionary = {
	"boredom":    0.0,
	"lonely":     0.0,
	"sleepiness": 0.0,
	"joy":        0.0,
	"fear":       0.0,
	"hunger":     55.0,
}

# ── Transient ─────────────────────────────────────────────────────────────────
@export var is_battling: bool = false
@export var current_action_id: StringName = &""


func set_health(value: int) -> void:
	var max_hp: int = definition.max_health if definition else 1
	health = clampi(value, 0, max_hp)
	stats_changed.emit()


func set_block(value: int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()


func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	var initial_damage := damage
	damage = clampi(damage - block, 0, damage)
	block = clampi(block - initial_damage, 0, block)
	health -= damage


func heal(amount: int) -> void:
	var max_hp: int = definition.max_health if definition else 1
	health = min(health + amount, max_hp)
	stats_changed.emit()


func gain_block(amount: int) -> void:
	block += amount


# ── Emotion helpers ───────────────────────────────────────────────────────────
func raise_emotion(key: StringName, amount: float) -> void:
	emotions[key] = minf(emotions.get(key, 0.0) + amount, 100.0)
	emotions_changed.emit()


func lower_emotion(key: StringName, amount: float) -> void:
	emotions[key] = maxf(emotions.get(key, 0.0) - amount, 0.0)
	emotions_changed.emit()


func get_emotion(key: StringName) -> float:
	return emotions.get(key, 0.0)
