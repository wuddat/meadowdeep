class_name Interactable
extends Node2D

@onready var area: Area2D = %Area2D
@onready var collider: CollisionShape2D = %CollisionShape2D
@onready var sprite: Sprite2D = %Sprite2D

var _player: Node
var _creature: CreatureBattleUnit
var _usable: bool = false

func _ready() -> void:
	_establish_connections()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _player:
		_player = body
	_usable = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_usable = false

func _on_creature_ensnared(creature: CreatureBattleUnit) -> void:
	_creature = creature

func _unhandled_input(input: InputEvent) -> void:
	if input.is_action_pressed("left_mouse") and _usable == true and _creature:
		_creature.unsnare()
		_usable = false
		queue_free()

func _establish_connections() -> void:
	Events.creature_ensnared.connect(_on_creature_ensnared)
	Events.creature_freed.connect(queue_free)
