class_name Run
extends Node

const SCENES: Dictionary = {
	"meadow": preload("uid://ckvqrdjwvkti2"),
	"ruins_prep": preload("uid://31pta4kuy77o"),
	"ruins": preload("uid://uxisf2rn7cwt"),
}



@export var player_data: PlayerData
@onready var current_view: Node = $CurrentView
@onready var fade: ColorRect = %Fade

var active_stats: PlayerData


func _ready() -> void:
	if not player_data:
		push_warning("[RUN]: No player_data assigned")
		return
	active_stats = player_data.create_instance()
	_setup_event_connections()
	_swap_scene("meadow")


func _setup_event_connections() -> void:
	if not Events.scene_transition_requested.is_connected(_on_scene_transition_requested):
		Events.scene_transition_requested.connect(_on_scene_transition_requested)


func _on_scene_transition_requested(scene_id: String) -> void:
	_swap_scene(scene_id)


func _swap_scene(scene_id: String) -> void:
	if not SCENES.has(scene_id):
		push_warning("[RUN] No Scene_ID for: %s" % scene_id)
		return
	_clear_current_view()
	var new_scene:Node = SCENES[scene_id].instantiate()
	current_view.add_child(new_scene)
	if not new_scene.is_node_ready():
		await new_scene.ready
	if new_scene.has_method("setup"):
		new_scene.setup(active_stats)

	

func _clear_current_view() -> void:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()
