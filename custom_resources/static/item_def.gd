class_name ItemDef
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EXOTIC }
enum ItemCategory { FOOD, TOY, MEDICINE, RELIC, STAT_FRAGMENT, ESSENCE, INFUSION }

# ── Identity ──────────────────────────────────────────────────────────────────
@export_group("Identity")
@export var id: String
@export var display_name: String
@export var description: String
@export var category: ItemCategory = ItemCategory.FOOD
@export var rarity: Rarity = Rarity.COMMON
@export var value: int

# ── Visuals ───────────────────────────────────────────────────────────────────
@export_group("Visuals")
@export var art: Texture2D

func get_category() -> ItemCategory:
	return category
