extends Node2D

var size := Vector2(160, 90)

var paint := PackedByteArray2D.new()
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated: BitMap = BitMap.new()
var palette = Global.palette
var diffs_enabled = false

var pause_process = true

@onready var sprite = $Sprite2D
var image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)

func force_update():
	updated.create(Vector2i(size))
	update_rect = Rect2(0,0,size.x,size.y)
	update_needed = true

func _ready():
	image.fill(Color.WHITE)
	sprite.texture = ImageTexture.create_from_image(image)

func _process(_delta):
	if get_tree().paused and not pause_process:
		return
	if update_needed:
		update_paint()

func update_palette():
	force_update()

func update_paint():
	var newrect = Rect2(Vector2.ZERO, size)
	if not newrect.encloses(update_rect):
		update_rect = newrect
	for y in range(update_rect.position.y, update_rect.end.y):
		for x in range(update_rect.position.x, update_rect.end.x):
			if updated.get_bit(x, y):
				continue
			var col = paint.at(x, y)
			if col == 0:
				image.set_pixel(x, y, Color.WHITE)
			else:
				image.set_pixel(x, y, palette[(col-1) % palette.size()])
			updated.set_bit(x, y, true)
	update_needed = false
	sprite.texture.update(image)
