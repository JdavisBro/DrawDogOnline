extends Control

@onready var dog = $SubViewport/DogAnim
@onready var brush = $SubViewport/brush

@onready var clothes_list = $VBoxContainer/HBoxContainer/ClothesScroll/ClothesItemList
@onready var hat_list = $VBoxContainer/HBoxContainer/HatScroll/HatItemList
@onready var hair_list = $VBoxContainer/HBoxContainer/HairScroll/HairItemList

var clothes = []
var hats = []
var hair = []

var newdog = null

func setup(itemlist: ItemList, dict, iconpath, current, ex=null, ex_path=null):
	var out = []
	var ls = dict.keys()
	if ex:
		ls += ex
	itemlist.remove_item(0)
	for i in ls:
		var icon
		if ex and i in ex:
			icon = load(ex_path % Global.body1_ims[i])
		else:
			if i in Global.body2_hats:
				icon = load("res://assets/chicory/clothes2/%02d.png" % Global.body1_ims[i])
			else:
				icon = load(iconpath % dict[i])
		itemlist.add_item(i, icon)
		if i == current:
			itemlist.select(itemlist.item_count-1)
		out.append(i)
	return out


func _ready():
	newdog = Global.dog_dict
	dog.big = true
	brush.scale *= 6
	brush.global_position = dog.body.global_position + (Vector2(0, -25)*5)
	brush.rotation_degrees = 135
	brush.position += (Vector2(0, 50)*5).rotated(brush.rotation)
	brush.get_node("handle").modulate = newdog.color.brush_handle
	brush.get_node("end").modulate = Global.palette[0]
	clothes = setup(clothes_list, Global.body_ims, "res://assets/chicory/clothes/%02d.png", newdog.clothes)
	hats = setup(hat_list, Global.hat_ims, "res://assets/chicory/hat/%02d.png", newdog.hat, Global.body2_hats, "res://assets/chicory/clothes2/%02d.png")
	hair = setup(hair_list, Global.hair_ims, "res://assets/chicory/hat/%02d.png", newdog.hair)
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/BodyPickerButton.color = newdog.color.body
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/ClothesPickerButton.color = newdog.color.clothes
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/HatPickerButton.color = newdog.color.hat
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/BrushPickerButton.color = newdog.color.brush_handle

func _process(_delta):
	brush.global_position = dog.body.global_position + (Vector2(0, -15)*5)
	brush.position += (Vector2(0, 60)*5).rotated(brush.rotation)

func _on_confirm_button_pressed():
	if MultiplayerManager.connected:
		MultiplayerManager.dog_update_dog.rpc(newdog)
	else:
		Global.dog_dict = newdog
		Global.save_dog()
	queue_free()

func _on_cancel_button_pressed():
	queue_free()

func update_dog_visual():
	dog.set_dog_dict(newdog)
	brush.get_node("handle").modulate = newdog.color.brush_handle

func _on_clothes_item_list_item_selected(index):
	newdog.clothes = clothes[index]
	update_dog_visual()

func _on_hat_item_list_item_selected(index):
	newdog.hat = hats[index]
	update_dog_visual()

func _on_hair_item_list_item_selected(index):
	newdog.hair = hair[index]
	update_dog_visual()

func _on_body_picker_button_color_changed(color):
	newdog.color.body = color
	update_dog_visual()

func _on_clothes_picker_button_color_changed(color):
	newdog.color.clothes = color
	update_dog_visual()

func _on_hat_picker_button_color_changed(color):
	newdog.color.hat = color
	update_dog_visual()

func _on_brush_picker_button_color_changed(color):
	newdog.color.brush_handle = color
	update_dog_visual()
