extends Camera2D

const SCREEN_SIZE = Vector2(1920, 1080)
const ZOOM_SPEED = Vector2(0.5, 0.5)
const MOVE_DIST = Vector2(0.25, 0.25) # cursor distance from corner of the screen to move camera
const MOVE_SPEED = Vector2(1, 1) # 1 = screen size, per second
const MODIFIER_MULT = 4

var mouse_pos = Vector2.ZERO

func _physics_process(delta):
	var prev_center = position + SCREEN_SIZE/zoom/2
	var speed = ZOOM_SPEED
	if Input.is_action_pressed("zoom_modifier"):
		speed *= MODIFIER_MULT
	if Input.is_action_pressed("zoom_in"):
		zoom += speed*delta
	if Input.is_action_pressed("zoom_out"):
		zoom -= speed*delta
		if zoom < Vector2.ONE:
			zoom = Vector2.ONE
	if Input.is_action_just_pressed("zoom_reset"):
		zoom = Vector2.ONE
	var new_center = position + SCREEN_SIZE/zoom/2
	if prev_center != new_center:
		position += prev_center - new_center
	if DisplayServer.window_is_focused() and Rect2(Vector2.ZERO, SCREEN_SIZE).has_point(get_viewport().get_mouse_position()):
		mouse_pos = get_global_mouse_position()
	if zoom == Vector2.ONE:
		return
	var mouse_camera = (mouse_pos - position) / (SCREEN_SIZE / zoom)
	if Rect2(MOVE_DIST, Vector2.ONE-(MOVE_DIST*2)).has_point(mouse_camera):
		return
	var move = ( mouse_camera - MOVE_DIST * (Vector2.ONE/MOVE_DIST/2) )
	move = (move + (-MOVE_DIST*move.normalized()))*(Vector2.ONE/MOVE_DIST)
	move = MOVE_SPEED * move * (SCREEN_SIZE/zoom) * delta
	position += move
