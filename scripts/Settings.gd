extends Node

const SAVED_PROPERTIES = ["last_save_location"]

var last_save_location = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)

func save():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	var out = {}
	print()
	for i in SAVED_PROPERTIES:
		out[i] = get(i)
	file.store_line(JSON.stringify(out))

func _ready():
	if not FileAccess.file_exists("user://settings.json"):
		return
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	var props = JSON.parse_string(file.get_line())
	if not props:
		return
	for i in props:
		set(i, props[i])
