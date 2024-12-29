extends Control

@export var music_volume: float = 0.5
@export var sfx_volume: float = 0.5
const SAVE_PATH = "user://settings.cfg"

func _ready():
	# Set process mode to ensure it works while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	print("Settings Menu loaded.")
	# Show mouse cursor when settings menu is active
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Load saved settings
	load_settings()

	# Initialize slider values
	$VBoxContainer/MusicSlider.value = music_volume * 100
	$VBoxContainer/SFXSlider.value = sfx_volume * 100

	# Apply the settings to audio buses immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

func _exit_tree():
	# Save settings before exiting
	save_settings()

func _on_MusicSlider_value_changed(value: float):
	music_volume = value / 100
	print("Music Volume:", music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	save_settings()

func _on_SFXSlider_value_changed(value: float):
	sfx_volume = value / 100
	print("SFX Volume:", sfx_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	save_settings()

func _on_BackToGameButton_pressed():
	print("Returning to the game...")
	hide()  # Hide the settings menu
	get_parent().show()  # Show the pause menu again
	get_tree().paused = false  # Resume the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
		print("Settings file found, loading values...")
		music_volume = config.get_value("Audio", "music_volume", 0.5)
		sfx_volume = config.get_value("Audio", "sfx_volume", 0.5)
	else:
		print("Settings file missing or corrupted, using defaults.")
		music_volume = 0.5
		sfx_volume = 0.5

	# Apply the loaded or default values to the audio buses
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

	# Update sliders to reflect loaded values
	$VBoxContainer/MusicSlider.value = music_volume * 100
	$VBoxContainer/SFXSlider.value = sfx_volume * 100

func linear_to_db(value: float) -> float:
	if value > 0:
		return 20.0 * log(value)
	return -80.0

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_BackToGameButton_pressed()
