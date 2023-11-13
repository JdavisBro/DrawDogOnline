extends Control

var players = {}

var player_node = preload("res://objects/player_list_player.tscn")

var paints = {}

var paint_node = preload("res://objects/paint.tscn")

@onready var mapviewport = $VBoxContainer/HBoxContainer/MapContainer/MapViewport
@onready var playercontainer = $VBoxContainer/HBoxContainer/PlayerListContainer/VBoxContainer

func set_paint(level, paint, palette):
	if level == Global.current_level:
		return
	var node = paint_node.instantiate()
	node.force_update()
	node.paint = paint
	node.palette = palette
	node.pause_process = true
	node.diffs_enabled = false
	node.position = Vector2(1920, 1080) * Vector2(level.x, level.y)
	node.name = "%d,%d" % [level.x, level.y]
	paints[level] = node
	mapviewport.add_child(node)

func update_paint(level, diff, rect):
	PaintUtil.apply_diff(paints[level], diff, rect)
	print("applied %d,%d,%d" % [level.x, level.y, level.z])

func update_palette(level, palette):
	paints[level].palette = palette
	paints[level].setup_tilemap_layers()

func add_player(pid, userdata, level):
	var node = player_node.instantiate()
	node.username = userdata.username
	node.level = level
	node.dog_dict = userdata.dog
	playercontainer.add_child(node)
	node.setup()
	players[pid] = node

func set_players(playerlist):
	for level in playerlist:
		for pid in playerlist[level]:
			var userdata = playerlist[level][pid]
			add_player(pid, userdata, level)

func set_player(pid, userdata, level):
	if pid in players:
		players[pid].dog_dict = userdata.dog
		players[pid].level = level
		players[pid].setup()
	else:
		add_player(pid, userdata, level)

func update_dog(pid, newdog):
	if pid in players:
		players[pid].dog.set_dog_dict(newdog)

func remove_player(pid):
	if pid in players:
		players[pid].queue_free()
		players.erase(pid)

func _ready():
	var node = Sprite2D.new()
	node.texture = Global.paint_target.get_node("DisplaySprite").texture
	node.material = Global.paint_target.get_node("DisplaySprite").material
	node.name = "%d,%d" % [Global.current_level.x, Global.current_level.y]
	node.position = Vector2(1920, 1080) * Vector2(Global.current_level.x, Global.current_level.y)
	node.centered = false
	mapviewport.add_child(node)
	Global.paint_target.pause_process = true
	MultiplayerManager.client.player_list = self
	MultiplayerManager.get_map_player_list.rpc_id(1)

func before_close():
	MultiplayerManager.client.player_list = null
	Global.paint_target.pause_process = false

func _on_close_pressed():
	before_close()
	queue_free()
