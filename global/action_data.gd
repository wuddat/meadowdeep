# action_data.gd
# Autoload registry of BattleAction .tres files under res://battles/battle_actions/.
# Indexed by filename stem (e.g. "strike", "move_toward", "shoot") — matches the
# string IDs stored in creatures.json `starting_actions` / `action_ids`.
extends Node

const ACTIONS_ROOT := "res://battles/battle_actions"

var _actions: Dictionary = {}  # id (String) → BattleAction
var _scanned: bool = false


func _ready() -> void:
	_ensure_scanned()


# Scan lazily on first access. Autoload _ready order isn't guaranteed before
# scene-export hydration (e.g. SaveMgr boot-resume loads a scene before this
# autoload is even constructed), so any accessor self-initializes the registry.
func _ensure_scanned() -> void:
	if _scanned:
		return
	_scanned = true
	_scan_dir(ACTIONS_ROOT)


func _print_library() -> void:
	print("[ActionData] loaded %d actions:" % _actions.size())
	var ids := _actions.keys()
	ids.sort()
	for id in ids:
		var act: BattleAction = _actions[id]
		var intent_str := "AGGRESSIVE" if act.intent == BattleAction.Intent.AGGRESSIVE else "DEFENSIVE"
		print("  - %s  [%s]  weight=%.1f  script=%s" % [
			id, intent_str, act.chance_weight, act.get_script().resource_path.get_file()
		])


func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("ActionData: could not open " + path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			_scan_dir(full)
		elif entry.ends_with(".tres"):
			_register(full, entry.get_basename())
		entry = dir.get_next()
	dir.list_dir_end()


func _register(res_path: String, id: String) -> void:
	var res := load(res_path)
	if res == null or not (res is BattleAction):
		push_warning("ActionData: skipping non-BattleAction at %s" % res_path)
		return
	if _actions.has(id):
		push_warning("ActionData: duplicate move id '%s' (overwriting with %s)" % [id, res_path])
	_actions[id] = res


func get_action(id: String) -> BattleAction:
	_ensure_scanned()
	return _actions.get(id)


func get_actions(ids: Array) -> Array[BattleAction]:
	_ensure_scanned()
	var out: Array[BattleAction] = []
	for id in ids:
		var m := get_action(id)
		if m != null:
			out.append(m)
		else:
			push_warning("ActionData: unknown move id '%s'" % id)
	return out


func has_action(id: String) -> bool:
	_ensure_scanned()
	return _actions.has(id)


func all_ids() -> Array:
	_ensure_scanned()
	return _actions.keys()
