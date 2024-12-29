extends Node  # or Node3D if appropriate

# Minimum and maximum seconds between lightning flashes
@export var lightning_min_interval: float = 3.0
@export var lightning_max_interval: float = 12.0

# How long the flash should be visible (seconds)
@export var flash_duration: float = 0.2

# How much to boost the brightness during a flash
@export var flash_brightness_boost: float = 1.5

# Path to the thunder sound effect
@export var thunder_sound_path: String = "res://assets/thunder-sound.mp3"

@onready var world_env: WorldEnvironment = $".."
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()  # Dynamically created AudioStreamPlayer

var original_brightness: float = 1.0

func _ready() -> void:
	# Safety check: ensure we have a valid environment
	if not world_env or not world_env.environment:
		printerr("No WorldEnvironment or Environment resource found!")
		return

	# Make sure Adjustments are enabled (so adjusting brightness works)
	world_env.environment.adjustment_enabled = true

	# Store the original environment brightness
	original_brightness = world_env.environment.adjustment_brightness

	# Set up the AudioStreamPlayer for the thunder sound
	add_child(audio_player)
	var thunder_sound = load(thunder_sound_path) as AudioStream
	if thunder_sound:
		audio_player.stream = thunder_sound
	else:
		printerr("Failed to load thunder sound: %s" % thunder_sound_path)

	# Start random lightning loop
	randomize()  # Seeds random number generation
	start_lightning_loop()

func start_lightning_loop() -> void:
	# This runs forever, randomly flashing lightning
	while true:
		# Wait a random delay
		var delay = randf_range(lightning_min_interval, lightning_max_interval)
		await get_tree().create_timer(delay).timeout

		# Trigger a lightning flash
		await trigger_lightning_flash()

func trigger_lightning_flash() -> void:
	# Increase environment brightness by some amount
	world_env.environment.adjustment_brightness = original_brightness + flash_brightness_boost

	# Play the thunder sound
	if audio_player.stream:
		audio_player.play()

	# Wait for the flash duration
	await get_tree().create_timer(flash_duration).timeout

	# Restore original brightness
	world_env.environment.adjustment_brightness = original_brightness
