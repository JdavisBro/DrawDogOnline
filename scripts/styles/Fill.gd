extends Node

var brush
var icon = preload("res://assets/chicory/stamp/25.png") # CHANGE THIS

var flood_node

func _init(nbrush):
	brush = nbrush

func paint(position: Vector2, _prev_position: Vector2, color: int, just: bool):
	position = position.round()
	if not just or Global.paint_target.paint.at(position.x, position.y) == color:
		return
	flood_node = PaintBurst.new(Global.paint_target, color, Global.paint_target.paint.at(position.x, position.y))
	flood_node.position = position
	brush.add_child(flood_node)
