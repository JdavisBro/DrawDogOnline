extends Node

enum SettingType {
	BOOL = 0,
	INT_LIST = 1,
}

const SAVED_PROPERTIES = [
	"last_save_location",
	"title_paint_custom",
	"title_paint_custom_size",
	"title_paint_custom_palette",
	"hold_brushburst",
	"fill_bucket_do_corners",
	"eyestrain_mode",
	"title_paint_custom_enabled",
]

# Not in settings UI
var last_save_location = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
var title_paint_custom = ""
var title_paint_custom_size = 7371
var title_paint_custom_palette = []

const SETTING_INFO = { # info for settings ui
	"hold_brushburst": {"type": SettingType.BOOL, "name": "Holding paint fills screen", "desc": "If holding paint in one spot fills the screen with paint."},
	"fill_bucket_do_corners": {"type": SettingType.BOOL, "name": "Fill bucket fills through corners", "desc": "Fill bucket can fill through corners. This can make it slower but prevent accidental changes."},
	"eyestrain_mode": {"type": SettingType.INT_LIST, "value_names": ["None", "Default", "Lots"], "name": "Eyestrain Mode", "desc": ""},
	"title_paint_custom_enabled": {"type": SettingType.BOOL, "name": "Use Custom Title Screen Paint", "desc": "Requires setting on the pause screen in game. Automatically set to on when set in game."}
}

# In Settings UI
var hold_brushburst = true
var fill_bucket_do_corners = true
var eyestrain_mode = 1
var title_paint_custom_enabled = false

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
