extends Control

var submenu = null

func _process(_delta):
	if Global.pause_enable == false:
		return
	if Input.is_action_just_pressed("pause", true) and not get_tree().paused:
		get_tree().paused = true
		visible = true
		get_parent().move_child(self, -1) # level control steals input
	elif Input.is_action_just_pressed("pause", true)  and get_tree().paused and visible:
		if is_instance_valid(submenu):
			if submenu.has_method("before_close"):
				submenu.before_close()
			submenu.queue_free()
		else:
			get_tree().paused = false
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if get_tree().paused and visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_resume_pressed():
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_player_list_pressed():
	submenu = preload("res://scenes/ui/player_list.tscn").instantiate()
	add_child(submenu)

func _on_edit_palette_pressed():
	submenu = preload("res://scenes/ui/set_palette.tscn").instantiate()
	add_child(submenu)

func _on_edit_dog_pressed():
	submenu = preload("res://scenes/ui/set_dog.tscn").instantiate()
	add_child(submenu)

func _on_settings_pressed():
	submenu = preload("res://scenes/ui/settings.tscn").instantiate()
	add_child(submenu)

func _on_leave_server_pressed():
	get_tree().paused = false
	visible = false
	MultiplayerManager.client.reconnect = false
	multiplayer.multiplayer_peer.close()
