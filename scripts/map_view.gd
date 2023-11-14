extends SubViewportContainer

@onready var viewport = $MapViewport
@onready var camera = $MapViewport/Camera2D

var moving = false

var ZOOM_MIN = 0.05
var ZOOM_MAX = 10.0

func _gui_input(event):
	if event is InputEventMouseMotion:
		if moving:
			camera.position -= event.relative/(camera.zoom.x)
	elif event is InputEventMouseButton:
		var scroll := 0.0
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				var viewcorner = camera.get_screen_center_position() - (Vector2(viewport.size)/camera.zoom/2.0)
				var pos = viewcorner + (event.position/camera.zoom)
				var screen_pos = pos.posmodv(Vector2(1920, 1080))
				var screen = (pos / Vector2(1920, 1800)).floor()
				prints(screen, screen_pos) # Teleport!
			MOUSE_BUTTON_MIDDLE:
				moving = event.pressed
			MOUSE_BUTTON_WHEEL_DOWN:
				scroll -= event.factor/50.0
			MOUSE_BUTTON_WHEEL_UP:
				scroll += event.factor/50.0
		if scroll != 0:
			var loops = 0
			var newzoom = camera.zoom + Vector2.ONE * scroll
			while newzoom.x <= 0:
				scroll /= 2
				newzoom = camera.zoom + Vector2.ONE * scroll
				loops += 1
				if loops > 9:
					scroll = 0
			camera.zoom = newzoom.clamp(Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))
