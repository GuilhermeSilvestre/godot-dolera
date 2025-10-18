extends CharacterBody3D

@onready var navigation_agent_3d = $NavigationAgent3D
@onready var warlock = $warlock1

const SPEED = 9.0

var direction : Vector3
var next_position : Vector3

func _physics_process(delta):

	navigation_agent_3d.target_position = next_position
	direction = navigation_agent_3d.get_next_path_position() - global_position
	velocity = direction.normalized() * SPEED

	# Rotate warlock towards movement direction
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		warlock.rotation.y = lerp_angle(warlock.rotation.y, target_rotation, delta * 10.0)

	move_and_slide()

func move_character_click(position : Vector3):
	next_position = position
	print("Target:", position)
