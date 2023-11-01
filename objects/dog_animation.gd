extends Node2D

# TODO:
# - body _0 _1 _2s, head _1
# - animation framerate & holds

var animation: DogAnimation
var animation_name: String

var puppet = true

var frame = 0.0
var previous_f = -1
var flip = false : set = _set_flip

var speed_scale = 1.0

var tween

var sprites_A := []
var sprites_B := []
var sprites_ear := []

@onready var B = $B
@onready var body = $body
@onready var A = $A
@onready var head = $head
@onready var ear = $ear
@onready var hat = $hat

const FLIP_TIME = 0.08

func flip_tween(val):
	if scale.x != val:
		if tween:
			tween.kill()
		tween = get_tree().create_tween()
		tween.tween_property(self, "scale:x", val, FLIP_TIME).set_ease(tween.EASE_OUT).set_trans(tween.TRANS_SINE)

func _set_flip(value):
	if flip != value:
		flip = value
		if flip:
			flip_tween(-1)
		elif scale.x != 1:
			flip_tween(1)

func _ready():
	play("idle")
	for anim in ["run", "runup"]:
		for l in [["A", Global.loaded_sprites_A], ["B", Global.loaded_sprites_B], ["ear", Global.loaded_sprites_ear]]:
			load_frames(anim, l[0], l[1])

func _process(delta):
	var f = int(frame / 10)
	if f == previous_f:
		frame += 60 * delta * animation.speed_scale * speed_scale
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
	frame += 60 * delta * animation.speed_scale * speed_scale

func load_frames(anim, layer, loaded):
	if anim in loaded:
		return loaded[anim]
	var frames = []
	var i = 0
	var path = "res://assets/chicory/dog/%s/%s/%02d.png" % [anim, layer, i]
	while ResourceLoader.exists(path):
		frames.append(ResourceLoader.load(path))
		i += 1
		path = "res://assets/chicory/dog/%s/%s/%02d.png" % [anim, layer, i]
	loaded[anim] = frames
	return frames

func play(anim):
	if not ResourceLoader.exists("res://data/animations/" + anim + ".tres"):
		push_warning("Animation not found " + anim)
		return
	if not puppet and MultiplayerManager.connected:
		MultiplayerManager.dog_update_animation.rpc(anim)
		MultiplayerManager.client.me.animation = anim
	animation = ResourceLoader.load("res://data/animations/" + anim + ".tres")
	animation_name = anim
	frame = 0
	previous_f = -1
	for i in [B, A, ear]:
		if anim == "idle":
			i.offset = Vector2(-animation.origin.x / 5, -animation.origin.y / 5)
		else:
			i.offset = Vector2(-animation.origin.x, -animation.origin.y)
	var frames = load_frames(anim, "B", Global.loaded_sprites_B)
	sprites_B = frames
	if frames.is_empty(): # Not all animations have a B
		B.texture = null
		B.visible = false
	else:
		B.texture = frames[0]
		B.visible = true
	frames = load_frames(anim, "A", Global.loaded_sprites_A)
	sprites_A = frames
	if frames.is_empty(): # Not all animations have an A
		A.texture = null
		A.visible = false
	else:
		A.texture = frames[0]
		A.visible = true
	frames = load_frames(anim, "ear", Global.loaded_sprites_ear)
	sprites_ear = frames
	ear.texture = frames[0] # All animations have an ear, thank god

func play_if_not(anim):
	if animation_name != anim:
		play(anim)
