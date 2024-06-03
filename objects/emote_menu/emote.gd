extends PanelContainer

@onready var doganim = $SubViewport/DogAnim
@onready var viewport = $SubViewport

var menu

var emote: String = "sit"
var emote_dict: Dictionary
var dog_dict: Dictionary = Global.dog_dict

func _ready() -> void:
	if not emote_dict:
		emote_dict = Global.emotes[emote]
	doganim.set_dog_dict(dog_dict)
	doganim.play(emote_dict.loop if "loop" in emote_dict else emote_dict.start)
	doganim.frame = emote_dict.preview_frame*10 if "preview_frame" in emote_dict else 0
	doganim.position = doganim.animation.origin
	if "loop_expression" in emote_dict:
		doganim.set_expression(emote_dict.loop_expression)
	elif "start_expression" in emote_dict:
		doganim.set_expression(emote_dict.start_expression)
	doganim._process(0.0)
	viewport.render_target_update_mode = viewport.UPDATE_ONCE
	# tell me why "Item Get" displays as Item Ge when there's no space!!!! Item Gett displays as that so WHYY
	$Button.text = emote_dict.name + " "

func _process(_delta: float) -> void:
	if Global.dog_dict != dog_dict:
		dog_dict = Global.dog_dict
		doganim.set_dog_dict(dog_dict)
		viewport.render_target_update_mode = viewport.UPDATE_ONCE 


func _on_button_pressed():
	menu.button_pressed(emote)
