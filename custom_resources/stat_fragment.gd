class_name StatFragment
extends MeadowWorldItem

# ── Fragment Stats ────────────────────────────────────────────────────────────────
@export_group("Fragment Stats")
@export var creature_attribute: StatBlock.StatType
@export var pips: int = 1


func _init() -> void:
	category = ItemCategory.STAT_FRAGMENT
