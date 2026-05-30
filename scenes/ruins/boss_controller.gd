class_name BossController
extends Node2D

enum State {SNARING, ATTACKING, VULNERABLE}

@export var snare_range: float = 200.0
@export var attack_range: float = 80.0
@export var attack_damage: int = 5
@export var vulnerable_duration: float = 3.0


var _state: State = State.SNARING
var _creature: Node
var _boss: BattleActor
var prop_controller: PropController

func _ready() -> void:
	_establish_connections()
	

func next_steps(boss: BattleActor) -> Array[Dictionary]:
	if not _boss:
		_boss = boss
	if not is_instance_valid(_creature):
		_creature = _get_node("active_creatures")
		
	if _creature == null:
		return []
	match _state:
		State.SNARING: return _snaring(boss)
		State.ATTACKING: return _attacking(boss)
		State.VULNERABLE: return _vulnerable()
	return []


func _get_node(group: String) -> Node:
	var node_array: Array[Node] = get_tree().get_nodes_in_group(group)
	if node_array:
		return node_array[0]
	else:
		return null


func _snaring(boss: BattleActor) -> Array[Dictionary]:
	if not BattleAction.range_check(boss, _creature, snare_range):
		return [{ "id": &"move", "data": { "target": _creature, "mode": MoveToAction.Mode.TOWARD, "stop_distance": snare_range } }]
	var snare_tar: CreatureBattleUnit = _creature
	snare_tar.snare()
	return [{"id":&"idle", "data": {"timer": 0.4}}]


func _attacking(boss: BattleActor) -> Array[Dictionary]:
	if not BattleAction.range_check(boss, _creature, attack_range):
		return [{ "id": &"move", "data": { "target": _creature, "mode": MoveToAction.Mode.TOWARD, "stop_distance": attack_range } }]
	var dmg := DamageEffect.new()
	dmg.amount = attack_damage
	return [{ "id": &"strike", "data": { \
	"target": _creature, "effects": [dmg] as Array[Effect], \
	"animation_string": "strike", "min_duration": 0.3 } }]


func _vulnerable() -> Array[Dictionary]:
	return [{"id":&"idle", "data": {"timer": 0.4}}]


func _on_creature_snared(c: CreatureBattleUnit) -> void:
	print("[BOSS] recv creature_ensnared | SNARING -> ATTACKING")
	_random_assign_unsnare_and_creature(c)
	_state = State.ATTACKING
	var p := self.get_parent()
	if p:
		p.collider.disabled = true

func _teleport_self_to_coords(coords: Vector2) -> void:
	_boss.global_position = coords

func _random_assign_unsnare_and_creature(c: CreatureBattleUnit) -> void:
	var unsnare_spawn = (RNG.instance.randi_range(0,2) + 1)
	prop_controller.spawn_interactable(unsnare_spawn, c)
	
func _on_creature_freed(_c: CreatureBattleUnit) -> void:
	print("[BOSS] recv creature_freed | -> VULNERABLE (%.1fs)" % vulnerable_duration)
	_state = State.VULNERABLE
	var p := self.get_parent()
	if p:
		p.collider.disabled = false
	await get_tree().create_timer(vulnerable_duration).timeout
	if _state == State.VULNERABLE:
		print("[BOSS] vulnerable window over | VULNERABLE -> SNARING")
		_state = State.SNARING


func _establish_connections() -> void:
	Events.creature_freed.connect(_on_creature_freed)
	Events.creature_ensnared.connect(_on_creature_snared)
