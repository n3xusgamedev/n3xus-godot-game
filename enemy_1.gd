extends CharacterBody3D

@export var patrol_speed: float = 3.0          # Speed while patrolling
@export var chase_speed: float = 6.0           # Speed while chasing the player
@export var patrol_distance: float = 10.0      # Max distance to patrol from the starting position
@export var detection_radius: float = 15.0     # Detection radius for the player
@export var lose_player_distance: float = 20.0 # Distance at which the enemy loses the player
@export var rotation_speed: float = 3.0        # Speed for smooth rotation
@export var step_back_interval: float = 3.0    # Time between step-back actions when chasing
@export var step_back_distance: float = 2.0    # Distance to step back
@export var health: int = 3                    # Enemy's health

# Internal state variables
var original_position: Vector3
var patrol_direction: Vector3 = Vector3(0, 0, 1)  # Patrol along +Z
var is_chasing: bool = false
var player: Node3D = null
var patrolling_forward: bool = true
var last_step_back_time: float = 0.0  # Tracks time since the last step-back action

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	original_position = global_transform.origin
	connect_signals()
	last_step_back_time = Time.get_ticks_msec() / 1000.0  # Initialize step-back timer
	print("Enemy initialized at: ", original_position)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)

	if is_chasing and player:
		print("Chasing the player.")
		chase_player(delta)
	else:
		patrol(delta)

	move_and_slide()

	if velocity.length() > 0.01:
		rotate_toward_velocity(delta)

	# Play walking animation if moving
	if velocity.length() > 0:
		animation_player.play("Walk")
	else:
		animation_player.stop()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/3d/default_gravity") * delta

func patrol(delta: float) -> void:
	if is_chasing:
		return

	if patrolling_forward:
		velocity = patrol_direction * patrol_speed
	else:
		velocity = -patrol_direction * patrol_speed

	var distance_from_start = (global_transform.origin - original_position).length()

	if distance_from_start >= patrol_distance and patrolling_forward:
		patrolling_forward = false
		print("Reversing patrol direction to backward.")
	elif distance_from_start <= 0.5 and not patrolling_forward:
		patrolling_forward = true
		print("Reversing patrol direction to forward.")

func chase_player(delta: float) -> void:
	if not player:
		print("No player to chase.")
		return

	var dir_to_player = (player.global_transform.origin - global_transform.origin).normalized()

	# Normalize velocity to avoid excessive tilt
	velocity = dir_to_player * chase_speed
	velocity.y = 0  # Lock Y-axis to prevent tilting up or down

	var distance_to_player = (player.global_transform.origin - global_transform.origin).length()
	if distance_to_player > lose_player_distance:
		is_chasing = false
		player = null
		print("Player out of range. Resuming patrol.")
		return

	# Slow down when very close to the player
	if distance_to_player < 1.0:
		velocity = velocity.lerp(Vector3.ZERO, delta * 5.0)
		print("Slowing down near the player.")

	# Step back periodically
	if Time.get_ticks_msec() / 1000.0 - last_step_back_time >= step_back_interval:
		step_back()
		last_step_back_time = Time.get_ticks_msec() / 1000.0

func step_back() -> void:
	print("Stepping back to allow the player to escape.")
	velocity -= velocity.normalized() * step_back_distance

func rotate_toward_velocity(delta: float) -> void:
	var current_dir = -global_transform.basis.z.normalized()
	var target_dir = velocity.normalized()

	if target_dir.length() < 0.01:
		return

	var rotation_axis = current_dir.cross(target_dir)
	if rotation_axis.length() > 0.01:
		rotation_axis = rotation_axis.normalized()
		var angle = current_dir.angle_to(target_dir)

		var rotation_step = min(rotation_speed * delta, angle)
		global_transform.basis = global_transform.basis.rotated(rotation_axis, rotation_step)

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy took damage. Health remaining: ", health)

	if health <= 0:
		die()

func die() -> void:
	print("Enemy has died.")
	animation_player.play("Die")
	queue_free()

# Signal handlers
func _on_Area3D_body_entered(body: Node3D) -> void:
	print("Body entered: ", body.name, " Groups: ", body.get_groups())
	if body.is_in_group("Player"):
		print("Player detected! Starting chase.")
		is_chasing = true
		player = body
	else:
		print("Non-player entity detected: ", body.name)

func _on_Area3D_body_exited(body: Node3D) -> void:
	print("Body exited: ", body.name)
	if body == player:
		print("Player left detection radius. Resuming patrol.")
		is_chasing = false
		player = null

func connect_signals() -> void:
	var detection_area = $Area3D
	if detection_area:
		detection_area.body_entered.connect(_on_Area3D_body_entered)
		detection_area.body_exited.connect(_on_Area3D_body_exited)
		print("Detection signals connected.")
	else:
		print("Error: Detection Area3D not found.")
