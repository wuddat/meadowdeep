#player_data.gd
class_name PlayerData
extends Resource

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture2D

@export_group("Gameplay Data")
@export var inventory: Inventory
var ruins_creature: CreatureInstance = null

@export_group("Creature Data")
@export var starting_party: Array[String] = []
@export var creatures: Array[CreatureInstance] = []


func create_instance() -> Resource:
	var instance: PlayerData = self.duplicate()
	instance.creatures = []
	instance.inventory = inventory.duplicate(true) if inventory else Inventory.new()
	for species_id in starting_party:
		var creature := CreatureData.create_creature_instance(species_id)
		if creature:
			instance.creatures.append(creature)
		else:
			push_warning("Missing creature data for %s" % species_id)
	return instance


func get_all_creatures() -> Array[CreatureInstance]:
	return creatures


func on_creature_added_to_party(creature: CreatureInstance) -> void:
	creatures.append(creature)
	print("Creature added to party: %s" % creature.definition.species_id)


func check_if_all_party_fainted() -> void:
	if creatures.any(func(c): return c.health > 0):
		return
	Events.player_died.emit()


func get_creature_by_uid(creature_uid: String) -> CreatureInstance:
	for c in creatures:
		if c.uid == creature_uid:
			return c
	push_warning("No creature in party with UID: " + creature_uid)
	return null
