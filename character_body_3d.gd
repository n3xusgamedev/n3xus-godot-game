extends CharacterBody3D

const SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.01
@export var CONTROLLER_SENSITIVITY = 0.1  # Increased sensitivity for controller camera look-around
@export var INTERACT_KEY: StringName = "ui_accept"
@export var EXIT_KEY: StringName = "ui_cancel"
@export var RUN_KEY: StringName = "ui_run"

var rotation_x: float = 0.0
var interactable: Node = null
var current_vehicle: Node = null
@onready var player_camera: Camera3D = $MeshInstance3D/Camera3D

# Joystick axis IDs for right stick
const JOY_AXIS_RIGHT_X = 2  # Horizontal look
const JOY_AXIS_RIGHT_Y = 3  # Vertical look
const DEADZONE = 0.1        # Deadzone for joystick

var is_paused: bool = false
var pause_menu_instance: Node = null  # Reference to the loaded pause menu instance
const PAUSE_MENU_PATH: String = "res://pause_menu_2.tscn"  # Hardcoded path to the pause menu scene
var pause_menu_scene: PackedScene = preload(PAUSE_MENU_PATH)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Player script ready. Mouse locked.")

	if player_camera:
		player_camera.current = true
		print("Player camera initialized.")
	else:
		print("Error: Player camera not found.")

	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	print("Signals for Area3D connected.")

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		# Handle mouse look-around
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotation_x -= event.relative.y * MOUSE_SENSITIVITY
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		if player_camera:
			player_camera.rotation.x = rotation_x

	if Input.is_action_just_pressed(INTERACT_KEY) and interactable:
		handle_interaction()

	if Input.is_action_just_pressed(EXIT_KEY) and current_vehicle:
		print("Attempting to exit vehicle...")
		if current_vehicle.has_method("exit_jet"):
			print("Exiting jet...")
			current_vehicle.exit_jet()
		elif current_vehicle.has_method("exit_car"):
			print("Exiting car...")
			current_vehicle.exit_car()
		else:
			print("Error: Current vehicle has no valid exit method.")
		current_vehicle = null
		exit_vehicle()

	# Updated pause menu handling
	if (event is InputEventKey and event.pressed and event.keycode == KEY_P) or \
	   (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		toggle_pause_menu()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not is_paused:  # Only handle ESC for mouse capture when not paused
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float):
	if current_vehicle or is_paused:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var speed = SPEED
	if Input.is_action_pressed(RUN_KEY):
		speed = RUN_SPEED

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Controller right stick look-around
	var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	# Apply deadzone and sensitivity
	if abs(right_stick_x) > DEADZONE:
		rotate_y(-right_stick_x * CONTROLLER_SENSITIVITY)
	if abs(right_stick_y) > DEADZONE:
		rotation_x -= right_stick_y * CONTROLLER_SENSITIVITY
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		if player_camera:
			player_camera.rotation.x = rotation_x

func toggle_pause_menu():
	is_paused = not is_paused
	get_tree().paused = is_paused

	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Show cursor when paused
		if pause_menu_scene and not pause_menu_instance:
			pause_menu_instance = pause_menu_scene.instantiate()
			
			if pause_menu_instance is Control:
				print("Adding pause menu to the root.")
				get_tree().root.get_child(0).add_child(pause_menu_instance)
				print("Pause menu loaded and shown.")
			else:
				print("Error: Pause menu is not a Control node.")
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Hide cursor when unpaused
		if pause_menu_instance:
			pause_menu_instance.queue_free()
			pause_menu_instance = null
			print("Pause menu hidden.")

func _on_body_entered(body):
	if body.is_in_group("interactables"):
		interactable = body
		print("Interactable detected: ", body.name)

func _on_body_exited(body):
	if interactable == body:
		interactable = null
		print("Interactable exited: ", body.name)

func handle_interaction():
	if interactable:
		print("Handling interaction with: ", interactable.name)
		if interactable.is_in_group("jets"):
			interactable.enter_jet(self)
			current_vehicle = interactable
			player_camera.current = false
			print("Entered jet and disabled player camera.")
		elif interactable.is_in_group("cars"):
			interactable.enter_car(self)
			current_vehicle = interactable
			player_camera.current = false
			print("Entered car and disabled player camera.")

func exit_vehicle():
	current_vehicle = null  # Clear the reference to the vehicle
	set_physics_process(true)  # Reactivate player controls
	player_camera.current = true  # Switch back to the player's camera
	velocity = Vector3.ZERO  # Reset player velocity
	print("Exited vehicle and player controls restored.")
	
