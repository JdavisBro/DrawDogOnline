extends Control

var players = {}
var heads = {}

var player_node = preload("res://objects/player_list_player.tscn")
var head_node = preload("res://objects/map_dog_head.tscn")

var paints = {}
var update_needed = []

var minimal_paint_node = load("res://objects/minimal_paint.tscn")

var screen = Vector2(160, 90)

var updating = true

@onready var teleport = $VBoxContainer/MarginContainer/HBoxContainer/Teleport
var teleport_level = null
var teleport_position = null

@onready var mapviewport = $VBoxContainer/HBoxContainer/MapContainer/MapViewport
@onready var mapheads = $VBoxContainer/HBoxContainer/MapContainer/MapViewport/heads
@onready var playercontainer = $VBoxContainer/HBoxContainer/PlayerListContainer/VBoxContainer

func set_teleport(pos):
	teleport_level = (pos / Vector2(160, 90)).floor().clamp(Vector2(-20,-20), Vector2(20, 20))
	teleport_level = Vector3(teleport_level.x, teleport_level.y, 0)
	teleport_position = pos.posmodv(Vector2(160, 90)) * 12
	teleport.text = "Teleport to %d,%d,%d" % [teleport_level.x, teleport_level.y, teleport_level.z]
	teleport.disabled = false
	%teleportpoint.position = pos
	%teleportpoint.visible = true

func set_paint(level, paint, palette, local=false):
	if level == Global.current_level:
		return
	if level in paints:
		paints[level].paint.array = paint
		paints[level].palette = palette
		paints[level].modulate.a = 1.0
		if paints[level] not in update_needed:
			update_needed.push_front(paints[level])
		return
	var node
	node = minimal_paint_node.instantiate()
	node.pause_process = updating
	node.force_update()
	node.palette = palette
	node.position = screen * Vector2(level.x, level.y)
	node.name = "%d,%d" % [level.x, level.y]
	paints[level] = node
	mapviewport.add_child(node)
	node.paint.array = paint
	node.update_needed = false
	if local:
		node.modulate.a = 0.7
	update_needed.append(node)

func update_paint(level, diff, rect):
	if level not in paints:
		MultiplayerManager.request_map_paint.rpc_id(1, level)
		return
	PaintUtil.apply_diff(paints[level], diff, rect)
	paints[level].modulate.a = 1.0

func set_unchanged_levels(unchanged_levels):
	for level in unchanged_levels:
		if level in paints:
			paints[level].modulate.a = 1.0

const MAX_UPDATE_TIME = 80 #ms

func _process(_delta):
	var start_time = Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start_time) < MAX_UPDATE_TIME:
		if not update_needed:
			return
		update_needed.pop_front().update_paint()
		if (Time.get_ticks_msec() - start_time) > MAX_UPDATE_TIME:
			return

func update_palette(level, palette):
	if not MultiplayerManager.palette_sanity_check(paints[level].palette, palette):
		return
	paints[level].palette = palette
	paints[level].force_update()

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
	head.position = userdata.position / 12.0 + (screen * Vector2(level.x, level.y))
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
		heads[pid].position = userdata.position / 12.0 + (screen * Vector2(level.x, level.y))
		heads[pid].set_dog_dict(userdata.dog)
	else:
		add_player(pid, userdata, level)

func update_dog(pid, newdog):
	if pid in players:
		players[pid].dog.set_dog_dict(newdog)
		heads[pid].set_dog_dict(newdog)

func update_head_position(pid, newpos):
	if pid in players:
		heads[pid].position = newpos / 12.0 + (screen * Vector2(players[pid].level.x, players[pid].level.y))

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

func sort_by_distance(a, b, middle_position):
	return a.distance_squared_to(middle_position) < b.distance_squared_to(middle_position)

func _ready():
	add_player(MultiplayerManager.uid, MultiplayerManager.client.me, Global.current_level, true)
	var node = Sprite2D.new()
	node.texture = Global.paint_target.get_node("DisplaySprite").texture
	node.material = Global.paint_target.get_node("DisplaySprite").material
	node.name = "%d,%d" % [Global.current_level.x, Global.current_level.y]
	node.position = screen * Vector2(Global.current_level.x, Global.current_level.y)
	node.centered = false
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mapviewport.add_child(node)
	Global.paint_target.pause_process = true
	MultiplayerManager.client.player_list = self
	var paint_times = {}
	for level in MultiplayerManager.client.paint_cache:
		paint_times[level] = MultiplayerManager.client.paint_cache[level].time
	MultiplayerManager.get_map_player_list.rpc_id(1, paint_times)
	$VBoxContainer/MarginContainer/HBoxContainer/Close.grab_focus()
	var levels = MultiplayerManager.client.paint_cache.keys()
	levels.sort_custom(sort_by_distance.bind(Vector3(Global.current_level.x, Global.current_level.y, 0)))
	for level in levels:
		var paint_data = MultiplayerManager.client.paint_cache[level]
		set_paint(level, MultiplayerManager.decompress_paint(paint_data.paint, paint_data.size), paint_data.palette, true)

func before_close():
	MultiplayerManager.client.player_list = null
	Global.paint_target.pause_process = false
	MultiplayerManager.map_closed.rpc_id(0)

func _on_update_switch_toggled(button_pressed):
	updating = button_pressed
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
	$VBoxContainer/HBoxContainer/MapContainer/MapViewport/Camera2D.zoom = Vector2(1, 1)

func _on_clear_cache_pressed() -> void:
	MultiplayerManager.client.paint_cache = {}
	MultiplayerManager.get_map_player_list.rpc_id(1, {})
	for level in paints.keys():
		paints[level].queue_free()
		paints.erase(level)
