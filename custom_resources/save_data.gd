class_name SaveData
extends Resource

@export var save_version: int = 1
@export var creatures: Array[CreatureInstance] = []
@export var ruins_creature: CreatureInstance = null
@export var inventory: Inventory
@export var current_scene: String = ""
