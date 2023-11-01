extends Node2D

var size := Vector2(162, 91)
var total_pixel := size.x * size.y

var paint := []
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated := []
var palette = Global.palette
var boil_timer := 0.0

var paint_diff := []
var drawing_paint_diff = false
var paint_diff_rect = Rect2(Vector2.ZERO, Vector2.ZERO)
var paint_diff_changed = false

@onready var map = $TileMap

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
	setup_tilemap_layers()
	clear_paint()
	if not Global.paint_target:
		Global.paint_target = self

var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "X"]

func connected():
	if not drawing_paint_diff:
		clear_paint_diff()
	drawing_paint_diff = true
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

func _process(delta):
#	if Input.is_action_just_pressed("ui_accept"):
#		clear_paint(true)
	if MultiplayerManager.connected:
		connected()
	boil_timer += delta
	randomize()
	if boil_timer > 0.25:
		map.material.set_shader_parameter("boil", randf())
		boil_timer = fmod(boil_timer, 0.25)
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
