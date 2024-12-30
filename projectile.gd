extends Node3D

@export var speed: float = 20.0
@export var damage: int = 1  # Damage dealt to enemies
@export var lifetime: float = 5.0  # Time before the projectile disappears
var velocity: Vector3 = Vector3.ZERO

func _ready():
	# Queue free after the projectile's lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float):
	# Move the projectile forward
	global_transform.origin += velocity * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()  # Destroy the projectile on impact
