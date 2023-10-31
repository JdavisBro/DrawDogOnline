extends Node

const VALUE_REQUIRED = ["join-server", "server-start"]

var scene_changed = false

func process_arg(key, value=""):
	if key == "server-start":
		MultiplayerManager.server = true
		MultiplayerManager.port = MultiplayerManager.DEFAULT_PORT
		if value != "default":
			MultiplayerManager.port = str(int(value))
		get_tree().change_scene_to_file("res://scenes/server.tscn")
		MultiplayerManager.start()
		scene_changed = true
	elif key == "join-server":
		MultiplayerManager.get_ip_port(value)
		get_tree().change_scene_to_file("res://scenes/level.tscn")
		MultiplayerManager.start()
		scene_changed = true

func _ready():
	var key = ""
	var getting_value = false
	var args = OS.get_cmdline_args()
	print(args)
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
		get_tree().change_scene_to_file("res://scenes/level.tscn")
