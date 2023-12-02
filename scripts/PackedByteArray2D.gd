class_name PackedByteArray2D
extends Object

var array := PackedByteArray()
var size = Vector2(162, 91)
var fill = 0

func _init(nsize: Vector2=size, nfill: int=fill):
	size = nsize
	if nfill:
		fill = nfill
	array.resize(size.x * size.y)
	array.fill(fill)

func at(x: int, y: int):
	return array[(y*size.x)+x]

func put(x: int, y: int, value: Variant):
	array[(y*size.x)+x] = value

func clear():
	array.fill(fill)

func duplicate():
	var new = PackedByteArray2D.new(size, fill)
	new.array = array.duplicate()
	return new
