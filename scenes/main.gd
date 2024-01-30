extends Node

const VALUE_REQUIRED = ["join-server", "server-start", "--winpos", "--winsize", "--authtype"]

var scene_changed = false

var start_connection = false
var server = false

func process_arg(key, value=""):
	match key:
		"--authtype":
			if value in ["discord"]:
				MultiplayerManager.auth_type = value
			elif value == "none":
				MultiplayerManager.auth_type = null
			else:
				push_warning("Invalid Auth Type")
				get_tree().quit()
		"server-start":
			start_connection = true
			server = true
			MultiplayerManager.port = MultiplayerManager.DEFAULT_PORT
			if value != "default":
				if value.is_valid_int():
					MultiplayerManager.port = int(value)
				else:
					print("Port Invalid")
					get_tree().quit()
			scene_changed = true
		"join-server":
			start_connection = true
			server = false
			MultiplayerManager.get_ip_port(value)
			scene_changed = true
		"--winpos":
			var val = value.split(",")
			var pos = Vector2(int(val[0]), int(val[1]))
			var decoration_size = DisplayServer.window_get_position() - DisplayServer.window_get_position_with_decorations()
			DisplayServer.window_set_position(pos+Vector2(decoration_size))
		"--winsize":
			var val = value.split(",")
			var size = Vector2(int(val[0]), int(val[1]))
			DisplayServer.window_set_size(size)

func _ready():
	var key = ""
	var getting_value = false
	var args = OS.get_cmdline_args()
	for value in args:
		if value.is_absolute_path(): continue
		if not getting_value:
			key = value
			if key in VALUE_REQUIRED:
				getting_value = true
			else:
				process_arg(key)
		else:
			process_arg(key, value)
			getting_value = false
	if start_connection:
		MultiplayerManager.start(server)
	if not scene_changed:
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/title.tscn")
