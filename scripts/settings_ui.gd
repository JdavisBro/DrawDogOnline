extends Control

@onready var container = $VBoxContainer/PanelContainer/VBoxContainer

var newvalues = {}

func _ready():
	for prop in Settings.SETTING_INFO:
		var val = Settings.SETTING_INFO[prop]
		var setting_type = val.type
		var setting_con = HBoxContainer.new()
		setting_con.tooltip_text = val.desc
		var label = Label.new()
		label.size_flags_horizontal = SIZE_EXPAND
		label.text = val.name
		setting_con.add_child(label)
		var value_node
		match setting_type:
			Settings.SettingType.BOOL:
				value_node = CheckButton.new()
				value_node.button_pressed = Settings.get(prop)
				value_node.connect("toggled", bool_setting_changed.bind(prop))
			Settings.SettingType.INT_LIST:
				value_node = OptionButton.new()
				for i in val.value_names:
					value_node.add_item(i)
				value_node.select(Settings.get(prop))
				value_node.connect("item_selected", int_list_changed.bind(prop))
			_:
				push_warning("Non Implemented Setting Type.")
				continue
		value_node.size_flags_horizontal = SIZE_SHRINK_END
		setting_con.add_child(value_node)
		container.add_child(setting_con)

func bool_setting_changed(value, property):
	newvalues[property] = value

func int_list_changed(value, property):
	newvalues[property] = value

func _on_cancel_button_pressed():
	queue_free()

func _on_confirm_button_pressed():
	for prop in newvalues:
		Settings.set(prop, newvalues[prop])
		Settings.save()
	queue_free()
