extends Node

const paint_size := Vector2(162, 91)
const paint_total := paint_size.x * paint_size.y

enum PlayerStatus {
	Normal = 0,
	Paused = 1,
	PlayerList = 2,
	Palette = 3,
	Dog = 4,
	Setting = 5,
}

@onready var loading_screen = preload("res://scenes/ui/loading.tscn").instantiate()
@onready var pause_screen = preload("res://scenes/ui/pause.tscn").instantiate()

var pause_enable = false

var boil_timer := 0.0
var boil = randf()

const body_ims = {'Overalls': 0, 'Flower Dress': 1, 'Hoodie': 2, 'Pocket Jacket': 3, 'Starry Tee': 4, 'Stripey Tee': 5, 'Sunny Tee': 6, 'Bolt Tee': 7, 'Moon Tee': 8, 'Big Star': 9, 'Black Tee': 10, 'Kerchief': 10, 'Scarf': 10, 'Shawl': 10, 'Spike': 10, 'Bee': 11, 'Big Flower': 12, 'High Nooner': 13, 'Dot Dress': 14, 'Cord Coat': 15, 'Puffy Jacket': 16, 'Dorky': 17, 'Woven': 18, 'Rex Bod': 19, 'Wielder Cloak': 20, 'Hotneck': 21, 'Gothy': 22, 'Nice Shirt': 23, 'Smock': 24, 'Island': 25, 'Splashpants': 26, 'Splash Onesie': 27, 'College': 28, 'Biker Jacket': 29, 'Mascot Bod': 30, 'Avast': 31, 'Mailbag': 32, 'Bard': 33, 'Tux': 34, 'Scientist': 35, 'Fuzzy Jacket': 36, 'Sailor': 37, 'Sequins': 38, 'Black Dress': 39, 'Leafy': 40, 'Pajamas': 41, 'Cute Dress': 42, 'Pilot': 43, 'Shell Tee': 44, 'Big Heart': 45, 'Robo': 46, 'Ski Jacket': 47, 'Gorgeous': 48, 'Royal': 49, 'Hiker': 50}
const body0_ims = {'Gorgeous': 13, 'Hiker': 15}
const body1_ims = {'Kerchief': 1, 'Scarf': 2, 'Wielder Cloak': 4, 'Neck_Headphones': 7, 'Sailor': 8, 'Shawl': 9, 'Spike': 10, 'Studs': 11}
const body2_ims = {'Cord Coat': 3, 'Bard': 5, 'Fuzzy Jacket': 6, 'Ski Jacket': 12, 'Royal': 14}

const hat_ims = {'Bandana': 0, 'Beanie': 1, 'Brimcap': 2, 'Strawhat': 3, 'Sunhat': 4, 'Headband': 8, 'Bow': 9, 'Antenna': 12, 'Flower': 13, 'Howdy': 14, 'Shades': 15, 'Tinted Shades': 16, 'Line Shades': 17, 'Big Shades': 18, 'Beret': 19, 'Rex Head': 20, 'Wielder Wrap': 21, 'Newsie': 22, 'Half-Moons': 23, 'Round Glasses': 24, 'Square Glasses': 25, 'Pointish Glasses': 26, 'Spellcaster': 27, 'Backwards': 28, 'Feather': 29, 'Ahoy': 30, 'Delivery': 31, 'Earmuffs': 32, 'Clown': 33, 'Wintry': 34, 'Eyepatch': 35, 'Gnome': 36, 'Mascot Head': 37, 'Spike Helmet': 38, 'Big Fungus': 39, 'Nautical': 40, 'Fungus': 41, 'Goggles': 42, 'Chef': 43, 'Foxy': 44, 'Sparkles': 45, 'Aviators': 46, 'Beak': 47, 'Rim Shades': 48, 'Bell': 49, 'Elf': 50, 'Gardener': 51, 'Stache': 52, 'Monocle': 53, 'Stormy': 54, 'Superstar': 55, 'Headphones': 78, 'Headscarf': 79, 'Skate Helmet': 80, 'Mask': 81, 'Top Hat': 82, 'Helm': 83, 'Beard': 84, 'Crown': 85, 'Earflaps': 86, 'Tiara': 87, 'Horns': 88}
const hair_ims = {'Simple': 5, 'Flip': 6, 'Floofy': 7, 'Big Fluffy': 10, 'Gorgeous': 11, 'Mullet': 56, 'Bowl': 57, 'Pony': 58, 'Hedgehog': 59, 'Boyband': 60, 'Shaved': 61, 'Shortcurl': 62, 'Pixie': 63, 'Bob': 64, 'Anime': 65, 'Dreds': 66, 'Fuzz': 67, 'Fro': 68, 'Emo': 69, 'Pigtails': 70, 'Pompadour': 71, 'Spikehawk': 72, 'Flame': 73, 'Topknot': 74, 'Bellhair': 75, 'Hawk': 76, 'Longpony': 77, 'Highback': 90, 'Swoosh': 91, 'Mofro': 92, 'Poodle': 93, 'Frizz': 94, 'Curleye': 95}

const hair_shown_hats = ["Aviators","Beak","Beard","Big Shades","Bow","Clown","Eyepatch","Flower","Goggles","Half-Moons","Headband","Horns","Kerchief","Line Shades","Mask","Monocle","None","Pointish Glasses","Rim Shades","Round Glasses","Scarf","Shades","Shawl","Sparkles","Spike","Square Glasses","Stache","Stormy","Studs","Superstar","Tiara","Tinted Shades"]
const hats_over_ear = ["Ahoy","Big Fungus","Custom","Earmuffs","Headphones","Howdy","Rex Head","Spellcaster","Strawhat","Sunhat","Top Hat"]
const body2_hats = ["Shawl","Spike","Studs","Kerchief","Scarf"]

var dog_dict = {"clothes": "Overalls", "hat": "Bandana", "hair": "Simple", "color": {"body": Color(1,1,1), "hat": Color(1,1,1), "clothes": Color(1,1,1), "brush_handle": Color(1,1,1)}}

var loaded_sprites_A := {}
var loaded_sprites_B := {}
var loaded_sprites_ear := {}

var loaded_brush = []

var username = "Default"

var palette = [
	Color("#00f3dd"), Color("#d8ff55"), Color("#ffa694"), Color("#b69aff")
]

var paint_target = null
var paint_res: int = 12

var current_level = Vector3(0, 0, 0)

var paintable = true
var screenshot = null
var filedialog = null

func load_username():
	if FileAccess.file_exists("user://username.txt"):
		var file = FileAccess.open("user://username.txt", FileAccess.READ)
		Global.username = file.get_line().strip_edges()
		file.close()

func save_username():
	var file = FileAccess.open("user://username.txt", FileAccess.WRITE)
	file.store_line(Global.username)
	file.close()

func load_dog():
	if not FileAccess.file_exists("user://dog.json"):
		return
	var file = FileAccess.open("user://dog.json", FileAccess.READ)
	var newdog = JSON.parse_string(file.get_line())
	if not newdog: return
	for i in newdog.color:
		newdog.color[i] = Color(newdog.color[i])
	dog_dict = newdog

func save_dog():
	var file = FileAccess.open("user://dog.json", FileAccess.WRITE)
	var outdog = dog_dict
	for i in outdog.color:
		if not typeof(outdog.color[i]) == TYPE_STRING:
			outdog.color[i] = "#" + outdog.color[i].to_html(false)
	file.store_line(JSON.stringify(outdog))

func cancel_screenshotting():
	filedialog.queue_free()
	screenshot = null
	paintable = true
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func save_screenshot(path):
	screenshot.save_png(path)
	Settings.last_save_location = "/".join(path.split("/").slice(0, -1)) + "/"
	Settings.save()
	filedialog.queue_free()
	screenshot = null
	get_tree().paused = false
	paintable = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta):
	randomize()
	boil_timer += delta
	if boil_timer > 0.25:
		boil = randf()
		boil_timer = fmod(boil_timer, 0.25)
	
	if Input.is_action_just_pressed("fullscreen", true):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	if Input.is_action_just_pressed("screenshot", true) and not get_tree().paused:
		if Global.paint_target and not screenshot:
			screenshot = await Global.paint_target.get_texture()
			if OS.has_feature("web"):
				JavaScriptBridge.download_buffer(screenshot.save_png_to_buffer(), "paint.png", "image/png")
			else:
				get_tree().paused = true
				paintable = false
				filedialog = FileDialog.new()
				
				filedialog.exclusive = true
				var cornerdist = Vector2i(1920, 1080)/10
				filedialog.position = cornerdist
				filedialog.size = Vector2i(1920, 1080)-cornerdist*2
				
				filedialog.access = FileDialog.ACCESS_FILESYSTEM
				filedialog.current_dir = Settings.last_save_location
				
				filedialog.add_filter("*.png", "PNG File")
				filedialog.title = "Save Paint Screenshot"
				
				add_child(filedialog)
				filedialog.visible = true
				filedialog.connect("canceled", cancel_screenshotting)
				filedialog.connect("file_selected", save_screenshot)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	loading_screen.visible = false
	get_parent().add_child.call_deferred(loading_screen)
	pause_screen.visible = false
	get_parent().add_child.call_deferred(pause_screen)
	load_username()
	load_dog()
