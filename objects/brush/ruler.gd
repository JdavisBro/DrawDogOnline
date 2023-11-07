extends Node2D

const WIDTH = 3
const STEP = Vector2(12, 12)

var start
var end
var rect

@onready var brush = $'..'

func _process(_delta):
	if not Input.is_action_pressed("ruler"):
		rect = null
		visible = false
		return
	
	visible = true
	
	if Input.is_action_just_pressed("ruler"):
		start = brush.pos.snapped(STEP) - Vector2(6,6)
		rect = Rect2(start, Vector2.ZERO)
	
	var newend = brush.pos.snapped(STEP) - Vector2(6,6)
	if newend != end:
		rect = Rect2(start, Vector2.ZERO)
		rect = rect.expand(newend)
		end = newend
		queue_redraw()
	
	var dist = (abs(start - end) / STEP) + Vector2.ONE
	$distlabel.text = "%d, %d" % [dist.x, dist.y]
	$distlabel.position = end + Vector2(30, -30)

func _draw():
	if not (rect and start and end):
		return
	for y in range(rect.position.y, rect.end.y+STEP.y, STEP.y):
		if fposmod((start.y - y)/STEP.y+(sign(start.y - end.y)), 5) == 0:
			draw_rect(Rect2(Vector2(end.x-2, y), STEP+Vector2(4, 0)), Color.WHITE, false, WIDTH)
		else:
			draw_rect(Rect2(Vector2(end.x, y), STEP), Color.WHITE, false, WIDTH)
	for x in range(rect.position.x, rect.end.x+STEP.x, STEP.x):
		if fposmod((start.x - x)/STEP.x+(sign(start.x - end.x)), 5) == 0:
			draw_rect(Rect2(Vector2(x, start.y-2), STEP+Vector2(0, 4)), Color.WHITE, false, WIDTH)
		else:
			draw_rect(Rect2(Vector2(x, start.y), STEP), Color.WHITE, false, WIDTH)
