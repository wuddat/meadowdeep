class_name FoodDef
extends ItemDef

# ── Food Stats ────────────────────────────────────────────────────────────────
@export_group("Food Stats")
@export var durability: int
@export var creature_attribute: GrowthStat.StatType
@export var attribute_increment: int


func _init() -> void:
	category = ItemCategory.FOOD
