extends Control

@onready var container = $Container
var colorsels = []
var newpalette = Global.palette

func add_panel(color, index):
	var newpanel = $ColorPanel.duplicate()
	newpanel.visible = true
	newpanel.name = "Color %02s" % (index+1)
	container.add_child(newpanel, true)
	container.move_child(newpanel, index)
	newpanel.setup_buttons()
	newpanel.colorpicker.color = color
	colorsels.append(newpanel)

func _ready():
	var i = 0
	for color in newpalette:
		add_panel(color, i)
		i += 1
	if len(newpalette) == 15:
		$GridContainer/PlusButton.visible = false

func _process(_delta):
	var i = 0
	for sel in colorsels:
		newpalette[i] = sel.colorpicker.color
		i += 1

func _on_plus_button_pressed():
	if len(newpalette) < 15:
		add_panel(Color.RED, len(newpalette))
		newpalette.append(Color.RED)
	if len(newpalette) == 15:
		$GridContainer/PlusButton.visible = false

func _on_confirm_button_pressed():
	if MultiplayerManager.connected:
		MultiplayerManager.set_palette.rpc(newpalette, Global.current_level)
	queue_free()
