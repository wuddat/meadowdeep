# custom_resources/qte_data.gd
class_name QTEData
extends Resource

enum InputType { PRESS, HOLD_RELEASE, MASH }
enum Context { OFFENSIVE, DEFENSIVE }

@export var id: String
@export var input_type: InputType
@export var context: Context
@export var input_action: StringName = &"qte_press"

@export_group("Timing")
@export var total_duration: float = 1.5       # how long the widget is alive
@export var target_window_start: float = 0.8  # when "good" zone begins
@export var target_window_duration: float = 0.3
@export var perfect_window_duration: float = 0.08  # centered in target

@export_group("Outcomes")
@export var on_perfect: QTEOutcome
@export var on_good: QTEOutcome
@export var on_miss: QTEOutcome
