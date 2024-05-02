extends Node2D

var size := Vector2(160, 90)

var paint := PackedByteArray2D.new()
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated: BitMap = BitMap.new()
var palette = Global.palette

@onready var sprite = $Sprite2D
var image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)

func force_update():
	updated.create(Vector2i(size))
	update_rect = Rect2(0,0,size.x,size.y)
	update_needed = true

func _ready():
	image.fill(Color.WHITE)
	sprite.texture = ImageTexture.create_from_image(image)

func update_paint(defer):
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
	if defer:
		sprite.texture.update.call_deferred(image)
	else:
		sprite.texture.update(image)
