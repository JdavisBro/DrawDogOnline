extends TextEdit

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		print(Engine.get_process_frames())
		if Input.is_action_just_pressed("ui_focus_prev", true):
			if focus_previous:
				get_node(focus_previous).grab_focus()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("ui_focus_next", true):
			if focus_next:
				get_node(focus_next).grab_focus()
			get_viewport().set_input_as_handled()
