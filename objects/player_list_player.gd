extends Control

var username = "Default"
var level = Vector3.ZERO
var dog_dict = {"clothes": "Overalls", "hat": "Bandana", "hair": "Simple", "color": {"body": Color(1,1,1), "hat": Color(1,1,1), "clothes": Color(1,1,1), "brush_handle": Color(1,1,1)}}

var dog
@onready var username_label = $MarginContainer/HBoxContainer/VBoxContainer/Username
@onready var level_label = $MarginContainer/HBoxContainer/VBoxContainer/Level

func setup():
	dog.set_dog_dict(dog_dict)
	username_label.text = username
	level_label.text = "%d,%d,%d" % [level.x, level.y, level.z]

func _ready():
	dog = load("res://objects/dog/dog_animation.tscn").instantiate() # Preloading or instantiating in the scene tree for some reason breaks dog_animation for all nodes
	dog.position = Vector2(75, 130)
	$SubViewport.add_child(dog)
