extends Control

@onready var iptitle = $VBoxContainer/VBoxContainer/IPTitle
@onready var ipenter = $VBoxContainer/VBoxContainer/HBoxContainer/IPEnter
@onready var usernameenter = $VBoxContainer/VBoxContainer2/UsernameEnter
@onready var status = $Status
@onready var protocolselect = $VBoxContainer/VBoxContainer/HBoxContainer/ProtocolSelect

var submenu
var paintset = false

func load_custom_paint():
	if Settings.title_paint_custom_enabled and Settings.title_paint_custom:
		$paint.paint.array = MultiplayerManager.decompress_paint(Marshalls.base64_to_raw(Settings.title_paint_custom), Settings.title_paint_custom_size)
		var pal = []
		for i in Settings.title_paint_custom_palette:
			pal.append(Color(i))
		$paint.palette = pal
		$paint.setup_tilemap_layers()
		$paint.force_update()
		paintset = true

func _ready():
	load_custom_paint()
	get_tree().paused = false
	Global.pause_enable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	status.text = MultiplayerManager.connection_status
	usernameenter.text = Global.username
	
	ipenter.text = Settings.last_server_ip
	protocolselect.select(0)
	if Settings.last_server_protocol == "wss://":
		protocolselect.select(1)
	
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search")
		search = search.lstrip("?").split("&")
		for i in search:
			i = i.split("=")
			i[0] = i[0].to_lower()
			if i[0] == "ip":
				ipenter.text = i[1]
			elif i[0] == "secure":
				if i[1] == "true":
					protocolselect.select(1)

func _process(_delta):
	if Settings.title_paint_custom_enabled != paintset:
		if Settings.title_paint_custom_enabled:
			load_custom_paint()
		else:
			$paint.set_init_paint()
			$paint.setup_tilemap_layers()
			$paint.force_update()
			paintset = false
	if submenu and Input.is_action_just_pressed("pause", true):
		if submenu.has_method("before_close"):
			submenu.before_close()
		submenu.queue_free()
		submenu = null

func _on_join_button_pressed():
	Global.current_level = Vector3.ZERO
	MultiplayerManager.protocol = protocolselect.text
	if not MultiplayerManager.get_ip_port(ipenter.text):
		iptitle.text = "IP - Invalid:"
		return
	if Global.username != usernameenter.text.strip_edges():
		Global.username = usernameenter.text.strip_edges()
		Global.save_username()
	MultiplayerManager.start()

func _on_settings_button_pressed():
	submenu = preload("res://scenes/ui/settings.tscn").instantiate()
	add_child(submenu)

func _on_set_dog_button_pressed():
	submenu = preload("res://scenes/ui/set_dog.tscn").instantiate()
	add_child(submenu)
