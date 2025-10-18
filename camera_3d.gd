extends Camera3D

@onready var ray_cast_3d = $RayCast3D
@export var character : CharacterBody3D

var mouse_position : Vector2
var camera_offset : Vector3

func _ready():
	if character:
		camera_offset = global_position - character.global_position

func _process(delta):
	# Follow character
	if character:
		global_position = global_position.lerp(character.global_position + camera_offset, delta * 5.0)

	if Input.is_action_just_pressed("click_to_move"):
		mouse_position = get_viewport().get_mouse_position()
		ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 100
		ray_cast_3d.force_raycast_update()

		if ray_cast_3d.is_colliding() and "floor" in ray_cast_3d.get_collider().get_groups():
			var position : Vector3 = ray_cast_3d.get_collision_point()
			character.move_character_click(position)
