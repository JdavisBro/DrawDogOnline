extends Node2D

@export var set_paint_target := true
@export var init_paint_string := ""
@export var init_paint_size := 0
@export var init_palette: Array[Color] = []

var size := Vector2(162, 91)
var total_pixel := size.x * size.y

var paint := PackedByteArray2D.new()
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated: BitMap = BitMap.new()
var palette = Global.palette

var diffs_enabled = true

var paint_diff := PackedByteArray2D.new(size, -1)
var paint_diff_drawing = false
var paint_diff_rect = Rect2(Vector2.ZERO, Vector2.ZERO)
var paint_diff_changed = false

const UNDO_LENGTH = 10

var undo_queue = []
var redo_queue = []

var undo_diff := PackedByteArray2D.new(paint.size, 255)
var undo_diff_rect = Rect2(Vector2.ZERO, Vector2.ZERO)
var undo_diff_changed = false

var pause_process = false

@onready var map = $PaintViewport/TileMap
@onready var paintviewport = $PaintViewport

func get_texture():
	$ScreenshotViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	return $ScreenshotViewport.get_texture().get_image()

func clear_undo():
	undo_queue = []
	redo_queue = []
	undo_diff_changed = false

func clear_paint():
	paint.clear()
	updated.create(Vector2i(size))
	update_rect = Rect2(0,0,size.x,size.y)
	update_needed = true

func clear_paint_diff():
	paint_diff.clear()
	paint_diff_changed = false

func clear_undo_diff(undo=true, clear_redo=true):
	add_undo_to(undo, clear_redo)
	undo_diff.clear()
	undo_diff_changed = false

func add_undo_to(undo=true, clear_redo=true):
	if not undo_diff_changed:
		return
	var queue
	if undo:
		queue = undo_queue
		if clear_redo:
			redo_queue = []
	else:
		queue = redo_queue
	var undodict = {}
	undodict["diff"] = undo_diff.duplicate()
	undodict["rect"] = undo_diff_rect
	queue.push_front(undodict)
	if len(queue) > UNDO_LENGTH:
		queue.remove_at(len(queue)-1)

func setup_tilemap_layers():
	while map.get_layers_count() > len(palette):
		map.remove_layer(map.get_layers_count()-1)
	var i = 0
	for col in palette:
		if i >= map.get_layers_count():
			map.add_layer(i)
		map.set_layer_modulate(i, col)
		i += 1

func set_init_paint():
	if init_paint_string:
		palette = init_palette
		paint.array = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(init_paint_string), init_paint_size)

func force_update():
	updated.create(Vector2i(size))
	update_rect = Rect2(0,0,size.x,size.y)
	update_needed = true

func _ready():
	clear_paint()
	clear_undo_diff()
	set_init_paint()
	setup_tilemap_layers()
	if not Global.paint_target and set_paint_target:
		Global.paint_target = self

func connected():
	if not paint_diff_drawing:
		clear_paint_diff()
	paint_diff_drawing = true
	if paint_diff_changed:
		var newrect = Rect2(Vector2.ZERO, size)
		if not newrect.encloses(paint_diff_rect):
			paint_diff_rect = newrect
		var newdiff = paint_diff.slice(paint_diff_rect).array
		var diffs = MultiplayerManager.encode_diff(newdiff)
		MultiplayerManager.draw_diff_to_server.rpc_id(1, diffs[0], diffs[1], paint_diff_rect, Global.current_level)
		clear_paint_diff()

func apply_undo(diff, rect):
	get_tree().call_group("paintbursts", "stop")
	var newrect = Rect2(Vector2.ZERO, size)
	if not newrect.encloses(rect):
		rect = newrect
	var newdiff = diff.slice(rect).array
	var diffs = MultiplayerManager.encode_diff(newdiff)
	if diffs[0] > 0:
		PaintUtil.apply_diff(Global.paint_target, newdiff, rect, MultiplayerManager.uid, false)

func _process(_delta):
	$DisplaySprite.material.set_shader_parameter("boil", Global.boil)
	$ScreenshotViewport/ScreenshotSprite.material.set_shader_parameter("boil", Global.boil)

	if get_tree().paused and not pause_process:
		return
	if MultiplayerManager.connected:
		connected()
		
	if Input.is_action_just_pressed("undo", true):
		clear_undo_diff()
		if undo_queue:
			var undo = undo_queue.pop_front()
			apply_undo(undo.diff, undo.rect)
			add_undo_to(false) # applying the undo basically reverses the diff to be redo so add it to redo
			undo_diff_changed = false
			clear_undo_diff() # clears undo without adding  becasues above line
	elif Input.is_action_just_pressed("redo", true):
		clear_undo_diff() # adds current undo to list (can clear redo)
		if redo_queue:
			var undo = redo_queue.pop_front()
			apply_undo(undo.diff, undo.rect) # reverses redo
			clear_undo_diff(true, false) # adds reversed redo to undo
	randomize()
	
	if update_needed:
		update_paint()

func update_paint(defer=false):
	var newrect = Rect2(Vector2.ZERO, size-Vector2.ONE)
	if not newrect.encloses(update_rect):
		update_rect = newrect
	for y in range(update_rect.position.y, update_rect.end.y):
		for x in range(update_rect.position.x, update_rect.end.x):
			if updated.get_bit(x, y):
				continue
			for i in range(len(palette)):
				map.set_cell(i, Vector2(x, y))
			var donecol = []
			var v1 = paint.at(x, y)
			var v2 = paint.at(x+1, y)
			var v3 = paint.at(x+1, y+1)
			var v4 = paint.at(x, y+1)
			for color in [v1, v2, v3, v4]:
				if color in donecol or color == 0 or color > map.get_layers_count():
					continue
				donecol.append(color)
				var val = int(v1 == color) + (int(v2 == color) << 1) + (int(v3 == color) << 2) + (int(v4 == color) << 3) 
				if val > 0:
					if defer:
						@warning_ignore("integer_division")
						map.call_deferred("set_cell", color-1, Vector2(x, y), 0, Vector2((val) % 4, (val) / 4))
					else:
						@warning_ignore("integer_division")
						map.set_cell(color-1, Vector2(x, y), 0, Vector2((val) % 4, (val) / 4))
			updated.set_bit(x, y, true)
	update_needed = false
	if defer:
		paintviewport.call_deferred("set_update_mode", SubViewport.UPDATE_ONCE)
	else:
		paintviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
