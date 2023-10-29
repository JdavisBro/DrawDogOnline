extends Node2D

var size := Vector2(162, 91)
var total_pixel := size.x * size.y

var paint := []
var update_needed := true
var update_rect := Rect2(Vector2.ZERO, size-Vector2.ONE)
var updated := []
var palette := [
	Color("#00f3dd"), Color("#d8ff55"), Color("#ffa694"), Color("#b69aff"), Color(0,0,0)
]
var boil_timer := 0.0


@onready var map = $TileMap

func random_paint():
	randomize()
	paint = []
	updated = []
	for i in range(total_pixel):
		if i % int(size.x) == 0:
			paint.append([])
			updated.append([])
		paint[-1].append(randi_range(0,4))
		updated[-1].append(false)
		update_rect = Rect2(0,0,size.x,size.y)
		update_needed = true

func setup_tilemap_layers():
	while map.get_layers_count() > 1:
		map.remove_layer(map.get_layers_count()-1)
	var i = 0
	for col in palette:
		if i > 0:
			map.add_layer(-1)
		map.set_layer_modulate(i, col)
		i += 1

func _ready():
	setup_tilemap_layers()
	random_paint()
	if not Global.paint_target:
		Global.paint_target = self

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		random_paint()
	boil_timer += delta
	randomize()
	if boil_timer > 0.25:
		map.material.set_shader_parameter("boil", randf())
		boil_timer = fmod(boil_timer, 0.25)
	if update_needed:
		for y in range(update_rect.position.y, min(update_rect.end.y, size.y-1)):
			for x in range(update_rect.position.x, min(update_rect.end.x, size.x-1)):
				if not updated[y][x] or not updated[y][x+1] or not updated[y+1][x] or not updated[y+1][x+1]:
					for i in range(len(palette)):
						map.set_cell(i, Vector2(x, y))
					var spot = paint[y][x]
					var donecol = []
					for color in [paint[y][x], paint[y][x+1], paint[y+1][x+1], paint[y+1][x]]:
						if color not in donecol and color > 0:
							donecol.append(color)
							var val = int(spot == color) + (int(paint[y][x+1] == color) << 1) + (int(paint[y+1][x+1] == color) << 2) + (int(paint[y+1][x] == color) << 3) 
							if val > 0:
								@warning_ignore("integer_division")
								map.set_cell(color-1, Vector2(x, y), 0, Vector2((val) % 4, (val)/4))
					updated[y][x] = true
		update_needed = false
