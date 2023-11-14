extends Node

var paint = {}
var palettes = {}
var save_required = true
var players = {} # level: {pid: userinfo}
var player_location = {} # pid: level

const SAVE_INTERVAL = 5.0

var save_timer = 0.0

# Builtin

func save_levels():
	var levelsout = {}
	for level in paint:
		check_server_level(level)
		var levelstr = "%s,%s,%s" % [level.x, level.y, level.z]
		var lpaint = MultiplayerManager.compress_paint(paint[level])
		var palette = []
		for col in palettes[level]:
			palette.append("#" + col.to_html(false))
		levelsout[levelstr] = {"paintsize": lpaint[0], "paint": Marshalls.raw_to_base64(lpaint[1]), "palette": palette}
	var file = FileAccess.open("user://levels.json", FileAccess.WRITE)
	file.store_line(JSON.stringify(levelsout))	
	file.close()
	print("Saved")
	save_required = false

func _process(delta):
	if save_required:
		save_timer += delta
		if save_timer > SAVE_INTERVAL:
			save_timer = 0.0
			save_levels()

# Signals

func on_player_disconnected(id):
	if id in player_location:
		MultiplayerManager.join_leave_message.rpc(players[player_location[id]][id].username, false)
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
	if level not in palettes:
		palettes[level] = Global.palette
	return level

func load_paint():
	if FileAccess.file_exists("user://paint.txt"):
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
		save_levels()
		file.close()
		DirAccess.open("user://").remove("paint.txt")
	elif FileAccess.file_exists("user://levels.json"):
		var file = FileAccess.open("user://levels.json", FileAccess.READ)
		var levelsin = JSON.parse_string(file.get_line())
		file.close()
		for level in levelsin:
			var leveldata = levelsin[level]
			level = level.split(",")
			level = Vector3(int(level[0]), int(level[1]), int(level[2]))
			paint[level] = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(leveldata.paint), leveldata.paintsize)
			palettes[level] = []
			for col in leveldata.palette:
				palettes[level].append(Color(col))

# Start

func start():
	DisplayServer.window_set_size(Vector2(10, 10))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	load_paint()
	var peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = ["ludus"]
	var error = peer.create_server(MultiplayerManager.port)
	if error:
		print(error)
	multiplayer.multiplayer_peer = peer
	print("Server Started")
	
# RPC

func draw_diff_to_server(pid, size, diff, rect, level):
	MultiplayerManager.draw_diff_from_server.rpc(size, diff, rect, level, pid)
	diff = MultiplayerManager.decode_diff(diff, size)
	var i = 0
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			if diff[i] != "X":
				var target_pos = rect.position + Vector2(x, y)
				paint[level][target_pos.y][target_pos.x] =  diff[i].hex_to_int()
			i += 1
	save_required = true

func request_move_to_level(pid, userinfo, level):
	if pid in player_location:
		players[player_location[pid]].erase(pid)
		player_location.erase(pid)
	else:
		MultiplayerManager.join_leave_message.rpc(userinfo.username, true)
	level = check_server_level(level)
	var newpaint = MultiplayerManager.compress_paint(paint[level])
	MultiplayerManager.recieve_level_paint.rpc_id(pid, newpaint[1], newpaint[0], level, palettes[level])
	MultiplayerManager.kill_puppets.rpc_id(pid)
	for puppet in players[level]:
		MultiplayerManager.recieve_puppet.rpc_id(pid, puppet, players[level][puppet])
	players[level][pid] = userinfo
	player_location[pid] = level
	MultiplayerManager.complete_level_move.rpc_id(pid, level)

func set_palette(_pid, palette, level):
	if palettes[level] != palette:
		palettes[level] = palette
		save_required = true

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

func dog_update_dog(pid, dog):
	if pid in player_location:
		players[player_location[pid]][pid].dog = dog

func dog_update_playerstatus(pid, playerstatus):
	if pid in player_location:
		players[player_location[pid]][pid].playerstatus = playerstatus

func chat_message(_pid, username, level, message):
	print("ROOM %s (%d,%d,%d)> %s" % [username, level.x, level.y, level.z, message])

func chat_message_global(_pid, username, level, message):
	print("GLOBAL %s (%d,%d,%d)> %s" % [username, level.x, level.y, level.z, message])

func get_map_player_list(pid):
	MultiplayerManager.recieve_player_list.rpc_id(pid, players)
	for level in paint:
		if player_location[pid] == level: continue
		var newpaint = MultiplayerManager.compress_paint(paint[level])
		MultiplayerManager.recieve_level_paint.rpc_id(pid, newpaint[1], newpaint[0], level, palettes[level])

func request_map_paint(pid, level):
	var newpaint = MultiplayerManager.compress_paint(paint[level])
	MultiplayerManager.recieve_level_paint.rpc_id(pid, newpaint[1], newpaint[0], level, palettes[level])
