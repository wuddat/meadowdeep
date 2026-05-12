class_name Stats
extends Resource

signal stats_changed

@export var max_health := 1
@export var health: int : set = set_health
@export var block: int : set = set_block
@export var uid: String

# ── Identity ──────────────────────────────────────────────────────────
@export_group("Identity")
@export var species_id: String
@export var creature_name: String
@export var element_type: String        # e.g. "verdant", "ember"

# ── Visuals ──────────────────────────────────────────────────────────
@export_group("Visuals")
@export var frames: SpriteFrames
@export var art: Texture
@export var icon: Texture

# ── Moves ──────────────────────────────────────────────────────────
@export_group("Moves")
@export var move_ids: Array[String] = []        # learnable pool
@export var starting_moves: Array[String] = []  # moves at creation


func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()


func set_block(value: int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()


func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	var initial_damage = damage
	damage = clampi(damage - block, 0, damage)
	block = clampi(block - initial_damage, 0, block)
	health -= damage


func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	stats_changed.emit()


func gain_block(amount: int) -> void:
	block += amount


func create_instance() -> Resource:
	var instance: Stats = self.duplicate(true)
	instance.health = max_health
	instance.block = 0
	return instance
