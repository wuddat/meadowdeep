#player_stats.gd
class_name PlayerStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture2D
@export var frames: SpriteFrames

@export_group("Gameplay Data")

@export_group("Creature Data")
@export var starting_party: Array[String] = []
@export var current_party: Array[CreatureStats] = []


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()



func create_instance() -> Resource:
	var instance: PlayerStats = self.duplicate()
	instance.health = max_health
	instance.block = 0

	instance.current_party = []
	for species_id in starting_party:
		var creature = CreatureData.create_creature_instance(species_id)
		if creature:
			instance.current_party.append(creature)
		else:
			push_warning("Missing creature data for %s" % species_id)
	return instance



func get_all_creatures() -> Array[CreatureStats]:
	return current_party



func on_creature_added_to_party(creature: CreatureStats) -> void:
	current_party.append(creature)
	print("Creature added to party: %s" % creature.species_id)


func check_if_all_party_fainted() -> void:
	if current_party.any(func(c): return c.health > 0):
		return
	Events.player_died.emit()


func get_creature_by_uid(creature_uid: String) -> CreatureStats:
	for c in current_party:
		if c.uid == creature_uid:
			return c
	push_warning("No creature in party with UID: " + creature_uid)
	return null
