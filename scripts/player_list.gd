extends Control

var players = {}

var player_node = preload("res://objects/player_list_player.tscn")

@onready var playercontainer = $VBoxContainer/ScrollContainer/HFlowContainer

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
	MultiplayerManager.client.player_list = self
	MultiplayerManager.get_player_list.rpc_id(1)

func before_close():
	MultiplayerManager.client.player_list = null

func _on_close_pressed():
	before_close()
	queue_free()
