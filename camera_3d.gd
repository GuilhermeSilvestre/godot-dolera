extends Camera3D

@onready var ray_cast_3d = $RayCast3D
@export var character : CharacterBody3D

var mouse_position : Vector2

func _process(_delta):
	if Input.is_action_just_pressed("click_to_move"):
		mouse_position = get_viewport().get_mouse_position()
		ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 100
		ray_cast_3d.force_raycast_update()
		
		if ray_cast_3d.is_colliding() and "floor" in ray_cast_3d.get_collider().get_groups():
			var position : Vector3 = ray_cast_3d.get_collision_point()
			character.move_character_click(position)
