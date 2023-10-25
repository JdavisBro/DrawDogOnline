extends Node2D

# TODO:
# - body _0 _1 _2s, head _1
# - animation framerate & holds

var animation: DogAnimation
var animation_name: String

var frame = 0
var previous_f = -1
var flip = false : set = _set_flip

var sprites_A := []
var sprites_B := []
var sprites_ear := []

@onready var B = $B
@onready var body = $body
@onready var A = $A
@onready var head = $head
@onready var ear = $ear
@onready var hat = $hat

func _set_flip(value):
	flip = value
	for i in [B, body, A, head, ear, hat]: # Add _1s and stuff here
		i.flip_h = value

func _ready():
	play("idle")

func _process(delta):
	var f = int(frame / 10)
	if f == previous_f:
		frame += 1
		return
	previous_f = f
	if f >= len(sprites_ear): # All animations have an ear so checking this is best
		if animation.loop == "1":
			frame = 0
			f = 0
		elif animation.loop == "0":
			frame -= 1
			f = len(sprites_ear)-1
		else:
			play(animation.loop)
			f = 0
	if animation.body:
		var f_body: DogAnimationFrame = animation.body[f % len(animation.body)]
		body.position = f_body.position
		body.rotation_degrees = -f_body.rotation
	if animation.head:
		var f_head: DogAnimationFrame = animation.head[f % len(animation.head)]
		for i in [head, hat]: # Update for horns AND hat clothes
			i.position = f_head.position
			i.rotation_degrees = f_head.rotation
	for layer in ["B", "A", "ear"]:
		match layer:
			"B":
				if sprites_B:
					B.texture = sprites_B[min(f, len(sprites_B)-1)]
			"A":
				if sprites_A:
					A.texture = sprites_A[min(f, len(sprites_A)-1)]
			"ear":
				if sprites_ear:
					ear.texture = sprites_ear[f]
	frame += 1

func play(anim):
	if ResourceLoader.exists("res://data/animations/" + anim + ".tres"):
		animation = ResourceLoader.load("res://data/animations/" + anim + ".tres")
		animation_name = anim
		frame = 0
		previous_f = -1
		for i in [B, A, ear]:
			if anim == "idle":
				i.offset = Vector2(-animation.origin.x / 5, -animation.origin.y / 5)
			else:
				i.offset = Vector2(-animation.origin.x, -animation.origin.y)
		for layer in ["B", "A", "ear"]:
			var frames = []
			var i = 0
			var path = "res://assets/chicory/dog/%s/%s/%02d.png" % [animation_name, layer, i]
			while ResourceLoader.exists(path):
				frames.append(ResourceLoader.load(path))
				print(path)
				i += 1
				path = "res://assets/chicory/dog/%s/%s/%02d.png" % [animation_name, layer, i]
			match layer:
				"B":
					sprites_B = frames
					if frames.is_empty(): # Not all animations have a B
						B.texture = null
						B.visible = false
					else:
						B.texture = frames[0]
						B.visible = true
				"A":
					sprites_A = frames
					if frames.is_empty(): # Not all animations have an A
						A.texture = null
						A.visible = false
					else:
						A.texture = frames[0]
						A.visible = true
				"ear":
					sprites_ear = frames
					ear.texture = frames[0] # All animations have an ear, thank god
	else:
		push_warning("Animation not found " + anim)
