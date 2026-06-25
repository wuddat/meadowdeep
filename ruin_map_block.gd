class_name RuinMapBlock
extends TileMapLayer

signal combat_triggered(block: RuinMapBlock)

@export var attach_points: Array[Marker2D]
@export var nav_points: Array[Marker2D]
@export var room: Room
@export var combat_trigger_area: Area2D


func anchor_directions() -> Array[StringName]:
	var out: Array[StringName] = []
	for marker: Marker2D in attach_points:
		out.append(_cardinal(marker.position.rotated(rotation)))
	return out


func anchor_for_direction(dir: StringName) -> Marker2D:
	for marker:Marker2D in attach_points:
		if _cardinal(marker.position.rotated(rotation)) == dir:
			return marker
	return null


func _cardinal(marker_coords: Vector2) -> StringName:
	if absf(marker_coords.x) > absf(marker_coords.y):
		return &"E" if marker_coords.x > 0.0 else &"W"
	return &"S" if marker_coords.y > 0.0 else &"N"


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CreatureBattleUnit and room and room.type in [Room.Type.COMBAT, Room.Type.BOSS] and not room.cleared:
		combat_trigger_area.set_deferred("monitoring", false)
		call_deferred("emit_signal", "combat_triggered", self)
