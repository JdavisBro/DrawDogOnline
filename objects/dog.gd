extends Node2D

var anim = 0
var anims = ["idle", "run", "runup", "walk", "walkup", "jump", "hop_up", "hop_down", "sit"]

@onready var animation = $AnimationManager

func _process(delta):
	var prev = anim
	if Input.is_action_just_pressed("ui_left"):
		anim -= 1
		if anim < 0:
			anim = len(anims)-1
	if Input.is_action_just_pressed("ui_right"):
		anim += 1
		if anim >= len(anims):
			anim = 0
	if anim != prev:
		animation.play(anims[anim])
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
