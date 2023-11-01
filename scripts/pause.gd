extends Control

func _process(_delta):
	if Global.pause_enable == false:
		return
	if Input.is_action_just_pressed("pause") and not get_tree().paused:
		get_tree().paused = true
		visible = true
	elif Input.is_action_just_pressed("pause")  and get_tree().paused and visible:
		get_tree().paused = false
		visible = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if get_tree().paused and visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_edit_palette_pressed():
	add_child(preload("res://scenes/set_palette.tscn").instantiate())

func _on_leave_server_pressed():
	multiplayer.peer.close()
