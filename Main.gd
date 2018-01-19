extends Control

const SAVE_PATH = "user://inputmap.cfg"

enum TAB_INDEX {KEYBOARDMOUSE_TAB, GAMEPAD_TAB, INPUTTEST_TAB}

enum CAPTURE_STATES {KEYBOARDMOUSE_CAPTURE, GAMEPAD_CAPTURE, TEST_CAPTURE}

const MOUSE_BUTTONS = ["", 
						"Mouse 1", 
						"Mouse 2", 
						"Mouse 3", 
						"Mouse Wheel Up", 
						"Mouse Wheel Down", 
						"Mouse Wheel Left", 
						"Mouse Wheel Right"]

const ACTION_NAMES = ["Move forward", 
					"Move back", 
					"Move left", 
					"Move right", 
					"Sprint", 
					"Jump", 
					"Primary attack", 
					"Secondary attack", 
					"Reload"]

const ACTION_KEYS = ["move_forward",
					"move_back",
					"move_left",
					"move_right",
					"sprint",
					"jump",
					"primary_attack",
					"secondary_attack",
					"reload"]

onready var _settings = {
	"keyboardmouse": {
		"move_forward": "kb_W",
		"move_back" : "kb_S",
		"move_left" : "kb_A",
		"move_right" : "kb_D",
		"sprint" : "kb_Shift",
		"jump" : "kb_Space",
		"primary_attack" : "mb_1",
		"secondary_attack" : "mb_2",
		"reload" : "kb_R"
	},
	"gamepad": {
		"move_forward": "jm_-1",
		"move_back" : "jm_+1",
		"move_left" : "jm_-0",
		"move_right" : "jm_+0",
		"sprint" : "jb_2",
		"jump" : "jb_0",
		"primary_attack" : "jb_7",
		"secondary_attack" : "jb_6",
		"reload" : "jb_1"
	}
}

onready var _default_settings = {
	"keyboardmouse": {
		"move_forward": "kb_W",
		"move_back" : "kb_S",
		"move_left" : "kb_A",
		"move_right" : "kb_D",
		"sprint" : "kb_Shift",
		"jump" : "kb_Space",
		"primary_attack" : "mb_1",
		"secondary_attack" : "mb_2",
		"reload" : "kb_R"
	},
	"gamepad": {
		"move_forward": "jm_-1",
		"move_back" : "jm_+1",
		"move_left" : "jm_-0",
		"move_right" : "jm_+0",
		"sprint" : "jb_2",
		"jump" : "jb_0",
		"primary_attack" : "jb_7",
		"secondary_attack" : "jb_6",
		"reload" : "jb_1"
	}
}

onready var kbm_table = $Background/InputTabContainer/KeyboardMouseTab/KeyboardMouseTable
onready var gp_table = $Background/InputTabContainer/GamepadTab/GamepadTable

var capture_state = KEYBOARDMOUSE_CAPTURE

func _ready():
	$Background/InputTabContainer.set_tab_title(KEYBOARDMOUSE_TAB, "Keyboard + Mouse")
	$Background/InputTabContainer.set_tab_title(GAMEPAD_TAB, "Gamepad")
	$Background/InputTabContainer.set_tab_title(INPUTTEST_TAB, "Input Test")
	
	$Background/InputTabContainer/InputTestTab/RawOutputBackground/RawOutputLabel.set_scroll_follow(true)
	$Background/InputTabContainer/InputTestTab/ActionOutputBackground/ActionOutputLabel.set_scroll_follow(true)
	
	if !_load_config():
		# stored ConfigFile does not exist, try and create from default settings
		_copy_default_settings("keyboardmouse")
		_copy_default_settings("gamepad")
		_save_config()
	
	_generate_input_map()
	_populate_input_map()
	
	_load_keyboardmouse_table()
	_load_gamepad_table()
	
	set_process_input(false)
	
#	print(Input.get_connected_joypads())
#	print(Input.get_joy_name(0))

func _load_config():
	
	# Load the values from Godot ConfigFile stored
	# on the disk and populate the _settings dictionary.
	
	var config_file = ConfigFile.new()
	var result = config_file.load(SAVE_PATH)
	
	if result == OK:
		for capture_type in _settings.keys():
			for key in _settings[capture_type].keys():
				var action = config_file.get_value(capture_type,key)
				_settings[capture_type][key] = action
		return true
	else:
		print("ConfigFile failed to load. ERR_", result)
		return false

func _save_config():
	
	# Save the _settings dictionary to the Godot ConfigFile
	# and write to disk.
	
	var config_file = ConfigFile.new()
	
	for capture_type in _settings.keys():
		for key in _settings[capture_type].keys():
			config_file.set_value(capture_type, key, _settings[capture_type][key])

	config_file.save(SAVE_PATH)

func _copy_default_settings(p_capture_type):
	
	# Copy the values from the _default_settings dictionary
	# into the _settings dictionary
	
	for key in _default_settings[p_capture_type].keys():
		_settings[p_capture_type][key] = _default_settings[p_capture_type][key]

func _clear_input_map():
	
	# Clear any changes by reloading ProjectSettings default InputMap
	
	InputMap.load_from_globals()
	
func _generate_input_map():
	
	# Create InputMap actions from ACTION_KEYS array.
	
	for i in range (0, ACTION_KEYS.size()):
		InputMap.add_action(ACTION_KEYS[i])

func _populate_input_map():
	
	# Populate the InputMap using the values obtained
	# from the _settings dictionary.
	
	var event
	
	for capture_type in _settings.keys():
		for key in _settings[capture_type].keys():
			var setting = _settings[capture_type][key]
			
			if setting.length() > 0: 
				if setting.begins_with("kb_"):
					event = InputEventKey.new()
					var scancode_string = setting
					scancode_string.erase(0, 3)
					var scancode = OS.find_scancode_from_string(scancode_string)
					event.scancode = scancode
					InputMap.action_add_event(key, event)
				elif setting.begins_with("mb_"):
					event = InputEventMouseButton.new()
					var setting_string = setting
					setting_string.erase(0, 3)
					event.button_index = setting_string.to_int()
					InputMap.action_add_event(key, event)
				elif setting.begins_with("jm_"):
					event = InputEventJoypadMotion.new()
					var setting_string = setting
					setting_string.erase(0, 3)
					if setting_string.begins_with("+"):
						setting_string.erase(0, 1)
						event.axis = setting_string.to_int()
						event.axis_value = 1.0
					elif setting_string.begins_with("-"):
						setting_string.erase(0, 1)
						event.axis = setting_string.to_int()
						event.axis_value = -1.0
					else:
						event.axis = setting_string.to_int()
					InputMap.action_add_event(key, event)
				elif setting.begins_with("jb_"):
					event = InputEventJoypadButton.new()
					var setting_string = setting
					setting_string.erase(0, 3)
					event.button_index = setting_string.to_int()
					InputMap.action_add_event(key, event)
				else:
					print("invalid save data")

func _load_keyboardmouse_table():
	
	# Populate the keyboardmouse table with values from the _settings dictionary.
	
	kbm_table.clear()
	var root = kbm_table.create_item()
	kbm_table.set_hide_root(true)
	kbm_table.set_columns(2)
	kbm_table.set_column_title(0, "Action")
	kbm_table.set_column_title(1, "Key/Button")
	kbm_table.set_column_titles_visible(true)
	
	for i in range(0, ACTION_NAMES.size()):
		# row is a TreeItem
		var row = kbm_table.create_item(root)
		row.set_selectable(0, false)
		# metadata stores the row index in the table for the TreeItem
		row.set_metadata(0,i) 
		row.set_text(0, ACTION_NAMES[i])
		var keybutton = _translate_save_setting(_settings["keyboardmouse"][ACTION_KEYS[i]])
		row.set_text(1, keybutton)
	
func _load_gamepad_table():
	
	# Populate the gamepad table with values from the _settings dictionary.
	
	gp_table.clear()
	var root = gp_table.create_item()
	gp_table.set_hide_root(true)
	gp_table.set_columns(2)
	gp_table.set_column_title(0, "Action")
	gp_table.set_column_title(1, "Key/Button")
	gp_table.set_column_titles_visible(true)
	
	for i in range(0, ACTION_NAMES.size()):
		# row is a TreeItem
		var row = gp_table.create_item(root)
		row.set_selectable(0, false)
		# metadata stores the row index in the table for the TreeItem
		row.set_metadata(0,i)
		row.set_text(0, ACTION_NAMES[i])
		var keybutton = _translate_save_setting(_settings["gamepad"][ACTION_KEYS[i]])
		row.set_text(1, keybutton)

func _translate_save_setting(p_setting):
	
	# Convert action key/setting save format to human readable text
	# for display in the tables.
	
	if p_setting.length() > 0: 
		if p_setting.begins_with("kb_"):
			var display_string = p_setting
			display_string.erase(0, 3)
			return display_string
		elif p_setting.begins_with("mb_"):
			var display_string = p_setting
			display_string.erase(0, 3)
			display_string = MOUSE_BUTTONS[display_string.to_int()]
			return display_string
		elif p_setting.begins_with("jm_"):
			var display_string = p_setting
			display_string.erase(0, 3)
			if display_string.begins_with("+"):
				display_string.erase(0, 1)
				return str(Input.get_joy_axis_string(display_string.to_int()),"+")
			elif display_string.begins_with("-"):
				display_string.erase(0, 1)
				return str(Input.get_joy_axis_string(display_string.to_int()),"-")
			else:
				return Input.get_joy_axis_string(display_string.to_int())
		elif p_setting.begins_with("jb_"):
			var display_string = p_setting
			display_string.erase(0, 3)
			display_string = Input.get_joy_button_string(display_string.to_int())
			return display_string
		else:
			return str("invalid save data")
	
	return str("")

func _on_InputTabContainer_tab_changed( tab ):
	
	# If we have been capturing on the Input Test tab,
	# disable process input if we switched tabs.
	if capture_state == TEST_CAPTURE and tab != INPUTTEST_TAB:
		set_process_input(false)
	
	# Change capture state depending on which tab is visible
	if tab == KEYBOARDMOUSE_TAB:
		capture_state = KEYBOARDMOUSE_CAPTURE
	elif tab == GAMEPAD_TAB:
		capture_state = GAMEPAD_CAPTURE
	elif tab == INPUTTEST_TAB:
		capture_state = TEST_CAPTURE
		set_process_input(true)

func _on_DefaultsButton_button_up():
	
	# Populate the _settings dictionary with default settings
	# and reload the table.
	
	if capture_state == KEYBOARDMOUSE_CAPTURE:
		_copy_default_settings("keyboardmouse")
		_load_keyboardmouse_table()
	elif capture_state == GAMEPAD_CAPTURE:
		_copy_default_settings("gamepad")
		_load_gamepad_table()

func _on_EditKeyButton_button_up():
	
	# If a key/button cell is selected and the Edit
	# button is pressed; highlight the cell and
	# wait for input.
	
	if capture_state == KEYBOARDMOUSE_CAPTURE:
		var selected = kbm_table.get_selected()
		if selected != null:
			selected.set_text(1, "")
			selected.set_custom_bg_color(1, Color(1.0, 0.5, 0.0, 1.0), false)
			$Background/EditKeyButton.release_focus()
			set_process_input(true)
	elif capture_state == GAMEPAD_CAPTURE:
		var selected = gp_table.get_selected()
		if selected != null:
			selected.set_text(1, "")
			selected.set_custom_bg_color(1, Color(1.0, 0.5, 0.0, 1.0), false)
			$Background/EditKeyButton.release_focus()
			set_process_input(true)

func _on_ClearKeyButton_button_up():
	
	# Set the currently selected key/button to be blank
	
	if capture_state == KEYBOARDMOUSE_CAPTURE:
		var selected = kbm_table.get_selected()
		if selected != null:
			var index = selected.get_metadata(0)
			var key = ACTION_KEYS[index]
			selected.set_text(1, "")
			selected.deselect(1)
			_settings["keyboardmouse"][key] = ""
			$Background/ClearKeyButton.release_focus()
	elif capture_state == GAMEPAD_CAPTURE:
		var selected = gp_table.get_selected()
		if selected != null:
			var index = selected.get_metadata(0)
			var key = ACTION_KEYS[index]
			selected.set_text(1, "")
			selected.deselect(1)
			_settings["gamepad"][key] = ""
			$Background/ClearKeyButton.release_focus()

func _on_SaveButton_button_up():
	
	# Save settings to disk and recreate the InputMap to apply
	# any changes
	
	if capture_state == KEYBOARDMOUSE_CAPTURE or capture_state == GAMEPAD_CAPTURE:
		_save_config()
		_clear_input_map()
		_generate_input_map()
		_populate_input_map()
		
		_load_keyboardmouse_table()
		_load_gamepad_table()

func _on_ReloadButton_button_up():
	
	# Clear InputMap and reload from disk
	
	if capture_state == KEYBOARDMOUSE_CAPTURE or capture_state == GAMEPAD_CAPTURE:
		_load_config()
		_clear_input_map()
		_generate_input_map()
		_populate_input_map()
		
		_load_keyboardmouse_table()
		_load_gamepad_table()

func _input(event):
	
	# Handle input events from connected devices depending on
	# the capture state we are in.
	# We can capture Keyboard Keys, Mouse Buttons,
	# Gamepad Motion and Gamepad Buttons.
	
	match capture_state:
		KEYBOARDMOUSE_CAPTURE:
			if event is InputEventKey && !event.is_echo():
				
				# Store the captured key/button in the _settings dictionary
				var setting = str("kb_", OS.get_scancode_string(event.scancode))
				var selected = kbm_table.get_selected()
				var index = selected.get_metadata(0)
				var key = ACTION_KEYS[index]
				_settings["keyboardmouse"][key] = setting
				
				# Update the table and reset the cell background to normal colour
				selected.set_text(1, OS.get_scancode_string(event.scancode))
				selected.deselect(1)
				selected.set_custom_bg_color(1, Color(1.0, 0.5, 0.0, 0.0), false)
				
				# Disable input capture
				get_tree().set_input_as_handled()
				set_process_input(false)
			elif event is InputEventMouseButton and event.is_pressed():
				
				# Store the captured key/button in the _settings dictionary
				var setting = str("mb_", event.button_index)
				var selected = kbm_table.get_selected()
				var index = selected.get_metadata(0)
				var key = ACTION_KEYS[index]
				_settings["keyboardmouse"][key] = setting
				
				# Update the table and reset the cell background to normal colour
				selected.set_text(1, MOUSE_BUTTONS[event.button_index])
				selected.deselect(1)
				selected.set_custom_bg_color(1, Color(1.0, 0.5, 0.0, 0.0), false)
				
				# Disable input capture
				get_tree().set_input_as_handled()
				set_process_input(false)
		GAMEPAD_CAPTURE:
			if event is InputEventJoypadButton and event.is_pressed():
				
				# Store the captured key/button in the _settings dictionary
				var setting = str("jb_", event.button_index)
				var selected = gp_table.get_selected()
				var index = selected.get_metadata(0)
				var key = ACTION_KEYS[index]
				_settings["gamepad"][key] = setting
				
				# Update the table and reset the cell background to normal colour
				selected.set_text(1, Input.get_joy_button_string(event.button_index))
				selected.deselect(1)
				selected.set_custom_bg_color(1, Color(1.0, 0.5, 0.0, 0.0), false)
				
				# Disable input capture
				get_tree().set_input_as_handled()
				set_process_input(false)
			elif event is InputEventJoypadMotion and event.is_pressed():
				
				# axis_value can be a float between -1.0 and +1.0 depending
				# on how far the analog stick has moved. We just need to 
				# capture the sign of the value at this point.
				var axis_sign = ""
				if event.axis_value < 0.0:
					axis_sign = "-"
				elif event.axis_value > 0.0:
					axis_sign = "+"
				
				# Store the captured axis in the _settings dictionary
				var setting = str("jm_", axis_sign, event.axis)
				var selected = gp_table.get_selected()
				var index = selected.get_metadata(0)
				var key = ACTION_KEYS[index]
				_settings["gamepad"][key] = setting
				
				# Update the table and reset the cell background to normal colour
				selected.set_text(1, str(Input.get_joy_axis_string(event.axis), axis_sign))
				selected.deselect(1)
				selected.set_custom_bg_color(1, Color(1.0, 0.5, 0.0, 0.0), false)
				
				# Disable input capture
				get_tree().set_input_as_handled()
				set_process_input(false)
		TEST_CAPTURE:
			
			# Append the captured input event descriptions to the raw output rich text label
			
			if event is InputEventKey and event.is_pressed():
				var message = str("[u]Keyboard:[/u] ", OS.get_scancode_string(event.scancode), "\n")
				$Background/InputTabContainer/InputTestTab/RawOutputBackground/RawOutputLabel.append_bbcode(message)
				
			if event is InputEventMouseButton and event.is_pressed():
				var message = str("[u]Mouse:[/u] ", MOUSE_BUTTONS[event.button_index], "\n")
				$Background/InputTabContainer/InputTestTab/RawOutputBackground/RawOutputLabel.append_bbcode(message)
				
			if event is InputEventJoypadButton and event.is_pressed():
				# Here you can choose between displaying the button index or the decoded button name
				var message = str("[u]Gamepad:[/u] ", Input.get_joy_button_string(event.button_index), "\n")
				#var message = str("[u]Gamepad:[/u] Button ", event.button_index, "\n")
				$Background/InputTabContainer/InputTestTab/RawOutputBackground/RawOutputLabel.append_bbcode(message)
				
			if event is InputEventJoypadMotion and event.is_pressed():
				var axis_sign = ""
				if event.axis_value < 0.0:
					axis_sign = "-"
				elif event.axis_value > 0.0:
					axis_sign = "+"
				# Here you can choose between displaying the button index or the decoded axis name
				var message = str("[u]Gamepad:[/u] ", Input.get_joy_axis_string(event.axis), axis_sign, "\n")
				#var message = str("[u]Gamepad:[/u] Axis ", event.axis, axis_sign, "\n")
				$Background/InputTabContainer/InputTestTab/RawOutputBackground/RawOutputLabel.append_bbcode(message)
			
			# Append the captured action pressed names to the action output rich text label
			for i in range (0, ACTION_KEYS.size()):
				if Input.is_action_pressed(ACTION_KEYS[i]):
					$Background/InputTabContainer/InputTestTab/ActionOutputBackground/ActionOutputLabel.append_bbcode(str(ACTION_NAMES[i], "\n"))
				
