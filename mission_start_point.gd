extends Node3D

@export var mission_name: String = "Mission 1"
@export var mission_description: String = "Start your first mission."
@export var interact_key: String = "ui_accept"

@onready var display_label: Label3D = $Label3D  # Add a Label3D node to the scene
@onready var area3d: Area3D = $Area3D

var player_in_area: bool = false

func _ready():
	display_label.visible = false  # Ensure the label is hidden by default
	area3d.body_entered.connect(_on_body_entered)
	area3d.body_exited.connect(_on_body_exited)
	print("Mission Start Point Ready: ", mission_name)

func _process(delta: float):
	if player_in_area and Input.is_action_just_pressed(interact_key):
		start_mission()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_area = true
		display_label.text = "Press 'E' to start " + mission_name
		display_label.visible = true
		print("Player entered mission start point for:", mission_name)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		display_label.visible = false
		print("Player exited mission start point for:", mission_name)

func start_mission():
	print("Starting mission:", mission_name)
	display_label.text = "Starting " + mission_name
	# Add your mission initialization logic here
	display_label.visible = false
