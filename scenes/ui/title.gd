extends Control

@onready var status = $Status

var submenu
var paintset = false

func load_custom_paint():
	if Settings.title_paint_custom_enabled and Settings.title_paint_custom:
		$paint.paint.array = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(Settings.title_paint_custom), Settings.title_paint_custom_size, Settings.title_paint_custom_version)
		if Settings.title_paint_custom_version != MultiplayerManager.CURRENT_PAINT_VERSION:
			var data = MultiplayerManager.compress_paint($paint.paint.array)
			Settings.title_paint_custom = data[1]
			Settings.title_paint_custom_size = data[0]
			Settings.title_paint_custom_version = MultiplayerManager.CURRENT_PAINT_VERSION
			Settings.save()
		var pal = []
		for i in Settings.title_paint_custom_palette:
			pal.append(Color(i))
		$paint.palette = pal
		$paint.force_update()
		paintset = true

var tree: Tree
var root: TreeItem

var selected_server_index

func server_list_selected():
	selected_server_index = tree.get_selected().get_index()

func _on_serverlist_join_button_pressed() -> void:
	if selected_server_index == null:
		return
	var selected_server = Settings.server_list[selected_server_index]
	MultiplayerManager.ip = selected_server.ip
	MultiplayerManager.port = selected_server.port
	MultiplayerManager.protocol = selected_server.protocol
	Settings.username = selected_server.username
	Global.current_level = Vector3.ZERO
	MultiplayerManager.start()

func _on_serverlist_delete_button_pressed() -> void:
	if selected_server_index == null:
		return
	prints("server list", Settings.server_list[selected_server_index])
	prints("tree item", root.get_child(selected_server_index).get_metadata(0))
	Settings.server_list.remove_at(selected_server_index)
	root.get_child(selected_server_index).free()
	#tree.clear()
	#root = tree.create_item()
	#for server in Settings.server_list:
		#server_list_add_server(server, -1)
	selected_server_index = null
	Settings.save()

func server_list_add_server(server: Dictionary, index: int):
	var item = tree.create_item(root, index)
	item.set_text(0, server.display)
	item.set_text(1, server.username)
	item.set_metadata(0, server)

func _ready():
	load_custom_paint()
	get_tree().paused = false
	Global.pause_enable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%TabContainer.current_tab = Settings.last_server_tab
	status.text = MultiplayerManager.connection_status
	%UsernameEnter.text = Settings.username
	
	if MultiplayerManager.uri_used:
		%ProtocolSelect.select(int(MultiplayerManager.protocol == "wss://"))
		%IPEnter.text = MultiplayerManager.uri_used
		MultiplayerManager.uri_used = ""
	else:
		%IPEnter.text = Settings.last_server_ip
		%ProtocolSelect.select(0)
		if Settings.last_server_protocol == "wss://":
			%ProtocolSelect.select(1)
	
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search")
		search = search.lstrip("?").split("&")
		for i in search:
			i = i.split("=")
			i[0] = i[0].to_lower()
			if i[0] == "ip":
				%IPEnter.text = i[1]
			elif i[0] == "secure":
				if i[1] == "true":
					%ProtocolSelect.select(1)
	
	tree = %ServerListTree
	root = tree.create_item()
	tree.hide_root = true
	tree.set_column_expand_ratio(0, 3)
	tree.set_column_expand_ratio(1, 1)
	for server in Settings.server_list:
		server_list_add_server(server, -1)

func _process(_delta):
	if Settings.title_paint_custom_enabled != paintset:
		if Settings.title_paint_custom_enabled:
			load_custom_paint()
		else:
			$paint.set_init_paint()
			$paint.force_update()
			paintset = false
	if submenu and Input.is_action_just_pressed("pause", true):
		if submenu.has_method("before_close"):
			submenu.before_close()
		submenu.queue_free()
		submenu = null

func verify_ip():
	MultiplayerManager.protocol = %ProtocolSelect.text
	if not MultiplayerManager.set_ip_port(%IPEnter.text):
		%IPTitle.text = "IP - Invalid:"
		return
	if Settings.username != %UsernameEnter.text.strip_edges():
		Settings.username = %UsernameEnter.text.strip_edges()
		Settings.save()

func _on_join_button_pressed():
	Global.current_level = Vector3.ZERO
	verify_ip()
	MultiplayerManager.start()

func _on_add_button_pressed() -> void:
	verify_ip()
	var server_data := {"display": MultiplayerManager.get_ip(true), "protocol": "wss://", "ip": MultiplayerManager.ip, "port": MultiplayerManager.port,  "username": Settings.username}
	Settings.server_list.push_front(server_data)
	Settings.save()
	server_list_add_server(server_data, 0)

func _on_settings_button_pressed():
	submenu = preload("res://scenes/ui/settings.tscn").instantiate()
	add_child(submenu)

func _on_set_dog_button_pressed():
	submenu = preload("res://scenes/ui/set_dog.tscn").instantiate()
	add_child(submenu)

func _on_tab_container_tab_changed(tab: int) -> void:
	Settings.last_server_tab = tab
	Settings.save()
