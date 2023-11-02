extends Control

var submenu = null

func _process(_delta):
	if Global.pause_enable == false:
		return
	if Input.is_action_just_pressed("pause") and not get_tree().paused:
		get_tree().paused = true
		visible = true
	elif Input.is_action_just_pressed("pause")  and get_tree().paused and visible:
		if is_instance_valid(submenu):
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

func _on_edit_palette_pressed():
	submenu = preload("res://scenes/set_palette.tscn").instantiate()
	add_child(submenu)

func _on_leave_server_pressed():
	get_tree().paused = false
	visible = false
	multiplayer.multiplayer_peer.close()
