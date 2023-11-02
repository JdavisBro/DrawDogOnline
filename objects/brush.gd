extends Node2D

var dog

var size = 24
var color_index = 0
var pos = Vector2.ZERO
var prev_position = Vector2.ZERO
var prev_paint_pos = Vector2.ZERO
var paint_pos = Vector2.ZERO

var prev_draw_col = 1
var prev_size = 24
var prev_drawing = false

var texture_movement = 0.0

var flood_start_timer = 0.0
var flood_node

var brush_return_timer = 5.0

@onready var circle = $circle
@onready var prop = $prop

const FLOOD_START = 1.0
const BRUSH_SIZES = [24, 72, 6]
const BRUSH_RETURN_TIME = 0.5

func reset_flood():
	flood_start_timer = 0.0
	if is_instance_valid(flood_node): flood_node.queue_free()

func _physics_process(delta):
	prev_position = pos
	if DisplayServer.window_is_focused():
		pos = get_global_mouse_position()
	
	prev_paint_pos = paint_pos
	paint_pos = (pos / Global.paint_res).round()
	
	if Input.is_action_just_pressed("brush_size_next"):
		size = BRUSH_SIZES[(BRUSH_SIZES.find(size)+1) % len(BRUSH_SIZES)]
		reset_flood()
		
	if Input.is_action_just_pressed("brush_color_next"):
		color_index = (color_index+1) % len(Global.palette)
		reset_flood()
	elif Input.is_action_just_pressed("brush_color_prev"):
		color_index = posmod(color_index-1, len(Global.palette))
		reset_flood()
	
	var drawing = false
	var draw_col
	if Input.is_action_pressed("draw"):
		draw_col = color_index + 1
		drawing = true
		if (not Input.is_action_pressed("erase") or Input.is_action_just_pressed("erase")) and Input.is_action_just_pressed("draw"): # If button just pressed change prev_pos to not use that
			prev_position = pos
	if Input.is_action_pressed("erase"):
		draw_col = 0
		drawing = true
		if not Input.is_action_pressed("draw") and Input.is_action_just_pressed("erase"): # If button just pressed change prev_pos to not use that
			prev_position = pos
	if drawing:

		if prev_position.distance_to(pos) <= 1:
			flood_start_timer += delta
		else:
			reset_flood()
		if flood_start_timer > 1.0:
			if not flood_node:
				flood_node = PaintBurst.new(Global.paint_target, draw_col)
				flood_node.position = paint_pos
				add_child(flood_node)
		else:
			PaintUtil.draw_line(Global.paint_target, draw_col, prev_position/Global.paint_res, pos/Global.paint_res, ceil(size / 12))
	else:
		reset_flood()

	circle.position = pos
	brush_return_timer = prop.update(delta, drawing, brush_return_timer, pos, prev_position, size)
	circle.visible = brush_return_timer > .5
	
	if drawing and draw_col == 0:
		prop.end_color = Color.WHITE
	else:
		prop.end_color = Global.palette[color_index]
	
	if draw_col == null:
		draw_col = color_index + 1
	MultiplayerManager.client.brush_me_update(pos, drawing, draw_col, size)
	if (pos != prev_position and (not brush_return_timer > 0.5)) or prev_draw_col != draw_col or prev_size != size or prev_drawing != drawing:
		MultiplayerManager.brush_update.rpc(pos, drawing, draw_col, size)
	prev_draw_col = draw_col
	prev_drawing = drawing
	prev_size = size

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	prop.dog = dog
	prop.handle.modulate = Global.dog_dict.color.brush_handle
	if not Global.loaded_brush:
		for i in range(3):
			Global.loaded_brush.append(load("res://assets/chicory/brush/%s.png" % (i+1)))
