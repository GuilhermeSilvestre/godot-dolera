extends CharacterBody3D

@onready var navigation_agent_3d = $NavigationAgent3D
@onready var warlock = $warlock1

const SPEED = 9.0

var direction : Vector3
var next_position : Vector3
var fireball_scene = preload("res://fireball.tscn")

func _physics_process(delta):

	navigation_agent_3d.target_position = next_position
	direction = navigation_agent_3d.get_next_path_position() - global_position
	velocity = direction.normalized() * SPEED

	# Rotate warlock towards movement direction
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		warlock.rotation.y = lerp_angle(warlock.rotation.y, target_rotation, delta * 10.0)

	move_and_slide()

	# Cast fireball on right-click
	if Input.is_action_just_pressed("cast_fireball"):
		cast_fireball()

func move_character_click(position : Vector3):
	next_position = position

func cast_fireball():
	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)

	# Calculate forward direction from warlock's Y rotation
	var forward = Vector3(sin(warlock.rotation.y), 0, cos(warlock.rotation.y))

	# Spawn fireball in front of the warlock
	fireball.global_position = global_position + Vector3(0, 1, 0) + forward * 0.8
	fireball.set_direction(forward)
