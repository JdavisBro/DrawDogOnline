extends Control

@onready var palette_item = $VBoxContainer/HBoxContainer/PaletteColumnContainer/PaletteContainer/ScrollContainer/PaletteItemList
@onready var ingame_tree = $VBoxContainer/HBoxContainer/InGameColumnContainer/InGameContainer/ScrollContainer/InGameTree
@onready var colorpicker = $VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/MarginContainer/ColorPicker
@onready var warning = $VBoxContainer/MarginContainer/WarningPanelContainer
@onready var warninglabel = $VBoxContainer/MarginContainer/WarningPanelContainer/Label

var ingame_tree_root

var selected_index = 0

var colorsels = []
var newpalette = Global.palette.duplicate()

var palettes = {'town': [Color(0.0, 0.953, 0.867), Color(0.847, 1.0, 0.333), Color(1.0, 0.651, 0.58), Color(0.714, 0.604, 1.0)], 'town_spooky': [Color(0.075, 0.761, 0.89), Color(0.796, 0.878, 0.502), Color(0.957, 0.51, 0.729), Color(0.718, 0.459, 1.0)], 'town_spooky2': [Color(0.0, 0.467, 0.71), Color(0.561, 0.584, 0.373), Color(0.682, 0.188, 0.569), Color(0.494, 0.145, 0.745)], 'town_postgame': [Color(0.016, 1.0, 0.769), Color(0.725, 1.0, 0.376), Color(0.996, 0.62, 0.557), Color(0.463, 0.565, 1.0)], 'boss1': [Color(0.561, 0.953, 0.0)], 'boss2': [Color(0.0, 0.675, 0.784)], 'brekkie': [Color(1.0, 0.773, 0.039), Color(0.671, 0.992, 0.725), Color(1.0, 0.498, 0.192), Color(0.275, 0.69, 0.663)], 'brunch': [Color(0.282, 0.369, 0.424), Color(0.455, 0.557, 0.553), Color(0.729, 0.78, 0.616), Color(0.765, 0.545, 0.263)], 'cave': [Color(1.0, 0.0, 0.588), Color(0.361, 0.0, 1.0), Color(0.0, 1.0, 0.878), Color(1.0, 0.698, 0.0)], 'dinners': [Color(0.733, 0.922, 0.863), Color(0.467, 0.776, 0.765), Color(0.953, 0.541, 0.541), Color(1.0, 0.949, 0.788)], 'elevenses': [Color(0.949, 0.769, 0.353), Color(0.369, 0.549, 0.416), Color(0.749, 0.702, 0.353), Color(0.733, 0.247, 0.231)], 'feast': [Color(1.0, 0.137, 0.4), Color(1.0, 0.604, 0.18), Color(0.694, 0.953, 0.239), Color(1.0, 0.435, 0.98)], 'foothills': [Color(1.0, 0.71, 0.275), Color(0.345, 0.647, 0.698), Color(0.922, 0.49, 0.255), Color(0.439, 0.451, 0.184)], 'forest': [Color(1.0, 0.369, 0.157), Color(1.0, 0.588, 0.0), Color(1.0, 0.765, 0.106), Color(0.71, 0.408, 0.455)], 'gray': [Color(0.482, 0.482, 0.482)], 'grub1': [Color(0.263, 0.796, 0.988), Color(0.471, 0.969, 0.847), Color(0.82, 0.988, 0.553), Color(0.941, 0.627, 1.0)], 'grub2': [Color(0.706, 0.196, 1.0), Color(0.996, 0.286, 0.655), Color(0.42, 0.345, 0.984), Color(0.204, 0.729, 0.996)], 'island': [Color(0.682, 1.0, 0.267), Color(1.0, 0.776, 0.173), Color(0.059, 0.773, 0.631), Color(0.631, 0.471, 1.0)], 'meadows': [Color(0.729, 0.925, 0.204), Color(0.961, 0.914, 0.235), Color(0.165, 0.894, 0.627), Color(1.0, 0.565, 0.341)], 'mtn': [Color(0.922, 0.533, 0.31), Color(0.62, 0.369, 0.251), Color(0.341, 0.737, 0.753), Color(0.827, 0.847, 0.333)], 'newgame': [Color(0.067, 0.745, 0.596), Color(0.329, 0.216, 0.333), Color(0.004, 0.145, 0.271)], 'nibble': [Color(0.643, 1.0, 0.329), Color(0.859, 0.365, 1.0), Color(0.176, 0.992, 0.792), Color(0.533, 0.498, 1.0)], 'ocean': [Color(0.133, 0.706, 1.0), Color(0.063, 0.525, 0.922), Color(0.235, 0.922, 0.816), Color(0.286, 0.416, 0.984)], 'peak': [Color(0.875, 0.871, 0.961), Color(0.694, 0.886, 0.898), Color(0.827, 0.933, 0.918), Color(0.706, 0.765, 0.91)], 'potluck': [Color(0.988, 0.463, 0.49), Color(0.843, 0.957, 0.58), Color(1.0, 0.863, 0.502), Color(1.0, 1.0, 0.682)], 'rainforest': [Color(0.502, 0.91, 0.714), Color(0.631, 1.0, 0.976), Color(0.741, 0.486, 0.973), Color(0.447, 0.533, 0.965)], 'river': [Color(0.682, 0.914, 0.914), Color(0.816, 0.922, 0.667), Color(0.612, 0.843, 0.761), Color(0.686, 0.667, 0.737)], 'ruins': [Color(0.875, 0.773, 0.569), Color(0.702, 0.506, 0.518), Color(0.859, 0.655, 0.58), Color(0.451, 0.384, 0.431)], 'ruins_dark': [Color(0.812, 0.812, 0.714), Color(0.725, 0.588, 0.761), Color(0.812, 0.588, 0.608), Color(0.796, 0.333, 0.529)], 'spooky': [Color(0.573, 0.878, 0.0), Color(1.0, 0.137, 0.0), Color(0.102, 0.788, 0.067), Color(0.431, 0.0, 0.263)], 'springs': [Color(0.545, 0.745, 0.953), Color(0.992, 0.831, 0.133), Color(0.98, 0.38, 0.392), Color(0.549, 0.267, 0.643)], 'swamp': [Color(0.812, 0.941, 0.62), Color(0.059, 0.588, 0.62), Color(0.251, 0.875, 0.667), Color(0.969, 0.482, 0.651)]}
var palette_aliases = {"Luncheon": "town","Luncheon Spooky": "town_spooky","Luncheon Spooky 2": "town_spooky2","Luncheon Postgame": "town_postgame","Boss 1": "boss1","Boss 2": "boss2","Brekkie": "brekkie","Brunch Canyon": "brunch","Caves": "cave","Dinners": "dinners","Elevenses": "elevenses","Feast": "feast","Appie Foothills": "foothills","Supper Woods": "forest","Gray": "gray","Grub Caverns": "grub1","Grub Deep": "grub2","Spoons Island": "island","Teatime Meadows": "meadows","Dessert Mountain": "mtn","Newgame": "newgame","Nibble Tunnel": "nibble","Ocean": "ocean","Dessert Mountain Peak": "peak","Potluck": "potluck","Banquet Rainforest": "rainforest","Sips River": "river","Wielder Temple": "ruins","Wielder Temple Dark": "ruins_dark","Spooky": "spooky","Simmer Springs": "springs","Gulp Swamp": "swamp"}

func get_gradient_texture(color):
	var gradtex = GradientTexture2D.new()
	gradtex.gradient = Gradient.new()
	gradtex.gradient.remove_point(1)
	gradtex.gradient.set_color(0, color)
	return gradtex

func add_palette(color, i):
	palette_item.add_item("Color %s" % (i+1), get_gradient_texture(color))

func set_color(color):
	newpalette[selected_index] = color
	palette_item.get_item_icon(selected_index).gradient.set_color(0, color)

func get_ingame_colors(search=""):
	for i in ingame_tree_root.get_children():
		ingame_tree_root.remove_child(i)
	for pname in palette_aliases:
		if search != "" and search.to_lower() not in pname.to_lower():
			continue
		var paltree = ingame_tree_root.create_child()
		paltree.set_selectable(0, false)
		paltree.set_text(0, pname)
		var pal = palettes[palette_aliases[pname]]
		for ii in range(len(pal)):
			var palcoltree = paltree.create_child()
			palcoltree.set_icon(0, get_gradient_texture(pal[ii]))
			palcoltree.set_text(0, "Color %s" % (ii+1))
			
			#ingame_item.add_item("%s Color %s" % [pname, (ii+1)], get_gradient_texture(pal[ii]))

func check_editing():
	var paletters = []
	for pid in MultiplayerManager.client.level_puppets:
		if MultiplayerManager.client.level_puppets[pid].playerstatus == Global.PlayerStatus.Palette:
			paletters.append(MultiplayerManager.client.level_puppets[pid].userinfo.username)
	if paletters:
		var are = "is"
		if len(paletters) > 1:
			are = "are"
		warninglabel.text = warninglabel.text % [", ".join(paletters), are]
	else:
		warning.visible = false

func _ready():
	check_editing()
	var i = 0
	palette_item.remove_item(0)
	for color in newpalette:
		add_palette(color, i)
		i += 1
	if len(newpalette) == 15:
		$VBoxContainer/HBoxContainer/PaletteColumnContainer/PlusButton.disabled = true
	
	ingame_tree_root = ingame_tree.create_item()
	get_ingame_colors()
	
	palette_item.select(0)
	ingame_tree.set_selected(ingame_tree_root.get_child(0), 0)

func _on_plus_button_pressed():
	if len(newpalette) < 15:
		add_palette(Color.RED, len(newpalette))
		newpalette.append(Color.RED)
	if len(newpalette) == 15:
		$VBoxContainer/HBoxContainer/PaletteColumnContainer/PlusButton.disabled = true

func _on_confirm_button_pressed():
	if MultiplayerManager.connected:
		MultiplayerManager.set_palette.rpc(newpalette, Global.current_level)
	queue_free()

func _on_cancel_button_pressed():
	queue_free()

func _on_palette_item_list_item_selected(index):
	colorpicker.color = newpalette[index]
	selected_index = index

func _on_apply_color_button_pressed():
	set_color(colorpicker.color)

func _on_in_game_apply_button_pressed():
	if ingame_tree.get_selected().get_icon(0):
		set_color(ingame_tree.get_selected().get_icon(0).gradient.colors[0])

func _on_in_game_tree_item_activated():
	if ingame_tree.get_selected().get_icon(0):
		set_color(ingame_tree.get_selected().get_icon(0).gradient.colors[0])

func _on_in_game_search_text_changed(new_text):
	get_ingame_colors(new_text)
