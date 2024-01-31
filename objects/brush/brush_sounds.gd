extends Node2D



@onready var sfx = {
	"sfx_colorswitch": $color_switch,
	"sfx_size_small": $size_small,
	"sfx_size_medium": $size_medium,
	"sfx_size_big": $size_big,
	"sfx_paint": $paint_medium,
	"sfx_erase": $erase
}

var paint_timer = 0
var erase_timer = 0

func play_sound(sound):
	sfx[sound].play()
	
func play_sound_on_size_change(size):
	if size==6:
		play_sound("sfx_size_small")
	elif size==24:
		play_sound("sfx_size_medium")
	elif size==72:
		play_sound("sfx_size_big")
	
func erase():
	if not sfx["sfx_erase"].playing:
		sfx["sfx_erase"].play(erase_timer)

	
func paint():
	if not sfx["sfx_paint"].playing:
		sfx["sfx_paint"].play(paint_timer)

func stop_painting():
	erase_timer = sfx["sfx_erase"].get_playback_position()
	paint_timer = sfx["sfx_paint"].get_playback_position()
	sfx["sfx_paint"].stop()
	sfx["sfx_erase"].stop()
	
