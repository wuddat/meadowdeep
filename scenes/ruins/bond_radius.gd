class_name BondRadius
extends Node2D

@onready var bond_radius_area: Area2D = $BondRadiusArea
@onready var collider: CollisionShape2D = $BondRadiusArea/BondRadiusCollider
@onready var radius_border: Sprite2D = $RadiusBorder
@onready var radius_fill: Sprite2D = $RadiusFill
@onready var fill_material := radius_fill.material as ShaderMaterial

@export var player_model: Node

@export_range(0.0, 1.0) var bond_progress: float = 0.0:
	set(value):
		bond_progress = clampf(value, 0.0, 1.0)
		_update_material()

var player_near: bool = false

const MAGIC_NUMBER: float = 0.707
const FILL_TIME: float = 5.0

func _ready() -> void:
	if fill_material:
		_update_material()

func _process(delta: float) -> void:
	if not player_near:
		_shrink_radius(delta)
		return
	_grow_radius(delta)

func _grow_radius(delta: float) -> void:
	bond_progress += delta / FILL_TIME
	_update_material()

func _shrink_radius(delta: float) -> void:
	bond_progress -= delta / FILL_TIME
	_update_material()

func _update_material() -> void:
	if not fill_material:
		return
	fill_material.set_shader_parameter("progress", bond_progress * MAGIC_NUMBER)

func _on_bond_radius_area_body_entered(body: Node2D) -> void:
	if body == player_model and player_near == false:
		player_near = true


func _on_bond_radius_area_body_exited(body: Node2D) -> void:
	if body == player_model and player_near == true:
		player_near = false
