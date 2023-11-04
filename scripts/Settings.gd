extends Node

const SAVED_PROPERTIES = ["last_save_location", "hold_brushburst", "fill_bucket_do_corners"]
const SETTING_INFO = { # info for settings ui
	"hold_brushburst": {"type": TYPE_BOOL, "name": "Holding paint fills screen", "desc": "If holding paint in one spot fills the screen with paint."},
	"fill_bucket_do_corners": {"type": TYPE_BOOL, "name": "Fill bucket fills through corners", "desc": "Fill bucket can fill through corners. This can make it slower but prevent accidental changes."}
}

var last_save_location = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
var hold_brushburst = true
var fill_bucket_do_corners = true

func save():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	var out = {}
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
