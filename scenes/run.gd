class_name Run
extends Node

const SCENES: Dictionary = {
	"meadow": preload("uid://ckvqrdjwvkti2"),
	"ruins_prep": preload("uid://31pta4kuy77o"),
	"ruins": preload("uid://uxisf2rn7cwt"),
}

const SAVE_ON_ENTER: Array[String] = ["meadow", "ruins"]


@export var player_data: PlayerData
@onready var current_view: Node = $CurrentView
@onready var fade: ColorRect = %Fade

var active_stats: PlayerData
var _current_scene: String = ""

func _ready() -> void:
	if not player_data:
		push_warning("[RUN]: No player_data assigned")
		return
	active_stats = player_data.create_instance()
	_load_save_if_present()
	_setup_event_connections()
	_swap_scene(_current_scene)


func _setup_event_connections() -> void:
	if not Events.scene_transition_requested.is_connected(_on_scene_transition_requested):
		Events.scene_transition_requested.connect(_on_scene_transition_requested)
	if not Events.ruins_run_started.is_connected(_on_ruins_run_started):
		Events.ruins_run_started.connect(_on_ruins_run_started)


func _on_scene_transition_requested(scene_id: String) -> void:
	_swap_scene(scene_id)

func _on_ruins_run_started(creature: CreatureInstance) -> void:
	if creature:
		active_stats.ruins_creature = creature

func _swap_scene(scene_id: String) -> void:
	if not SCENES.has(scene_id):
		push_warning("[RUN] No Scene_ID for: %s" % scene_id)
		return
	if scene_id in SAVE_ON_ENTER:
		_save_game_state(scene_id)
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


func _save_game_state(scene_id: String) -> void:
	var save_data: SaveData = SaveData.new()
	save_data.creatures = active_stats.creatures
	save_data.inventory = active_stats.inventory
	save_data.ruins_creature = active_stats.ruins_creature
	save_data.current_scene = scene_id
	SaveMgr.save(save_data)


func _load_save_if_present() -> void:
	if not SaveMgr.has_save():
		_current_scene = "meadow"
		return
	var save_data := SaveMgr.load_game()
	if not save_data:
		return
	if save_data.creatures.size() > 0:
		active_stats.creatures = save_data.creatures
	if save_data.inventory:
		active_stats.inventory = save_data.inventory
	if save_data.ruins_creature:
		active_stats.ruins_creature = save_data.ruins_creature
	if save_data.current_scene != "":
		_current_scene = save_data.current_scene
