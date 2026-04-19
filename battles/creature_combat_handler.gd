class_name CreatureCombatHandler
extends Node

var _party_units: Array[CreatureBattleUnit] = []


func start_combat(units: Array[CreatureBattleUnit]) -> void:
	_party_units = units
	Events.combat_started.emit()
	for unit in _party_units:
		unit.start_combat()


func stop_combat() -> void:
	for unit in _party_units:
		unit.stop_combat()
	Events.combat_ended.emit()
