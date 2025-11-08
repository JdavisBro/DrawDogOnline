extends Node

func ensure_bounds(size: Vector2, position: Vector2):
	var newpos = position.clamp(Vector2.ZERO, size-Vector2.ONE).round()
	if position.x < 0 or position.x >= size.x or position.y < 0 or position.y >= size.y:
		return Vector2.INF
	return newpos

func ensure_rect_bounds(size: Vector2, rect: Rect2):
	var paint_rect = Rect2(Vector2.ZERO, size-Vector2.ONE)
	if paint_rect.encloses(rect):
		return rect
	#push_warning("Paint rect drawing out of paint bounds.")
	var new_rect = Rect2(rect.position.clamp(Vector2.ZERO, size), Vector2.ZERO)
	new_rect.end = rect.end.clamp(Vector2.ZERO, size)
	return new_rect

func update_pos(paint, color: int, position: Vector2, me=true, diff=false):
	position = ensure_bounds(paint.size, position)
	if position.x == INF:
		return
	undo_diff(paint, color, position, me, diff)
	if paint.paint.at(position.x, position.y) == color:
		return
	if me and not diff:
		update_diff(paint, color, position)
	paint.paint.put(position.x, position.y, color)
	paint.image.set_pixelv(position, Color.TRANSPARENT if color == 0 else paint.palette[color-1])
	
func update_diff(paint, color, position):
	if not paint.paint_diff_drawing or not paint.diffs_enabled:
		return
	paint.paint_diff.put(position.x, position.y, color)
	if not paint.paint_diff_changed:
		paint.paint_diff_rect = Rect2(position, Vector2.ONE)
	else:
		paint.paint_diff_rect = paint.paint_diff_rect.expand(position)
		paint.paint_diff_rect = paint.paint_diff_rect.expand(position+Vector2.ONE)
	paint.paint_diff_changed = true

func undo_diff(paint, _color, position, me, diff):
	if (diff and me) or not paint.diffs_enabled:
		return
	if not me: # someone else updates where i have
		if paint.undo_diff.at(position.x, position.y) != -1:
			paint.undo_diff.put(position.x, position.y, -1)
		for i in paint.undo_queue:
			if i.diff:
				if i.diff.at(position.x, position.y) != -1:
					i.diff.put(position.x, position.y, -1)
		for i in paint.redo_queue:
			if i.diff:
				if i.diff.at(position.x, position.y) != -1:
					i.diff.put(position.x, position.y, -1)
		return
	if paint.undo_diff.at(position.x, position.y) != 255:
		return
	paint.undo_diff.put(position.x, position.y, paint.paint.at(position.x, position.y))
	if not paint.undo_diff_changed:
		paint.undo_diff_rect = Rect2(position, Vector2.ONE)
	else:
		paint.undo_diff_rect = paint.undo_diff_rect.expand(position)
		paint.undo_diff_rect = paint.undo_diff_rect.expand(position+Vector2.ONE)
	paint.undo_diff_changed = true

func apply_diff(paint, diff, rect, pid=0, multiplayer_diff=true):
	var i = 0
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			if diff[i] != 255:
				var target_pos = rect.position + Vector2(x, y)
				update_pos(paint, diff[i], target_pos, pid == MultiplayerManager.uid, multiplayer_diff)
			i += 1

func draw_rect(paint, color: int, rect: Rect2):
	rect = ensure_rect_bounds(paint.size, rect)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var position = Vector2(x, y)
			update_pos(paint, color, position)

func draw_line(paint, color: int, start: Vector2, end: Vector2, thickness: int=1):
	var dist = start.distance_squared_to(end)
	if (thickness > 1 and dist == 0) or thickness <= 1 and dist < 1:
		update_pos(paint, color, start)
		return
	var update_line_pos = func(pos): update_pos(paint, color, pos)
	if thickness > 1:
		@warning_ignore("integer_division")
		var half_thickness = int(thickness) / 2
		var angle = start.angle_to_point(end)
		var start1 = (start + Vector2.from_angle(angle - PI/2) * half_thickness).snapped(Vector2.ONE)
		var start2 = (start + Vector2.from_angle(angle + PI/2) * half_thickness).snapped(Vector2.ONE)
		var end1 = (end + Vector2.from_angle(angle - PI/2) * half_thickness).snapped(Vector2.ONE)
		bresenham(start1, start2, func(pos): bresenham(pos, end1 + (pos - start1), update_line_pos))
		return
	if start == end:
		update_pos(paint, color, start)
		return
	bresenham(start, end, update_line_pos)

func bresenham(start: Vector2, end: Vector2, function: Callable):
	var position = start
	var dx = abs(end.x - start.x)
	var sx = 1 if start.x < end.x else -1
	var dy = -abs(end.y - start.y)
	var sy = 1 if start.y < end.y else -1
	var error = dx + dy
	while true:
		function.call(position)
		var e2 = 2 * error
		if e2 >= dy:
			if (sx == 1 and position.x >= end.x) or (sx == -1 and position.x <= end.x): break
			error += dy
			position.x += sx
		elif e2 <= dx:
			if (sy == 1 and position.y >= end.y) or (sy == -1 and position.y <= end.y): break
			error += dx
			position.y += sy 


func draw_line_old(paint, color: int, start: Vector2, end: Vector2, thickness: int=1):
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
				draw_line_old(paint, color, start1, end1)
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
