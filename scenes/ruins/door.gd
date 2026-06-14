class_name Door
extends Area2D

enum State {OPEN, CLOSED, SECRET, REVEALED, NO_DOOR}

const DOOR_CL = preload("uid://bxcuo8dd6tonf")
const DOOR_OP = preload("uid://gnkju1bl8xe7")

signal entered(destination: Room, from_direction: StringName)

@export var state: State = State.CLOSED


var room_data: Room
var direction: StringName  # &"N" / &"S" / &"E" / &"W"


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_refresh_visuals()


func setup(destination: Room, dir: StringName, initial_state: State = State.OPEN) -> void:
	room_data = destination
	direction = dir
	state = initial_state
	if is_node_ready():
		_refresh_visuals()


func open() -> void:
	state = State.OPEN
	_refresh_visuals()


func close() -> void:
	state = State.CLOSED
	_refresh_visuals()


func _refresh_visuals() -> void:
	# Inert states: invisible AND collision off so body_entered can't fire.
	var active := state == State.OPEN or state == State.CLOSED or state == State.REVEALED
	visible = active
	monitoring = active
	monitorable = active
	#if sprite == null:
		#return
	#match state:
		#State.OPEN:     sprite.texture = DOOR_OP
		#State.CLOSED:   sprite.texture = DOOR_CL
		#State.REVEALED: sprite.texture = DOOR_CL
		#State.SECRET:   sprite.texture = null
		#State.NO_DOOR:  sprite.texture = null


func _on_body_entered(_body: Node2D) -> void:
	if state != State.OPEN or room_data == null:
		return
	entered.emit(room_data, direction)
