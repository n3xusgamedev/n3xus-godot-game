extends CharacterBody3D

@export var speed: float = 3.0
@export var patrol_distance: float = 10.0
@export var chase_speed: float = 6.0
@export var detection_radius: float = 15.0
@export var health: int = 3
@export var rotation_speed: float = 5.0

var original_position: Vector3
var patrol_direction: Vector3 = Vector3.FORWARD  # Patrol along +Z by default
var is_chasing: bool = false
var player: Node3D = null  # Reference to the player

func _ready() -> void:
	original_position = global_transform.origin
	connect_signals()

func _physics_process(delta: float) -> void:
	# If you need gravity, uncomment or adjust as needed:
	# self.velocity.y -= 9.8 * delta
	
	# Reset vertical velocity if you want strictly horizontal movement
	self.velocity.y = 0.0
	
	if is_chasing and player:
		chase_player(delta)
	else:
		patrol(delta)

	# In Godot 4, move_and_slide() uses the built-in velocity
	# and returns 'true' if a collision happened, otherwise 'false'.
	move_and_slide()
	
	# Rotate to face movement direction
	if self.velocity.length() > 0.01:
		rotate_toward_direction(delta)

func patrol(delta: float) -> void:
	# We'll only set x/z velocity for horizontal patrolling
	# self.velocity is a built-in in CharacterBody3D
	self.velocity.x = 0.0
	self.velocity.z = 0.0

	# Move in patrol_direction
	self.velocity += patrol_direction * speed

	# Reverse direction if we've gone beyond the patrol distance
	var distance_from_start = (global_transform.origin - original_position).length()
	if distance_from_start >= patrol_distance:
		patrol_direction = -patrol_direction

func chase_player(delta: float) -> void:
	# Reset horizontal velocity before setting chase direction
	self.velocity.x = 0.0
	self.velocity.z = 0.0
	
	var dir_to_player = (player.global_transform.origin - global_transform.origin).normalized()
	self.velocity += dir_to_player * chase_speed

	# Optionally slow down if very close to the player
	if (player.global_transform.origin - global_transform.origin).length() < 1.0:
		self.velocity = self.velocity.lerp(Vector3.ZERO, delta * 5.0)

func rotate_toward_direction(delta: float) -> void:
	# Enemy's forward is -basis.z in Godot 3D
	var current_dir = -global_transform.basis.z
	var target_dir = self.velocity.normalized()

	if target_dir.length() < 0.01:
		return

	var rotation_axis = current_dir.cross(target_dir).normalized()
	var angle = current_dir.angle_to(target_dir)

	if angle > 0.01:
		var rotation_step = min(rotation_speed * delta, angle)
		global_transform.basis = global_transform.basis.rotated(rotation_axis, rotation_step)

func _on_Area3D_body_entered(body: Node3D) -> void:
	# If using a name check:
	# if body.name == "Player":
	#     is_chasing = true
	#     player = body
	
	# If using a group instead (recommended):
	if body.is_in_group("Player"):
		is_chasing = true
		player = body

func _on_Area3D_body_exited(body: Node3D) -> void:
	if body == player:
		is_chasing = false
		player = null

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func connect_signals() -> void:
	var detection_area = $Area3D
	detection_area.body_entered.connect(_on_Area3D_body_entered)
	detection_area.body_exited.connect(_on_Area3D_body_exited)
