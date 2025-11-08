extends Node2D

@export var set_paint_target := true
@export var init_paint_string := ""
@export var init_paint_size := 0
@export var init_palette: Array[Color] = []

var size := Vector2(162, 91)
var total_pixel := size.x * size.y

var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)

var paint := PackedByteArray2D.new()
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated := BitMap.new()
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

func get_texture():
	$ScreenshotViewport/ScreenshotSprite.material.set_shader_parameter("boil", Global.boil)
	$ScreenshotViewport/ScreenshotSprite.texture = ImageTexture.create_from_image(image)
	$ScreenshotViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	return $ScreenshotViewport.get_texture().get_image()

func clear_undo():
	undo_queue = []
	redo_queue = []
	undo_diff_changed = false

func clear_paint():
	image.fill(Color.TRANSPARENT)
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

func update_palette():
	force_update()

func set_init_paint():
	if init_paint_string:
		palette = init_palette
		paint.array = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(init_paint_string), init_paint_size)

func force_update():
	updated.create(Vector2i(size))
	update_rect = Rect2(0,0,size.x,size.y)
	update_needed = true

func _ready():
	$DisplaySprite.texture = ImageTexture.create_from_image(image)
	clear_paint()
	clear_undo_diff()
	set_init_paint()
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
	$DisplaySprite.texture.update(image)

func update_paint():
	var newrect = Rect2(Vector2.ZERO, size)
	if not newrect.encloses(update_rect):
		update_rect = newrect
	for y in range(update_rect.position.y, update_rect.end.y):
		for x in range(update_rect.position.x, update_rect.end.x):
			if updated.get_bit(x, y):
				continue
			var v1 = paint.at(x, y)
			image.set_pixel(x, y, Color.TRANSPARENT if v1 == 0 else palette[v1-1])
			updated.set_bit(x, y, true)
	update_needed = false
