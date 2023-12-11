extends Node2D

const ACCEL = 6000
const MAX_SPEED = 600
const JUMP_MAX_SPEED = 800

var velocity = Vector2.ONE
var prev_position

var jumping = false
var jump_dir = Vector2.ZERO
var jump_buffered = false

var brush

var facing = false : set = _set_facing
var anim = 0
var anims = ["idle", "run", "runup", "walk", "walkup", "jump", "hop_up", "hop_down", "sit"]

@onready var animation = $AnimationManager

func _set_facing(new):
	facing = new
	animation.flip = new

func do_movement(delta):
	prev_position = position
	
	var move = Input.get_vector("left", "right", "up", "down").limit_length() # this is weird compared to usual but idk how to fix it maybe later?
	
	if not jumping and (Input.is_action_just_pressed("jump") or jump_buffered):
		jumping = true
		jump_dir = move
		animation.play("jump")
		jump_buffered = false
	
	if jumping:
		if animation.animation_name != "jump":
			jumping = false
			velocity = move * MAX_SPEED
			
		elif (animation.frame / 10) > 9:
			if jump_buffered:
				jumping = false
			velocity = Vector2.ZERO
			
		else:
			velocity = jump_dir * JUMP_MAX_SPEED
		if (animation.frame / 10) > 3 and Input.is_action_just_pressed("jump"):
			jump_buffered = true
	else:
		velocity = move * MAX_SPEED
	
	position += velocity*delta

func change_sprite_by_velocity():
	if velocity.x != 0:
		facing = velocity.x < 0
	
	if jumping:
		return
	
	if velocity.is_zero_approx():
		if animation.animation_name in ["run", "runup", "walk", "walkup"]:
			animation.play_if_not("idle")
	else:
		if velocity.x == 0:
			animation.play_if_not("runup")
		else:
			animation.play_if_not("run")

func _physics_process(delta):
	do_movement(delta)
	
	z_index = int(global_position.y)
	
	change_sprite_by_velocity()
	
	var old_level = Global.current_level
	if position.x > 1920 and Global.current_level.x + 1 <= MultiplayerManager.LEVEL_RANGE.x:
		Global.current_level.x += 1
		position.x = 1
	elif position.x < 0 and Global.current_level.x - 1 >= -MultiplayerManager.LEVEL_RANGE.x:
		Global.current_level.x += -1
		position.x = 1919
	if position.y > 1080 and Global.current_level.y + 1 <= MultiplayerManager.LEVEL_RANGE.y:
		Global.current_level.y += 1
		position.y = 1
	elif position.y < 0 and Global.current_level.y - 1 >= -MultiplayerManager.LEVEL_RANGE.y:
		Global.current_level.y += -1
		position.y = 1079
	if Global.current_level != old_level:
		MultiplayerManager.client.change_level(null, position)
		return
	position = position.clamp(Vector2.ZERO, Vector2(1920, 1080))
	
	
	if animation.animation_name == "idle" and brush.prev_drawing and brush.pos < position != facing:
		facing = brush.pos < position
	
	if prev_position != position and MultiplayerManager.connected:
		MultiplayerManager.dog_update_position.rpc(position)
	MultiplayerManager.client.me.position = position

func _ready():
	animation.puppet = false
	animation.sfx.set_not_puppet()
	brush = preload("res://objects/brush/brush.tscn").instantiate()
	brush.dog = self
	get_node("..").add_child.call_deferred(brush)
	animation.set_dog_dict(Global.dog_dict)
	$username.text = Global.username
