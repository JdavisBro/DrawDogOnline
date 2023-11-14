extends Node2D

var tween

@onready var headnode = $head
@onready var hair = $head/hair
@onready var head = $head/head
@onready var hat = $head/hat
@onready var hat_1 = $head/hat_1
@onready var ear = $head/ear

var prev_position = Vector2(-1920*20, -1080*20)
var flip = false

const FLIP_TIME = 0.08

func _process(_delta):
	if prev_position.x == position.x:
		return
	var newflip = prev_position.x > position.x
	if flip != newflip:
		prints(prev_position.x, position.x)
		flip = newflip
		var nextscale = 1
		if flip:
			nextscale = -1
		if tween:
			tween.kill()
		tween = get_tree().create_tween()
		tween.bind_node(self)
		tween.tween_property(headnode, "scale:x", nextscale, FLIP_TIME).set_ease(tween.EASE_OUT).set_trans(tween.TRANS_SINE)
	prev_position = position

func reset_fit_textures():
	hair.texture = null
	hat.texture = null
	hat_1.texture = null

func set_dog_dict(dog_dict):
	reset_fit_textures()
	if dog_dict.hat in Global.hat_ims:
		hat.texture = load("res://assets/chicory/hat/%02d.png" % Global.hat_ims[dog_dict.hat])
	if dog_dict.hat in Global.hair_shown_hats:
		hair.texture = load("res://assets/chicory/hat/%02d.png" % Global.hair_ims[dog_dict.hair])
	if dog_dict.hat in Global.hats_over_ear:
		hat.move_to_front()
	else:
		ear.move_to_front()
	if dog_dict.hat == "Horns":
		hat_1.texture = load("res://assets/chicory/hat/89.png")
	
	hair.modulate = dog_dict.color.body
	head.modulate = dog_dict.color.body
	ear.modulate = dog_dict.color.body
	
	hat.modulate = dog_dict.color.hat
	hat_1.modulate = dog_dict.color.hat
	
