extends VBoxContainer

const DISPLAY_TIME = 2.0
const FADEOUT_TIMER = 0.5
const MAX_CHATS = 50
const ROOM_MESSAGE = "%s> %s"
const GLOBAL_MESSAGE = "%s (%d,%d,%d)> %s"
const JOIN_MESSAGE = "%s joined!"
const LEAVE_MESSAGE = "%s left."

var display_timer = 0.0
var eating_inputs = false
var red_tex = GradientTexture2D.new()
var orange_tex = GradientTexture2D.new()
var redtab = [false, false, false]

@onready var lineedit = $LineEdit
@onready var tab = $"TabContainer"
@onready var roomchat = $"TabContainer/Room Chat/RoomBox"
@onready var globalchat = $"TabContainer/Global Chat/GlobalBox"

func add_message(chat, message, tab_ind):
	var prev_end = chat.get_parent().scroll_vertical == max(0, chat.size.y - chat.get_parent().size.y)
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	chat.add_child(label)
	if chat.get_child_count() > MAX_CHATS:
		chat.get_child(-1).queue_free()
	if tab_ind == tab.current_tab:
		display_timer = 0.0
	else:
		if ("@%s" % Global.username.to_lower()) in message.to_lower():
			tab.set_tab_icon(tab_ind, orange_tex)
		elif not redtab[tab_ind]:
			tab.set_tab_icon(tab_ind, red_tex)
		redtab[tab_ind] = true
	if prev_end:
		await get_tree().process_frame
		chat.get_parent().scroll_vertical = max(0, chat.size.y - chat.get_parent().size.y)

func add_connection_message(username, joined):
	if joined:
		add_message(globalchat, JOIN_MESSAGE % username, 1)
	else:
		add_message(globalchat, LEAVE_MESSAGE % username, 1)
	
func add_room_message(username, message):
	add_message(roomchat, ROOM_MESSAGE % [username, message], 0)

func add_global_message(username, level, message):
	add_message(globalchat, GLOBAL_MESSAGE % [username, level.x, level.y, level.z, message], 1)

func clear_room_chat():
	for child in roomchat.get_children():
		roomchat.remove_child(child)

func _process(delta):
	if redtab[tab.current_tab]:
		tab.set_tab_icon(tab.current_tab, null)
		redtab[tab.current_tab] = false
	if Input.is_action_just_pressed("chat", true) and not lineedit.has_focus():
		lineedit.grab_focus()
		Global.chat = true
		Global.pause_enable = false
	if Input.is_action_just_pressed("ui_text_clear_carets_and_selection", true) and lineedit.has_focus():
		display_timer = DISPLAY_TIME
		lineedit.release_focus()
	if lineedit.has_focus():
		display_timer = 0.0
	
	if tab.current_tab == 2 and lineedit.has_focus():
		lineedit.editable = false
	else:
		lineedit.editable = true
	
	if display_timer > 0 and tab.current_tab == 2:
		display_timer = DISPLAY_TIME+FADEOUT_TIMER
	display_timer += delta
	
	if display_timer > DISPLAY_TIME:
		modulate.a = clamp(1.0 - (display_timer - DISPLAY_TIME)/FADEOUT_TIMER, 0 , 1)
	else:
		modulate.a = 1
	
	for i in range(3):
		tab.set_tab_disabled(i, modulate.a == 0)
	
	if modulate.a != 0 and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		display_timer = 0.0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Global.paintable = false
		lineedit.mouse_filter = MOUSE_FILTER_PASS
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		Global.paintable = true
		lineedit.mouse_filter = MOUSE_FILTER_IGNORE

func _ready():
	MultiplayerManager.client.chat = self
	red_tex.gradient = Gradient.new()
	red_tex.gradient.remove_point(1)
	red_tex.gradient.set_color(0, Color.RED)
	red_tex.height = 10
	red_tex.width = 10
	orange_tex.gradient = red_tex.gradient.duplicate()
	orange_tex.gradient.set_color(0, Color.ORANGE)
	orange_tex.height = 10
	orange_tex.width = 10

func reset_lineedit():
	lineedit.release_focus()
	lineedit.text = ""
	Global.chat = false
	await get_tree().process_frame
	await get_tree().process_frame # uhhh
	Global.pause_enable = true

func _on_line_edit_focus_exited():
	reset_lineedit()

func _on_line_edit_text_submitted(new_text):
	if not new_text:
		return
	match tab.current_tab:
		0:
			MultiplayerManager.chat_message.rpc(Global.username, Global.current_level, new_text)
		1:
			MultiplayerManager.global_chat_message.rpc(Global.username, Global.current_level, new_text)
	reset_lineedit()
