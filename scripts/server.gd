extends Node

var paint = {}
var modified_paint = true
var players = {} # level: {pid: userinfo}
var player_location = {} # pid: level

const SAVE_INTERVAL = 5.0

var save_timer = 0.0

# Builtin

func save_level(file, level):
	var lpaint = MultiplayerManager.compress_paint(paint[level])
	file.store_line("%s,%s,%s" % [level.x, level.y, level.z])
	file.store_line(str(lpaint[0]))
	file.store_line(Marshalls.raw_to_base64(lpaint[1]))

func _process(delta):
	save_timer += delta
	if save_timer > SAVE_INTERVAL and modified_paint:
		save_timer = 0.0
		var file = FileAccess.open("user://paint.txt", FileAccess.WRITE)
		for level in paint:
			save_level(file, level)
		file.close()
		print("Saved")
		modified_paint = false

# Signals

func on_player_disconnected(id):
	if id in player_location:
		players[player_location[id]].erase(id)
		player_location.erase(id)

# Utils

func new_paint():
	var newpaint = []
	for i in range(Global.paint_total):
		if i % int(Global.paint_size.x) == 0:
			newpaint.append([])
		newpaint[-1].append(0)
	return newpaint

func check_server_level(level):
	level = MultiplayerManager.level_in_bounds(level)
	if level not in players:
		players[level] = {}
	if level not in paint:
		paint[level] = new_paint()
	return level

func load_paint():
	var file = FileAccess.open("user://paint.txt", FileAccess.READ)
	if not file:
		return
	while file.get_position() < file.get_length():
		var level = file.get_line().split(",")
		level = Vector3(int(level[0]), int(level[1]), int(level[2]))
		var size = int(file.get_line())
		var paintstr = file.get_line()
		paintstr = Marshalls.base64_to_raw(paintstr)
		paint[level] = MultiplayerManager.decompress_paint(paintstr, size)

# Start

func start():
	DisplayServer.window_set_size(Vector2(10, 10))
	load_paint()
	var peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = ["ludus"]
	var error = peer.create_server(MultiplayerManager.port)
	if error:
		print(error)
	multiplayer.multiplayer_peer = peer
	print("Server Started")
	
# RPC

func request_move_to_level(pid, userinfo, level):
	if pid in player_location:
		players[player_location[pid]].erase(pid)
		player_location.erase(pid)
	level = check_server_level(level)
	var newpaint = MultiplayerManager.compress_paint(paint[level])
	MultiplayerManager.recieve_level_paint.rpc_id(pid, newpaint[1], newpaint[0])
	MultiplayerManager.kill_puppets.rpc_id(pid)
	for puppet in players[level]:
		MultiplayerManager.recieve_puppet.rpc_id(pid, puppet, players[level][puppet])
	players[level][pid] = userinfo
	player_location[pid] = level
	MultiplayerManager.complete_level_move.rpc_id(pid, level)

func draw_diff_to_server(_pid, size, diff, rect, level):
	MultiplayerManager.draw_diff_from_server.rpc(size, diff, rect, level)
	diff = MultiplayerManager.decode_diff(diff, size)
	var i = 0
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			if diff[i] != "X":
				var target_pos = rect.position + Vector2(x, y)
				paint[level][target_pos.y][target_pos.x] =  diff[i].hex_to_int()
			i += 1
	modified_paint = true

func brush_update(pid, position, drawing, color, size):
	if pid in player_location:
		players[player_location[pid]][pid].brush.position = position
		players[player_location[pid]][pid].brush.drawing = drawing
		players[player_location[pid]][pid].brush.color = color
		players[player_location[pid]][pid].brush.size = size

func dog_update_position(pid, position):
	if pid in player_location:
		players[player_location[pid]][pid].position = position

func dog_update_animation(pid, animation):
	if pid in player_location:
		players[player_location[pid]][pid].animation = animation
