extends PanelContainer

var palettes = {"town": [Color(0, 243, 221), Color(216, 255, 85), Color(255, 166, 148), Color(182, 154, 255)], "town_spooky": [Color(19, 194, 227), Color(203, 224, 128), Color(244, 130, 186), Color(183, 117, 255)], "town_spooky2": [Color(0, 119, 181), Color(143, 149, 95), Color(174, 48, 145), Color(126, 37, 190)], "town_postgame": [Color(4, 255, 196), Color(185, 255, 96), Color(254, 158, 142), Color(118, 144, 255)], "boss1": [Color(143, 243, 0)], "boss2": [Color(0, 172, 200)], "brekkie": [Color(255, 197, 10), Color(171, 253, 185), Color(255, 127, 49), Color(70, 176, 169)], "brunch": [Color(72, 94, 108), Color(116, 142, 141), Color(186, 199, 157), Color(195, 139, 67)], "cave": [Color(255, 0, 150), Color(92, 0, 255), Color(0, 255, 224), Color(255, 178, 0)], "dinners": [Color(187, 235, 220), Color(119, 198, 195), Color(243, 138, 138), Color(255, 242, 201)], "elevenses": [Color(242, 196, 90), Color(94, 140, 106), Color(191, 179, 90), Color(187, 63, 59)], "feast": [Color(255, 35, 102), Color(255, 154, 46), Color(177, 243, 61), Color(255, 111, 250)], "foothills": [Color(255, 181, 70), Color(88, 165, 178), Color(235, 125, 65), Color(112, 115, 47)], "forest": [Color(255, 94, 40), Color(255, 150, 0), Color(255, 195, 27), Color(181, 104, 116)], "gray": [Color(123, 123, 123)], "grub1": [Color(67, 203, 252), Color(120, 247, 216), Color(209, 252, 141), Color(240, 160, 255)], "grub2": [Color(180, 50, 255), Color(254, 73, 167), Color(107, 88, 251), Color(52, 186, 254)], "island": [Color(174, 255, 68), Color(255, 198, 44), Color(15, 197, 161), Color(161, 120, 255)], "meadows": [Color(186, 236, 52), Color(245, 233, 60), Color(42, 228, 160), Color(255, 144, 87)], "mtn": [Color(235, 136, 79), Color(158, 94, 64), Color(87, 188, 192), Color(211, 216, 85)], "newgame": [Color(17, 190, 152), Color(84, 55, 85), Color(1, 37, 69)], "nibble": [Color(164, 255, 84), Color(219, 93, 255), Color(45, 253, 202), Color(136, 127, 255)], "ocean": [Color(34, 180, 255), Color(16, 134, 235), Color(60, 235, 208), Color(73, 106, 251)], "peak": [Color(223, 222, 245), Color(177, 226, 229), Color(211, 238, 234), Color(180, 195, 232)], "potluck": [Color(252, 118, 125), Color(215, 244, 148), Color(255, 220, 128), Color(255, 255, 174)], "rainforest": [Color(128, 232, 182), Color(161, 255, 249), Color(189, 124, 248), Color(114, 136, 246)], "river": [Color(174, 233, 233), Color(208, 235, 170), Color(156, 215, 194), Color(175, 170, 188)], "ruins": [Color(223, 197, 145), Color(179, 129, 132), Color(219, 167, 148), Color(115, 98, 110)], "ruins_dark": [Color(207, 207, 182), Color(185, 150, 194), Color(207, 150, 155), Color(203, 85, 135)], "spooky": [Color(146, 224, 0), Color(255, 35, 0), Color(26, 201, 17), Color(110, 0, 67)], "springs": [Color(139, 190, 243), Color(253, 212, 34), Color(250, 97, 100), Color(140, 68, 164)], "swamp": [Color(207, 240, 158), Color(15, 150, 158), Color(64, 223, 170), Color(247, 123, 166)]}
var palette_aliases = {"Luncheon": "town","Luncheon Spooky": "town_spooky","Luncheon Spooky 2": "town_spooky2","Luncheon Postgame": "town_postgame","Boss 1": "boss1","Boss 2": "boss2","Brekkie": "brekkie","Brunch Canyon": "brunch","Caves": "cave","Dinners": "dinners","Elevenses": "elevenses","Feast": "feast","Appie Foothills": "foothills","Supper Woods": "forest","Gray": "gray","Grub Caverns": "grub1","Grub Deep": "grub2","Spoons Island": "island","Teatime Meadows": "meadows","Dessert Mountain": "mtn","Newgame": "newgame","Nibble Tunnel": "nibble","Ocean": "ocean","Dessert Mountain Peak": "peak","Potluck": "potluck","Banquet Rainforest": "rainforest","Sips River": "river","Wielder Temple": "ruins","Wielder Temple Dark": "ruins_dark","Spooky": "spooky","Simmer Springs": "springs","Gulp Swamp": "swamp"}

@onready var colorpicker = $HBoxContainer/ColorPicker

func _palette_button_pressed(color):
	colorpicker.color = color

func setup_buttons():
	var buttons_container = $HBoxContainer/ScrollContainer/VBoxContainer
	var button = buttons_container.get_node("Button")
	for pname in palette_aliases:
		var palette = palettes[palette_aliases[pname]]
		var i = 0
		for color in palette:
			color = Color(color.r/255, color.g/255, color.b/255)
			var newbutton = button.duplicate()
			newbutton.icon = newbutton.icon.duplicate()
			newbutton.icon.gradient = newbutton.icon.gradient.duplicate()
			newbutton.icon.gradient.set_color(0, color)
			newbutton.text = pname + (" c%s" % i)
			newbutton.connect("pressed", _palette_button_pressed.bind(color))
			i += 1
			buttons_container.add_child(newbutton)
	button.queue_free()

