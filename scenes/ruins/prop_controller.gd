class_name PropController
extends Node2D

@onready var pylon_1: Sprite2D = $"../Pylon1"
@onready var pylon_2: Sprite2D = $"../Pylon2"
@onready var pylon_3: Sprite2D = $"../Pylon3"
@onready var fire: Node2D = $"../Fire"

#in case you ever delete the pylons because we both know you will
const pylon_1_pos = Vector2(149,148)
const pylon_2_pos = Vector2(322,90)
const pylon_3_pos = Vector2(503,148)

const INTERACTABLE = preload("uid://c607lg16urosb")


func spawn_interactable(pylon: int, c: CreatureBattleUnit) -> void:
	var spawn_pos: Vector2
	match pylon:
		1:
			spawn_pos = pylon_1.global_position
			c.global_position = pylon_3.global_position
		2:
			spawn_pos = pylon_2.global_position
			c.global_position = pylon_1.global_position
		3:
			spawn_pos = pylon_3.global_position
			c.global_position = pylon_2.global_position

	var interactable := INTERACTABLE.instantiate() as Interactable
	interactable._creature = c
	interactable.global_position = spawn_pos
	self.add_child(interactable)


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
	if not node:
		return
	node.show()
	var children := node.get_children()
	for child in children:
		if "visible" in child:
			child.visible = true
