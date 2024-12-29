extends Control

func _ready():
	visible = false  # Ensure the pause menu is hidden initially
	print("Pause Menu initialized.")

func toggle_pause():
	# Toggle visibility and paused state
	visible = not visible
	get_tree().paused = visible
	if visible:
		print("Game Paused")
	else:
		print("Game Resumed")

func _on_resume_button_pressed():
	toggle_pause()

func _on_settings_button_pressed():
	if not visible:
		return  # Prevent action if the menu isn't visible
	print("Opening settings menu from pause menu...")
	visible = false  # Hide the pause menu before switching scenes
	get_tree().paused = false  # Unpause the game
	get_tree().change_scene("res://settings_menu.tscn")  # Update this path if necessary

func _on_quit_to_main_menu_button_pressed():
	if not visible:
		return  # Prevent action if the menu isn't visible
	print("Quitting to main menu...")
	visible = false  # Hide the pause menu before switching scenes
	get_tree().paused = false  # Unpause the game
	get_tree().change_scene("res://main_menu.tscn")  # Update this path if necessary
