extends Node2D

@onready var sfx = {
	"sfx_footsteps": $footsteps,
	"sfx_jump": $jump,
	"sfx_jumpwhoosh": $jump_whoosh,
	"sfx_land": $land,
	"sfx_stop": $stop,
	"sfx_turn": $turn
}

var step_timer = 0.0
var step_frequency = 0.3334
var running = false
var anim_speed = 1.0

func set_not_puppet():
	for s in sfx:
		sfx[s].set_bus("DogSounds")

func _process(delta):
	if running:
		step_timer += delta * anim_speed
		if step_timer >= step_frequency:
			step_timer = fmod(step_timer, step_frequency)
			play_sound("sfx_footsteps")

func play_sound(sound):
	sfx[sound].play()

func start_running():
	if not running:
		running = true
		step_timer = 0

func stop_running():
	if running:
		running = false
		step_timer = 0

func jump():
	stop_running()
	play_sound("sfx_jumpwhoosh")
	play_sound("sfx_jump")
	
func turn_around():
	play_sound("sfx_turn")
	step_timer = 8
