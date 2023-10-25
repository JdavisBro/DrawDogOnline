extends Node2D

var textures = []

@onready var paint = get_node("../../..")

func _ready():
	for i in range(15):
		textures.append(ResourceLoader.load("res://assets/chicory/paint/%02d.png" % i))

func _process(_delta):
	if paint.update_needed:
		queue_redraw()

func _draw():
	for y in range(len(paint)):
		if y == 90:
			break
		for x in range(len(paint.paint[y])):
			if x == 161:
				break
			if not paint.updated[y][x]:
				paint.redrew = true
				var spot = paint.paint[y][x]
				var donecol = []
				for color in [paint.paint[y][x], paint.paint[y][x+1], paint.paint[y+1][x+1], paint.paint[y+1][x]]:
					if color not in donecol and color > 0:
						donecol.append(color)
						var val = int(spot == color) + (int(paint.paint[y][x+1] == color) << 1) + (int(paint.paint[y+1][x+1] == color) << 2) + (int(paint.paint[y+1][x] == color) << 3) 
						draw_texture(textures[val-1], Vector2(x*12, y*12), paint.palette[color-1])
				paint.updated[y][x] = true
