extends Node2D

var anim = 0

var prev_position

var userinfo
var playerstatus = Global.PlayerStatus.Normal : set=_set_playerstatus

var discord_user = null

var facing = false

var brush_position = Vector2(0, 0)
var brush_prev_position = Vector2(0, 0)
var brush_drawing = false
var brush_color = 0
var brush_return_timer = 5.0
var brush_size = 24

@onready var animation = $AnimationManager
@onready var brush = $prop

func _set_playerstatus(newstatus):
	playerstatus = newstatus
	if playerstatus > 0:
		$PlayerStatus.texture = load("res://assets/playerstatus/%d.png" % playerstatus)
		$PlayerStatus.visible =  true
	else:
		$PlayerStatus.visible =  false

func _ready():
	brush.dog = self
	Settings.connect("settings_changed", update_auth)

func _process(delta):
	z_index = int(global_position.y)
	if prev_position:
		if (position.x - prev_position.x) != 0:
			facing = (position.x - prev_position.x) < 0
			animation.flip = facing
	prev_position = position
	
	brush_return_timer = brush.update(delta, brush_drawing, brush_return_timer, brush_position, brush_prev_position, brush_size)
	
	if brush_drawing and brush_color == 0:
		brush.end_color = Color.WHITE
	else:
		if brush_color:
			brush.end_color = Global.palette[(brush_color-1) % len(Global.palette)]
	
	if animation.animation_name == "idle" and brush_drawing:
		if animation.flip != (brush_position.x < position.x):
			animation.flip = (brush_position.x < position.x)
	
	brush_prev_position = brush_position

func update_profile():
	$Auth/Profile.texture = ImageTexture.create_from_image(await Global.get_discord_profile(discord_user))

func update_auth():
	if Settings.show_auth_names and MultiplayerManager.auth_type != null:
		$Auth.visible = true
		$Auth/AuthName.text = discord_user.username
		if Settings.show_avatars_level:
			update_profile()
		else:
			$Auth/Profile.texture = null
	else:
		$Auth.visible = false

