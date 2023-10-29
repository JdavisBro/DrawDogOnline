extends Node

func ensure_bounds(size: Vector2, position: Vector2):
	var newpos = position.clamp(Vector2.ZERO, size-Vector2.ONE)
	if newpos != position:
		pass#push_warning("Paint drawing out of paint bounds.")
	return newpos

func ensure_rect_bounds(size: Vector2, rect: Rect2):
	var paint_rect = Rect2(Vector2.ZERO, size-Vector2.ONE)
	if paint_rect.encloses(rect):
		return rect
	pass#push_warning("Paint rect drawing out of paint bounds.")
	var new_rect = Rect2(rect.position.clamp(Vector2.ZERO, size), Vector2.ONE)
	new_rect.end = rect.end.clamp(Vector2.ZERO, size)
	return new_rect
	

func update_pos(paint, color: int, position: Vector2):
	position = ensure_bounds(paint.size, position)
	if paint.paint[position.y][position.x] == color:
		return
	paint.paint[position.y][position.x] = color
	paint.updated[position.y][position.x] = false
	if not paint.update_needed:
		paint.update_rect = Rect2(position - Vector2.ONE, Vector2.ONE*2)
	paint.update_rect = paint.update_rect.expand(position+Vector2.ONE)
	paint.update_rect = paint.update_rect.expand(position-Vector2.ONE)
	paint.update_needed = true

func draw_rect(paint, color: int, rect: Rect2):
	rect = ensure_rect_bounds(paint.size, rect)
	print(rect.position, rect.end)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var position = Vector2(x, y)
			update_pos(paint, color, position)

func draw_line(paint, color: int, start: Vector2, end: Vector2, thickness: int=1):
	if start.distance_to(end) < 0.1:
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

func flood_from(paint, color: int, center: Vector2, min_dist: int, max_dist: int):
	center = center.floor() # ehh maybe do this better but i kinda don't care
	draw_rect(paint, color, Rect2(center.x + max_dist/2, center.y + max_dist/4, 1, 1).expand(Vector2(center.x + min_dist/2, center.y - max_dist/4))) # RIGHT
	draw_rect(paint, color, Rect2(center.x - max_dist/2, center.y + max_dist/4, 1, 1).expand(Vector2(center.x - min_dist/2, center.y - max_dist/4))) # LEFT
	draw_rect(paint, color, Rect2(center.x - max_dist/4, center.y - max_dist/2, 1, 1).expand(Vector2(center.x + max_dist/4, center.y - min_dist/2))) # UP
	draw_rect(paint, color, Rect2(center.x - max_dist/4, center.y + max_dist/2, 1, 1).expand(Vector2(center.x + max_dist/4, center.y + min_dist/2))) # DOWN
	var corners = [
		Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)
	]
	var add = Vector2(0,1)
	
	for corner in corners:
		var minpos1 = Vector2(center.x + (min_dist/2 * corner.x), center.y + (min_dist/4 * corner.y))
		var minpos2 = Vector2(center.x + (min_dist/4 * corner.x), center.y + (min_dist/2 * corner.y))
		var maxpos1 = Vector2(center.x + (max_dist/2 * corner.x), center.y + (max_dist/4 * corner.y))+add
		var maxpos2 = Vector2(center.x + (max_dist/4 * corner.x), center.y + (max_dist/2 * corner.y))+add
		var mid1 = minpos1.lerp(maxpos1, 0.5)
		var mid2 = minpos2.lerp(maxpos2, 0.5)
		var thickness = floor(minpos1.distance_to(maxpos1))
		draw_line(paint, color, mid1, mid2, thickness)
		add = Vector2.ZERO

#	var flood_pos = [position]
#	print(position)
#	var flood_done = []
#	while flood_pos:
#		position = flood_pos[-1]
#		var dist = center.distance_to(position)
#		if dist > max_dist:
#			flood_pos.erase(position)
#			flood_done.append(position)
#			continue
#		if dist < min_dist:
#			flood_pos.erase(position)
#			flood_done.append(position)
#			flood_pos.append(position+Vector2(1,0))
#			continue
#		if dist >= min_dist:
#			update_pos(paint, color, position)
#		flood_done.append(position)
#		flood_pos.erase(position)
#		for pos in [position+Vector2(-1, 0), position+Vector2(1,0), position+Vector2(0, 1), position+Vector2(0,-1),position+Vector2(-1, 1),position+Vector2(-1, -1)]:
#			if pos in flood_done or pos in flood_pos or center.distance_to(pos) > max_dist and pos != center:
#				continue
#			flood_pos.append(pos)
