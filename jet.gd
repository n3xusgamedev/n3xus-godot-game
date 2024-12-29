extends RigidBody3D

@export var enter_key: String = "ui_accept"  # Button to enter the jet
@export var exit_key: String = "ui_cancel"  # Button to exit the jet
@export var speed: float = 20.0             # Forward speed
@export var vertical_speed: float = 10.0    # Ascend/descend speed
@export var rotation_speed: float = 3.0     # Rotation speed
@export var drag: float = 0.05              # Gradual deceleration resistance
@export var mouse_sensitivity: float = 0.01 # Camera sensitivity

var is_piloted: bool = false                # If the jet is being controlled
var player_ref: CharacterBody3D = null      # Reference to the player
@onready var jet_camera: Camera3D = $JetCamera  # Camera of the jet

var linear_velocity_custom: Vector3 = Vector3.ZERO  # Custom velocity
var angular_velocity_custom: Vector3 = Vector3.ZERO # Custom rotation velocity
var rotation_x: float = 0.0  # Vertical rotation (pitch)

func _ready():
	if jet_camera:
		jet_camera.current = false
		print("Jet camera initialized and set to inactive.")
	else:
		print("Error: Jet camera not found.")

	self.gravity_scale = 1.0  # Jet initially responds to gravity

func _physics_process(delta: float):
	if is_piloted:
		handle_flight(delta)

		if Input.is_action_just_pressed(exit_key):
			exit_jet()
	else:
		linear_velocity_custom = linear_velocity_custom.lerp(Vector3.ZERO, drag * delta)

	apply_movement(delta)

func handle_flight(delta: float):
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("ui_up"):  # Forward
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):  # Backward
		input_dir.z += 1
	if Input.is_action_pressed("ui_page_up"):  # Ascend
		input_dir.y += 1
	if Input.is_action_pressed("ui_page_down"):  # Descend
		input_dir.y -= 1

	if Input.is_action_pressed("ui_left"):  # Rotate left
		angular_velocity_custom.y += rotation_speed * delta
	if Input.is_action_pressed("ui_right"):  # Rotate right
		angular_velocity_custom.y -= rotation_speed * delta

	linear_velocity_custom += global_transform.basis * input_dir * speed * delta
	linear_velocity_custom = linear_velocity_custom.lerp(Vector3.ZERO, drag * delta)

	# Joystick camera control
	var joystick_x = Input.get_axis("right_stick_x", "right_stick_deadzone")
	var joystick_y = Input.get_axis("right_stick_y", "right_stick_deadzone")
	rotate_y(-joystick_x * mouse_sensitivity * 3)
	rotation_x -= joystick_y * mouse_sensitivity * 3
	rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
	if jet_camera:
		jet_camera.rotation.x = rotation_x

func apply_movement(delta: float):
	linear_velocity = linear_velocity_custom
	angular_velocity = angular_velocity_custom

func enter_jet(player):
	print("Player entering the jet.")
	is_piloted = true
	player_ref = player

	if jet_camera:
		jet_camera.current = true
		print("Jet camera activated.")

	if player_ref:
		player_ref.visible = false
		player_ref.set_physics_process(false)
		print("Player hidden and controls disabled.")
	else:
		print("Error: Player reference is null when entering jet.")

	self.gravity_scale = 0.0

func exit_jet():
	print("Player exiting the jet.")
	print("Debug: is_piloted before deactivating: ", is_piloted)
	is_piloted = false

	if player_ref:
		print("Debug: player_ref is valid. Re-enabling player.")
		player_ref.visible = true
		print("Debug: Player visibility set to true.")
		player_ref.set_physics_process(true)
		print("Debug: Player physics process re-enabled.")
		player_ref.global_transform.origin = global_transform.origin + Vector3(0, 2, 0)
		print("Debug: Player repositioned near the jet.")
		player_ref.velocity = Vector3.ZERO  # Reset player velocity
		print("Debug: Player velocity reset.")

		# Explicitly call the character's exit_vehicle() function
		if "exit_vehicle" in player_ref:
			print("Debug: Calling player's exit_vehicle() method.")
			player_ref.exit_vehicle()
		else:
			print("Warning: Player does not have an exit_vehicle method.")

		player_ref = null  # Clear the reference after exiting
		print("Debug: player_ref cleared.")
	else:
		print("Error: Player reference is null when exiting jet.")

	if jet_camera:
		jet_camera.current = false
		print("Jet camera deactivated.")

	self.gravity_scale = 1.0
	print("Debug: Gravity scale restored to 1.0.")
