class_name RoomObjectHandler
extends Node2D

@onready var pylon_1: Sprite2D = $"../Pylon1"
@onready var pylon_2: Sprite2D = $"../Pylon2"
@onready var pylon_3: Sprite2D = $"../Pylon3"
@onready var fire: Node2D = $"../Fire"

const INTERACTABLE = preload("uid://c607lg16urosb")

func _ready() -> void:
	_establish_connections()


func _on_creature_snared(_c: CreatureBattleUnit) -> void:
	var test_trigger := INTERACTABLE.instantiate() as Interactable
	
	test_trigger._creature = _c
	test_trigger.global_position = pylon_2.global_position
	self.add_child(test_trigger)

func _on_creature_freed(_c: CreatureBattleUnit) -> void:
	pass
func set_objects(room: Room) -> void:
	if room.type != Room.Type.NOT_ASSIGNED:
		if pylon_1 == null:
			return
		_hide_children(pylon_1)
		_hide_children(pylon_2)
		_hide_children(pylon_3)
		_hide_children(fire)
	else:
		_show_children(pylon_1)
		_show_children(pylon_2)
		_show_children(pylon_3)
		_show_children(fire)

func _hide_children(node: Node) -> void:
	node.hide()
	var children := node.get_children()
	for child in children:
		if "visible" in child:
			child.visible = false

func _show_children(node: Node) -> void:
	node.show()
	var children := node.get_children()
	for child in children:
		if "visible" in child:
			child.visible = true

func _establish_connections() -> void:
	Events.creature_freed.connect(_on_creature_freed)
	Events.creature_ensnared.connect(_on_creature_snared)
