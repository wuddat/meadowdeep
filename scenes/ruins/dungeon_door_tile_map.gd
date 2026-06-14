class_name DungeonDoorTileMap
extends TileMapLayer

@export var template: TileMapLayer   # assign DungeonDoorTileTemplate in inspector

const BLOCKS := {
	 &"N": { &"CL": Rect2i(-3,-3, 6,3), &"OP": Rect2i(-3,-6, 6,3) },
	 &"S": { &"CL": Rect2i(-3, 0, 6,3), &"OP": Rect2i(-3, 3, 6,3) },
	 &"E": { &"CL": Rect2i( 3,-3, 3,7), &"OP": Rect2i( 6,-3, 3,7) },
	 &"W": { &"CL": Rect2i(-6,-3, 3,7), &"OP": Rect2i(-9,-3, 3,7) },
}

var anchors: Dictionary = {}

func _dest(dir: StringName, state:StringName, cell: Vector2i) -> Vector2i:
	var block: Rect2i = BLOCKS[dir][state]
	var center: Vector2i = block.position + block.size/2
	return anchors[dir] + (cell - center)

func open(dir: StringName) -> void:    _set_state(dir, &"OP")
func close(dir: StringName) -> void:   _set_state(dir, &"CL")
func clear_blocks(dir: StringName) -> void:
	_erase_block(dir, &"CL")
	_erase_block(dir, &"OP")

 # paint the chosen state's block, erase the other so they never coexist
func _set_state(dir: StringName, state: StringName) -> void:
	var other := &"OP" if state == &"CL" else &"CL"
	_erase_block(dir, other)
	_copy_block(dir, state)

func _copy_block(dir: StringName, state: StringName) -> void:
	for cell in _cells(BLOCKS[dir][state]):
		var dest := _dest(dir, state, cell)
		var sid := template.get_cell_source_id(cell)
		if sid == -1:
			erase_cell(dest)
		else:
			set_cell(dest, sid, template.get_cell_atlas_coords(cell),
					 template.get_cell_alternative_tile(cell))

func _erase_block(dir: StringName, state: StringName) -> void:
	for cell in _cells(BLOCKS[dir][state]):
		erase_cell(_dest(dir, state, cell))

func _cells(r: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			out.append(Vector2i(x, y))
	return out
