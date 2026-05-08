class_name MeadowWorldItem
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EXOTIC }
enum ItemCategory { FOOD, TOY, MEDICINE, RELIC, STAT_FRAGMENT, ESSENCE, INFUSION }

# ── Identity ──────────────────────────────────────────────────────────────────
@export_group("Identity")
var id: String
var uid: String
@export var display_name: String
@export var description: String
@export var category: ItemCategory = ItemCategory.FOOD
@export var rarity: Rarity = Rarity.COMMON
@export var value: int

# ── Visuals ───────────────────────────────────────────────────────────────────
@export_group("Visuals")
@export var art: Texture2D

func _ready() -> void:
	id = str(RNG.instance.randi())
	uid = id

func get_category() -> ItemCategory:
	return category
