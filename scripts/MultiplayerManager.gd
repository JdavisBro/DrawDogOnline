extends Node

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 33363

const LEVEL_RANGE = Vector2(20, 20)

const PAINT_CHANNEL = 2

var ip = DEFAULT_IP
var port = DEFAULT_PORT

var connected = false
var connection_status = ""

var server
var client
var uid = 0


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
	ip = newip
	return true

func level_in_bounds(level):
	return Vector3(clamp(level.x, -LEVEL_RANGE.x, LEVEL_RANGE.x), clamp(level.y, -LEVEL_RANGE.y, LEVEL_RANGE.y), 0)

func encode_diff(diff):
	var buffer = diff.to_ascii_buffer()
	return [buffer.size(), buffer.compress()]

func decode_diff(diff, size):
	return diff.decompress(size).get_string_from_ascii()

var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

func paint_to_str(inpaint):
	var out = ""
	for y in inpaint:
		for i in y:
			out += hex[i]
	var buffer = out.to_ascii_buffer()
	return [buffer.size(), buffer.compress()]

func paint_from_str(instr, size):
	instr = instr.decompress(size).get_string_from_ascii()
	var newpaint = []
	for i in range(Global.paint_total):
		if i % int(Global.paint_size.x) == 0:
			newpaint.append([])
		newpaint[-1].append(instr[i].hex_to_int())
	return newpaint

# RPC

@rpc("any_peer", "call_remote", "reliable", PAINT_CHANNEL)
func draw_diff_to_server(size, diff, rect, level):
	var pid = multiplayer.get_remote_sender_id()
	client.draw_diff_to_server(pid, size, diff, rect, level)

@rpc("authority", "call_remote", "reliable", PAINT_CHANNEL)
func draw_diff_from_server(size, diff, rect, level):
	var pid = multiplayer.get_remote_sender_id()	
	if server: return
	client.draw_diff(pid, size, diff, rect, level)

@rpc("any_peer", "call_remote", "unreliable") # this isn't rpc called atm
func draw_diff(size, diff, rect, level):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.draw_diff(pid, size, diff, rect, level)

@rpc("any_peer", "call_remote", "reliable", 3)
func request_move_to_level(userinfo, level):
	var pid = multiplayer.get_remote_sender_id()
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
	client.client_level_moved(pid, userinfo, level)

@rpc("authority", "call_remote", "reliable", 3)
func recieve_level_paint(newpaint, size):
	var pid = multiplayer.get_remote_sender_id()
	if server: return
	client.recieve_level_paint(pid, newpaint, size)

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

@rpc("any_peer", "call_remote", "unreliable_ordered")
func brush_update(position, drawing, color, size):
	var pid = multiplayer.get_remote_sender_id()
	client.brush_update(pid, position, drawing, color, size)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func dog_update_position(position):
	var pid = multiplayer.get_remote_sender_id()
	client.dog_update_position(pid, position)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func dog_update_animation(animation):
	var pid = multiplayer.get_remote_sender_id()
	client.dog_update_animation(pid, animation)

func start(nserver=false):
	server = nserver
	if server:
		client = preload("res://scripts/Server.gd").new()
	else:
		client = preload("res://scripts/Client.gd").new()
	add_child(client)
	client.start()
