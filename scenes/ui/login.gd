extends Control

var auth = DiscordClient.new(MultiplayerManager.client.client_id)

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
