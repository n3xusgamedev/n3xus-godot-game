extends CharacterBody3D

@export var speed: float = 3.0                # Normal patrol speed
@export var patrol_distance: float = 10.0    # Distance to patrol from the starting point
@export var chase_speed: float = 6.0         # Speed while chasing the player
@export var detection_radius: float = 15.0   # Radius to detect the player
@export var health: int = 3                  # Enemy health
@export var rotation_speed: float = 3.0      # Speed for smooth rotation

# Internal variables
var original_position: Vector3
var patrol_direction: Vector3 = Vector3.FORWARD  # Patrol along +Z
var is_chasing: bool = false
var player: Node3D = null
var patrolling_forward: bool = true            # True if patrolling forward

func _ready() -> void:
	original_position = global_transform.origin
	connect_signals()
	print("Enemy initialized.")

func _physics_process(delta: float) -> void:
	if is_chasing and player:
		chase_player(delta)
	else:
		patrol(delta)

	# Apply velocity and handle collisions
	move_and_slide()

	# Smoothly rotate toward movement direction
	if velocity.length() > 0.01:
		rotate_toward_velocity(delta)

func patrol(delta: float) -> void:
	# Move in the current patrol direction
	if patrolling_forward:
		velocity = patrol_direction * speed
	else:
		velocity = -patrol_direction * speed

	# Calculate distance from the starting position
	var distance_from_start = (global_transform.origin - original_position).length()

	# Reverse direction if exceeding patrol distance, with a buffer
	if distance_from_start >= patrol_distance and patrolling_forward:
		patrolling_forward = false
		print("Reversing patrol direction to backward.")
	elif distance_from_start <= 0.5 and not patrolling_forward:  # Buffer to prevent toggling
		patrolling_forward = true
		print("Reversing patrol direction to forward.")

func chase_player(delta: float) -> void:
	if not player:
		return

	# Calculate direction to the player
	var dir_to_player = (player.global_transform.origin - global_transform.origin).normalized()

	# Set velocity toward the player
	velocity = dir_to_player * chase_speed

	# Slow down if very close to the player
	var distance_to_player = (player.global_transform.origin - global_transform.origin).length()
	if distance_to_player < 1.0:
		velocity = velocity.lerp(Vector3.ZERO, delta * 5.0)
		print("Slowing down near the player.")

func rotate_toward_velocity(delta: float) -> void:
	# Get the current and target directions
	var current_dir = -global_transform.basis.z.normalized()
	var target_dir = velocity.normalized()

	# Skip rotation if velocity is negligible
	if target_dir.length() < 0.01:
		return

	# Calculate rotation axis and angle
	var rotation_axis = current_dir.cross(target_dir)
	if rotation_axis.length() > 0.01:
		rotation_axis = rotation_axis.normalized()
		var angle = current_dir.angle_to(target_dir)

		# Apply rotation smoothly
		var rotation_step = min(rotation_speed * delta, angle)
		global_transform.basis = global_transform.basis.rotated(rotation_axis, rotation_step)

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy took damage. Health remaining: ", health)
	if health <= 0:
		die()

func die() -> void:
	print("Enemy has died.")
	queue_free()

# Signal handlers
func _on_Area3D_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_chasing = true
		player = body
		print("Player detected! Starting chase.")

func _on_Area3D_body_exited(body: Node3D) -> void:
	if body == player:
		is_chasing = false
		player = null
		print("Player left detection radius. Resuming patrol.")

func connect_signals() -> void:
	var detection_area = $Area3D
	detection_area.body_entered.connect(_on_Area3D_body_entered)
	detection_area.body_exited.connect(_on_Area3D_body_exited)
	print("Detection signals connected.")
