extends Control

const TITLE_NEEDED = [Settings.SettingType.INT_LIST, Settings.SettingType.FLOAT_RANGE]

@onready var container = $VBoxContainer/PanelContainer/VBoxContainer

var newvalues = {}

func _ready():
	$VBoxContainer/MarginContainer/HBoxContainer/Close.grab_focus()
	for prop in Settings.SETTING_INFO:
		var val = Settings.SETTING_INFO[prop]
		var setting_type = val.type
		var setting_con = HBoxContainer.new()
		setting_con.tooltip_text = val.desc
		var value_node
		match setting_type:
			Settings.SettingType.BOOL:
				value_node = CheckButton.new()
				value_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				value_node.button_pressed = Settings.get(prop)
				value_node.text = val.name
				value_node.connect("toggled", bool_setting_changed.bind(prop))
			Settings.SettingType.INT_LIST:
				value_node = OptionButton.new()
				value_node.size_flags_horizontal = SIZE_SHRINK_END
				for i in val.value_names:
					value_node.add_item(i)
				value_node.select(Settings.get(prop))
				value_node.connect("item_selected", int_list_changed.bind(prop))
			Settings.SettingType.FLOAT_RANGE:
				value_node = HBoxContainer.new()
				value_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				value_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				var slider = HSlider.new()
				slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				var label = Label.new()
				label.size_flags_horizontal = Control.SIZE_FILL
				label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				label.custom_minimum_size.x = 55
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				value_node.add_child(slider)
				value_node.add_child(label)
				slider.value = Settings.get(prop)
				label.text = "%d%%" % Settings.get(prop)
				slider.min_value = val.min
				slider.max_value = val.max
				slider.connect("value_changed", float_range_changed.bind(prop, label))
			_:
				push_warning("Non Implemented Setting Type.")
				continue
		if setting_type in TITLE_NEEDED:
			var label = Label.new()
			label.size_flags_horizontal = SIZE_EXPAND
			label.text = val.name
			var panel = PanelContainer.new()
			setting_con.add_child(label)
			setting_con.add_child(value_node)
			panel.add_child(setting_con)
			container.add_child(panel)
		else:
			setting_con.add_child(value_node)
			container.add_child(setting_con)

func bool_setting_changed(value, property):
	newvalues[property] = value

func int_list_changed(value, property):
	newvalues[property] = value

func float_range_changed(value, property, label):
	newvalues[property] = value
	label.text = "%d%%" % value

func _on_cancel_button_pressed():
	queue_free()

func _on_confirm_button_pressed():
	for prop in newvalues:
		Settings.set(prop, newvalues[prop])
	Settings.save()
	queue_free()
