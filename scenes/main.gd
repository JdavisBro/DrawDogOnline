extends Node

const VALUE_REQUIRED = ["join-server", "server-start", "--winpos", "--winsize"]

var scene_changed = false

func process_arg(key, value=""):
	match key:
		"server-start":
			MultiplayerManager.port = MultiplayerManager.DEFAULT_PORT
			if value != "default":
				if value.is_valid_int():
					MultiplayerManager.port = int(value)
				else:
					print("Port Invalid")
					get_tree().quit()
			get_tree().change_scene_to_file("res://scenes/server.tscn")
			MultiplayerManager.start(true)
			scene_changed = true
		"join-server":
			MultiplayerManager.get_ip_port(value)
			get_tree().change_scene_to_file("res://scenes/level.tscn")
			MultiplayerManager.start(false)
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
	if not scene_changed:
		get_tree().change_scene_to_file("res://scenes/ui/title.tscn")
