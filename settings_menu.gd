extends Control

@export var music_volume: float = 0.5
@export var sfx_volume: float = 0.5
const SAVE_PATH = "user://settings.cfg"

# Store the previous scene to return to
var previous_scene: String = ""

func _ready():
	# Set process mode to ensure it works while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("Settings Menu loaded.")
	# Show mouse cursor when settings menu is active
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Store current scene path before loading settings
	previous_scene = get_tree().current_scene.scene_file_path
	print("Previous scene stored: ", previous_scene)
	
	# Load saved settings
	load_settings()
	
	# Initialize slider values
	$VBoxContainer/MusicSlider.value = music_volume * 100
	$VBoxContainer/SFXSlider.value = sfx_volume * 100

func _exit_tree():
	# Save settings before exiting
	save_settings()
	
	# Restore mouse capture when leaving settings menu
	# Only if we're going back to the game (not main menu)
	if get_tree().current_scene.name != "MainMenu":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_MusicSlider_value_changed(value: float):
	music_volume = value / 100
	print("Music Volume:", music_volume)
	# Update music volume globally
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	# Save settings after each change
	save_settings()

func _on_SFXSlider_value_changed(value: float):
	sfx_volume = value / 100
	print("SFX Volume:", sfx_volume)
	# Update SFX volume globally
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	# Save settings after each change
	save_settings()

func _on_BackToGameButton_pressed():
	print("Returning to world scene...")
	
	# Path to the world.tscn scene
	var world_scene_path = "res://world.tscn"
	
	var result = get_tree().change_scene_to_file(world_scene_path)
	if result != OK:
		print("Error returning to world scene: ", result)
	else:
		print("Returned to world scene successfully!")

func _on_BackToMenuButton_pressed():
	print("Returning to main menu...")
	var result = get_tree().change_scene_to_file("res://main_menu.tscn")
	if result != OK:
		print("Error loading main menu: ", result)
	else:
		print("Main menu loaded successfully!")

func save_settings():
	var config = ConfigFile.new()
	
	# Store values in the config file
	config.set_value("Audio", "music_volume", music_volume)
	config.set_value("Audio", "sfx_volume", sfx_volume)
	
	# Save the config file
	var error = config.save(SAVE_PATH)
	if error == OK:
		print("Settings saved successfully")
	else:
		print("Error saving settings: ", error)

func load_settings():
	var config = ConfigFile.new()
	
	# Try to load existing settings
	var error = config.load(SAVE_PATH)
	
	if error == OK:
		# Load values from config file
		music_volume = config.get_value("Audio", "music_volume", 0.5)  # 0.5 is default if not found
		sfx_volume = config.get_value("Audio", "sfx_volume", 0.5)
		
		# Apply loaded values to audio buses
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
		
		print("Settings loaded successfully")
	else:
		print("No settings file found, using defaults")

# Helper function to convert linear volume to decibels
func linear_to_db(value: float) -> float:
	if value > 0:
		return 20.0 * log(value)
	return -80.0  # Return -80 dB for silent volumes

# Handle input to allow closing with Escape key
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_BackToGameButton_pressed()  # Changed to return to game instead of menu
