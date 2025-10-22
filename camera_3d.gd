extends Camera3D

@onready var ray_cast_3d = $RayCast3D
@export var character : CharacterBody3D

var mouse_position : Vector2
var camera_offset : Vector3

# Configurações do zoom
@export var zoom_speed := 1.4
@export var min_fov := 30.0
@export var max_fov := 90.0

func _ready():
	if character:
		camera_offset = global_position - character.global_position

func _process(delta):
	# Segue o personagem
	if character:
		global_position = global_position.lerp(character.global_position + camera_offset, delta * 5.0)

	# Click-to-move
	if Input.is_action_pressed("click_to_move"):
		mouse_position = get_viewport().get_mouse_position()
		ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 100
		ray_cast_3d.force_raycast_update()

		if ray_cast_3d.is_colliding() and "floor" in ray_cast_3d.get_collider().get_groups():
			var position : Vector3 = ray_cast_3d.get_collision_point()
			character.move_character_click(position)

	# Zoom com scroll do mouse
# Captura o scroll do mouse
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			fov = clamp(fov - zoom_speed, min_fov, max_fov)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			fov = clamp(fov + zoom_speed, min_fov, max_fov)
