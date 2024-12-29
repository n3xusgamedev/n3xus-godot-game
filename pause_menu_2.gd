extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Don't hide the menu here since the player script handles visibility
	print("Pause Menu initialized")

func _input(event: InputEvent) -> void:
	# Handle both P key and Options/Start button for unpausing
	if get_tree().paused and (
		(event is InputEventKey and event.pressed and event.keycode == KEY_P) or
		(event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	):
		unpause()

func pause() -> void:
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("Game Paused")

func unpause() -> void:
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Game Resumed")

func _on_resume_button_pressed() -> void:
	unpause()

func _on_settings_button_pressed() -> void:
	print("Opening settings menu...")
	unpause()
	get_tree().change_scene_to_file("res://settings_menu.tscn")

func _on_quit_to_main_menu_button_pressed() -> void:
	print("Quitting to main menu...")

	# Replace or remove your unpause() call:
	get_tree().paused = false  # This "unpauses" the game.

	var result = get_tree().change_scene_to_file("res://main_menu.tscn")
	if result != OK:
		printerr("Error loading main menu: %d" % result)
	else:
		print("Main menu loaded successfully!")
