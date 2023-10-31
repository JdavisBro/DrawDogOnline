extends Node

const paint_size := Vector2(162, 91)
const paint_total := paint_size.x * paint_size.y

var loaded_sprites_A := {}
var loaded_sprites_B := {}
var loaded_sprites_ear := {}

var loaded_brush = []

var username = "Default"

var palette = [
	Color("#00f3dd"), Color("#d8ff55"), Color("#ffa694"), Color("#b69aff")
]

var paint_target = null
var paint_res: int = 12

var current_level = Vector3(0, 0, 0)
