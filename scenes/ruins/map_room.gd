#map_room.gd
class_name MapRoom
extends Area2D

signal selected(room: Room)

# Placeholder colors per room type — swap for icons once art exists
const TYPE_COLORS := {
	Room.Type.NOT_ASSIGNED: Color(0.4, 0.4, 0.4),
	Room.Type.COMBAT:       Color(0.9, 0.2, 0.2),
	Room.Type.TREASURE:     Color(0.9, 0.8, 0.1),
	Room.Type.REST_SITE:    Color(0.2, 0.8, 0.4),
	Room.Type.SHOP:         Color(0.2, 0.5, 0.9),
	Room.Type.BOSS:         Color(0.7, 0.0, 0.8),
	Room.Type.EVENT:        Color(0.8, 0.5, 0.2),
	Room.Type.EGG_CHAMBER:  Color(0.95, 0.6, 0.85),
}

const TYPE_LABELS := {
	Room.Type.NOT_ASSIGNED: "?",
	Room.Type.COMBAT:       "FIGHT",
	Room.Type.TREASURE:     "LOOT",
	Room.Type.REST_SITE:    "REST",
	Room.Type.SHOP:         "SHOP",
	Room.Type.BOSS:         "BOSS",
	Room.Type.EVENT:        "EVENT",
	Room.Type.EGG_CHAMBER:  "EGG",
}

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Visuals/Label

var available := false: set = set_available
var room: Room: set = set_room


func _ready() -> void:
	line_2d.visible = false


func set_available(new_value: bool) -> void:
	available = new_value

	if available:
		line_2d.visible = true
		animation_player.play("highlight")
		if room.type == Room.Type.BOSS:
			animation_player.play("hover")
	elif not room.selected:
		animation_player.stop()
		line_2d.visible = false
		sprite_2d.modulate = Color(1, 1, 1, 0.7)


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = RNG.instance.randi_range(-10, 10)
	var col = TYPE_COLORS.get(room.type, Color.WHITE)
	sprite_2d.modulate = col
	if label:
		label.text = TYPE_LABELS.get(room.type, "?")
		label.add_theme_color_override("font_color", col)
	if room.type == Room.Type.BOSS:
		animation_player.play("hover")


func show_selected() -> void:
	line_2d.modulate = Color.RED


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return

	room.selected = true
	animation_player.play("select")
	if room.type == Room.Type.BOSS:
		animation_player.play("boss_begin")


func _on_map_room_selected() -> void:
	selected.emit(room)
