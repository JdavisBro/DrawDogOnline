extends Control

var submenu = null

func _process(_delta):
	if !Global.pause_enable:
		return
	if Input.is_action_just_pressed("pause", true) and not get_tree().paused:
		get_tree().paused = true
		visible = true
		Global.paintable = false
		get_parent().move_child(self, -1) # level control steals input
		MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Paused)
	elif Input.is_action_just_pressed("pause", true) and get_tree().paused and visible:
		close_pause()
	if get_tree().paused and visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if not is_instance_valid(submenu):
			MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Paused)

func close_pause():
	if is_instance_valid(submenu):
		if submenu.has_method("before_close"):
			submenu.before_close()
		submenu.queue_free()
		submenu = null
		MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Paused)
	else:
		get_tree().paused = false
		visible = false
		Global.paintable = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Normal)

func _on_resume_pressed():
	close_pause()

func _on_player_list_pressed():
	MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.PlayerList)
	submenu = preload("res://scenes/ui/map.tscn").instantiate()
	add_child(submenu)

func _on_edit_palette_pressed():
	MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Palette)
	submenu = preload("res://scenes/ui/set_palette.tscn").instantiate()
	add_child(submenu)

func _on_edit_dog_pressed():
	MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Dog)
	submenu = preload("res://scenes/ui/set_dog.tscn").instantiate()
	add_child(submenu)

func _on_set_title_pressed():
	var paint = MultiplayerManager.compress_paint(Global.paint_target.paint)
	Settings.title_paint_custom_size = paint[0]
	Settings.title_paint_custom = Marshalls.raw_to_base64(paint[1])
	var pal = []
	for i in Global.paint_target.palette:
		pal.append(i.to_html(false))
	Settings.title_paint_custom_palette = pal
	Settings.title_paint_custom_enabled = true
	Settings.save()

func _on_settings_pressed():
	MultiplayerManager.dog_update_playerstatus.rpc(Global.PlayerStatus.Setting)
	submenu = preload("res://scenes/ui/settings.tscn").instantiate()
	add_child(submenu)

func _on_leave_server_pressed():
	get_tree().paused = false
	visible = false
	MultiplayerManager.client.reconnect = false
	multiplayer.multiplayer_peer.close()
