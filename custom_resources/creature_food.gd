class_name CreatureFood
extends MeadowWorldItem

# ── Food Stats ────────────────────────────────────────────────────────────────
@export_group("Food Stats")
@export var durability: int
@export var creature_attribute: StatBlock.StatType
@export var attribute_increment: int


func _init() -> void:
	category = ItemCategory.FOOD
