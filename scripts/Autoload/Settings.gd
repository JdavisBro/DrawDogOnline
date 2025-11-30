extends Node

signal settings_changed

enum SettingType {
	BOOL = 0,
	INT_LIST = 1,
	FLOAT_RANGE = 2,
}

const SAVED_PROPERTIES = [
	# No UI
	"last_save_location",
	"title_paint_custom",
	"title_paint_custom_size",
	"title_paint_custom_palette",
	"title_paint_custom_version",
	"allow_insecure_server_auth",
	"last_server_ip",
	"last_server_protocol",
	"server_list",
	"last_server_tab",
	"username",
	# UI
	"master_volume",
	"player_volume",
	"other_player_volume",
	"hold_brushburst",
	"fill_bucket_do_corners",
	"eyestrain_mode",
	"title_paint_custom_enabled",
	"show_auth_names",
	"show_avatars_level",
	"show_avatars_map",
]

# Not in settings UI
var last_save_location := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
var title_paint_custom := ""
var title_paint_custom_size := 7371
var title_paint_custom_palette := []
var title_paint_custom_version := 1
var allow_insecure_server_auth := false
var last_server_ip := MultiplayerManager.DEFAULT_IP
var last_server_protocol := "ws://"
var server_list := []
var last_server_tab := 0
var username := "Default"

const SETTING_INFO = { # info for settings ui
	"master_volume": {"type": SettingType.FLOAT_RANGE, "min": 0.0, "max": 100.0, "name": "Master Volume", "desc": "Volume of everything in the game."},
	"player_volume": {"type": SettingType.FLOAT_RANGE, "min": 0.0, "max": 100.0,  "name": "Player Volume", "desc": "Volume of your dog and brush."},
	"other_player_volume": {"type": SettingType.FLOAT_RANGE, "min": 0.0, "max": 100.0,  "name": "Other Player Volume", "desc": "Volume of other dogs and brushes."},
	"hold_brushburst": {"type": SettingType.BOOL, "name": "Holding paint fills screen", "desc": "If holding paint in one spot fills the screen with paint."},
	"fill_bucket_do_corners": {"type": SettingType.BOOL, "name": "Fill bucket fills through corners", "desc": "Fill bucket can fill through corners. This can make it slower but prevent accidental changes."},
	"eyestrain_mode": {"type": SettingType.INT_LIST, "value_names": ["None", "Default", "Lots"], "name": "Eyestrain Mode", "desc": ""},
	"title_paint_custom_enabled": {"type": SettingType.BOOL, "name": "Use Custom Title Screen Paint", "desc": "Requires setting on the pause screen in game. Automatically set to on when set in game."},
	"show_auth_names": {"type": SettingType.BOOL, "name": "Show Discord Username In Game", "desc": "Shows Discord usernames on authenticated servers."},
	"show_avatars_level": {"type": SettingType.BOOL, "name": "Show Avatars In Game", "desc": "Shows Discord avatars next to a username on authenticated servers (requires Show Discord Usernames In Game on)."},
	"show_avatars_map": {"type": SettingType.BOOL, "name": "Show Avatars In Player List", "desc": "Shows Discord avatars next to a username in the player list/map on authenticated servers."},
}

# In Settings UI
var master_volume := 100
var player_volume := 100
var other_player_volume := 80
var hold_brushburst := true
var fill_bucket_do_corners := true
var eyestrain_mode := 1
var title_paint_custom_enabled := false
var show_auth_names := true
var show_avatars_level := true
var show_avatars_map := true

func save():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	var out = {}
	for i in SAVED_PROPERTIES:
		out[i] = get(i)
	file.store_line(JSON.stringify(out))
	emit_signal("settings_changed")

func _ready():
	if not FileAccess.file_exists("user://settings.json"):
		return
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	var props = JSON.parse_string(file.get_as_text())
	if not props:
		return
	for i in props:
		set(i, props[i])
