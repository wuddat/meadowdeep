class_name RuinMapBlock
extends TileMapLayer

@export var attach_points: Array[Marker2D]
@export var nav_points: Array[Marker2D]


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
