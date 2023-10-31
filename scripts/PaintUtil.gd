extends Node

func ensure_bounds(size: Vector2, position: Vector2):
	var newpos = position.clamp(Vector2.ZERO, size-Vector2.ONE).round()
	if newpos != position:
		pass#push_warning("Paint drawing out of paint bounds.")
	return newpos

func ensure_rect_bounds(size: Vector2, rect: Rect2):
	var paint_rect = Rect2(Vector2.ZERO, size-Vector2.ONE)
	if paint_rect.encloses(rect):
		return rect
	pass#push_warning("Paint rect drawing out of paint bounds.")
	var new_rect = Rect2(rect.position.clamp(Vector2.ZERO, size), Vector2.ZERO)
	new_rect.end = rect.end.clamp(Vector2.ZERO, size)
	return new_rect

func update_pos(paint, color: int, position: Vector2):
	position = ensure_bounds(paint.size, position)
	update_diff(paint, color, position)
	if paint.paint[position.y][position.x] == color:
		return
	paint.paint[position.y][position.x] = color
	paint.updated[position.y][position.x] = false
	paint.updated[position.y][position.x-1] = false
	paint.updated[position.y-1][position.x] = false
	paint.updated[position.y-1][position.x-1] = false
	if not paint.update_needed:
		paint.update_rect = Rect2(position - Vector2.ONE, Vector2.ONE*2)
	else:
		paint.update_rect = paint.update_rect.merge(Rect2(position - Vector2.ONE, Vector2.ONE*2))
	paint.update_needed = true
	
func update_diff(paint, color, position):
	if not paint.drawing_paint_diff:
		return
	paint.paint_diff[position.y][position.x] = color
	if not paint.paint_diff_changed:
		paint.paint_diff_rect = Rect2(position, Vector2.ONE)
	else:
		paint.paint_diff_rect = paint.paint_diff_rect.expand(position)
	paint.paint_diff_changed = true

func apply_diff(paint, diff, rect):
	var diffing = paint.drawing_paint_diff
	paint.drawing_paint_diff = false
	var i = 0
	for x in range(rect.size.x+1):
		for y in range(rect.size.y+1):
			if diff[i] != "X":
				var target_pos = rect.position + Vector2(x, y)
				update_pos(paint, diff[i].hex_to_int(), target_pos)
			i += 1
	paint.drawing_paint_diff = diffing

func draw_rect(paint, color: int, rect: Rect2):
	rect = ensure_rect_bounds(paint.size, rect)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var position = Vector2(x, y)
			update_pos(paint, color, position)

func draw_line(paint, color: int, start: Vector2, end: Vector2, thickness: int=1):
	if start.distance_to(end) == 0:
		update_pos(paint, color, start)
		return
	var position = start
	@warning_ignore("integer_division")
	var half_thickness = thickness / 2
	var angle = start.angle_to_point(end)
	if thickness > 1:
		var start1 = position + Vector2.from_angle(angle - PI/2) * half_thickness
		var start2 = position + Vector2.from_angle(angle + PI/2) * half_thickness
		var end1 = end + Vector2.from_angle(angle - PI/2) * half_thickness
		var end2 = end + Vector2.from_angle(angle + PI/2) * half_thickness
		var done_start = []
		var done_end = []
		while true:
			if start1 not in done_start and end1 not in done_end:
				draw_line(paint, color, start1, end1)
				done_start.append(start1)
				done_start.append(end1)
			if start1 == start2:
				break
			start1 = start1.move_toward(start2, .5) # moving by more than .5 will miss some spots on diagonals
			end1 = end1.move_toward(end2, .5)
		return
	while true:
		update_pos(paint, color, position)
		if position == end:
			break
		position = position.move_toward(end, 0.75)
