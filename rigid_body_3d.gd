extends RigidBody3D

@export var acceleration: float = 10.0     # Acceleration force
@export var braking_force: float = 20.0   # Braking force
@export var max_speed: float = 50.0       # Maximum speed
@export var turn_speed: float = 3.0       # Turning speed
@export var friction: float = 1.0         # Friction to slow the car naturally
@export var enter_key: String = "ui_accept"  # Key to enter the car
@export var exit_key: String = "ui_cancel"   # Key to exit the car

var velocity: Vector3 = Vector3.ZERO      # Current velocity
var is_piloted: bool = false              # Whether the car is being controlled by the player
var player_ref: CharacterBody3D = null    # Reference to the player
@onready var car_camera: Camera3D = $CarCamera # Reference to the car's camera

# Controller axis mapping
const JOY_AXIS_L2 = 4  # Sony L2 for reverse
const JOY_AXIS_R2 = 5  # Sony R2 for forward
const JOY_AXIS_LEFT_X = 0  # Sony Left stick horizontal axis
const DEADZONE = 0.1  # Deadzone for joystick inputs

func _ready():
	if car_camera:
		car_camera.current = false
		print("Car camera initialized and set to inactive.")
	else:
		print("Error: Car camera not found.")

	print("Car is ready!")

func _physics_process(delta):
	if is_piloted:
		handle_input(delta)
		apply_friction(delta)
		move_and_slide()
	else:
		apply_friction(delta)

func handle_input(delta):
	var input_direction = 0.0

	# Forward and backward using R2 and L2 (Joystick)
	var forward_input = Input.get_joy_axis(0, JOY_AXIS_R2)  # Controller ID 0
	var backward_input = Input.get_joy_axis(0, JOY_AXIS_L2)

	if forward_input > DEADZONE:
		input_direction += forward_input
	if backward_input > DEADZONE:
		input_direction -= backward_input

	# Forward and backward using keyboard
	if Input.is_action_pressed("move_forward"):
		input_direction += 1.0
	if Input.is_action_pressed("move_backward"):
		input_direction -= 1.0

	# Apply acceleration or braking
	if input_direction != 0:
		var acceleration_force = acceleration * input_direction * delta
		velocity += global_transform.basis.z * -acceleration_force

	# Limit the speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# Turning using left stick (Joystick)
	var turn_input = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if abs(turn_input) > DEADZONE:
		rotate_y(-turn_input * turn_speed * delta)

	# Turning using keyboard
	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * delta)

	# Handle exiting the car
	if Input.is_action_just_pressed(exit_key):
		exit_car()

func apply_friction(delta):
	# Apply friction to naturally slow the car when no input is given
	velocity = velocity.lerp(Vector3.ZERO, friction * delta)

func move_and_slide():
	# Apply the velocity to move the car
	move_and_collide(velocity * get_physics_process_delta_time())

func enter_car(player: CharacterBody3D):
	print("Player entering the car.")
	is_piloted = true
	player_ref = player

	# Switch to the car's camera
	if car_camera:
		car_camera.current = true
		print("Car camera activated.")
	else:
		print("Error: Car camera not found.")

	# Hide the player and disable their controls
	if player_ref:
		player_ref.visible = false
		player_ref.set_physics_process(false)
		print("Player hidden and controls disabled.")
	else:
		print("Error: Player reference is null.")

func exit_car():
	print("Player exiting the car.")
	is_piloted = false

	# Restore the player's camera and controls
	if player_ref:
		player_ref.visible = true
		player_ref.set_physics_process(true)
		player_ref.global_transform.origin = global_transform.origin + Vector3(0, 2, 0)
		print("Player repositioned near the car.")
		player_ref = null
	else:
		print("Error: Player reference is null.")

	# Deactivate the car's camera
	if car_camera:
		car_camera.current = false
		print("Car camera deactivated.")

func _on_Area3D_body_entered(body):
	if body is CharacterBody3D and Input.is_action_pressed(enter_key):
		print("Player detected near the car. Calling enter_car()")
		enter_car(body)

func _on_Area3D_body_exited(body):
	if body == player_ref:
		print("Player exited the car's interaction area.")
