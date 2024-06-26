extends SubViewportContainer

@onready var map = $"../../.."
@onready var viewport = $MapViewport
@onready var camera = $MapViewport/Camera2D

var moving = false
var selecting = false

var ZOOM_MIN = 0.22
var ZOOM_MAX = 5

func get_teleport(event):
	var viewcorner = camera.get_screen_center_position() - (Vector2(viewport.size)/camera.zoom/2.0)
	var pos = viewcorner + (event.position/camera.zoom)
	var screen_pos = pos.posmodv(Vector2(160, 90))
	var screen = (pos / Vector2(160, 90)).floor().clamp(Vector2(-20,-20), Vector2(20, 20))
	screen = Vector3(screen.x, screen.y, 0)
	map.set_teleport(screen, screen_pos)

func _gui_input(event):
	if event is InputEventMouseMotion:
		if moving:
			camera.position = camera.get_screen_center_position()
			camera.position -= event.relative/(camera.zoom.x)
		if selecting:
			get_teleport(event)
	elif event is InputEventMouseButton:
		var scroll := 0.0
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				selecting = event.pressed
				get_teleport(event)
			MOUSE_BUTTON_LEFT:
				moving = event.pressed
			MOUSE_BUTTON_WHEEL_DOWN:
				scroll -= event.factor/50.0
			MOUSE_BUTTON_WHEEL_UP:
				scroll += event.factor/50.0
		if scroll != 0:
			var newzoom = camera.zoom + Vector2.ONE * (scroll / 4)
			camera.zoom = newzoom.clamp(Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))

func _ready():
	camera.position = (Vector2(Global.current_level.x, Global.current_level.y) * Vector2(1920, 1080)) + MultiplayerManager.client.me.position
