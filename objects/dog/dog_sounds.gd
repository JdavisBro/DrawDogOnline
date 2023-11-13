extends Node2D



@onready var sfx = {
	"sfx_footsteps": $footsteps,
	"sfx_jump": $jump,
	"sfx_jumpwhoosh": $jump_whoosh,
	"sfx_land": $land,
	"sfx_stop": $stop,
	"sfx_turn": $turn
}

var frame_counter = 0
var step_frequency = 20
var running = false


func _process(_delta):
	if running:
		frame_counter += 1
		if frame_counter == step_frequency:
			frame_counter = 0
			play_sound("sfx_footsteps")


func play_sound(sound):
	sfx[sound].play()

func start_running():
	if not running:
		running = true
		frame_counter = 0

func stop_running():
	if running:
		running = false
		frame_counter = 0

func jump():
	stop_running()
	play_sound("sfx_jumpwhoosh")
	play_sound("sfx_jump")
	
func turn_around():
	play_sound("sfx_turn")
	frame_counter = 8
