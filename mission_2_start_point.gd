extends Node3D

@export var mission_name: String = "Mission 2"
@export var mission_description: String = "Find and eliminate 5 enemies"
@export var interact_key: String = "ui_accept"

@onready var display_label: Label3D = $Label3D  # Add a Label3D node to the scene
@onready var area3d: Area3D = $Area3D
@onready var mission_objective_label: Label = $UI/MissionObjectiveLabel  # Reference to a UI label for mission objectives

var player_in_area: bool = false
var total_targets: int = 5
var targets_eliminated: int = 0
var mission_active: bool = false

func _ready():
	display_label.visible = false  # Ensure the label is hidden by default
	mission_objective_label.visible = false  # Ensure the mission objective is hidden by default
	area3d.body_entered.connect(_on_body_entered)
	area3d.body_exited.connect(_on_body_exited)
	print("Mission Start Point Ready: ", mission_name)

func _process(delta: float):
	if player_in_area and Input.is_action_just_pressed(interact_key):
		start_mission()

func _on_body_entered(body):
	if body.is_in_group("player"):
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
	if mission_active:
		return

	mission_active = true
	print("Starting mission:", mission_name)
	display_label.text = "Starting " + mission_name
	display_label.visible = false

	# Show mission objective on UI
	update_mission_objective()
	mission_objective_label.visible = true

func update_mission_objective():
	mission_objective_label.text = mission_name + ": " + mission_description + " " + str(targets_eliminated) + "/" + str(total_targets)

func on_enemy_killed():
	if not mission_active:
		return

	targets_eliminated += 1
	update_mission_objective()

	if targets_eliminated >= total_targets:
		complete_mission()

func complete_mission():
	print("Mission completed: ", mission_name)
	mission_active = false
	mission_objective_label.text = mission_name + ": Completed!"
	# Hide the objective after a short delay
	await get_tree().create_timer(3.0).timeout
	mission_objective_label.visible = false
