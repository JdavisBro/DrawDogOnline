extends Node2D

@onready var sfx = {
	"sfx_colorswitch": $color_switch,
	"sfx_size_small": $size_small,
	"sfx_size_medium": $size_medium,
	"sfx_size_big": $size_big,
	"sfx_paint": $paint_medium,
	"sfx_erase": $erase
}

func play_sound(sound):
	sfx[sound].play()
	
func play_sound_on_size_change(size):
	if size==6:
		play_sound("sfx_size_small")
	elif size==24:
		play_sound("sfx_size_medium")
	elif size==72:
		play_sound("sfx_size_big")
	
func erase(speed):
	if not sfx["sfx_erase"].playing and not sfx["sfx_erase"].stream_paused:
		sfx["sfx_erase"].play()
	AudioServer.get_bus_effect(AudioServer.get_bus_index("EraseBus"), 0).pitch_scale = speed + 0.5
	sfx["sfx_erase"].stream_paused = false

	
func paint():
	if not sfx["sfx_paint"].playing and not sfx["sfx_paint"].stream_paused:
		sfx["sfx_paint"].play()
	sfx["sfx_paint"].stream_paused = false

func stop_painting():
	sfx["sfx_erase"].stream_paused = true
	sfx["sfx_paint"].stream_paused = true
