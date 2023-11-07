extends Node2D

const RADIUS = 25

func _draw():
	draw_circle(Vector2.ZERO, RADIUS, Color.BLACK)
