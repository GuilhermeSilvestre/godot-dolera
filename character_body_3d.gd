extends CharacterBody3D

@onready var navigation_agent_3d = $NavigationAgent3D
@onready var warlock = $warlock1

const SPEED = 7.0

var direction : Vector3
var next_position : Vector3
var fireball_scene = preload("res://fireball.tscn")
var fireball_sound = preload("res://Sounds/fireballsound.mp3")


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
