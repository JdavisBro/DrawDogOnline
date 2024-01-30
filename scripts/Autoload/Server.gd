extends Node

var paint = {}
var palettes = {}
var save_required = true
var players = {} # level: {pid: userinfo}
var player_location = {} # pid: level

var saved_players = {} # players saved dogs & usernames {authid: {dog: dog, username: string}}

const SAVE_INTERVAL = 5.0

var save_timer = 0.0

var auth_type :
	get:
		return MultiplayerManager.auth_type

var auth: DiscordServer = null

# Builtin

func save_players():
	if auth:
		var outplayers = saved_players
		for user in outplayers:
			for i in outplayers[user].dog.color:
				if not typeof(outplayers[user].dog.color[i]) == TYPE_STRING:
					outplayers[user].dog.color[i] = "#" + outplayers[user].dog.color[i].to_html(false)
		FileAccess.open("user://players.json", FileAccess.WRITE_READ).store_line(JSON.stringify(outplayers))

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
	save_players()
	print("Saved")
	save_required = false

func _process(delta):
	if save_required:
		save_timer += delta
		if save_timer > SAVE_INTERVAL:
			save_timer = 0.0
			save_levels()

# Signals

func on_player_connected(id):
	if auth_type == null:
		MultiplayerManager.welcome.rpc_id(id)
		return
	MultiplayerManager.request_auth.rpc_id(id, auth_type, auth.client_id)

func on_player_disconnected(id):
	if id in player_location:
		MultiplayerManager.join_leave_message.rpc(players[player_location[id]][id].username, false)
		players[player_location[id]].erase(id)
		player_location.erase(id)
	if auth_type != null:
		MultiplayerManager.auth_user_remove.rpc(id)

# Utils

func new_paint():
	return PackedByteArray2D.new()

func check_server_level(level):
	level = MultiplayerManager.level_in_bounds(level)
	if level not in players:
		players[level] = {}
	if level not in paint:
		paint[level] = new_paint()
	if level not in palettes:
		palettes[level] = Global.palette
	return level

func load_players():
	if auth and FileAccess.file_exists("user://players.json"):
		saved_players = JSON.parse_string(FileAccess.open("user://players.json", FileAccess.READ).get_line())
		for user in saved_players:
			var player = saved_players[user]
			for i in player.dog.color:
				player.dog.color[i] = Color(player.dog.color[i])
			saved_players[user] = player


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
			paint[level] = PackedByteArray2D.new()
			paint[level].array = MultiplayerManager.decompress_paint(paintstr, size)
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
			paint[level] = PackedByteArray2D.new()
			paint[level].array = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(leveldata.paint), leveldata.paintsize)
			palettes[level] = []
			for col in leveldata.palette:
				palettes[level].append(Color(col))

func id_logged_in(discordid):
	for user in MultiplayerManager.authenticated_players.values():
		if user.id == discordid:
			return true
	return false

# Start

func start():
	DisplayServer.window_set_size(Vector2(10, 10))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	load_paint()
	if auth_type == "discord":
		auth = preload("res://scripts/Autoload/Auth/DiscordServer.gd").new()
		add_child(auth)
		load_players()
	var peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = ["ludus"]
	var error = peer.create_server(MultiplayerManager.port)
	if error:
		print(error)
	multiplayer.multiplayer_peer = peer
	print("Server Started")
	
# RPC

## Auth

func auth_get_tokens(pid, code, uri):
	if auth:
		var tokens
		if uri:
			tokens = await auth.get_token_from_code(code, uri)
		else:
			tokens = await auth.get_token_from_code(code)
		if not tokens:
			MultiplayerManager.auth_failed.rpc_id(pid, "Login failed. Try again")
			return
		var discorduser = (await auth.get_user_from_token(tokens["access_token"]))
		if discorduser == {} or discorduser == null:
			MultiplayerManager.auth_failed.rpc_id(pid, "Login failed. Try again")
			return
		var prev_user = null
		if discorduser.id in saved_players: prev_user = saved_players[discorduser.id]
		MultiplayerManager.auth_user_add.rpc(pid, discorduser)
		MultiplayerManager.auth_logged_in.rpc_id(pid, tokens, discorduser, MultiplayerManager.authenticated_players, prev_user)

func auth_login(pid, tokens):
	var newtokens = await auth.get_user_from_token_or_refresh(tokens)
	print(newtokens)
	if newtokens == null:
		print("Player %s login failed" % pid)
		MultiplayerManager.auth_failed.rpc_id(pid, "Login failed. Try again")
		return
	tokens = newtokens[0]
	var user = newtokens[1]
	if id_logged_in(user.id) and not OS.is_debug_build():
		print("User %s kicked, already logged in." % user.username)
		MultiplayerManager.auth_failed.rpc_id(pid, "Account already logged into server.")
		return
	var prev_user = null
	if user.id in saved_players: prev_user = saved_players[user.id]
	prints(user.id in saved_players, saved_players[user.id])
	MultiplayerManager.auth_user_add.rpc(pid, user)
	MultiplayerManager.auth_logged_in.rpc_id(pid, tokens, user, MultiplayerManager.authenticated_players, prev_user)
	print("User %s logged in" % user.username)

## Paint

func draw_diff_to_server(pid, size, diff, rect, level):
	MultiplayerManager.draw_diff_from_server.rpc(size, diff, rect, level, pid)
	diff = MultiplayerManager.decode_diff(diff, size)
	var i = 0
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			if diff[i] != 255:
				var target_pos = rect.position + Vector2(x, y)
				paint[level].put(target_pos.x, target_pos.y, diff[i])
			i += 1
	save_required = true

func request_move_to_level(pid, userinfo, level):
	if pid in player_location:
		players[player_location[pid]].erase(pid)
		player_location.erase(pid)
	else:
		MultiplayerManager.join_leave_message.rpc(userinfo.username, true)
	if auth:
		saved_players[MultiplayerManager.authenticated_players[pid].id] = {"dog": userinfo.dog, "username": userinfo.username}
		save_required = true
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

## Dog

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
	if auth:
		saved_players[MultiplayerManager.authenticated_players[pid].id]["dog"] = dog
		save_required = true

func dog_update_playerstatus(pid, playerstatus):
	if pid in player_location:
		players[player_location[pid]][pid].playerstatus = playerstatus

## Chat

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
