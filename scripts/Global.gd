extends Node

const paint_size := Vector2(162, 91)
const paint_total := paint_size.x * paint_size.y

@onready var loading_screen = preload("res://scenes/loading.tscn").instantiate()
@onready var pause_screen = preload("res://scenes/pause.tscn").instantiate()

var pause_enable = false

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

func _ready():
	get_parent().add_child.call_deferred(loading_screen)
	get_parent().add_child.call_deferred(pause_screen)
