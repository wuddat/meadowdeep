#player_stats.gd
class_name PlayerStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture2D
@export var frames: SpriteFrames

@export_group("Gameplay Data")
@export var inventory: Inventory

@export_group("Creature Data")
@export var starting_party: Array[String] = []
@export var creatures: Array[CreatureStats] = []


func take_damage(damage: int) -> void:
	super.take_damage(damage)



func create_instance() -> Resource:
	var instance: PlayerStats = self.duplicate()
	instance.health = max_health
	instance.block = 0

	instance.creatures = []
	instance.inventory = inventory.duplicate(true) if inventory else Inventory.new()
	for species_id in starting_party:
		var creature = CreatureData.create_creature_instance(species_id)
		if creature:
			instance.creatures.append(creature)
		else:
			push_warning("Missing creature data for %s" % species_id)
	return instance



func get_all_creatures() -> Array[CreatureStats]:
	return creatures



func on_creature_added_to_party(creature: CreatureStats) -> void:
	creatures.append(creature)
	print("Creature added to party: %s" % creature.species_id)


func check_if_all_party_fainted() -> void:
	if creatures.any(func(c): return c.health > 0):
		return
	Events.player_died.emit()


func get_creature_by_uid(creature_uid: String) -> CreatureStats:
	for c in creatures:
		if c.uid == creature_uid:
			return c
	push_warning("No creature in party with UID: " + creature_uid)
	return null
