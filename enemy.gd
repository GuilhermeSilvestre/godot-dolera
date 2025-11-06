extends CharacterBody3D

@export var speed := 4.0
@export var stuck_threshold_time := 1.0
@export var stuck_distance_threshold := 0.05
@export var avoid_touch_distance := 1.0
@export var random_offset_strength := 0.5

var warlock: Node3D
@onready var anim_player = $enemy2/AnimationPlayer
@onready var hit_area = $HitArea  # certifique-se que o nó existe

var stuck_timer := 0.0
var last_pos := Vector3.ZERO
var random_offset := Vector3.ZERO
var initial_y := 0.0
var is_dead := false

func _ready():
	add_to_group("enemies")
	warlock = get_tree().get_first_node_in_group("player")
	last_pos = global_position
	initial_y = global_position.y
	
	# 🔇 Desativa colisão logo ao spawnar
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# 🕒 Reativa colisão depois de 0.2 segundos
	await get_tree().create_timer(0.2).timeout
	collision_layer = 1
	collision_mask = 1

	if anim_player:
		anim_player.play("walking")

	# conecta a detecção de colisão com fireballs
	if hit_area:
		hit_area.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if is_dead:
		return

	if warlock == null:
		return

	var dir = (warlock.global_position - global_position)
	dir.y = 0
	if dir.length() > 0:
		dir = dir.normalized()

	if global_position.distance_to(last_pos) < stuck_distance_threshold:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	last_pos = global_position

	if stuck_timer > stuck_threshold_time:
		if not _is_touching_warlock():
			random_offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		else:
			random_offset = Vector3.ZERO
		stuck_timer = 0.0

	var move_dir = (dir + random_offset * random_offset_strength).normalized()
	move_dir.y = 0
	velocity = move_dir * speed
	move_and_slide()
	global_position.y = initial_y

	if warlock:
		look_at(warlock.global_position, Vector3.UP)
		rotate_y(deg_to_rad(180))

	if anim_player and anim_player.current_animation != "walking":
		anim_player.play("walking")


func _is_touching_warlock() -> bool:
	if warlock == null:
		return false
	return global_position.distance_to(warlock.global_position) <= avoid_touch_distance


# 🚨 Detecta quando algo colide com o "HitArea"
func _on_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("fireballs"):  # fireball deve ter este grupo
		die()


# 💀 Função de morte
func die():
	is_dead = true
	velocity = Vector3.ZERO

	if anim_player and anim_player.has_animation("die"):
		anim_player.speed_scale = 1.5  # 💨 acelera a animação
		anim_player.play("die")

		# 🔊 toca o som de morte do monstro
		var death_sound = AudioStreamPlayer3D.new()
		death_sound.stream = load("res://Sounds/monsterdie.mp3")
		death_sound.volume_db = -6
		add_child(death_sound)
		death_sound.play()
		# Remove o som quando terminar
		death_sound.finished.connect(death_sound.queue_free)

	# ⏳ espera o fim da animação antes de remover o inimigo
	await get_tree().create_timer(0.7).timeout
	queue_free()
