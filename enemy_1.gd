extends CharacterBody3D

@export var patrol_speed: float = 3.0          # Speed while patrolling
@export var chase_speed: float = 6.0           # Speed while chasing the player
@export var patrol_distance: float = 30.0      # Max distance to patrol from the starting position
@export var detection_radius: float = 15.0     # Detection radius for the player
@export var lose_player_distance: float = 20.0 # Distance at which the enemy loses the player
@export var rotation_speed: float = 3.0        # Speed for smooth rotation
@export var step_back_interval: float = 3.0    # Time between step-back actions when chasing
@export var step_back_distance: float = 2.0    # Distance to step back
@export var health: int = 3                    # Enemy's health
@export var random_patrol_variance: float = 45.0  # Maximum angle variance in degrees for random patrol
@export var endpoint_rotation_time: float = 1.0   # Time taken to rotate at patrol endpoints
@export var chase_rotation_speed: float = 5.0     # How fast to rotate towards player while chasing
@export var gravity_multiplier: float = 2.0       # Adjust gravity strength

# Internal state variables
var original_position: Vector3
var patrol_direction: Vector3 = Vector3(0, 0, 1)
var is_chasing: bool = false
var player: Node3D = null
var patrolling_forward: bool = true
var last_step_back_time: float = 0.0
var is_rotating_at_endpoint: bool = false
var rotation_timer: float = 0.0
var target_rotation: Basis
var current_patrol_target: Vector3
var rng = RandomNumberGenerator.new()
var gravity: float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	original_position = global_transform.origin
	connect_signals()
	last_step_back_time = Time.get_ticks_msec() / 1000.0
	rng.randomize()
	set_new_patrol_target()
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	print("Enemy initialized at: ", original_position)

func _physics_process(delta: float) -> void:
	# Store current horizontal velocity
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	
	# Apply gravity first
	if not is_on_floor():
		velocity.y -= gravity * gravity_multiplier * delta
	else:
		# When on floor, apply a small downward force to maintain contact
		velocity.y = -1.0
	
	# Handle movement based on state
	if is_rotating_at_endpoint:
		handle_endpoint_rotation(delta)
		horizontal_velocity = Vector3.ZERO
	elif is_chasing and player:
		chase_player(delta)
		horizontal_velocity = velocity * Vector3(1, 0, 1)  # Preserve horizontal movement
	else:
		patrol(delta)
		horizontal_velocity = velocity * Vector3(1, 0, 1)  # Preserve horizontal movement
	
	# Recombine horizontal movement with vertical velocity
	velocity = Vector3(horizontal_velocity.x, velocity.y, horizontal_velocity.z)
	
	# Apply movement
	move_and_slide()
	
	# Handle rotation if moving
	if horizontal_velocity.length() > 0.1:
		rotate_towards_direction(horizontal_velocity.normalized(), delta)
	
	update_animation()

func patrol(delta: float) -> void:
	if is_rotating_at_endpoint:
		return

	var target_direction = (current_patrol_target - global_transform.origin).normalized()
	var target_velocity = target_direction * patrol_speed
	
	# Only apply to horizontal components
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	
	var distance_to_target = (current_patrol_target - global_transform.origin).length()
	
	if distance_to_target < 0.5:
		start_endpoint_rotation()

func chase_player(delta: float) -> void:
	if not player:
		return

	var dir_to_player = (player.global_transform.origin - global_transform.origin)
	var distance_to_player = dir_to_player.length()
	dir_to_player = dir_to_player.normalized()
	
	# Set horizontal velocity for movement
	var target_velocity = dir_to_player * chase_speed
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	
	# Rotate towards player
	rotate_towards_direction(dir_to_player, delta, chase_rotation_speed)
	
	if distance_to_player > lose_player_distance:
		is_chasing = false
		player = null
		set_new_patrol_target()
		print("Player out of range. Resuming patrol.")
		return

	if distance_to_player < 1.0:
		velocity = velocity.lerp(Vector3.ZERO, delta * 5.0)

	if Time.get_ticks_msec() / 1000.0 - last_step_back_time >= step_back_interval:
		step_back()
		last_step_back_time = Time.get_ticks_msec() / 1000.0

# Rest of the functions remain the same as in the previous version...
func rotate_towards_direction(direction: Vector3, delta: float, custom_speed: float = rotation_speed) -> void:
	if direction.length() < 0.001:
		return
		
	var target_transform = Transform3D().looking_at(direction, Vector3.UP)
	var target_basis = target_transform.basis
	
	var current_basis = global_transform.basis
	var interpolated_transform = current_basis.slerp(target_basis, custom_speed * delta)
	
	global_transform.basis = interpolated_transform

func set_new_patrol_target() -> void:
	var random_angle = rng.randf_range(-random_patrol_variance, random_patrol_variance)
	var rotation_transform = Transform3D().rotated(Vector3.UP, deg_to_rad(random_angle))
	patrol_direction = (rotation_transform.basis * Vector3(0, 0, 1)).normalized()
	
	if patrolling_forward:
		current_patrol_target = original_position + patrol_direction * patrol_distance
	else:
		current_patrol_target = original_position

func start_endpoint_rotation() -> void:
	is_rotating_at_endpoint = true
	rotation_timer = 0.0
	patrolling_forward = !patrolling_forward
	
	var new_direction = -patrol_direction if patrolling_forward else patrol_direction
	var target_transform = Transform3D().looking_at(new_direction, Vector3.UP)
	target_rotation = target_transform.basis
	
	velocity = Vector3.ZERO
	print("Starting endpoint rotation")

func handle_endpoint_rotation(delta: float) -> void:
	rotation_timer += delta
	var rotation_progress = rotation_timer / endpoint_rotation_time
	
	if rotation_progress >= 1.0:
		is_rotating_at_endpoint = false
		set_new_patrol_target()
		print("Endpoint rotation complete")
		return
	
	var current_transform = Transform3D(global_transform.basis)
	var interpolated_transform = current_transform.interpolate_with(Transform3D(target_rotation), rotation_progress)
	global_transform.basis = interpolated_transform.basis

func step_back() -> void:
	var step_back_vector = -velocity.normalized() * step_back_distance
	step_back_vector.y = 0  # Keep y component separate for gravity
	velocity += step_back_vector
	print("Stepping back")

func update_animation() -> void:
	if not animation_player:
		return
		
	if is_rotating_at_endpoint:
		animation_player.stop()
	elif velocity.length() > 0.1:
		animation_player.play("Walk2")
	else:
		animation_player.stop()

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy took damage. Health remaining: ", health)

	if health <= 0:
		die()

func die() -> void:
	print("Enemy has died.")
	animation_player.play("Die")
	queue_free()

func _on_Area3D_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("Player detected! Starting chase.")
		is_chasing = true
		player = body

func _on_Area3D_body_exited(body: Node3D) -> void:
	if body == player:
		print("Player left detection radius. Resuming patrol.")
		is_chasing = false
		player = null
		set_new_patrol_target()

func connect_signals() -> void:
	var detection_area = $Area3D
	if detection_area:
		detection_area.body_entered.connect(_on_Area3D_body_entered)
		detection_area.body_exited.connect(_on_Area3D_body_exited)
		print("Detection signals connected.")
	else:
		print("Error: Detection Area3D not found.")
