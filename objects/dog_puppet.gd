extends Node2D

var anim = 0
var anims = ["idle", "run", "runup", "walk", "walkup", "jump", "hop_up", "hop_down", "sit"]

var prev_position

var facing = false

var brush_position = Vector2(0, 0)
var brush_prev_position = Vector2(0, 0)
var brush_drawing = false
var brush_color = 0
var brush_return_timer = 5.0
var brush_size = 24

@onready var animation = $AnimationManager
@onready var brush = $prop

func _ready():
	brush.dog = self

func _process(delta):
	z_index = global_position.y
	if prev_position:
		if (position.x - prev_position.x) != 0:
			facing = (position.x - prev_position.x) < 0
			animation.flip = facing
	prev_position = position
	
	brush_return_timer = brush.update(delta, brush_drawing, brush_return_timer, brush_position, brush_prev_position, brush_size)
	
	if brush_drawing and brush_color == 0:
		brush.end_color = Color.WHITE
	else:
		if brush_color:
			brush.end_color = Global.palette[brush_color-1]
	
	brush_prev_position = brush_position
