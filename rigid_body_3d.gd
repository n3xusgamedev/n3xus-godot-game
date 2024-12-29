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

func _ready():
	# Ensure the car camera is initially inactive
	if car_camera:
		car_camera.current = false
		print("Car camera initialized and set to inactive.")
	else:
		print("Error: Car camera not found.")

	print("Car is ready!")

func _physics_process(delta):
	if is_piloted:
		# Handle input and movement when piloted
		handle_input(delta)
		apply_friction(delta)
		move_and_slide()
	else:
		# Ensure the car naturally slows down when not piloted
		apply_friction(delta)

func handle_input(delta):
	var input_direction = 0.0

	# Handle forward and backward movement
	if Input.is_action_pressed("ui_up"):
		input_direction = 1.0
	elif Input.is_action_pressed("ui_down"):
		input_direction = -1.0

	# Apply acceleration or braking
	if input_direction != 0:
		var acceleration_force = acceleration * input_direction * delta
		velocity += global_transform.basis.z * -acceleration_force  # Move forward/backward

	# Limit the speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# Handle turning
	if Input.is_action_pressed("ui_left"):
		rotate_y(turn_speed * delta)
	elif Input.is_action_pressed("ui_right"):
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
		player_ref.set_process(false)
		print("Player hidden and controls disabled.")
	else:
		print("Error: Player reference is null.")

func exit_car():
	print("Player exiting the car.")
	is_piloted = false

	# Restore the player's camera and controls
	if player_ref:
		player_ref.visible = true
		player_ref.set_process(true)
		player_ref.global_transform.origin = global_transform.origin + Vector3(0, 2, 0)  # Place player next to the car
		print("Player repositioned near the car.")
	else:
		print("Error: Player reference is null.")

	# Deactivate the car's camera
	if car_camera:
		car_camera.current = false
		print("Car camera deactivated.")

func _on_Area3D_body_entered(body):
	if body is CharacterBody3D:
		print("Player detected near the car.")
