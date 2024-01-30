extends Node2D

var dog

var size = 24
var color_index = 0
var pos = Vector2.ZERO

var prev_position = Vector2.ZERO

var use_mouse_pos = true

const SPEED = 1000

var prev_mouse_pos = Vector2.ZERO
@warning_ignore("integer_division")
var controller_pos = Vector2(1920/2, 1080/2)

var paint_pos = Vector2.ZERO
var prev_paint_pos = Vector2.ZERO

var prev_draw_col = 1
var prev_size = 24
var prev_drawing = false

var texture_movement = 0.0

var flood_start_timer = 0.0
var flood_node
var was_flooding = false

var brush_return_timer = 5.0

var styles = []
var selected_style = 0

var camera

@onready var styletip = $styletip

@onready var circle = $circle
@onready var prop = $prop
@onready var sfx = $SoundManager

const FLOOD_START = 1.0
const BRUSH_SIZES = [24, 72, 6]
const BRUSH_RETURN_TIME = 0.5

func reset_flood():
	flood_start_timer = 0.0
	if is_instance_valid(flood_node): flood_node.queue_free()
	if styles[selected_style-1].has_method("flood_stop"):
		styles[selected_style-1].flood_stop()

func process_style_inputs():
	var oldsel = selected_style
	if Input.is_action_just_pressed("style_1", true):
		if selected_style == 1:
			selected_style = 0
		else:
			selected_style = 1
	elif Input.is_action_just_pressed("style_2", true):
		if selected_style == 2:
			selected_style = 0
		else:
			selected_style = 2
	elif Input.is_action_just_pressed("style_3", true):
		if selected_style == 3:
			selected_style = 0
		else:
			selected_style = 3
	elif Input.is_action_just_pressed("style_4", true):
		if selected_style == 4:
			selected_style = 0
		else:
			selected_style = 4
	if selected_style > len(styles):
		selected_style = 0
	if oldsel != selected_style:
		if styles[oldsel-1].has_method("swapped_out"):
			styles[oldsel-1].swapped_out()
		reset_flood()
	if selected_style:
		styletip.visible = true
		styletip.get_node("Label").text = str(selected_style)
		styletip.get_node("Icon").texture = styles[selected_style-1].icon
		styletip.position = pos + Vector2(23, -74)
	else:
		styletip.visible = false

func _physics_process(delta):
	prev_position = pos
	
	var old_use_mouse_pos = use_mouse_pos
	
	var move = Input.get_vector("brush_left", "brush_right", "brush_up", "brush_down").limit_length()
	if not move.is_zero_approx():
		controller_pos += move*SPEED*delta
		use_mouse_pos = false
	
	elif DisplayServer.window_is_focused():
		if prev_mouse_pos != get_global_mouse_position():
			use_mouse_pos = true
			prev_mouse_pos = get_global_mouse_position()
	
	if use_mouse_pos:
		pos = get_global_mouse_position()
	else:
		pos = controller_pos
	
	if use_mouse_pos != old_use_mouse_pos:
		prev_position = pos
	
	if get_tree().paused:
		return
	
	if not Global.paintable:
		brush_return_timer = prop.update(delta, false, brush_return_timer, pos, prev_position, size)
		$circle.visible = false
		return
	
	prev_paint_pos = paint_pos
	paint_pos = pos / Global.paint_res
	
	if !Global.chat:
		if Input.is_action_just_pressed("brush_size_next", true):
			size = BRUSH_SIZES[(BRUSH_SIZES.find(size)+1) % len(BRUSH_SIZES)]
			reset_flood()
			sfx.play_sound_on_size_change(size)
			
		if Input.is_action_just_pressed("brush_color_next", true):
			color_index = (color_index+1) % len(Global.palette)
			reset_flood()
			sfx.play_sound("sfx_colorswitch")
		elif Input.is_action_just_pressed("brush_color_prev", true):
			color_index = posmod(color_index-1, len(Global.palette))
			reset_flood()
			sfx.play_sound("sfx_colorswitch")
		process_style_inputs()
	
	var drawing = false
	var draw_col
	if Input.is_action_pressed("draw"):
		draw_col = color_index + 1
		drawing = true
		if (not Input.is_action_pressed("erase", true) or Input.is_action_just_pressed("erase", true)) and Input.is_action_just_pressed("draw", true): # If button just pressed change prev_pos to not use that
			prev_position = pos
	if Input.is_action_pressed("erase", true):
		draw_col = 0
		drawing = true
		if not Input.is_action_pressed("draw", true) and Input.is_action_just_pressed("erase", true): # If button just pressed change prev_pos to not use that
			prev_position = pos
	
	if (not prev_drawing) and drawing and (not get_tree().get_nodes_in_group("paintbursts")): # If im drawing new and there are no brushbursts
		Global.paint_target.clear_undo_diff()
	
	if drawing:
		if prev_position.distance_to(pos) <= 1:
			flood_start_timer += delta
		else:
			reset_flood()
		
		if flood_start_timer > 1.0 and Settings.hold_brushburst:
			if selected_style:
				if styles[selected_style-1].has_method("flood"):
					styles[selected_style-1].flood(paint_pos, draw_col, !was_flooding)
				was_flooding = true
			else:
				if not flood_node:
					flood_node = PaintBurst.new(Global.paint_target, draw_col)
					flood_node.position = paint_pos
					add_child(flood_node)
		else:
			if selected_style:
				if styles[selected_style-1].has_method("paint"):
					styles[selected_style-1].paint(paint_pos, prev_paint_pos, draw_col, prev_drawing != drawing)
			else:
				PaintUtil.draw_line(Global.paint_target, draw_col, prev_position/Global.paint_res, pos/Global.paint_res, ceil(size / 12))
	else:
		reset_flood()

	circle.scale = (Vector2.ONE/camera.zoom).clamp(Vector2(0.25, 0.25), Vector2.ONE)
	$ColorSelectorCircle.scale = Vector2.ONE/camera.zoom
	circle.position = pos
	brush_return_timer = prop.update(delta, drawing, brush_return_timer, pos, prev_position, size)
	circle.visible = brush_return_timer > .5
	
	if drawing and draw_col == 0:
		prop.end_color = Color.WHITE
	else:
		prop.end_color = Global.palette[color_index % len(Global.palette)]
	
	if draw_col == null:
		draw_col = color_index + 1
		
	if prev_drawing == true and drawing == false:
		sfx.stop_painting()
	elif drawing == true:
		if draw_col == 0:
			sfx.erase()
		else:
			sfx.paint()

			
	MultiplayerManager.client.brush_me_update(pos, drawing, draw_col, size)
	if (pos != prev_position and (not brush_return_timer > 0.5)) or prev_draw_col != draw_col or prev_size != size or prev_drawing != drawing:
		MultiplayerManager.brush_update.rpc(pos, drawing, draw_col, size)
	prev_draw_col = draw_col
	prev_drawing = drawing
	prev_size = size
	
	

func setup_styles():
	# add a ui and loading and stuff when there are more than 4 brush styles. or before, whatever.
	styles.append(preload("res://scripts/styles/Fill.gd").new(self))

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	prop.dog = dog
	prop.handle.modulate = Global.dog_dict.color.brush_handle
	camera = dog.get_node("../Camera2D")
	setup_styles()
	if not Global.loaded_brush:
		for i in range(3):
			Global.loaded_brush.append(load("res://assets/chicory/brush/%s.png" % (i+1)))
