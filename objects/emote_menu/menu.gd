extends Control

@export var dog: Node

@onready var container = $PanelContainer/VBoxContainer/FlowContainer
var emote_node = preload("res://objects/emote_menu/emote.tscn")

func _ready():
	for emote in Global.emotes:
		var node = emote_node.instantiate()
		node.emote = emote
		node.name = emote
		node.menu = self
		container.add_child(node)

func button_pressed(emote: String):
	dog.do_emote(Global.emotes[emote])
	visible = false
	Global.paintable = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_close_pressed():
	visible = false
	Global.paintable = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta):
	if Input.is_action_just_pressed("emote"):
		Global.paintable = visible
		visible = !visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
