extends Node2D

const ROOM_SIZE := Vector2(32, 32)
const FLOOR_NUM := 1

const TYPE_COLORS := {
	Room.Type.NOT_ASSIGNED: Color.WHITE,           # start
	Room.Type.COMBAT:       Color.INDIAN_RED,
	Room.Type.BOSS:         Color.PURPLE,
	Room.Type.EGG_CHAMBER:  Color.PINK,
	Room.Type.TREASURE:     Color.GOLD,
	Room.Type.REST_SITE:    Color.SEA_GREEN,
	Room.Type.SHOP:         Color.CORNFLOWER_BLUE,
	Room.Type.EVENT:        Color.ORANGE,
}

const TYPE_LABELS := {
	Room.Type.NOT_ASSIGNED: "S",
	Room.Type.COMBAT:       "C",
	Room.Type.BOSS:         "B",
	Room.Type.EGG_CHAMBER:  "E",
	Room.Type.TREASURE:     "T",
	Room.Type.REST_SITE:    "R",
	Room.Type.SHOP:         "$",
	Room.Type.EVENT:        "?",
}

@onready var generator: MapGenerator = $MapGenerator


func _ready() -> void:
	_regen()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				_regen()


func _regen() -> void:
	var data = generator.generate_floor(FLOOR_NUM)
	print(data)
	queue_redraw()
	_print_ascii()


func _draw() -> void:
	var center := get_viewport_rect().size / 2
	var font := ThemeDB.fallback_font
	for room: Room in generator.room_map.values():
		var pos: Vector2 = room.position + center
		var col: Color = TYPE_COLORS.get(room.type, Color.WHITE)
		draw_rect(Rect2(pos - ROOM_SIZE / 2, ROOM_SIZE), col)
		draw_rect(Rect2(pos - ROOM_SIZE / 2, ROOM_SIZE), Color.BLACK, false, 1)

		# door stubs
		if room.doors & MapGenerator.DOOR_N:
			draw_line(pos, pos + Vector2(0, -ROOM_SIZE.y / 2), Color.WHITE, 2)
		if room.doors & MapGenerator.DOOR_S:
			draw_line(pos, pos + Vector2(0,  ROOM_SIZE.y / 2), Color.WHITE, 2)
		if room.doors & MapGenerator.DOOR_E:
			draw_line(pos, pos + Vector2( ROOM_SIZE.x / 2, 0), Color.WHITE, 2)
		if room.doors & MapGenerator.DOOR_W:
			draw_line(pos, pos + Vector2(-ROOM_SIZE.x / 2, 0), Color.WHITE, 2)

		var label: String = TYPE_LABELS.get(room.type, "?")
		draw_string(font, pos + Vector2(-3, 3), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.BLACK)
		draw_string(font, pos + Vector2(-ROOM_SIZE.x / 2 + 2, -ROOM_SIZE.y / 2 + 8), str(room.depth), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)

	draw_string(font, Vector2(16, 24), "SPACE/ENTER = reroll  rooms=%d" % generator.room_map.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func _print_ascii() -> void:
	if generator.room_map.is_empty():
		return
	var min_x := 999
	var max_x := -999
	var min_y := 999
	var max_y := -999
	for pos: Vector2i in generator.room_map.keys():
		min_x = min(min_x, pos.x); max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y); max_y = max(max_y, pos.y)

	print("--- map (rooms=%d) ---" % generator.room_map.size())
	for y in range(min_y, max_y + 1):
		var line := ""
		for x in range(min_x, max_x + 1):
			var p := Vector2i(x, y)
			if generator.room_map.has(p):
				var r: Room = generator.room_map[p]
				line += TYPE_LABELS.get(r.type, "?")
				line += "-" if r.doors & MapGenerator.DOOR_E else " "
			else:
				line += "  "
		print(line)
