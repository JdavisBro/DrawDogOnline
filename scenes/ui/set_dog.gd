extends Control

@onready var dog = $SubViewport/DogAnim
@onready var brush = $SubViewport/brush

@onready var clothes_list = $VBoxContainer/HBoxContainer/ClothesContainer/ClothesScroll/ClothesItemList
@onready var hat_list = $VBoxContainer/HBoxContainer/HatContainer/HatScroll/HatItemList
@onready var hair_list = $VBoxContainer/HBoxContainer/HairContainer/HairScroll/HairItemList

var newdog = null

func setup(itemlist: ItemList, dict, iconpath, search, current, ex=null, ex_path=null):
	var ls = dict.keys()
	if ex:
		ls += ex
	while itemlist.item_count != 0:
		itemlist.remove_item(0)
	for i in ls:
		if search != "" and search.to_lower() not in i.to_lower():
			continue
		var icon
		if ex and i in ex:
			icon = load(ex_path % Global.body1_ims[i])
		else:
			if i in Global.body2_hats:
				icon = load("res://assets/chicory/clothes2/%02d.png" % Global.body1_ims[i])
			else:
				icon = load(iconpath % dict[i])
		itemlist.add_item(i, icon)
		if current != null and i == current:
			itemlist.select(itemlist.item_count-1)

func _ready():
	newdog = Global.dog_dict
	dog.big = true
	brush.scale *= 6
	brush.global_position = dog.body.global_position + (Vector2(0, -25)*5)
	brush.rotation_degrees = 135
	brush.position += (Vector2(0, 50)*5).rotated(brush.rotation)
	brush.get_node("handle").modulate = newdog.color.brush_handle
	brush.get_node("end").modulate = Global.palette[0]
	setup(clothes_list, Global.body_ims, "res://assets/chicory/clothes/%02d.png", "", newdog.clothes)
	setup(hat_list, Global.hat_ims, "res://assets/chicory/hat/%02d.png", "", newdog.hat, Global.body2_hats, "res://assets/chicory/clothes2/%02d.png")
	setup(hair_list, Global.hair_ims, "res://assets/chicory/hat/%02d.png", "", newdog.hair)
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/BodyPickerButton.color = newdog.color.body
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/ClothesPickerButton.color = newdog.color.clothes
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/HatPickerButton.color = newdog.color.hat
	$VBoxContainer/HBoxContainer/CenterContainer/VBoxContainer/BrushPickerButton.color = newdog.color.brush_handle
	$VBoxContainer/MarginContainer/HBoxContainer/CancelButton.grab_focus()

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
	newdog.clothes = clothes_list.get_item_text(index)
	update_dog_visual()

func _on_hat_item_list_item_selected(index):
	newdog.hat = hat_list.get_item_text(index)
	update_dog_visual()

func _on_hair_item_list_item_selected(index):
	newdog.hair = hair_list.get_item_text(index)
	update_dog_visual()

func _on_body_picker_button_color_changed(color):
	newdog.color.body = Color(color)
	update_dog_visual()

func _on_clothes_picker_button_color_changed(color):
	newdog.color.clothes = Color(color)
	update_dog_visual()

func _on_hat_picker_button_color_changed(color):
	newdog.color.hat = Color(color)
	update_dog_visual()

func _on_brush_picker_button_color_changed(color):
	newdog.color.brush_handle = Color(color)
	update_dog_visual()

func _on_clothes_search_text_changed(new_text):
		setup(clothes_list, Global.body_ims, "res://assets/chicory/clothes/%02d.png", new_text, newdog.clothes)

func _on_hat_search_text_changed(new_text):
	setup(hat_list, Global.hat_ims, "res://assets/chicory/hat/%02d.png", new_text, newdog.hat, Global.body2_hats, "res://assets/chicory/clothes2/%02d.png")

func _on_hair_search_text_changed(new_text):
	setup(hair_list, Global.hair_ims, "res://assets/chicory/hat/%02d.png", new_text, newdog.hair)
