extends Node

var USER_INFO = {
	"username": "Default", "position": Vector2.ZERO, "animation": "idle", "facing": false, "playerstatus": Global.PlayerStatus.Normal,
	"brush": {
		"position": Vector2.ZERO, "drawing": false, "color": 1, "size": 24
	},
	"dog": Global.dog_dict
}
var level_puppets = {} # pid: dogpuppet
var dogpuppet = preload("res://objects/dog/dog_puppet.tscn")
var level_scene
var dog
var chat
var me = USER_INFO

var player_list

var reconnect = true

const TIMEOUT_TIME = 10.0
var timeout = 0.0
var timeout_enable = false

var auth_error: String = ""
var client_id
var server_player = {"dog": null, "username": null}

# Signal

func on_player_disconnected(id):
	if player_list:
		player_list.remove_player(id)
	if id in level_puppets:
		if is_instance_valid(level_puppets[id]):
			level_puppets[id].queue_free()
		level_puppets.erase(id)

func on_connected_ok():
	me.position = Vector2.ZERO
	me.username = Global.username

func on_connected_fail():
	timeout_enable = false
	get_tree().paused = false
	set_loading(false)
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")

func on_server_disconnected():
	if reconnect:
		start()
	else:
		set_loading(false)
		get_tree().change_scene_to_file("res://scenes/ui/title.tscn")

# Builtin

func _process(delta):
	if not timeout_enable:
		return
	timeout += delta
	if timeout > TIMEOUT_TIME:
		reconnect = false
		multiplayer.multiplayer_peer.close()
		MultiplayerManager.connection_status = "Connection Timed Out"
		set_loading(false)
		timeout_enable = false
		get_tree().change_scene_to_file("res://scenes/ui/title.tscn")

# Util

func brush_me_update(position, drawing, color, size):
	me.brush.position = position
	me.brush.drawing = drawing
	me.brush.color = color
	me.brush.size = size

func set_loading(loading):
	get_tree().paused = loading
	Global.loading_screen.visible = loading

func add_puppet(pid, userinfo):
	if pid in level_puppets:
		if is_instance_valid(level_puppets[pid]):
			level_puppets[pid].queue_free()
		else:
			return
	var puppet = dogpuppet.instantiate()
	puppet.userinfo = userinfo
	puppet.position = userinfo.position
	level_puppets[pid] = puppet
	level_scene.add_child(puppet)
	puppet.get_node("username").text = userinfo.username
	puppet.discord_user = MultiplayerManager.authenticated_players[pid]
	puppet.update_auth()
	puppet.brush_position = userinfo.brush.position
	puppet.brush_drawing = userinfo.brush.drawing
	puppet.brush_color = userinfo.brush.color
	puppet.brush_size = userinfo.brush.size
	puppet.animation.play(userinfo.animation)
	puppet.animation.flip = userinfo.facing
	puppet.facing = userinfo.facing
	puppet.animation.set_dog_dict(userinfo.dog)
	puppet.brush.handle.modulate = userinfo.dog.color.brush_handle
	puppet.playerstatus = userinfo.playerstatus

func get_server_auth_tokens(ip):
	if FileAccess.file_exists("user://auth.json"):
		var auth_tokens = JSON.parse_string(FileAccess.open("user://auth.json", FileAccess.READ).get_line())
		if ip in auth_tokens: # another method of matching servers?
			return auth_tokens[ip]
	return null

func set_server_auth_tokens(ip, tokens):
	var auth_tokens = {}
	if FileAccess.file_exists("user://auth.json"):
		auth_tokens = JSON.parse_string(FileAccess.open("user://auth.json", FileAccess.READ).get_line())
		if not auth_tokens:
			auth_tokens = {}
	auth_tokens[ip] = tokens
	FileAccess.open("user://auth.json", FileAccess.WRITE_READ).store_string(JSON.stringify(auth_tokens))

# for other nodes

func change_level(level, position):
	if level != null:
		Global.current_level = level
	if position != null:
		dog.position = position
		me.position = position
	get_tree().call_group("paintbursts", "queue_free")
	Global.paint_target.clear_paint_diff()
	set_loading(true)
	MultiplayerManager.request_move_to_level.rpc_id(1, me, Global.current_level)
	get_tree().paused = true

func get_ip():
	return "%s%s:%s" % [MultiplayerManager.protocol, MultiplayerManager.ip, MultiplayerManager.port]

func enter_level():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
	await get_tree().node_added
	MultiplayerManager.request_move_to_level.rpc_id(1, me, Global.current_level)

# Start

func start():
	timeout_enable = true
	set_loading(true)
	var peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = ["ludus"]
	#var error = peer.create_client(ip, port)
	var error = peer.create_client("%s%s:%d" % [MultiplayerManager.protocol, MultiplayerManager.ip, MultiplayerManager.port])
	if error:
		print(error)
	multiplayer.multiplayer_peer = peer
	print("Connection Started")
	if MultiplayerManager.protocol == "wss://" and MultiplayerManager.port == MultiplayerManager.DEFAULT_WSS_PORT:
		Settings.last_server_ip = MultiplayerManager.ip
	elif MultiplayerManager.protocol == "ws://" and MultiplayerManager.port == MultiplayerManager.DEFAULT_PORT:
		Settings.last_server_ip = MultiplayerManager.ip
	else:
		Settings.last_server_ip = "%s:%d" % [MultiplayerManager.ip, MultiplayerManager.port]
	Settings.last_server_protocol = MultiplayerManager.protocol
	Settings.save()

# RPC

## Auth

func welcome(_pid):
	get_tree().change_scene_to_file("res://scenes/level.tscn")
	await get_tree().node_added
	MultiplayerManager.request_move_to_level.rpc_id(1, me, Global.current_level)
	MultiplayerManager.auth_type = null
	
func request_auth(_pid, auth_type, server_client_id):
	if auth_type != null and not (MultiplayerManager.protocol == "wss://" or Settings.allow_insecure_server_auth or OS.is_debug_build()):
		MultiplayerManager.connection_status = "Insecure Server"
		reconnect = false
		multiplayer.multiplayer_peer.close()
		return
	client_id = server_client_id
	timeout_enable = false
	MultiplayerManager.auth_type = auth_type
	if auth_type == "discord":
		var tokens = get_server_auth_tokens(get_ip())
		if tokens:
			# tokens = {"access_token": "a", "refresh_token": "a"} # invalid token test
			MultiplayerManager.auth_login.rpc_id(1, tokens)
		else:
			get_tree().change_scene_to_file("res://scenes/ui/login.tscn")

func auth_logged_in(_pid, tokens, userinfo, authenticated, prev_users):
	MultiplayerManager.authenticated_players = authenticated
	set_server_auth_tokens(get_ip(), tokens)
	print("Logged in as %s" % userinfo.username)
	var login = get_node_or_null("/root/Login")
	if not login:
		get_tree().change_scene_to_file("res://scenes/ui/login.tscn")
		await get_tree().node_added
		login = get_node("/root/Login")
		await login.ready
	if prev_users and prev_users.dog:
		login.server_user(prev_users.dog, prev_users.username)
	login.logged_in()

func auth_failed(_pid, error_message):
	set_server_auth_tokens(get_ip(), null)
	auth_error = error_message
	print(auth_error)
	var login = get_node("/root/Login")
	if login:
		login.update_error(error_message)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/login.tscn")

## Paint

func draw_diff(_pid, size, diff, rect, level, user):
	diff = MultiplayerManager.decode_diff(diff, size)
	if level == Global.current_level:
		PaintUtil.apply_diff(Global.paint_target, diff, rect, user)
	elif player_list:
		player_list.update_paint(level, diff, rect)

func recieve_level_paint(_pid, newpaint, size, level, palette):
	if level == Global.current_level:
		Global.paint_target.clear_paint()
		Global.paint_target.paint.array = MultiplayerManager.decompress_paint(newpaint, size)
		set_palette(_pid, palette, level)
	elif player_list:
		player_list.set_paint(level, MultiplayerManager.decompress_paint(newpaint, size), palette)

## Puppets

func kill_puppets(_pid):
	level_puppets = {}
	get_tree().call_group("dogpuppets", "queue_free")

func recieve_puppet(_pid, puppet, userinfo):
	if puppet != MultiplayerManager.uid:
		add_puppet(puppet, userinfo)

## Level

func complete_level_move(_pid, level):
	timeout_enable = false
	Global.paint_target.clear_undo()
	Global.current_level = level
	chat.clear_room_chat()
	get_tree().paused = false
	set_loading(false)
	MultiplayerManager.client_level_moved.rpc(me, level)

func client_level_moved(pid, userinfo, level):
	if player_list:
		player_list.set_player(pid, userinfo, level)
	if level != Global.current_level:
		if pid in level_puppets:
			level_puppets[pid].queue_free()
			level_puppets.erase(pid)
	else:
		add_puppet(pid, userinfo)

func set_palette(_pid, palette, level):
	if level == Global.current_level:
		Global.palette = palette
		Global.paint_target.palette = palette
		Global.paint_target.setup_tilemap_layers()
		dog.brush.color_index = min(dog.brush.color_index, len(Global.palette)-1)
	elif player_list:
		player_list.update_palette(level, palette)

## Dogs

func brush_update(pid, position, drawing, color, size):
	if pid in level_puppets:
		if not is_instance_valid(level_puppets[pid]):
			level_puppets.erase(pid)
			return
		level_puppets[pid].brush_position = position
		level_puppets[pid].brush_drawing = drawing
		level_puppets[pid].brush_color = color
		level_puppets[pid].brush_size = size

func dog_update_position(pid, position):
	if player_list:
		player_list.update_head_position(pid, position)
	if pid in level_puppets:
		level_puppets[pid].position = position

func dog_update_animation(pid, animation):
	if pid in level_puppets:
		level_puppets[pid].animation.play(animation)

func dog_update_dog(pid, newdog):
	if player_list:
		player_list.update_dog(pid, newdog)
	if pid == MultiplayerManager.uid:
		Global.dog_dict = newdog
		me.dog = newdog
		dog.animation.set_dog_dict(newdog)
		dog.brush.prop.handle.modulate = newdog.color.brush_handle
		Global.save_dog()
	if pid in level_puppets:
		level_puppets[pid].animation.set_dog_dict(newdog)
		level_puppets[pid].brush.handle.modulate = newdog.color.brush_handle

func dog_update_playerstatus(pid, playerstatus):
	if pid == MultiplayerManager.uid:
		me.playerstatus = playerstatus
	if pid in level_puppets:
		level_puppets[pid].playerstatus = playerstatus
		if playerstatus > 0 and level_puppets[pid].animation.animation_name != "idle":
			level_puppets[pid].animation.speed_scale = 0
		else:
			level_puppets[pid].animation.speed_scale = 1

## Chat

func chat_message(_pid, username, level, message):
	if level == Global.current_level:
		chat.add_room_message(username, message)

func global_chat_message(_pid, username, level, message):
	chat.add_global_message(username, level, message)

func join_leave_message(_pid, username, joined):
	chat.add_connection_message(username, joined)

func recieve_player_list(_pid, playerlist):
	if player_list:
		player_list.set_players(playerlist)

