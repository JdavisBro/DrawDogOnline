# meta-name: Brush Style

extends Node

var brush
var icon = preload("res://assets/chicory/stamp/00.png") # CHANGE THIS

func _init(nbrush):
	brush = nbrush

# Position is UNROUNDED paint position. Color is 0 (empty), 1-15 palette. Just is if this is the first paint/flood frame

func paint(position: Vector2, prev_position: Vector2, color: int, just: bool):
	pass

func flood(position: Vector2, color: int, just: bool):
	pass

func flood_stop():
	pass

func swapped_out(): # Called when swapped from this brush style to none/a different one
	flood_stop()
