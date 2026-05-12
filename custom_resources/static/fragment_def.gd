class_name FragmentDef
extends ItemDef

# ── Fragment Stats ────────────────────────────────────────────────────────────────
@export_group("Fragment Stats")
@export var creature_attribute: GrowthStat.StatType
@export var pips: int = 1


func _init() -> void:
	category = ItemCategory.STAT_FRAGMENT
