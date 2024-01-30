extends Control

var auth = DiscordClient.new(MultiplayerManager.client.client_id)

var local_dog_dict = null
var server_dog_dict = null

@onready var local_username = $VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Local/Username
@onready var server_username = $VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Server/Username
@onready var local_dog = $VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Local/Dog/SubViewport/AnimationManager
@onready var server_dog = $VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Server/Dog/SubViewport/AnimationManager

func update_error(message):
	$VBoxContainer/CenterContainer/VBoxContainer/ErrorMsg.text = message

func _on_login_button_pressed():
	auth.login()

func _on_leave_button_pressed():
	MultiplayerManager.client.reconnect = false
	multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")

func _ready():
	add_child(auth)
	MultiplayerManager.client.set_loading(false)
	update_error(MultiplayerManager.client.auth_error)
	local_user(Global.dog_dict, Global.username)

func local_user(dog, username):
	local_dog_dict = dog
	local_dog.set_dog_dict(dog)
	local_username.text = username

func server_user(dog, username):
	if username == local_username.text and dog == local_dog_dict:
		MultiplayerManager.client.enter_level.call_deferred()
		return
	server_dog.set_dog_dict(dog)
	server_dog_dict = dog
	server_username.text = username
	server_username.editable = true
	$VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Server.visible = true

func logged_in():
	$VBoxContainer/CenterContainer/VBoxContainer/LoginButton.visible = false
	$VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Local/UseLocalDog.disabled = false
	$VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/Server/UseServerDog.disabled = false

func _on_use_local_dog_pressed():
	Global.username = local_username.text
	MultiplayerManager.client.enter_level()

func _on_use_server_dog_pressed():
	Global.username = server_username.text
	Global.dog_dict = server_dog_dict
	MultiplayerManager.client.me.dog = server_dog_dict
	MultiplayerManager.client.enter_level()
