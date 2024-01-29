extends Control

var players = {}
var heads = {}

var player_node = preload("res://objects/player_list_player.tscn")
var head_node = preload("res://objects/map_dog_head.tscn")

var paints = {}

var paint_node = preload("res://objects/paint.tscn")

var screen = Vector2(1920, 1080)

var threads = []

@onready var teleport = $VBoxContainer/MarginContainer/HBoxContainer/Teleport
var teleport_level = null
var teleport_position = null

@onready var mapviewport = $VBoxContainer/HBoxContainer/MapContainer/MapViewport
@onready var mapheads = $VBoxContainer/HBoxContainer/MapContainer/MapViewport/heads
@onready var playercontainer = $VBoxContainer/HBoxContainer/PlayerListContainer/VBoxContainer

func set_teleport(level, pos):
	teleport_level = level
	teleport_position = pos
	teleport.text = "Teleport to %d,%d,%d" % [level.x, level.y, level.z]
	teleport.disabled = false

func set_paint(level, paint, palette):
	if level == Global.current_level:
		return
	var node = paint_node.instantiate()
	node.force_update()
	node.palette = palette
	node.diffs_enabled = false
	node.position = screen * Vector2(level.x, level.y)
	node.name = "%d,%d" % [level.x, level.y]
	paints[level] = node
	mapviewport.add_child(node)
	node.paint.array = paint
	node.update_needed = false
	var thread = Thread.new()
	threads.append(thread)
	var _err = thread.start(node.update_paint.bind(true))

func update_paint(level, diff, rect):
	if level not in paints:
		MultiplayerManager.request_map_paint.rpc_id(1, level)
		return
	PaintUtil.apply_diff(paints[level], diff, rect)

func update_palette(level, palette):
	paints[level].palette = palette
	paints[level].setup_tilemap_layers()

func add_player(pid, userdata, level, adding_self=false):
	if pid == MultiplayerManager.uid and not adding_self:
		return
	var node = player_node.instantiate() # player list
	node.username = userdata.username
	node.level = level
	node.pid = pid
	node.dog_dict = userdata.dog
	node.connect("gui_input", head_input.bind(pid))
	playercontainer.add_child(node)
	node.setup()
	node.name = userdata.username
	if adding_self:
		node.username_label.add_theme_color_override("font_color", Color("5c7aff"))
	players[pid] = node
	var head = head_node.instantiate() # map head
	mapheads.add_child(head)
	heads[pid] = head
	head.flip = userdata.facing
	if adding_self:
		head.get_node("username").add_theme_color_override("font_color", Color("5c7aff"))
	head.get_node("username").text = userdata.username
	head.position = userdata.position + (screen * Vector2(level.x, level.y))
	head.name = userdata.username
	head.set_dog_dict(userdata.dog)

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
		heads[pid].position = userdata.position + (screen * Vector2(level.x, level.y))
		heads[pid].set_dog_dict(userdata.dog)
	else:
		add_player(pid, userdata, level)

func update_dog(pid, newdog):
	if pid in players:
		players[pid].dog.set_dog_dict(newdog)
		heads[pid].set_dog_dict(newdog)

func update_head_position(pid, newpos):
	if pid in players:
		heads[pid].position = newpos + (screen * Vector2(players[pid].level.x, players[pid].level.y))

func remove_player(pid):
	if pid in players:
		players[pid].queue_free()
		players.erase(pid)
		heads[pid].queue_free()
		heads.erase(pid)

func head_input(event: InputEvent, pid):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mapviewport.get_node("Camera2D").position = heads[pid].position

func _ready():
	add_player(MultiplayerManager.uid, MultiplayerManager.client.me, Global.current_level, true)
	var node = Sprite2D.new()
	node.texture = Global.paint_target.get_node("DisplaySprite").texture
	node.material = Global.paint_target.get_node("DisplaySprite").material
	node.name = "%d,%d" % [Global.current_level.x, Global.current_level.y]
	node.position = screen * Vector2(Global.current_level.x, Global.current_level.y)
	node.centered = false
	mapviewport.add_child(node)
	Global.paint_target.pause_process = true
	MultiplayerManager.client.player_list = self
	MultiplayerManager.get_map_player_list.rpc_id(1)

func before_close():
	for thread in threads:
		if thread.is_started():
			thread.wait_to_finish()
	MultiplayerManager.client.player_list = null
	Global.paint_target.pause_process = false

func _on_update_switch_toggled(button_pressed):
	for level in paints:
		paints[level].pause_process = button_pressed

func _on_heads_switch_toggled(button_pressed):
	mapheads.visible = button_pressed

func _on_close_pressed():
	before_close()
	queue_free()

func _on_teleport_pressed():
	MultiplayerManager.client.change_level(teleport_level, teleport_position)
	get_node("..").submenu = null
	get_node("..").close_pause()
	before_close()
	queue_free()

func _on_reset_zoom_pressed():
	$VBoxContainer/HBoxContainer/MapContainer/MapViewport/Camera2D.zoom = Vector2(0.1, 0.1)
