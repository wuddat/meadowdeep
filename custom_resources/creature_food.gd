class_name CreatureFood
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EXOTIC }

@export var name: String
@export var durability: int
@export var creature_attribute: String
@export var rarity: Rarity
@export var value: int
@export var art: Texture2D = preload("res://art/game_art/items/berry.png")
