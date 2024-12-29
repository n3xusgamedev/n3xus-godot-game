extends Control

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var button_container: VBoxContainer = $PanelContainer/VBoxContainer/Buttons

# Text to display
var full_text: String = "N3xus"
var glitch_characters: Array = ["@", "#", "$", "%", "&", "*", "!", "?"]
var reveal_speed: float = 0.35  # Seconds between each character reveal

func _enter_tree() -> void:
	# Captures the mouse pointer at start
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready() -> void:
	print("Main Menu loaded.")

	# Ensure UI elements exist
	if title_label == null:
		printerr("Error: TitleLabel not found.")
		return
	if button_container == null:
		printerr("Error: ButtonContainer not found.")
		return

	# Hide buttons initially
	button_container.visible = false

	# Load a TTF/OTF font using 'load()' or 'ResourceLoader.load()'
	var font_file: FontFile = load("res://TransformersMovie.ttf") as FontFile
	if font_file == null:
		printerr("Failed to load font resource!")
		return
	
	# Apply the font to the label as a theme override
	title_label.add_theme_font_override("font", font_file)
	# Override the font size via a theme override
	title_label.add_theme_font_size_override("font_size", 64)

	# Start the title animation
	await animate_title()

	# Show buttons after the animation and restore mouse visibility
	button_container.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Focus on the first button
	if button_container.get_child_count() > 0:
		button_container.get_child(0).grab_focus()

func animate_title() -> void:
	if title_label == null:
		printerr("Error: TitleLabel is null.")
		return

	title_label.text = ""  # Clear the label text
	var displayed_text: String = ""

	# Loop through each character in the text
	for char in full_text:
		# Add a short glitch effect before revealing the actual character
		for i in range(3):
			if title_label:
				title_label.text = displayed_text + randomize_glitch()
			await get_tree().create_timer(reveal_speed / 4.0).timeout

		# Reveal the actual character
		displayed_text += char
		if title_label:
			title_label.text = displayed_text
		await get_tree().create_timer(reveal_speed).timeout

	print("Title animation complete.")

func randomize_glitch() -> String:
	# Generate a random glitch character
	return glitch_characters[randi() % glitch_characters.size()]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		# Focus on the next button
		navigate_buttons(1)
	elif event.is_action_pressed("ui_up"):
		# Focus on the previous button
		navigate_buttons(-1)
	elif event.is_action_pressed("ui_accept"):
		# Trigger the focused button's pressed signal
		var focused = get_tree().focus_owner
		if focused and focused is Button:
			focused.emit_signal("pressed")

func navigate_buttons(direction: int) -> void:
	# Get the currently focused button
	var focused = get_tree().focus_owner

	# Find the next or previous button in the button container
	var index = button_container.get_children().find(focused)
	var next_index = (index + direction) % button_container.get_child_count()
	if next_index < 0:
		next_index = button_container.get_child_count() - 1  # Wrap around

	# Focus on the next button
	var next_button = button_container.get_child(next_index)
	if next_button and next_button is Button:
		next_button.grab_focus()

func _on_start_game_pressed() -> void:
	print("Starting game...")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var result = get_tree().change_scene_to_file("res://world.tscn")
	if result != OK:
		printerr("Error loading scene: %d" % result)
	else:
		print("Scene loaded successfully!")

func _on_settings_button_pressed() -> void:
	print("Opening settings menu...")
	var result = get_tree().change_scene_to_file("res://settings_menu.tscn")
	if result != OK:
		printerr("Error loading settings menu: %d" % result)
	else:
		print("Settings menu loaded successfully!")

func _on_quit_button_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()
