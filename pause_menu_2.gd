extends Control

# Preload the settings menu
@onready var settings_menu = preload("res://settings_menu.tscn").instantiate()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Add the settings menu as a child, but keep it hidden initially
	add_child(settings_menu)
	settings_menu.hide()

	# Safely center the settings menu
	if settings_menu is Control:
		settings_menu.position = (get_viewport_rect().size - settings_menu.size) / 2
	else:
		printerr("Settings menu is not a Control node. Positioning might not work.")
	print("Pause Menu and Settings Menu initialized")

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
	settings_menu.show()

	# Ensure the game remains paused when the settings menu is open
	get_tree().paused = true

	# Safely recenter the settings menu
	if settings_menu is Control:
		settings_menu.position = (get_viewport_rect().size - settings_menu.size) / 2

func _on_quit_to_main_menu_button_pressed() -> void:
	print("Quitting to main menu...")
	get_tree().paused = false  # This "unpauses" the game.

	var result = get_tree().change_scene_to_file("res://main_menu.tscn")
	if result != OK:
		printerr("Error loading main menu: %d" % result)
	else:
		print("Main menu loaded successfully!")
