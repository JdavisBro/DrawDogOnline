extends ColorRect

var shader_mode = 4 # set to four to be incorrect on the first time

func _process(_delta):
	if shader_mode == Settings.eyestrain_mode:
		return
	var mult = Vector4.ONE
	var add = Vector4.ZERO
	match int(Settings.eyestrain_mode):
		1: # Default
			mult = Vector4(1, 0.941, 0.847, 1.0)
			add = Vector4(0, 0.02, 0.082, 0)
		2: # Lots
			mult = Vector4(0.941, 0.772, 0.588, 1.0)
	material.set_shader_parameter("mult", mult)
	material.set_shader_parameter("add", add)
	shader_mode = Settings.eyestrain_mode
