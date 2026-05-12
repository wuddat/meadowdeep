class_name ActionQueue
extends Resource

signal action_started(id: StringName, data: Dictionary)
signal queue_emptied

var _queue: Array[Dictionary] = []

var current_action: StringName:
	get: return _queue[0]["id"] if not _queue.is_empty() else &""


func enqueue(id: StringName, data: Dictionary) -> void:
	_queue.append({"id": id, "data": data})
	if _queue.size() == 1:
		action_started.emit(id, data)


func push_front(id: StringName, data: Dictionary) -> void:
	_queue.push_front({"id": id, "data": data})
	action_started.emit(id, data)


func done() -> void:
	if _queue.is_empty():
		return
	_queue.pop_front()
	if _queue.is_empty():
		queue_emptied.emit()
	else:
		action_started.emit(_queue[0]["id"], _queue[0]["data"])


func contains(id: StringName) -> bool:
	for entry in _queue:
		if entry["id"] == id:
			return true
	return false


func peek() -> Dictionary:
	return _queue[0] if not _queue.is_empty() else {}


func remove(id: StringName) -> void:
	_queue = _queue.filter(func(e): return e["id"] != id)


func clear() -> void:
	_queue.clear()
