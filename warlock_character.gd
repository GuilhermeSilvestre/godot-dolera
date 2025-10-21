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
		return  # ainda em cooldown, não faz nada

	can_cast = false  # bloqueia o cast até o cooldown acabar

	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)
	
	# 🔥 Tocar animação da fireball
	var anim_player = fireball.get_node("fireballv1/AnimationPlayer")
	if anim_player:
		anim_player.play("FireballAction")
		
	# 🔊 Criar e tocar som (segue a fireball)
	var player = AudioStreamPlayer3D.new()
	player.stream = fireball_sound
	fireball.add_child(player)
	player.play()

	# 🎯 Direção baseada na rotação do mago
	var forward = warlock.transform.basis.z.normalized()

	# 📍 Posição inicial
	fireball.global_position = warlock.global_position + Vector3(0, 1, 0) + forward * 0.8

	# 🧭 Orientação da fireball
	fireball.look_at(fireball.global_position + forward, Vector3.UP)

	# 🚀 Direção no script
	if fireball.has_method("set_direction"):
		fireball.set_direction(forward)

	# 🕒 Espera 1 segundo antes de permitir outro cast
	await get_tree().create_timer(0.6).timeout
	can_cast = true
