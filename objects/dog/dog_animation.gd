extends Node2D

# TODO:
# - body _0 _1 _2s, head _1
# - animation framerate & holds

var animation: DogAnimation
var animation_name: String
var prev_animation_name: String

var puppet = true

var frame = 0.0
var previous_f = -1
var flip = false : set = _set_flip

var big = false : set = _set_big

var speed_scale = 1.0

var tween

var initial_pos = Vector2.ZERO

var sprites_A := []
var sprites_B := []
var sprites_ear := []

@onready var B = $B
@onready var body_0 = $body_0
@onready var body = $body
@onready var A = $A
@onready var body_1 = $body_1
@onready var hat_1 = $hat_1
@onready var hair = $hair
@onready var head = $head
@onready var body_2 = $body_2
@onready var body_2_hat = $body_2_hat
@onready var ear = $ear
@onready var hat = $hat
@onready var sfx = $SoundManager

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
		sfx.turn_around()

func _set_big(value):
	big = value
	set_dog_dict(Global.dog_dict)
	play("idle")
	if big:
		head.texture = load("res://assets/chicory/expression/0_big.png")
		head.offset *= 5
	else:
		head.texture = load("res://assets/chicory/expression/0.png")
		head.offset /= 5
	for i in [body_0, body, body_1, hat_1, hair, body_2, body_2_hat, hat]:
		if big:
			i.offset *= 5
		else:
			i.offset /= 5

func _ready():
	play("idle")
	initial_pos = position
	for anim in ["run", "runup"]:
		for l in [["A", Global.loaded_sprites_A], ["B", Global.loaded_sprites_B], ["ear", Global.loaded_sprites_ear]]:
			load_frames(anim, l[0], l[1])

func _process(delta):
	var f = int(frame / 10)
	if animation_name == "jump":
		position.y = initial_pos.y - 70*sin( min(frame/10, len(sprites_ear)-2) * ( PI/(len(sprites_ear)-2) ) )
		$shadow.position.y = -position.y+5
		$shadow.visible = true
	else:
		position.y = initial_pos.y
		$shadow.visible = false
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
	var pos_scale = 1
	if big: pos_scale = 5
	if animation.body:
		var f_body: DogAnimationFrame = animation.body[f % len(animation.body)]
		for i in [body, body_0, body_1, body_2, body_2_hat]:
			i.position = f_body.position*pos_scale
			i.rotation_degrees = -f_body.rotation
	if animation.head:
		var f_head: DogAnimationFrame = animation.head[f % len(animation.head)]
		for i in [head, hair, hat, hat_1]:
			i.position = f_head.position*pos_scale
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

func reset_fit_textures():
	body_0.texture = null
	body.texture = null
	body_1.texture = null
	body_2_hat.texture = null
	hair.texture = null
	hat_1.texture = null
	body_2.texture = null
	hat.texture = null
	ear.move_to_front()

func set_dog_dict(dog_dict):
	reset_fit_textures()
	var suffix = ""
	if big:
		suffix = "_big"
	body.texture = load("res://assets/chicory/clothes%s/%02d.png" % [suffix, Global.body_ims[dog_dict.clothes]])
	if dog_dict.clothes in Global.body2_ims:
		body_2.texture = load("res://assets/chicory/clothes2%s/%02d.png" % [suffix, Global.body2_ims[dog_dict.clothes]])
	if dog_dict.clothes in Global.body1_ims:
		body_1.texture = load("res://assets/chicory/clothes2%s/%02d.png" % [suffix, Global.body1_ims[dog_dict.clothes]])
	if dog_dict.clothes in Global.body0_ims:
		body_0.texture = load("res://assets/chicory/clothes2%s/%02d.png" % [suffix, Global.body0_ims[dog_dict.clothes]])
	if dog_dict.hat in Global.body2_hats:
		body_2_hat.texture = load("res://assets/chicory/clothes2%s/%02d.png" % [suffix, Global.body1_ims[dog_dict.hat]])
	else:
		if dog_dict.hat in Global.hat_ims:
			hat.texture = load("res://assets/chicory/hat%s/%02d.png" % [suffix, Global.hat_ims[dog_dict.hat]])
	if dog_dict.hat in Global.hair_shown_hats:
		hair.texture = load("res://assets/chicory/hat%s/%02d.png" % [suffix, Global.hair_ims[dog_dict.hair]])
	if dog_dict.hat in Global.hats_over_ear:
		hat.move_to_front()
	if dog_dict.hat == "Horns":
		hat_1.texture = load("res://assets/chicory/hat%s/%02d.png" % [suffix, 89])
	
	B.modulate = dog_dict.color.body
	A.modulate = dog_dict.color.body
	ear.modulate = dog_dict.color.body
	head.modulate = dog_dict.color.body
	hair.modulate = dog_dict.color.body
	
	hat.modulate = dog_dict.color.hat
	hat_1.modulate = dog_dict.color.hat
	body_1.modulate = dog_dict.color.hat
	body_0.modulate = dog_dict.color.hat
	body_2_hat.modulate = dog_dict.color.hat
	
	body.modulate = dog_dict.color.clothes
	body_2.modulate = dog_dict.color.clothes

func load_frames(anim, layer, loaded):
	if big:
		anim = anim + "_big"
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
	if anim != "idle" and big:
		return
	animation = ResourceLoader.load("res://data/animations/" + anim + ".tres")
	prev_animation_name = animation_name
	animation_name = anim
	frame = 0
	previous_f = -1
	
	for i in [B, A, ear]:
		if anim == "idle" and not big:
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
	
	play_sounds_on_state_change()

func play_if_not(anim):
	if animation_name != anim:
		play(anim)


func play_sounds_on_state_change():
	if animation_name == "jump":
		sfx.jump()
	if animation_name == "idle" and (prev_animation_name=="run" or prev_animation_name =="runup"):
		sfx.play_sound("sfx_stop")
	if animation_name != "jump" and prev_animation_name=="jump":
		sfx.play_sound("sfx_land")
	if animation_name == "run" or animation_name == "runup":
		sfx.start_running()
	else:
		sfx.stop_running()


