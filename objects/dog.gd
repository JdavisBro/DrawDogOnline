extends CharacterBody2D

const ACCEL = 6000
const MAX_SPEED = 600

var brush

var facing = false : set = _set_facing
var anim = 0
var anims = ["idle", "run", "runup", "walk", "walkup", "jump", "hop_up", "hop_down", "sit"]

@onready var animation = $AnimationManager

func _set_facing(new):
	facing = new
	animation.flip = new

func do_movement(delta):
	var move = Input.get_vector("left", "right", "up", "down").limit_length() # this is weird compared to usual but idk how to fix it maybe later?
	
	velocity += move.normalized() * ACCEL * delta
	
	velocity = velocity.clamp(Vector2(-MAX_SPEED, -MAX_SPEED), Vector2(MAX_SPEED, MAX_SPEED))
	
	if sign(move.x) != sign(velocity.x):
		velocity.x = 0
	if sign(move.y) != sign(velocity.y):
		velocity.y = 0
	
	var unmodified_vel = velocity
	velocity *= abs(move)
	
	move_and_slide()
	
	velocity = unmodified_vel
	
	position.x = fposmod(position.x, 1920) # DEBUG: loop position on screen
	position.y = fposmod(position.y, 1080)

func change_sprite_by_velocity():
	if velocity.x != 0:
		facing = velocity.x < 0
	
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
	
	z_index = global_position.y
	
	change_sprite_by_velocity()
	
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _ready():
	brush = preload("res://objects/brush.tscn").instantiate()
	brush.dog = self
	get_node("..").add_child.call_deferred(brush)
