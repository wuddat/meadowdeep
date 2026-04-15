class_name BattleOverPanel
extends Panel

enum Type { WIN, LOSE }

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	label.text = text
	continue_button.visible = type == Type.WIN
	restart_button.visible = type == Type.LOSE
	show()
	get_tree().paused = true


func _on_continue_pressed() -> void:
	get_tree().paused = false
	Events.battle_won.emit()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/meadow/meadow.tscn")
