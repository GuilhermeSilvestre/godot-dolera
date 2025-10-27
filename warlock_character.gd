extends CharacterBody3D

@onready var navigation_agent_3d = $NavigationAgent3D
@onready var warlock = $warlock1
@onready var teleport_anim = $teleport/AnimationPlayer 
@onready var anim_player = $warlock1/AnimationPlayer
@onready var reflect_scene = preload("res://Reflect.tscn")

const BASE_SPEED = 7.0
var SPEED = BASE_SPEED

# 🚀 Configurações do Fast Move
const FAST_MOVE_SPEED := 17.0
const FAST_MOVE_DURATION := 0.5       # segundos de duração
const FAST_MOVE_COOLDOWN := 4.0       # segundos de cooldown
var can_fast_move := true
var is_fast_moving := false
var can_reflect := true

# 🔮 Teleporte
var is_teleporting := false
var can_teleport := true
const TELEPORT_COOLDOWN := 5.0
const TELEPORT_MAX_DISTANCE := 10.0
const TELEPORT_DELAY := 1.0

# 🔥 Fireball
var fireball_scene = preload("res://fireball.tscn")
var fireball_sound = preload("res://Sounds/fireballsound.mp3")
var teleport_sound = preload("res://Sounds/teleport.mp3")
var can_cast = true

var direction : Vector3
var next_position : Vector3


func _ready():
	$teleport.visible = false


func _physics_process(delta):
	if Input.is_action_just_pressed("reflect"):
		spawn_reflect()
		
	if is_teleporting:
		velocity = Vector3.ZERO
		return
		
	var target = navigation_agent_3d.get_next_path_position()
	direction = target - global_position
	direction.y = 0
	
	if Input.is_action_just_pressed("teleport"):
		teleport_to_mouse()

	# 🚀 Fast Move (barra de espaço)
	if Input.is_action_just_pressed("fast_move"):
		fast_move()

	if direction.length() > 0.1:
		velocity = direction.normalized() * SPEED

		var target_rotation = atan2(direction.x, direction.z)
		warlock.rotation.y = lerp_angle(warlock.rotation.y, target_rotation, delta * 10.0)

		if anim_player.current_animation != "Walking":
			anim_player.speed_scale = 2.5
			anim_player.play("Walking")
	else:
		velocity = Vector3.ZERO
		if anim_player.current_animation != "Idle":
			anim_player.speed_scale = 1.2
			anim_player.play("Idle")

	move_and_slide()

	if Input.is_action_just_pressed("cast_fireball"):
		cast_fireball()


func move_character_click(position: Vector3):
	next_position = position
	navigation_agent_3d.target_position = position


func cast_fireball():
	if not can_cast:
		return
	can_cast = false

	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.exclude = [warlock]

	var result = space_state.intersect_ray(params)
	var target_pos: Vector3 = result.position if result else from + camera.project_ray_normal(mouse_pos) * 10

	var dir = target_pos - warlock.global_position
	dir.y = 0
	if dir.length() > 0:
		warlock.rotation.y = atan2(dir.x, dir.z)

	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)

	var anim_player_fb = fireball.get_node("fireballv2/AnimationPlayer")
	if anim_player_fb:
		anim_player_fb.play("FireballAction")

	var player = AudioStreamPlayer3D.new()
	player.stream = fireball_sound
	fireball.add_child(player)
	player.play()

	var forward = dir.normalized()
	fireball.global_position = warlock.global_position + Vector3(0, 1, 0) + forward * 0.8
	fireball.look_at(fireball.global_position + forward, Vector3.UP)

	if fireball.has_method("set_direction"):
		fireball.set_direction(forward)

	await get_tree().create_timer(0.6).timeout
	can_cast = true


func teleport_to_mouse():
	if not can_teleport:
		return

	$teleport.visible = true
	can_teleport = false
	is_teleporting = true

	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.exclude = [self]

	var result = space_state.intersect_ray(params)
	if result:
		var target_pos = result.position
		target_pos.y = global_position.y

		var distance = global_position.distance_to(target_pos)
		if distance > TELEPORT_MAX_DISTANCE:
			target_pos = global_position + (target_pos - global_position).normalized() * TELEPORT_MAX_DISTANCE
			target_pos.y = global_position.y

		var player = AudioStreamPlayer3D.new()
		player.stream = teleport_sound
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)

		if teleport_anim:
			teleport_anim.speed_scale = 1.5
			teleport_anim.play("Teleport1")

		warlock.visible = false
		await get_tree().create_timer(TELEPORT_DELAY).timeout

		global_position = target_pos
		navigation_agent_3d.target_position = global_position
		warlock.visible = true

		if teleport_anim:
			teleport_anim.play("Teleport2")

	is_teleporting = false
	await get_tree().create_timer(TELEPORT_COOLDOWN).timeout
	can_teleport = true


# 🚀 Função do Fast Move
func fast_move():
	if not can_fast_move:
		return

	can_fast_move = false
	is_fast_moving = true
	SPEED = FAST_MOVE_SPEED

	await get_tree().create_timer(FAST_MOVE_DURATION).timeout

	SPEED = BASE_SPEED
	is_fast_moving = false

	await get_tree().create_timer(FAST_MOVE_COOLDOWN).timeout
	can_fast_move = true

func spawn_reflect():
	if not can_reflect:
		return  # impede spam

	can_reflect = false  # entra em cooldown

	var reflect = reflect_scene.instantiate()
	get_parent().add_child(reflect)

	# Descobre corretamente qual é a "frente" do Warlock
	var forward = warlock.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	# Define posição na frente do player, rente ao chão
	var distance_from_player := 0.7
	var vertical_offset := 0.1
	var spawn_pos = global_position + forward * distance_from_player
	spawn_pos.y = global_position.y + vertical_offset

	# Mantém rotação sem distorcer escala
	var basis_no_scale = warlock.global_transform.basis.orthonormalized()
	reflect.global_transform = Transform3D(basis_no_scale, spawn_pos)

	# Ajusta escala se necessário
	reflect.scale = Vector3(2.5, 2.5, 2.5)

	# Remove após 1.4 segundos
	var timer := Timer.new()
	timer.wait_time = 1.4
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(reflect):
			reflect.queue_free()
	)
	reflect.add_child(timer)
	timer.start()

	# Espera o cooldown de 2 segundos antes de permitir novamente
	await get_tree().create_timer(3.0).timeout
	can_reflect = true
