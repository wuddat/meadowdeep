#status_handler.gd
class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_DETAIL_OVERLAY_DELAY := 0.5

# Assign in the Godot editor once StatusUI.tscn is created.
# While null, statuses are tracked in logic only — no visual indicators.
@export var status_ui_scene: PackedScene

@export var status_owner: Node2D

# Logic-layer status list. Decoupled from scene tree so combat works before UI exists.
var _statuses: Array[Status] = []
var health_ui_status_container: Node = null


func set_status_ui_container(container: Node) -> void:
	health_ui_status_container = container


func apply_statuses_by_type(type: Status.Type) -> void:
	if type == Status.Type.EVENT_BASED:
		return

	var status_queue: Array[Status] = _statuses.filter(
		func(s: Status) -> bool: return s.type == type
	)

	if status_queue.is_empty():
		statuses_applied.emit(type)
		return

	var tween := create_tween()
	for status in status_queue:
		tween.tween_callback(func():
			status.apply_status(status_owner)
			match status.type:
				Status.Type.START_OF_TURN:
					if status.has_method("on_start_of_turn"):
						status.on_start_of_turn(status_owner)
				Status.Type.END_OF_TURN:
					if status.has_method("on_end_of_turn"):
						status.on_end_of_turn(status_owner)
		)
		tween.tween_interval(STATUS_APPLY_INTERVAL)

	tween.finished.connect(func(): statuses_applied.emit(type))


func add_status(status: Status) -> void:
	var stackable := status.stack_type != Status.StackType.NONE

	if not has_status(status.id):
		_statuses.append(status)
		status.status_applied.connect(_on_status_applied)
		status.initialize_status(status_owner)

		if status_ui_scene:
			var new_status_ui := status_ui_scene.instantiate()
			add_child(new_status_ui)
			new_status_ui.modulate.a = 0.0
			if "status" in new_status_ui:
				new_status_ui.set("status", status)
			var tween: Tween = create_tween()
			tween.parallel().tween_property(new_status_ui, "modulate", Color(1, 1, 1, 1), 0.2)
			columns = get_child_count()

			if health_ui_status_container:
				var visual_ui := status_ui_scene.instantiate()
				if "status" in visual_ui:
					visual_ui.set("status", status)
				health_ui_status_container.add_child(visual_ui)

		print(status.id, " status added")
		return

	if not status.can_expire and not stackable:
		return

	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		get_status(status.id).duration += status.duration
		print(status.id, " duration stacked")
		return

	if status.stack_type == Status.StackType.INTENSITY:
		var existing := get_status(status.id)
		existing.stacks += status.stacks
		print(status.id, " intensity stacked")
		existing.apply_status(status_owner)
		return


func has_and_consume_status(id: String) -> bool:
	if has_status(id):
		remove_status(id)
		return true
	return false


func clear_all_statuses() -> void:
	_statuses.clear()
	for child in get_children():
		child.queue_free()
	if health_ui_status_container:
		for child in health_ui_status_container.get_children():
			child.queue_free()


func has_status(id: String) -> bool:
	for status in _statuses:
		if status.id == id:
			return true
	return false


func get_status_stacks(id: String) -> int:
	var status := get_status(id)
	return status.stacks if status else 0


func get_status(id: String) -> Status:
	for status in _statuses:
		if status.id == id:
			return status
	return null


func decrement_status(id: String) -> void:
	var status: Status = get_status(id)
	if not status:
		return
	if status.stacks >= 1:
		status.stacks -= 1
	if status.duration >= 1 and status.can_expire:
		status.duration -= 1


func increment_status(id: String) -> void:
	var status: Status = get_status(id)
	if not status:
		return
	if status.stacks >= 1:
		status.stacks += 1
	if status.duration >= 1 and status.can_expire:
		status.duration += 1


func remove_status(id: String) -> void:
	for i in range(_statuses.size() - 1, -1, -1):
		if _statuses[i].id == id:
			_statuses.remove_at(i)

	for child in get_children():
		if "status" in child and child.get("status") != null:
			if child.get("status").id == id:
				child.queue_free()

	if health_ui_status_container:
		for child in health_ui_status_container.get_children():
			if "status" in child and child.get("status") != null:
				if child.get("status").id == id:
					child.queue_free()


# Marks a status for removal the next time the owner takes damage.
# TODO: Full implementation needs a signal hook into the unit's take_damage pathway.
# Phase 0 behaviour: removes immediately (conservative but safe).
func queue_remove_on_next_damage(id: String) -> void:
	remove_status(id)


func has_any_status() -> bool:
	return not _statuses.is_empty()


func get_statuses() -> Array[Status]:
	return _statuses


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1
		print(status.id, " applied — duration now: ", status.duration)


var _status_hover_timer: SceneTreeTimer = null


func _on_mouse_entered() -> void:
	_status_hover_timer = get_tree().create_timer(STATUS_DETAIL_OVERLAY_DELAY)
	await _status_hover_timer.timeout
	if _status_hover_timer:
		Events.status_tooltip_requested.emit(_statuses)
		_status_hover_timer = null


func _on_mouse_exited() -> void:
	if _status_hover_timer:
		_status_hover_timer.cancel_free()
		_status_hover_timer = null
	Events.status_tooltip_hide_requested.emit()
