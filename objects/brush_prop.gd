extends Node2D

var dog

var texture_movement = 0.0
var end_color = Color.WHITE : set=_set_end_color

@onready var handle = $handle
@onready var end = $end

func _set_end_color(color):
	end_color = color
	end.modulate = color

func update(delta, drawing, return_timer, pos, prev_position, size):
	var both_scale = pow(size / 24.0, 0.25)
	scale = Vector2(both_scale, both_scale)
	if drawing:
		return update_drawing(delta, pos, prev_position)
	else:
		return update_not_drawing(delta, pos, return_timer)

func update_drawing(delta, pos, prev_position):
	rotation = 0
	global_position = pos
	position.y += -50 * scale.y + 15
	z_index = pos.y
	if pos.x != prev_position.x:
		end.flip_h = pos.x < prev_position.x
	var x_movement = abs(pos.x - prev_position.x)
	handle.rotation_degrees = move_toward(handle.rotation_degrees, min(1, x_movement / 80.0) * 90 * sign(pos.x - prev_position.x), 360*delta)
	if x_movement > 2:
		texture_movement += x_movement / 300
	else:
		texture_movement = 0
	end.texture = Global.loaded_brush[max(1, 2 - floor(texture_movement))]
	return 0.0

func update_not_drawing(delta, pos, return_timer):
	return_timer += delta
	if return_timer > 0.5:
		global_position = dog.global_position + Vector2(0, -25)
		z_index = dog.z_index - 1
		rotation_degrees = 135 + 90 * ( ( ( -dog.animation.scale.x )+1 ) / 2.0 )
		position += Vector2(0, 60).rotated(rotation)
	else:
		global_position = pos
		position.y += -50 * scale.y
		z_index = pos.y
	handle.rotation_degrees = move_toward(handle.rotation_degrees, 0, 360*delta)
	end.texture = Global.loaded_brush[0]
	return return_timer
