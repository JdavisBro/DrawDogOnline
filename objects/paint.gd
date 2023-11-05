extends Node2D

@export var set_paint_target := true
@export var init_paint_string := ""
@export var init_paint_size := 0
@export var init_palette: Array[Color] = []

var size := Vector2(162, 91)
var total_pixel := size.x * size.y

var paint := []
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated := []
var palette = Global.palette
var boil_timer := 0.0

var paint_diff := []
var paint_diff_drawing = false
var paint_diff_rect = Rect2(Vector2.ZERO, Vector2.ZERO)
var paint_diff_changed = false

const UNDO_LENGTH = 10

var undo_queue = []
var redo_queue = []

var undo_diff := []
var undo_diff_rect = Rect2(Vector2.ZERO, Vector2.ZERO)
var undo_diff_changed = false

@onready var map = $MapViewport/TileMap

func get_texture():
	$ScreenshotViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	return $ScreenshotViewport.get_texture().get_image()

func clear_paint(random=false):
	randomize()
	paint = []
	updated = []
	for i in range(total_pixel):
		if i % int(size.x) == 0:
			paint.append([])
			updated.append([])
		var col = 0
		if random:
			col = randi_range(0,4)
		paint[-1].append(col)
		updated[-1].append(false)
		update_rect = Rect2(0,0,size.x,size.y)
		update_needed = true

func clear_paint_diff():
	paint_diff = []
	for i in range(total_pixel):
		if i % int(size.x) == 0:
			paint_diff.append([])
		paint_diff[-1].append(-1)
	paint_diff_changed = false

func clear_undo_diff(undoing=false):
	if not undoing:
		add_undo_to(undo_queue)
		undo_diff = []
		for i in range(total_pixel):
			if i % int(size.x) == 0:
				undo_diff.append([])
			undo_diff[-1].append(-1)
		return
	if undoing:
		add_undo_to(redo_queue) # If undoing add it to redo queue
		if undo_queue:
			var undo = undo_queue.pop_front()
			undo_diff = undo.diff
			undo_diff_rect = undo.rect

func add_undo_to(queue):
	var undo = {}
	undo["diff"] = undo_diff
	undo["rect"] = undo_diff_rect
	queue.push_front(undo)
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

func _ready():
	clear_paint()
	clear_undo_diff()
	if init_paint_string:
		palette = init_palette
		paint = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(init_paint_string), init_paint_size)
		init_paint_string = ""
	setup_tilemap_layers()
	if not Global.paint_target and set_paint_target:
		Global.paint_target = self

var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "X"]

func connected():
	if not paint_diff_drawing:
		clear_paint_diff()
	paint_diff_drawing = true
	if paint_diff_changed:
		var newdiff = ""
		var newrect = Rect2(Vector2.ZERO, size)
		if not newrect.encloses(paint_diff_rect):
			paint_diff_rect = newrect
		for x in range(paint_diff_rect.position.x, paint_diff_rect.end.x):
			for y in range(paint_diff_rect.position.y, paint_diff_rect.end.y):
				newdiff += hex[paint_diff[y][x]]
		#MultiplayerManager.draw_diff.rpc(newdiff, paint_diff_rect, Global.current_level)
		var diffs = MultiplayerManager.encode_diff(newdiff)
		MultiplayerManager.draw_diff_to_server.rpc_id(1, diffs[0], diffs[1], paint_diff_rect, Global.current_level)
		clear_paint_diff()

func do_undo():
	get_tree().call_group("paintbursts", "stop")
	var newdiff = ""
	var newrect = Rect2(Vector2.ZERO, size)
	if not newrect.encloses(undo_diff_rect):
		undo_diff_rect = newrect
	for x in range(undo_diff_rect.position.x, undo_diff_rect.end.x):
		for y in range(undo_diff_rect.position.y, undo_diff_rect.end.y):
			newdiff += hex[undo_diff[y][x]]
#	var diffs = MultiplayerManager.encode_diff(newdiff)
	PaintUtil.apply_diff(Global.paint_target, newdiff, undo_diff_rect, MultiplayerManager.uid, false)
	#MultiplayerManager.draw_diff_to_server.rpc_id(1, diffs[0], diffs[1], undo_diff_rect, Global.current_level)
	clear_undo_diff(true)

func _process(delta):
	boil_timer += delta
	if boil_timer > 0.25:
		var boil = randf()
		$DisplaySprite.material.set_shader_parameter("boil", boil)
		$ScreenshotViewport/ScreenshotSprite.material.set_shader_parameter("boil", boil)
		boil_timer = fmod(boil_timer, 0.25)
	if get_tree().paused:
		return
	if MultiplayerManager.connected:
		connected()
	if Input.is_action_just_pressed("undo", true):
		do_undo()
	randomize()
	if update_needed:
		var newrect = Rect2(Vector2.ZERO, size-Vector2.ONE)
		if not newrect.encloses(update_rect):
			update_rect = newrect
		for y in range(update_rect.position.y-1, update_rect.end.y): # -1 because we only render ones we can do msquares of
			for x in range(update_rect.position.x-1, update_rect.end.x):
				if updated[y][x]:
					continue
				for i in range(len(palette)):
					map.set_cell(i, Vector2(x, y))
				var donecol = []
				for color in [paint[y][x], paint[y][x+1], paint[y+1][x], paint[y+1][x+1]]:
					if color in donecol or color == 0 or color > map.get_layers_count():
						continue
					donecol.append(color)
					var val = int(paint[y][x] == color) + (int(paint[y][x+1] == color) << 1) + (int(paint[y+1][x+1] == color) << 2) + (int(paint[y+1][x] == color) << 3) 
					if val > 0:
						@warning_ignore("integer_division")
						map.set_cell(color-1, Vector2(x, y), 0, Vector2((val) % 4, (val) / 4))
				updated[y][x] = true
		update_needed = false
