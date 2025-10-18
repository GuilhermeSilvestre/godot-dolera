extends CharacterBody3D

@onready var navigation_agent_3d = $NavigationAgent3D

const SPEED = 9.0

var direction : Vector3
var next_position : Vector3

func _physics_process(_delta):

	navigation_agent_3d.target_position = next_position
	direction = navigation_agent_3d.get_next_path_position() - global_position
	velocity = direction.normalized() * SPEED
	
	move_and_slide()

func move_character_click(position : Vector3):
	next_position = position
	print("Target:", position)
