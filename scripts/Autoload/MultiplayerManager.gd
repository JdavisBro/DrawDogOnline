extends Node

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 33363
const DEFAULT_WSS_PORT = 443

const LEVEL_RANGE = Vector2(20, 20)

const PAINT_CHANNEL = 2
const CHAT_CHANNEL = 4

var ip = DEFAULT_IP
var port = DEFAULT_PORT
var protocol = "ws://"

var connected = false
var connection_status = ""

var server
var client
var uid = 0

var auth_type = null
var authenticated_players = {} # pid: discorduserinfo

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	process_mode = PROCESS_MODE_ALWAYS

# Signals

func _on_player_connected(id):
	prints(" new peer", id)
	if client.has_method("on_player_connected"):
		client.on_player_connected(id)

func _on_player_disconnected(id):
	prints("lost peer", id)
	if client.has_method("on_player_disconnected"):
		client.on_player_disconnected(id)

func _on_connected_ok():
	connected = true
	connection_status = "Conncted to server"
	print("Connected to server!")
	uid = multiplayer.get_unique_id()
	if client.has_method("on_connected_ok"):
		client.on_connected_ok()

func _on_connected_fail():
	connection_status = "Connection to server failed"
	print("Connection to server failed.")
	if client.has_method("on_connected_fail"):
		client.on_connected_fail()

func _on_server_disconnected():
	connected = false
	connection_status = "Disconnected from server"
	print("Disconnected from Server.")
	if client.has_method("on_server_disconnected"):
		client.on_server_disconnected()

# Util

func get_ip_port(newip):
	if ":" in newip:
		var both = newip.split(":")
		ip = both[0]
		if not both[1].is_valid_int():
			return false
		port = int(both[1])
	else:
		ip = newip
		if protocol == "wss://":
			port = DEFAULT_WSS_PORT
		else:
			port = DEFAULT_PORT
	return true

func level_in_bounds(level):
	return Vector3(clamp(level.x, -LEVEL_RANGE.x, LEVEL_RANGE.x), clamp(level.y, -LEVEL_RANGE.y, LEVEL_RANGE.y), 0)

func encode_diff(diff):
	return [diff.size(), diff.compress()]

func decode_diff(diff, size):
	return diff.decompress(size)

var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

func compress_paint(inpaint):
	var out = ""
	for y in range(inpaint.size.y):
		for x in range(inpaint.size.x):
			out += hex[inpaint.at(x,y)]
	var buffer = out.hex_decode()
	return [buffer.size(), buffer.compress()]

func decompress_paint(inb, size):
	var hexstr = inb.decompress(size).hex_encode()
	var array = PackedByteArray()
	for i in hexstr:
		array.append(i.hex_to_int())
	return array

func is_authenticated(pid):
	if auth_type == null:
		return true
	if pid in authenticated_players and authenticated_players[pid]:
		return true
	return pid == 1 # server is good

# RPC

## Auth

@rpc("authority", "call_remote", "reliable")
func welcome():
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.welcome(pid)

@rpc("authority", "call_remote", "reliable")
func request_auth(server_auth_type, client_id):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.request_auth(pid, server_auth_type, client_id)

@rpc("any_peer", "call_remote", "reliable")
func auth_get_tokens(code, uri=null):
	var pid = multiplayer.get_remote_sender_id()
	if !server: return
	client.auth_get_tokens(pid, code, uri)

@rpc("any_peer", "call_remote", "reliable")
func auth_login(tokens):
	var pid = multiplayer.get_remote_sender_id()
	if !server: return
	client.auth_login(pid, tokens)

@rpc("authority", "call_remote", "reliable")
func auth_logged_in(tokens, userinfo, authenticated, prev_users):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.auth_logged_in(pid, tokens, userinfo, authenticated, prev_users)

@rpc("authority", "call_remote", "reliable")
func auth_failed(error_message):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.auth_failed(pid, error_message)

@rpc("authority", "call_local", "reliable")
func auth_user_add(target_pid, user):
	authenticated_players[target_pid] = user

@rpc("authority", "call_local", "reliable")
func auth_user_remove(target_pid):
	authenticated_players.erase(target_pid)

## Paint

@rpc("any_peer", "call_remote", "reliable", PAINT_CHANNEL)
func draw_diff_to_server(size, diff, rect, level):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.draw_diff_to_server(pid, size, diff, rect, level)

@rpc("authority", "call_remote", "reliable", PAINT_CHANNEL)
func draw_diff_from_server(size, diff, rect, level, user):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.draw_diff(pid, size, diff, rect, level, user)

@rpc("any_peer", "call_remote", "unreliable") # this isn't rpc called atm
func draw_diff(size, diff, rect, level):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.draw_diff(pid, size, diff, rect, level)

## Level

@rpc("any_peer", "call_remote", "reliable", 3)
func request_move_to_level(userinfo, level):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	return client.request_move_to_level(pid, userinfo, level)

@rpc("authority", "call_remote", "reliable", 3)
func complete_level_move(level):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.complete_level_move(pid, level)

@rpc("any_peer", "call_remote", "reliable", 3)
func client_level_moved(userinfo, level):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	if not is_authenticated(pid): return
	client.client_level_moved(pid, userinfo, level)

@rpc("any_peer", "call_local", "reliable")
func set_palette(palette, level):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.set_palette(pid, palette, level)

@rpc("authority", "call_remote", "reliable", 3)
func recieve_level_paint(newpaint, size, level, palette):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.recieve_level_paint(pid, newpaint, size, level, palette)

## Puppets

@rpc("authority", "call_remote", "reliable", 3)
func kill_puppets():
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.kill_puppets(pid)

@rpc("authority", "call_remote", "reliable", 3)
func recieve_puppet(puppet, userinfo):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.recieve_puppet(pid, puppet, userinfo)

## Dog

@rpc("any_peer", "call_remote", "unreliable_ordered")
func brush_update(position, drawing, color, size):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.brush_update(pid, position, drawing, color, size)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func dog_update_position(position):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.dog_update_position(pid, position)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func dog_update_animation(animation):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.dog_update_animation(pid, animation)

@rpc("any_peer", "call_local", "reliable")
func dog_update_dog(dog):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.dog_update_dog(pid, dog)

@rpc("any_peer", "call_local", "reliable")
func dog_update_playerstatus(playerstatus):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.dog_update_playerstatus(pid, playerstatus)

## Chat

@rpc("any_peer", "call_local", "reliable", CHAT_CHANNEL)
func chat_message(username, level, message):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.chat_message(pid, username, level, message)
	
@rpc("any_peer", "call_local", "reliable", CHAT_CHANNEL)
func global_chat_message(username, level, message):
	var pid = multiplayer.get_remote_sender_id()
	if not is_authenticated(pid): return
	client.global_chat_message(pid, username, level, message)

@rpc("authority", "call_remote", "reliable", CHAT_CHANNEL)
func join_leave_message(username, joined):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	if not is_authenticated(pid): return
	client.join_leave_message(pid, username, joined)

@rpc("any_peer", "call_remote", "reliable")
func get_map_player_list():
	var pid = multiplayer.get_remote_sender_id()
	if not server: return
	if not is_authenticated(pid): return
	client.get_map_player_list(pid)

@rpc("authority", "call_remote", "reliable")
func recieve_player_list(playerlist):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.recieve_player_list(pid, playerlist)

@rpc("any_peer", "call_remote", "reliable")
func request_map_paint(level):
	var pid = multiplayer.get_remote_sender_id()
	if not server: return
	if not is_authenticated(pid): return
	client.request_map_paint(pid, level)

func start(nserver=false):
	server = nserver
	if client:
		client.queue_free()
	if server:
		client = preload("res://scripts/Autoload/Server.gd").new()
	else:
		client = preload("res://scripts/Autoload/Client.gd").new()
	add_child(client)
	client.start()
