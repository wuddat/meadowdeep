extends Node

const SAVE_PATH:= "user://save.tres"


func save(data: SaveData) -> void:
	var err:= ResourceSaver.save(data, SAVE_PATH)
	if err != OK:
		push_error("[SAVEMANAGER] Save Failed: %s" % error_string(err))


func load_game() -> SaveData:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as SaveData


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
