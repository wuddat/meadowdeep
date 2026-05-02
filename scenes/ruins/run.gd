#run.gd
# Ruin run orchestrator. map → room → map loop.
# Non-battle rooms show placeholder panels until their scenes are built.
# TODO: Persistent health/mana across rooms — battle.gd calls create_instance() each time.
class_name Run
extends Node

const BATTLE_SCENE := preload("res://battles/battle.tscn")

@export var player_stats: PlayerStats

@onready var current_view: Node = $CurrentView
@onready var fade: ColorRect = %Fade

var active_stats: PlayerStats


func _ready() -> void:
	if not player_stats:
		push_warning("Run: no player_stats assigned — set in editor")
		return
	active_stats = player_stats.create_instance()
	_setup_event_connections()
	#map.generate_new_map()
	#map.unlock_floor(0)


func _setup_event_connections() -> void:
	Events.map_exited.connect(_on_map_exited)
	Events.battle_won.connect(_show_map)
	Events.rest_site_exited.connect(_show_map)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_show_map)
	Events.event_room_exited.connect(_show_map)
	Events.egg_chamber_exited.connect(_show_map)


func _clear_current_view() -> void:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()


func _show_map() -> void:
	_clear_current_view()
	#map.show_map()
	#map.unlock_next_rooms()


func _load_battle(room: Room) -> void:
	_clear_current_view()
	get_tree().paused = false
	#map.hide_map()
	# Set properties before add_child so they're ready when _ready() fires
	var battle_scene := BATTLE_SCENE.instantiate() as Battle
	battle_scene.char_stats = active_stats
	battle_scene.battle_stats = room.battle_stats
	current_view.add_child(battle_scene)


func _show_placeholder(label_text: String, exit_signal: Signal) -> void:
	_clear_current_view()
	#map.hide_map()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	var btn := Button.new()
	btn.text = "Continue"
	btn.pressed.connect(exit_signal.emit)
	vbox.add_child(btn)
	current_view.add_child(panel)


func _on_map_exited(room: Room) -> void:
	match room.type:
		Room.Type.COMBAT, Room.Type.BOSS:
			_load_battle(room)
		Room.Type.REST_SITE:
			_show_placeholder("Rest Site\n(coming soon)", Events.rest_site_exited)
		Room.Type.SHOP:
			_show_placeholder("Shop\n(coming soon)", Events.shop_exited)
		Room.Type.TREASURE:
			_show_placeholder("Treasure Chamber\n(coming soon)", Events.treasure_room_exited)
		Room.Type.EVENT:
			_show_placeholder("Ancient Inscription\n(coming soon)", Events.event_room_exited)
		Room.Type.EGG_CHAMBER:
			_show_placeholder("Egg Chamber\nAn ancient egg rests here.\n(coming soon)", Events.egg_chamber_exited)
