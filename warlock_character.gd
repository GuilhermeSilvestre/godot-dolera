extends CharacterBody3D

@onready var navigation_agent_3d = $NavigationAgent3D
@onready var warlock = $warlock1

const SPEED = 7.0

var direction : Vector3
var next_position : Vector3
var fireball_scene = preload("res://fireball.tscn")
var fireball_sound = preload("res://Sounds/fireballsound.mp3")

@onready var anim_player = $warlock1/AnimationPlayer


func _physics_process(delta):
	var target = navigation_agent_3d.get_next_path_position()
	direction = target - global_position
	direction.y = 0  # evita movimento vertical

	if direction.length() > 0.1:
		velocity = direction.normalized() * SPEED
		
		# Rotaciona o warlock
		var target_rotation = atan2(direction.x, direction.z)
		warlock.rotation.y = lerp_angle(warlock.rotation.y, target_rotation, delta * 10.0)
		
		# 🔥 Toca a animação de walking se não estiver tocando
		if anim_player.current_animation != "Walking":
			anim_player.play("Walking")
	else:
		velocity = Vector3.ZERO  # parado
		
		# Para a animação ou toca idle (se tiver)
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")

	move_and_slide()

	# Fireball
	if Input.is_action_just_pressed("cast_fireball"):
		cast_fireball()


func move_character_click(position: Vector3):
	next_position = position
	navigation_agent_3d.target_position = position


var can_cast = true  # coloque isso fora da função, no topo do script

func cast_fireball():
	if not can_cast:
		return

	can_cast = false

	# 1️⃣ Obter a posição do mouse no mundo 3D
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state

	# 2️⃣ Raycast para encontrar ponto no mundo
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.exclude = [warlock]

	var result = space_state.intersect_ray(params)

	var target_pos: Vector3
	if result:
		target_pos = result.position
	else:
		target_pos = from + camera.project_ray_normal(mouse_pos) * 10  # fallback

	# 3️⃣ Girar o warlock para o mouse
	var dir = target_pos - warlock.global_position
	dir.y = 0
	if dir.length() > 0:
		var target_rotation = atan2(dir.x, dir.z)
		warlock.rotation.y = target_rotation

	# 4️⃣ Instanciar a fireball
	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)

	# Animação da fireball
	var anim_player_fb = fireball.get_node("fireballv2/AnimationPlayer")
	if anim_player_fb:
		anim_player_fb.play("FireballAction")

	# Som
	var player = AudioStreamPlayer3D.new()
	player.stream = fireball_sound
	fireball.add_child(player)
	player.play()

	# 5️⃣ Direção da fireball
	var forward = dir.normalized()
	fireball.global_position = warlock.global_position + Vector3(0, 1, 0) + forward * 0.8
	fireball.look_at(fireball.global_position + forward, Vector3.UP)

	if fireball.has_method("set_direction"):
		fireball.set_direction(forward)

	# 6️⃣ Cooldown
	await get_tree().create_timer(0.6).timeout
	can_cast = true
